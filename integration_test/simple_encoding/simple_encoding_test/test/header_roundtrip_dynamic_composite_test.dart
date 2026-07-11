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

  group('DynamicCompositeValue header roundtrip', () {
    group('with FlexibleValue variant (primitive)', () {
      test('roundtrips FlexibleValue with string', () async {
        const input = DynamicCompositeValue(
          flexibleValue: FlexibleValue(string: 'hello'),
        );

        final result = await api.testHeaderRoundtripDynamicComposite(
          dynamicValue: input,
        );

        expect(
          result,
          isA<
            TonikSuccess<HeadersRoundtripComplexDynamicCompositeGet200Response>
          >(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexDynamicCompositeGet200Response
                >;
        expect(
          success.value.xDynamicValue!.flexibleValue!.string,
          'hello',
        );
      });

      test('roundtrips FlexibleValue with integer', () async {
        const input = DynamicCompositeValue(
          flexibleValue: FlexibleValue(int: 42),
        );

        final result = await api.testHeaderRoundtripDynamicComposite(
          dynamicValue: input,
        );

        expect(
          result,
          isA<
            TonikSuccess<HeadersRoundtripComplexDynamicCompositeGet200Response>
          >(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexDynamicCompositeGet200Response
                >;
        expect(success.value.xDynamicValue!.flexibleValue!.int, 42);
      });

      test('roundtrips FlexibleValue with boolean', () async {
        const input = DynamicCompositeValue(
          flexibleValue: FlexibleValue(bool: true),
        );

        final result = await api.testHeaderRoundtripDynamicComposite(
          dynamicValue: input,
        );

        expect(
          result,
          isA<
            TonikSuccess<HeadersRoundtripComplexDynamicCompositeGet200Response>
          >(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexDynamicCompositeGet200Response
                >;
        expect(success.value.xDynamicValue!.flexibleValue!.bool, isTrue);
      });
    });

    group('with FlexibleValue variant (complex SimpleObject)', () {
      test('roundtrips FlexibleValue with SimpleObject', () async {
        const input = DynamicCompositeValue(
          flexibleValue: FlexibleValue(
            simpleObject: SimpleObject(name: 'test-object', value: 100),
          ),
        );

        final result = await api.testHeaderRoundtripDynamicComposite(
          dynamicValue: input,
        );

        expect(
          result,
          isA<
            TonikSuccess<HeadersRoundtripComplexDynamicCompositeGet200Response>
          >(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexDynamicCompositeGet200Response
                >;
        final object =
            success.value.xDynamicValue!.flexibleValue!.simpleObject;
        expect(object?.name, 'test-object');
        expect(object?.value, 100);
      });
    });

    group('with EntityType variant (discriminated)', () {
      test('roundtrips CompanyEntity', () async {
        const company = CompanyEntity(
          $type: CompanyEntityTypeModel.company,
          companyName: 'Acme Inc',
        );
        const input = DynamicCompositeValue(
          entityType: EntityTypeCompanyEntity(company),
        );

        final result = await api.testHeaderRoundtripDynamicComposite(
          dynamicValue: input,
        );

        expect(
          result,
          isA<
            TonikSuccess<HeadersRoundtripComplexDynamicCompositeGet200Response>
          >(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexDynamicCompositeGet200Response
                >;
        final entity = success.value.xDynamicValue!.entityType;
        expect(entity, isA<EntityTypeCompanyEntity>());
        expect(
          (entity! as EntityTypeCompanyEntity).value.companyName,
          'Acme Inc',
        );
      });

      test('roundtrips PersonEntity', () async {
        const person = PersonEntity(
          $type: PersonEntityTypeModel.person,
          firstName: 'John',
          lastName: 'Doe',
        );
        const input = DynamicCompositeValue(
          entityType: EntityTypePersonEntity(person),
        );

        final result = await api.testHeaderRoundtripDynamicComposite(
          dynamicValue: input,
        );

        expect(
          result,
          isA<
            TonikSuccess<HeadersRoundtripComplexDynamicCompositeGet200Response>
          >(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexDynamicCompositeGet200Response
                >;
        final entity = success.value.xDynamicValue!.entityType;
        expect(entity, isA<EntityTypePersonEntity>());
        final decoded = (entity! as EntityTypePersonEntity).value;
        expect(decoded.firstName, 'John');
        expect(decoded.lastName, 'Doe');
      });
    });

    group('with CompositeEntity variant (allOf)', () {
      test('roundtrips CompositeEntity', () async {
        final input = DynamicCompositeValue(
          compositeEntity: CompositeEntity(
            baseEntity: const BaseEntity(name: 'entity-123'),
            timestampMixin: TimestampMixin(
              createdAt: DateTime.utc(2024, 1, 15),
              updatedAt: DateTime.utc(2024, 1, 16),
            ),
            compositeEntityModel: const CompositeEntityModel(
              specificField: 'Test Entity',
            ),
          ),
        );

        final result = await api.testHeaderRoundtripDynamicComposite(
          dynamicValue: input,
        );

        expect(
          result,
          isA<
            TonikSuccess<HeadersRoundtripComplexDynamicCompositeGet200Response>
          >(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexDynamicCompositeGet200Response
                >;
        final composite = success.value.xDynamicValue!.compositeEntity;
        expect(composite?.baseEntity.name, 'entity-123');
        expect(composite?.compositeEntityModel.specificField, 'Test Entity');
        expect(composite?.timestampMixin.createdAt, DateTime.utc(2024, 1, 15));
        expect(composite?.timestampMixin.updatedAt, DateTime.utc(2024, 1, 16));
      });
    });

    group('with multiple variants set', () {
      test('fails when FlexibleValue has mixed shapes', () async {
        // FlexibleValue with both primitive (string) and complex (SimpleObject)
        // should cause encoding error due to mixed shapes
        const input = DynamicCompositeValue(
          flexibleValue: FlexibleValue(
            string: 'hello',
            simpleObject: SimpleObject(name: 'test', value: 1),
          ),
        );

        final result = await api.testHeaderRoundtripDynamicComposite(
          dynamicValue: input,
        );

        expect(
          result,
          isA<
            TonikError<HeadersRoundtripComplexDynamicCompositeGet200Response>
          >(),
        );
        final error =
            result
                as TonikError<
                  HeadersRoundtripComplexDynamicCompositeGet200Response
                >;
        expect(error.type, TonikErrorType.encoding);
      });

      test('two complex variants merge into one property map and decode back',
          () async {
        // Both variants share one merged property map, so either decodes
        // from it.
        const company = CompanyEntity(
          $type: CompanyEntityTypeModel.company,
          companyName: 'Acme',
        );
        final input = DynamicCompositeValue(
          entityType: const EntityTypeCompanyEntity(company),
          compositeEntity: CompositeEntity(
            baseEntity: const BaseEntity(name: 'id'),
            timestampMixin: TimestampMixin(
              createdAt: DateTime.utc(2024),
              updatedAt: DateTime.utc(2024),
            ),
            compositeEntityModel: const CompositeEntityModel(
              specificField: 'name',
            ),
          ),
        );

        final result = await api.testHeaderRoundtripDynamicComposite(
          dynamicValue: input,
        );

        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexDynamicCompositeGet200Response
                >;
        final value = success.value.xDynamicValue!;
        final entity = value.entityType;
        expect(entity, isA<EntityTypeCompanyEntity>());
        expect((entity! as EntityTypeCompanyEntity).value.companyName, 'Acme');
        expect(value.compositeEntity?.baseEntity.name, 'id');
        expect(
          value.compositeEntity?.compositeEntityModel.specificField,
          'name',
        );
      });
    });

    group('server-originated response', () {
      test('literal percent sequences in an injected dynamic-composite header '
          'decode verbatim', () async {
        // Server-originated: X-Dynamic-Value is injected via Dio, not
        // sent by Tonik's encoder.
        final injected = SimpleEncodingApi(
          CustomServer(
            baseUrl: baseUrl,
            serverConfig: ServerConfig(
              baseOptions: BaseOptions(
                headers: {
                  'X-Response-Status': '200',
                  'X-Dynamic-Value': 'name,x%2Fy 50%,value,9',
                },
              ),
            ),
          ),
        );

        final result = await injected.testHeaderRoundtripDynamicComposite();

        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexDynamicCompositeGet200Response
                >;
        expect(success.value.xDynamicValue, isNotNull);
        expect(success.value.xDynamicValue!.flexibleValue, isNotNull);
        expect(
          success.value.xDynamicValue!.flexibleValue!.simpleObject,
          isNotNull,
        );
        expect(
          success.value.xDynamicValue!.flexibleValue!.simpleObject!.name,
          'x%2Fy 50%',
        );
      });
    });
  });
}
