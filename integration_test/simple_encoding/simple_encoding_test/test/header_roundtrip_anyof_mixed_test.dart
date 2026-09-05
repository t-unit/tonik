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

  group('AnyOfMixed (FlexibleValue) header roundtrip', () {
    group('string variant', () {
      test('round-trips string value', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(string: 'hello'),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.headers['x-mixed-value'], 'hello');
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.string, 'hello');
      });
    });

    group('integer variant', () {
      test('round-trips integer value', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(int: 42),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.headers['x-mixed-value'], '42');
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.int, 42);
      });
    });

    group('boolean variant', () {
      test('round-trips true', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(bool: true),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.headers['x-mixed-value'], 'true');
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.bool, true);
      });

      test('round-trips false', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(bool: false),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.headers['x-mixed-value'], 'false');
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.bool, false);
      });
    });

    group('SimpleObject variant', () {
      test('round-trips SimpleObject with both fields', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(
            simpleObject: SimpleObject(name: 'test', value: 42),
          ),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();

        expect(recordedRequest.headers['x-mixed-value'], 'name,test,value,42');
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.simpleObject, isNotNull);
        expect(success.value.xMixedValue!.simpleObject!.name, 'test');
        expect(success.value.xMixedValue!.simpleObject!.value, 42);
      });

      test('round-trips SimpleObject with only name', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(
            simpleObject: SimpleObject(name: 'onlyName'),
          ),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.simpleObject, isNotNull);
        expect(success.value.xMixedValue!.simpleObject!.name, 'onlyName');
      });

      test('round-trips SimpleObject with only value', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(
            simpleObject: SimpleObject(value: 99),
          ),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.simpleObject, isNotNull);
        expect(success.value.xMixedValue!.simpleObject!.value, 99);
      });
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripAnyOfMixed.call();

          expect(result, isTonikSuccess);
          final success = requireSuccess(result);
          final recordedRequest = await imposterServer.takeRequest();
          expect(recordedRequest.headers['x-mixed-value'], isNull);
          expect(success.value.xMixedValue, isNull);
        },
      );
    });
  });
}
