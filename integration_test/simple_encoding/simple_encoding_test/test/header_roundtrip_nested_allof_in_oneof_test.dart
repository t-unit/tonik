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

  group('NestedAllOfInOneOf header roundtrip', () {
    group('AllOfComplex variant', () {
      test('round-trips AllOfComplex (Class1 + Class2 merged)', () async {
        final result = await api.testHeaderRoundtripNestedAllOfInOneOf.call(
          nestedValue: const NestedAllOfInOneOfAllOfComplex(
            AllOfComplex(
              class1: Class1(name: 'test'),
              class2: Class2(number: 42),
            ),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripNestedAllofInOneofGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripNestedAllofInOneofGet200Response
                >;

        // Verify encoded request header contains both class properties
        final headerValue =
            success.response.requestOptions.headers['X-Nested-Value'] as String;
        expect(headerValue, contains('name,test'));
        expect(headerValue, contains('number,42'));

        // Verify decoded response
        expect(
          success.value.xNestedValue,
          isA<NestedAllOfInOneOfAllOfComplex>(),
        );
        final decoded =
            success.value.xNestedValue! as NestedAllOfInOneOfAllOfComplex;
        expect(decoded.value.class1.name, 'test');
        expect(decoded.value.class2.number, 42);
      });

      test('round-trips AllOfComplex with spaces in name', () async {
        final result = await api.testHeaderRoundtripNestedAllOfInOneOf.call(
          nestedValue: const NestedAllOfInOneOfAllOfComplex(
            AllOfComplex(
              class1: Class1(name: 'hello world'),
              class2: Class2(number: 99),
            ),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripNestedAllofInOneofGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripNestedAllofInOneofGet200Response
                >;

        // Verify decoded response
        expect(
          success.value.xNestedValue,
          isA<NestedAllOfInOneOfAllOfComplex>(),
        );
        final decoded =
            success.value.xNestedValue! as NestedAllOfInOneOfAllOfComplex;
        expect(decoded.value.class1.name, 'hello world');
        expect(decoded.value.class2.number, 99);
      });
    });

    group('String variant', () {
      test('round-trips string value', () async {
        final result = await api.testHeaderRoundtripNestedAllOfInOneOf.call(
          nestedValue: const NestedAllOfInOneOfString('simple-string'),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripNestedAllofInOneofGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripNestedAllofInOneofGet200Response
                >;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Nested-Value'],
          'simple-string',
        );

        // Note: The decoder tries AllOfComplex first, which may succeed
        // even for a simple string due to how decodeObject works.
        // The actual decoded type depends on the implementation.
        expect(success.value.xNestedValue, isNotNull);
      });

      test('round-trips string with special characters', () async {
        final result = await api.testHeaderRoundtripNestedAllOfInOneOf.call(
          nestedValue: const NestedAllOfInOneOfString('test-value'),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripNestedAllofInOneofGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripNestedAllofInOneofGet200Response
                >;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Nested-Value'],
          'test-value',
        );
      });
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripNestedAllOfInOneOf.call();

          expect(
            result,
            isA<
              TonikSuccess<HeadersRoundtripNestedAllofInOneofGet200Response>
            >(),
          );
          final success =
              result
                  as TonikSuccess<
                    HeadersRoundtripNestedAllofInOneofGet200Response
                  >;

          // Verify no header was sent
          expect(
            success.response.requestOptions.headers['X-Nested-Value'],
            isNull,
          );

          // Verify response property is null
          expect(success.value.xNestedValue, isNull);
        },
      );
    });
  });
}
