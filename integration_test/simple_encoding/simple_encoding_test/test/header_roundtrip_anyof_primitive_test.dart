import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
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

  group('AnyOfPrimitive header roundtrip', () {
    group('string variant', () {
      test('round-trips simple string', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(string: 'hello'),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Flexible-Value'],
          'hello',
        );

        // Verify decoded response
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.string, 'hello');
      });

      test('round-trips string with spaces', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(string: 'hello world'),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>;

        // Verify encoded request header (spaces URL encoded)
        expect(
          success.response.requestOptions.headers['X-Flexible-Value'],
          'hello%20world',
        );

        // Verify decoded response
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.string, 'hello world');
      });

      test('empty string fails at encoding', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(string: ''),
        );

        expect(
          result,
          isA<TonikError<HeadersRoundtripAnyofPrimitiveGet200Response>>(),
        );
        final error =
            result as TonikError<HeadersRoundtripAnyofPrimitiveGet200Response>;

        expect(error.type, TonikErrorType.encoding);
        expect(error.response, isNull);
      });
    });

    group('integer variant', () {
      test('round-trips positive integer', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(int: 42),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Flexible-Value'],
          '42',
        );

        // Verify decoded response - note: anyOf may decode multiple variants
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.int, 42);
      });

      test('round-trips zero', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(int: 0),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Flexible-Value'],
          '0',
        );

        // Verify decoded response
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.int, 0);
      });

      test('round-trips negative integer', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(int: -123),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Flexible-Value'],
          '-123',
        );

        // Verify decoded response
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.int, -123);
      });
    });

    group('boolean variant', () {
      test('round-trips true', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(bool: true),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Flexible-Value'],
          'true',
        );

        // Verify decoded response
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.bool, true);
      });

      test('round-trips false', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(bool: false),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Flexible-Value'],
          'false',
        );

        // Verify decoded response
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.bool, false);
      });
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripAnyOfPrimitive.call();

          expect(
            result,
            isA<TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>>(),
          );
          final success =
              result
                  as TonikSuccess<HeadersRoundtripAnyofPrimitiveGet200Response>;

          // Verify no header was sent
          expect(
            success.response.requestOptions.headers['X-Flexible-Value'],
            isNull,
          );

          // Verify response property is null
          expect(success.value.xFlexibleValue, isNull);
        },
      );
    });
  });
}
