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

  group('NestedOneOfInAllOf header roundtrip', () {
    // Combining simple and complex branches makes header encoding invalid.

    group('encoding fails for mixed shapes', () {
      test('string variant with metadata fails at encoding', () async {
        final result = await api.testHeaderRoundtripNestedOneOfInAllOf.call(
          nestedValue: const NestedOneOfInAllOf(
            oneOfPrimitive: OneOfPrimitiveString('test'),
            nestedOneOfInAllOfModel: NestedOneOfInAllOfModel(metadata: 'meta'),
          ),
        );

        expect(result, isTonikError);
        final error = requireError(result);

        expect(error.type, TonikErrorType.encoding);
        expect(error.response, isNull);
      });

      test('integer variant with metadata fails at encoding', () async {
        final result = await api.testHeaderRoundtripNestedOneOfInAllOf.call(
          nestedValue: const NestedOneOfInAllOf(
            oneOfPrimitive: OneOfPrimitiveInt(42),
            nestedOneOfInAllOfModel: NestedOneOfInAllOfModel(metadata: 'info'),
          ),
        );

        expect(result, isTonikError);
        final error = requireError(result);

        expect(error.type, TonikErrorType.encoding);
        expect(error.response, isNull);
      });

      test('without metadata still fails at encoding', () async {
        final result = await api.testHeaderRoundtripNestedOneOfInAllOf.call(
          nestedValue: const NestedOneOfInAllOf(
            oneOfPrimitive: OneOfPrimitiveString('value'),
            nestedOneOfInAllOfModel: NestedOneOfInAllOfModel(),
          ),
        );

        expect(result, isTonikError);
        final error = requireError(result);

        expect(error.type, TonikErrorType.encoding);
      });
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripNestedOneOfInAllOf.call();

          expect(result, isTonikSuccess);
          final success = requireSuccess(result);
          final recordedRequest = await imposterServer.takeRequest();
          expect(recordedRequest.headers['x-nested-value'], isNull);
          expect(success.value.xNestedValue, isNull);
        },
      );
    });
  });
}
