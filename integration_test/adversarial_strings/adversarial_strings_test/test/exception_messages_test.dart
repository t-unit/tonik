import 'package:adversarial_strings_api/adversarial_strings_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late AdversarialApi api;

  setUpAll(() async {
    final server = await setupImposterServer();
    api = AdversarialApi(
      CustomServer(
        baseUrl: 'http://localhost:${server.port}/v1',
        serverConfig: testServerConfig(),
      ),
    );
  });

  test('binary cookie error preserves the dollar sign', () async {
    final result = await api.rejectBinaryCookie($ab: const TonikFileBytes([1]));

    final error = requireError(result);
    expect(error.type, TonikErrorType.encoding);
    expect(
      error.error,
      isA<EncodingException>().having(
        (e) => e.message,
        'message',
        r'Binary data cannot be form-encoded for cookie a$b',
      ),
    );
  });

  test('required header error does not interpolate hashCode', () async {
    final result = await api.rejectComplexHeader($foohashCode: const []);

    final error = requireError(result);
    expect(error.type, TonikErrorType.encoding);
    expect(
      error.error,
      isA<EncodingException>().having(
        (e) => e.message,
        'message',
        'Simple encoding does not support list with complex elements '
            r'for header X-Foo$hashCode',
      ),
    );
  });

  test('optional header only fails when supplied', () async {
    final omitted = await api.rejectOptionalComplexHeader();
    expect(omitted, isTonikSuccess);

    final supplied = await api.rejectOptionalComplexHeader(
      $foohashCode: const [],
    );
    final error = requireError(supplied);
    expect(error.type, TonikErrorType.encoding);
    expect(
      error.error,
      isA<EncodingException>().having(
        (e) => e.message,
        'message',
        'Simple encoding does not support list with complex elements '
            r'for header X-Foo$hashCode',
      ),
    );
  });

  test('simple path error preserves the backslash', () async {
    final result = await api.rejectBinaryPath(
      pathBackslashName: const TonikFileBytes([1]),
    );

    final error = requireError(result);
    expect(error.type, TonikErrorType.encoding);
    expect(
      error.error,
      isA<EncodingException>().having(
        (e) => e.message,
        'message',
        r'Simple encoding does not support binary values for path parameter path\name',
      ),
    );
  });

  test('matrix path error preserves the dollar sign', () async {
    final result = await api.rejectNestedMatrix($ab: const []);

    final error = requireError(result);
    expect(error.type, TonikErrorType.encoding);
    expect(
      error.error,
      isA<EncodingException>().having(
        (e) => e.message,
        'message',
        'Matrix encoding does not support arrays of objects or nested arrays '
            r'for path parameter a$b',
      ),
    );
  });

  test('single response header error preserves the dollar sign', () async {
    final result = await api.rejectResponseHeader();

    final error = requireError(result);
    expect(error.type, TonikErrorType.decoding);
    expect(
      error.error,
      isA<SimpleDecodingException>().having(
        (e) => e.message,
        'message',
        r'Nested lists are not supported in simple encoding at X-Foo$hashCode',
      ),
    );
  });

  test('multiple response header error preserves the dollar sign', () async {
    final result = await api.rejectMultiResponseHeader();

    final error = requireError(result);
    expect(error.type, TonikErrorType.decoding);
    expect(
      error.error,
      isA<SimpleDecodingException>().having(
        (e) => e.message,
        'message',
        r'Nested lists are not supported in simple encoding at X-Foo$hashCode',
      ),
    );
  });

  test('unexpected response still interpolates runtime diagnostics', () async {
    final result = await api.getQuotedContentType();

    final error = requireError(result);
    expect(error.type, TonikErrorType.decoding);
    expect(
      error.error,
      isA<ResponseDecodingException>().having(
        (e) => e.message,
        'message',
        'Unexpected content type: text/plain; charset=utf-8 '
            '(matched as: text/plain) for status code: 418',
      ),
    );
  });
}
