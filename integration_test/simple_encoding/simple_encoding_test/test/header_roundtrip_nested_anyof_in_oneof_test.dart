import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

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
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
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
          isTonikSuccess,
        );
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.headers['x-nested-value'],
          '42',
        );
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
          isTonikSuccess,
        );
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.headers['x-nested-value'],
          'number,99',
        );
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
          isTonikSuccess,
        );
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();

        // PriorityEnum.three has raw value 3.
        expect(
          recordedRequest.headers['x-nested-value'],
          '3',
        );

        // Integer decoding may succeed first.
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
          isTonikSuccess,
        );
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.headers['x-nested-value'],
          'true',
        );

        // AnyOfMixed is tried first.
        expect(success.value.xNestedValue, isNotNull);
      });

      test('round-trips boolean false', () async {
        final result = await api.testHeaderRoundtripNestedAnyOfInOneOf.call(
          nestedValue: const NestedAnyOfInOneOfBool(false),
        );

        expect(
          result,
          isTonikSuccess,
        );
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.headers['x-nested-value'],
          'false',
        );
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
            isTonikSuccess,
          );
          final success = requireSuccess(result);
          final recordedRequest = await imposterServer.takeRequest();
          expect(
            recordedRequest.headers['x-nested-value'],
            isNull,
          );
          expect(success.value.xNestedValue, isNull);
        },
      );
    });
  });
}
