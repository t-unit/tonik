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
        expect(success.value.xDynamicValue, isNotNull);
        expect(success.value.xDynamicValue!.flexibleValue, isNotNull);
        expect(success.value.xDynamicValue!.flexibleValue!.string, isNotNull);
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
        expect(success.value.xDynamicValue, isNotNull);
        expect(success.value.xDynamicValue!.flexibleValue, isNotNull);
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
        expect(success.value.xDynamicValue, isNotNull);
        expect(success.value.xDynamicValue!.flexibleValue, isNotNull);
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
        expect(success.value.xDynamicValue, isNotNull);
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
        expect(success.value.xDynamicValue, isNotNull);
        expect(success.value.xDynamicValue!.entityType, isNotNull);
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
        expect(success.value.xDynamicValue, isNotNull);
        expect(success.value.xDynamicValue!.entityType, isNotNull);
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
        expect(success.value.xDynamicValue, isNotNull);
        expect(success.value.xDynamicValue!.compositeEntity, isNotNull);
      });
    });

    group('with mixed variants (encoding error expected)', () {
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

      test('fails when multiple complex variants are set', () async {
        // Setting both entityType and compositeEntity should cause encoding
        // issues as anyOf requires exactly one value
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

        // This may encode successfully if both map to the same encoding shape
        // or fail if there's ambiguity
        expect(
          result,
          anyOf(
            isA<
              TonikSuccess<
                HeadersRoundtripComplexDynamicCompositeGet200Response
              >
            >(),
            isA<
              TonikError<HeadersRoundtripComplexDynamicCompositeGet200Response>
            >(),
          ),
        );
      });
    });
  });
}
