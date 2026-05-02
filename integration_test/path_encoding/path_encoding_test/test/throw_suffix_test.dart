import 'package:dio/dio.dart';
import 'package:path_encoding_api/path_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

/// Runtime checks that operations whose path parameter cannot be simple-
/// encoded surface an `EncodingException` (wrapped in `TonikError` with
/// type `encoding`) instead of producing an invalid URL like `<throw>.json`.
///
/// These tests pair with the `/simple/throw-suffix/...` fixtures: those only
/// verify the generated code compiles. These tests verify it BEHAVES.
void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  SimpleApi buildSimpleApi() {
    return SimpleApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(baseOptions: BaseOptions()),
      ),
    );
  }

  void expectEncodingError(
    TonikResult<EchoResponse> response, {
    required String parameterName,
  }) {
    expect(response, isA<TonikError<EchoResponse>>());
    final error = response as TonikError<EchoResponse>;
    expect(error.type, TonikErrorType.encoding);
    expect(error.error, isA<EncodingException>());
    final exception = error.error as EncodingException;
    expect(
      exception.message.contains('path parameter $parameterName'),
      isTrue,
      reason:
          'message "${exception.message}" should reference '
          'path parameter $parameterName',
    );
  }

  group('Simple style - throw-producing path parameters with suffix', () {
    test('map with complex (object) value type returns encoding error',
        () async {
      final api = buildSimpleApi();
      final response = await api.testSimpleMapComplexWithSuffix(
        m: const {'k': SimpleObject(name: 'n', count: 1)},
      );

      expectEncodingError(response, parameterName: 'm');
    });

    test('map with list value type returns encoding error', () async {
      final api = buildSimpleApi();
      final response = await api.testSimpleMapListWithSuffix(
        m: const {
          'k': ['a', 'b'],
        },
      );

      expectEncodingError(response, parameterName: 'm');
    });

    test('map with oneOf-of-simple-members value type returns encoding error',
        () async {
      final api = buildSimpleApi();
      final response = await api.testSimpleMapOneOfSimpleWithSuffix(
        m: const {
          'k': SimpleThrowSuffixMapOneofSimpleMJsonParametersMapOneOfModelInt(
            42,
          ),
        },
      );

      expectEncodingError(response, parameterName: 'm');
    });

    test('binary path parameter returns encoding error', () async {
      final api = buildSimpleApi();
      final response = await api.testSimpleBinaryWithSuffix(
        p: const TonikFileBytes([1, 2, 3]),
      );

      expectEncodingError(response, parameterName: 'p');
    });

    test('list of binary path parameter returns encoding error', () async {
      final api = buildSimpleApi();
      final response = await api.testSimpleListBinaryWithSuffix(
        p: const [TonikFileBytes([1, 2, 3])],
      );

      expectEncodingError(response, parameterName: 'p');
    });

    test('aliased map of complex objects returns encoding error', () async {
      final api = buildSimpleApi();
      final response = await api.testSimpleAliasMapComplexWithSuffix(
        p: const {'k': SimpleObject(name: 'n', count: 1)},
      );

      expectEncodingError(response, parameterName: 'p');
    });

    // testSimpleAliasNeverWithSuffix is intentionally skipped: its path
    // parameter has type `NeverSchema` (a typedef for `Never`), which has
    // no inhabitants — there is no value the test could pass to invoke it.
    // The fixture file still verifies the generated code compiles and that
    // `_path` would throw if it were ever reachable.
  });
}
