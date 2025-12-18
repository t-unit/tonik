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
        isA<TonikSuccess<HeadersRoundtripAllofPrimitivesGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripAllofPrimitivesGet200Response>;

      // Verify encoded request header (simple style: key,value,key,value)
      expect(
        success.response.requestOptions.headers['X-Merged-Object'],
        anyOf(
          'count,42,id,abc',
          'id,abc,count,42',
        ),
      );

      // Verify decoded response
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
        isA<TonikSuccess<HeadersRoundtripAllofPrimitivesGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripAllofPrimitivesGet200Response>;

      // Verify decoded response
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
        isA<TonikSuccess<HeadersRoundtripAllofPrimitivesGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripAllofPrimitivesGet200Response>;

      // Verify decoded response
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
        isA<TonikSuccess<HeadersRoundtripAllofPrimitivesGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripAllofPrimitivesGet200Response>;

      // Verify decoded response
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
            isA<TonikSuccess<HeadersRoundtripAllofPrimitivesGet200Response>>(),
          );
          final success =
              result
                  as TonikSuccess<
                    HeadersRoundtripAllofPrimitivesGet200Response
                  >;

          // Verify no header was sent
          expect(
            success.response.requestOptions.headers['X-Merged-Object'],
            isNull,
          );

          // Verify response property is null
          expect(success.value.xMergedObject, isNull);
        },
      );
    });
  });
}
