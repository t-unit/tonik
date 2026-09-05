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

  group('AnyOfPrimitive header roundtrip', () {
    group('string variant', () {
      test('round-trips simple string', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(string: 'hello'),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.headers['x-flexible-value'], 'hello');
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.string, 'hello');
      });

      test('round-trips string with spaces', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(string: 'hello world'),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();

        // Header field-values are transmitted literally: the space survives.
        expect(recordedRequest.headers['x-flexible-value'], 'hello world');
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.string, 'hello world');
      });

      test('round-trips empty string', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(string: ''),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();

        expect(recordedRequest.headers['x-flexible-value'], '');
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.string, '');
      });
    });

    group('integer variant', () {
      test('round-trips positive integer', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(int: 42),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.headers['x-flexible-value'], '42');

        // anyOf may decode multiple variants.
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.int, 42);
      });

      test('round-trips zero', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(int: 0),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.headers['x-flexible-value'], '0');
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.int, 0);
      });

      test('round-trips negative integer', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(int: -123),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.headers['x-flexible-value'], '-123');
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.int, -123);
      });
    });

    group('boolean variant', () {
      test('round-trips true', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(bool: true),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.headers['x-flexible-value'], 'true');
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.bool, true);
      });

      test('round-trips false', () async {
        final result = await api.testHeaderRoundtripAnyOfPrimitive.call(
          flexibleValue: const AnyOfPrimitive(bool: false),
        );

        expect(result, isTonikSuccess);
        final success = requireSuccess(result);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.headers['x-flexible-value'], 'false');
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.bool, false);
      });
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripAnyOfPrimitive.call();

          expect(result, isTonikSuccess);
          final success = requireSuccess(result);
          final recordedRequest = await imposterServer.takeRequest();
          expect(recordedRequest.headers['x-flexible-value'], isNull);
          expect(success.value.xFlexibleValue, isNull);
        },
      );
    });

    group('server-originated response', () {
      test('literal percent sequences in an injected anyOf header '
          'decode verbatim', () async {
        // Server-originated: X-Flexible-Value is injected via Dio, not
        // sent by Tonik's encoder.
        final injected = SimpleEncodingApi(
          CustomServer(
            baseUrl: baseUrl,
            serverConfig: testServerConfig(
              headers: {
                'X-Response-Status': '200',
                'X-Flexible-Value': 'a%2Fb 50%',
              },
            ),
          ),
        );

        final result = await injected.testHeaderRoundtripAnyOfPrimitive.call();

        final success = requireSuccess(result);
        expect(success.value.xFlexibleValue, isNotNull);
        expect(success.value.xFlexibleValue!.string, 'a%2Fb 50%');
      });
    });
  });
}
