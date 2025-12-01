import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8085;
  const baseUrl = 'http://localhost:$port/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  SimpleEncodingApi buildApi({required String responseStatus}) {
    return SimpleEncodingApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  late SimpleEncodingApi api;

  setUp(() {
    api = buildApi(responseStatus: '200');
  });

  group('OneOfPrimitive header roundtrip', () {
    group('OneOfPrimitiveInt', () {
      test('round-trips positive integer', () async {
        final result = await api.testHeaderRoundtripOneOfPrimitive.call(
          primitiveUnion: const OneOfPrimitiveInt(42),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Primitive-Union'],
          '42',
        );

        // Verify decoded response
        expect(success.value.xPrimitiveUnion, isA<OneOfPrimitiveInt>());
        expect(
          (success.value.xPrimitiveUnion! as OneOfPrimitiveInt).value,
          42,
        );
      });

      test('round-trips zero', () async {
        final result = await api.testHeaderRoundtripOneOfPrimitive.call(
          primitiveUnion: const OneOfPrimitiveInt(0),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Primitive-Union'],
          '0',
        );

        // Verify decoded response
        expect(success.value.xPrimitiveUnion, isA<OneOfPrimitiveInt>());
        expect(
          (success.value.xPrimitiveUnion! as OneOfPrimitiveInt).value,
          0,
        );
      });

      test('round-trips negative integer', () async {
        final result = await api.testHeaderRoundtripOneOfPrimitive.call(
          primitiveUnion: const OneOfPrimitiveInt(-123),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Primitive-Union'],
          '-123',
        );

        // Verify decoded response
        expect(success.value.xPrimitiveUnion, isA<OneOfPrimitiveInt>());
        expect(
          (success.value.xPrimitiveUnion! as OneOfPrimitiveInt).value,
          -123,
        );
      });

      test('round-trips large integer', () async {
        final result = await api.testHeaderRoundtripOneOfPrimitive.call(
          primitiveUnion: const OneOfPrimitiveInt(9999999),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Primitive-Union'],
          '9999999',
        );

        // Verify decoded response
        expect(success.value.xPrimitiveUnion, isA<OneOfPrimitiveInt>());
        expect(
          (success.value.xPrimitiveUnion! as OneOfPrimitiveInt).value,
          9999999,
        );
      });
    });

    group('OneOfPrimitiveString', () {
      test('round-trips simple string', () async {
        final result = await api.testHeaderRoundtripOneOfPrimitive.call(
          primitiveUnion: const OneOfPrimitiveString('hello'),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Primitive-Union'],
          'hello',
        );

        // Verify decoded response
        expect(success.value.xPrimitiveUnion, isA<OneOfPrimitiveString>());
        expect(
          (success.value.xPrimitiveUnion! as OneOfPrimitiveString).value,
          'hello',
        );
      });

      test('round-trips string with spaces', () async {
        final result = await api.testHeaderRoundtripOneOfPrimitive.call(
          primitiveUnion: const OneOfPrimitiveString('hello world'),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>;

        // Verify encoded request header (spaces are URL encoded)
        expect(
          success.response.requestOptions.headers['X-Primitive-Union'],
          'hello%20world',
        );

        // Verify decoded response
        expect(success.value.xPrimitiveUnion, isA<OneOfPrimitiveString>());
        expect(
          (success.value.xPrimitiveUnion! as OneOfPrimitiveString).value,
          'hello world',
        );
      });

      test('empty string fails at encoding', () async {
        final result = await api.testHeaderRoundtripOneOfPrimitive.call(
          primitiveUnion: const OneOfPrimitiveString(''),
        );

        // Empty strings throw EmptyValueException during encoding
        // because allowEmpty is false for headers
        expect(
          result,
          isA<TonikError<HeadersRoundtripOneofPrimitiveGet200Response>>(),
        );
        final error =
            result as TonikError<HeadersRoundtripOneofPrimitiveGet200Response>;

        // Verify this is an encoding error (not a network or decoding error)
        expect(error.type, TonikErrorType.encoding);

        // No response because request was never sent
        expect(error.response, isNull);
      });

      test('round-trips numeric string', () async {
        // Note: A numeric string might be decoded as integer
        final result = await api.testHeaderRoundtripOneOfPrimitive.call(
          primitiveUnion: const OneOfPrimitiveString('12345'),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Primitive-Union'],
          '12345',
        );

        // Numeric strings may be decoded as OneOfPrimitiveInt since
        // integer parsing is typically tried first in oneOf decoding
        expect(
          success.value.xPrimitiveUnion,
          anyOf(isA<OneOfPrimitiveString>(), isA<OneOfPrimitiveInt>()),
        );
      });
    });

    group('null handling', () {
      test('handles null primitiveUnion parameter', () async {
        final result = await api.testHeaderRoundtripOneOfPrimitive.call();

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripOneofPrimitiveGet200Response>;

        // Verify header is not present when null
        expect(
          success.response.requestOptions.headers['X-Primitive-Union'],
          isNull,
        );

        // Verify decoded response
        expect(success.value.xPrimitiveUnion, isNull);
      });
    });
  });
}
