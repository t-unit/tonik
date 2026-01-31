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

  group('CompositeEntity (AllOf simple) header roundtrip', () {
    test('round-trips with all required fields only', () async {
      final result = await api.testHeaderRoundtripAllOfSimple.call(
        compositeEntity: CompositeEntity(
          baseEntity: const BaseEntity(name: 'TestEntity'),
          timestampMixin: TimestampMixin(
            createdAt: DateTime.utc(2024, 1, 15, 10, 30),
          ),
          compositeEntityModel: const CompositeEntityModel(
            specificField: 'specific-value',
          ),
        ),
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripAllofSimpleGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripAllofSimpleGet200Response>;

      // Verify encoded request header contains all fields
      final headerValue =
          success.response.requestOptions.headers['X-Composite-Entity']
              as String;
      expect(headerValue, contains('name,TestEntity'));
      expect(headerValue, contains('specific_field,specific-value'));
      expect(headerValue, contains('created_at,'));

      // Verify decoded response
      expect(success.value.xCompositeEntity, isNotNull);
      expect(success.value.xCompositeEntity!.baseEntity.name, 'TestEntity');
      expect(
        success.value.xCompositeEntity!.compositeEntityModel.specificField,
        'specific-value',
      );
    });

    test('round-trips with all fields including optional', () async {
      final result = await api.testHeaderRoundtripAllOfSimple.call(
        compositeEntity: CompositeEntity(
          baseEntity: const BaseEntity(
            name: 'FullEntity',
            description: 'A complete entity',
          ),
          timestampMixin: TimestampMixin(
            createdAt: DateTime.utc(2024, 1, 15, 10, 30),
            updatedAt: DateTime.utc(2024, 6, 20, 14, 45),
          ),
          compositeEntityModel: const CompositeEntityModel(
            specificField: 'full-value',
          ),
        ),
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripAllofSimpleGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripAllofSimpleGet200Response>;

      // Verify decoded response
      expect(success.value.xCompositeEntity, isNotNull);
      expect(success.value.xCompositeEntity!.baseEntity.name, 'FullEntity');
      expect(
        success.value.xCompositeEntity!.baseEntity.description,
        'A complete entity',
      );
      expect(
        success.value.xCompositeEntity!.compositeEntityModel.specificField,
        'full-value',
      );
    });

    test('verifies datetime encoding format (ISO 8601)', () async {
      final createdAt = DateTime.utc(2024, 3, 10, 8, 15, 30);
      final result = await api.testHeaderRoundtripAllOfSimple.call(
        compositeEntity: CompositeEntity(
          baseEntity: const BaseEntity(name: 'DateTest'),
          timestampMixin: TimestampMixin(createdAt: createdAt),
          compositeEntityModel: const CompositeEntityModel(
            specificField: 'date-test',
          ),
        ),
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripAllofSimpleGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripAllofSimpleGet200Response>;

      // Verify the datetime was correctly decoded
      expect(success.value.xCompositeEntity, isNotNull);
      expect(
        success.value.xCompositeEntity!.timestampMixin.createdAt,
        createdAt,
      );
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripAllOfSimple.call();

          expect(
            result,
            isA<TonikSuccess<HeadersRoundtripAllofSimpleGet200Response>>(),
          );
          final success =
              result as TonikSuccess<HeadersRoundtripAllofSimpleGet200Response>;

          // Verify no header was sent
          expect(
            success.response.requestOptions.headers['X-Composite-Entity'],
            isNull,
          );

          // Verify response property is null
          expect(success.value.xCompositeEntity, isNull);
        },
      );
    });
  });
}
