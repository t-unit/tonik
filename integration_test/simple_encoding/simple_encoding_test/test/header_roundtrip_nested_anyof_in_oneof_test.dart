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

  group('NestedAnyOfInOneOf header roundtrip', () {
    group('AnyOfMixed variant', () {
      test('round-trips AnyOfMixed with integer', () async {
        final result = await api.testHeaderRoundtripNestedAnyOfInOneOf.call(
          nestedValue: const NestedAnyOfInOneOfAnyOfMixed(
            AnyOfMixed(int: 42),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripNestedAnyofInOneofGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripNestedAnyofInOneofGet200Response
                >;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Nested-Value'],
          '42',
        );

        // Verify decoded response
        expect(success.value.xNestedValue, isA<NestedAnyOfInOneOfAnyOfMixed>());
        final decoded =
            success.value.xNestedValue! as NestedAnyOfInOneOfAnyOfMixed;
        expect(decoded.value.int, 42);
      });

      test('round-trips AnyOfMixed with Class2', () async {
        final result = await api.testHeaderRoundtripNestedAnyOfInOneOf.call(
          nestedValue: const NestedAnyOfInOneOfAnyOfMixed(
            AnyOfMixed(class2: Class2(number: 99)),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripNestedAnyofInOneofGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripNestedAnyofInOneofGet200Response
                >;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Nested-Value'],
          'number,99',
        );

        // Verify decoded response
        expect(success.value.xNestedValue, isA<NestedAnyOfInOneOfAnyOfMixed>());
        final decoded =
            success.value.xNestedValue! as NestedAnyOfInOneOfAnyOfMixed;
        expect(decoded.value.class2, isNotNull);
        expect(decoded.value.class2!.number, 99);
      });

      test('round-trips AnyOfMixed with PriorityEnum', () async {
        final result = await api.testHeaderRoundtripNestedAnyOfInOneOf.call(
          nestedValue: const NestedAnyOfInOneOfAnyOfMixed(
            AnyOfMixed(priorityEnum: PriorityEnum.three),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripNestedAnyofInOneofGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripNestedAnyofInOneofGet200Response
                >;

        // Verify encoded request header (PriorityEnum.three has value 3)
        expect(
          success.response.requestOptions.headers['X-Nested-Value'],
          '3',
        );

        // Verify decoded response - note: integer decoding may succeed first
        expect(success.value.xNestedValue, isNotNull);
      });
    });

    group('Boolean variant', () {
      test('round-trips boolean true', () async {
        final result = await api.testHeaderRoundtripNestedAnyOfInOneOf.call(
          nestedValue: const NestedAnyOfInOneOfBool(true),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripNestedAnyofInOneofGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripNestedAnyofInOneofGet200Response
                >;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Nested-Value'],
          'true',
        );

        // Verify decoded response - AnyOfMixed will be tried first
        expect(success.value.xNestedValue, isNotNull);
      });

      test('round-trips boolean false', () async {
        final result = await api.testHeaderRoundtripNestedAnyOfInOneOf.call(
          nestedValue: const NestedAnyOfInOneOfBool(false),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripNestedAnyofInOneofGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripNestedAnyofInOneofGet200Response
                >;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Nested-Value'],
          'false',
        );

        // Verify decoded response
        expect(success.value.xNestedValue, isNotNull);
      });
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripNestedAnyOfInOneOf.call();

          expect(
            result,
            isA<
              TonikSuccess<HeadersRoundtripNestedAnyofInOneofGet200Response>
            >(),
          );
          final success =
              result
                  as TonikSuccess<
                    HeadersRoundtripNestedAnyofInOneofGet200Response
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
