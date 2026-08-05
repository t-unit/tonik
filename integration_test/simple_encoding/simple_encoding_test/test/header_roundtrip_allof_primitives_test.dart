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

  group('AllOfPrimitive header roundtrip', () {
    test('round-trips with both fields set', () async {
      final result = await api.testHeaderRoundtripAllOfPrimitives.call(
        mergedObject: const AllOfPrimitive(
          allOfPrimitiveModel: AllOfPrimitiveModel(count: 42),
          allOfPrimitiveModel2: AllOfPrimitiveModel2(id: 'abc'),
        ),
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      final recordedRequest = await imposterServer.takeRequest();

      expect(
        recordedRequest.headers['x-merged-object'],
        anyOf(
          'count,42,id,abc',
          'id,abc,count,42',
        ),
      );
      expect(success.value.xMergedObject, isNotNull);
      expect(success.value.xMergedObject!.allOfPrimitiveModel.count, 42);
      expect(success.value.xMergedObject!.allOfPrimitiveModel2.id, 'abc');
    });

    test('round-trips with only id set', () async {
      final result = await api.testHeaderRoundtripAllOfPrimitives.call(
        mergedObject: const AllOfPrimitive(
          allOfPrimitiveModel: AllOfPrimitiveModel(),
          allOfPrimitiveModel2: AllOfPrimitiveModel2(id: 'onlyId'),
        ),
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.value.xMergedObject, isNotNull);
      expect(success.value.xMergedObject!.allOfPrimitiveModel2.id, 'onlyId');
    });

    test('round-trips with only count set', () async {
      final result = await api.testHeaderRoundtripAllOfPrimitives.call(
        mergedObject: const AllOfPrimitive(
          allOfPrimitiveModel: AllOfPrimitiveModel(count: 99),
          allOfPrimitiveModel2: AllOfPrimitiveModel2(),
        ),
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.value.xMergedObject, isNotNull);
      expect(success.value.xMergedObject!.allOfPrimitiveModel.count, 99);
    });

    test('round-trips with negative count', () async {
      final result = await api.testHeaderRoundtripAllOfPrimitives.call(
        mergedObject: const AllOfPrimitive(
          allOfPrimitiveModel: AllOfPrimitiveModel(count: -5),
          allOfPrimitiveModel2: AllOfPrimitiveModel2(id: 'neg'),
        ),
      );

      expect(
        result,
        isTonikSuccess,
      );
      final success = requireSuccess(result);
      expect(success.value.xMergedObject, isNotNull);
      expect(success.value.xMergedObject!.allOfPrimitiveModel.count, -5);
      expect(success.value.xMergedObject!.allOfPrimitiveModel2.id, 'neg');
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripAllOfPrimitives.call();

          expect(
            result,
            isTonikSuccess,
          );
          final success = requireSuccess(result);
          final recordedRequest = await imposterServer.takeRequest();
          expect(
            recordedRequest.headers['x-merged-object'],
            isNull,
          );
          expect(success.value.xMergedObject, isNull);
        },
      );
    });
  });
}
