import 'package:big_decimal/big_decimal.dart';
import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

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

  group('Header Roundtrip OneOf Discriminated', () {
    group('PersonEntity', () {
      test('person entity with required fields only roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripOneOfDiscriminated(
          entity: const EntityTypePersonEntity(
            PersonEntity(
              $type: PersonEntityTypeModel.person,
              firstName: 'John',
            ),
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripOneofDiscriminatedGet200Response>>(),
        );
        final success =
            response
                as TonikSuccess<
                  HeadersRoundtripOneofDiscriminatedGet200Response
                >;
        expect(success.response.statusCode, 200);

        expect(success.value.xEntity, isA<EntityTypePersonEntity>());
        final entity = success.value.xEntity! as EntityTypePersonEntity;
        expect(entity.value.$type, PersonEntityTypeModel.person);
        expect(entity.value.firstName, 'John');
        expect(entity.value.lastName, isNull);
        expect(entity.value.age, isNull);
        expect(entity.value.birthDate, isNull);
      });

      test('person entity with all fields roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final birthDate = Date(1990, 5, 15);
        final response = await api.testHeaderRoundtripOneOfDiscriminated(
          entity: EntityTypePersonEntity(
            PersonEntity(
              $type: PersonEntityTypeModel.person,
              firstName: 'Jane',
              lastName: 'Doe',
              age: 34,
              birthDate: birthDate,
            ),
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripOneofDiscriminatedGet200Response>>(),
        );
        final success =
            response
                as TonikSuccess<
                  HeadersRoundtripOneofDiscriminatedGet200Response
                >;
        expect(success.response.statusCode, 200);

        expect(success.value.xEntity, isA<EntityTypePersonEntity>());
        final entity = success.value.xEntity! as EntityTypePersonEntity;
        expect(entity.value.$type, PersonEntityTypeModel.person);
        expect(entity.value.firstName, 'Jane');
        expect(entity.value.lastName, 'Doe');
        expect(entity.value.age, 34);
        expect(entity.value.birthDate, birthDate);
      });

      test('person entity with special characters in name roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripOneOfDiscriminated(
          entity: const EntityTypePersonEntity(
            PersonEntity(
              $type: PersonEntityTypeModel.person,
              firstName: 'Jose Maria',
              lastName: "O'Brien",
            ),
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripOneofDiscriminatedGet200Response>>(),
        );
        final success =
            response
                as TonikSuccess<
                  HeadersRoundtripOneofDiscriminatedGet200Response
                >;

        expect(success.value.xEntity, isA<EntityTypePersonEntity>());
        final entity = success.value.xEntity! as EntityTypePersonEntity;
        expect(entity.value.firstName, 'Jose Maria');
        expect(entity.value.lastName, "O'Brien");
      });
    });

    group('CompanyEntity', () {
      test('company entity with required fields only roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripOneOfDiscriminated(
          entity: const EntityTypeCompanyEntity(
            CompanyEntity(
              $type: CompanyEntityTypeModel.company,
              companyName: 'Acme Corp',
            ),
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripOneofDiscriminatedGet200Response>>(),
        );
        final success =
            response
                as TonikSuccess<
                  HeadersRoundtripOneofDiscriminatedGet200Response
                >;
        expect(success.response.statusCode, 200);

        expect(success.value.xEntity, isA<EntityTypeCompanyEntity>());
        final entity = success.value.xEntity! as EntityTypeCompanyEntity;
        expect(entity.value.$type, CompanyEntityTypeModel.company);
        expect(entity.value.companyName, 'Acme Corp');
        expect(entity.value.foundedYear, isNull);
        expect(entity.value.revenue, isNull);
        expect(entity.value.website, isNull);
      });

      test('company entity with all fields roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripOneOfDiscriminated(
          entity: EntityTypeCompanyEntity(
            CompanyEntity(
              $type: CompanyEntityTypeModel.company,
              companyName: 'Tech Innovations',
              foundedYear: 2010,
              revenue: BigDecimal.parse('1500000.50'),
              website: Uri.parse('https://techinnovations.com'),
            ),
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripOneofDiscriminatedGet200Response>>(),
        );
        final success =
            response
                as TonikSuccess<
                  HeadersRoundtripOneofDiscriminatedGet200Response
                >;
        expect(success.response.statusCode, 200);

        expect(success.value.xEntity, isA<EntityTypeCompanyEntity>());
        final entity = success.value.xEntity! as EntityTypeCompanyEntity;
        expect(entity.value.$type, CompanyEntityTypeModel.company);
        expect(entity.value.companyName, 'Tech Innovations');
        expect(entity.value.foundedYear, 2010);
        expect(entity.value.revenue, BigDecimal.parse('1500000.50'));
        expect(
          entity.value.website,
          Uri.parse('https://techinnovations.com'),
        );
      });

      test(
        'company entity with special characters in name roundtrip',
        () async {
          final api = buildApi(responseStatus: '200');
          final response = await api.testHeaderRoundtripOneOfDiscriminated(
            entity: const EntityTypeCompanyEntity(
              CompanyEntity(
                $type: CompanyEntityTypeModel.company,
                companyName: 'Muller & Sons GmbH',
              ),
            ),
          );

          expect(
            response,
            isA<
              TonikSuccess<HeadersRoundtripOneofDiscriminatedGet200Response>
            >(),
          );
          final success =
              response
                  as TonikSuccess<
                    HeadersRoundtripOneofDiscriminatedGet200Response
                  >;

          expect(success.value.xEntity, isA<EntityTypeCompanyEntity>());
          final entity = success.value.xEntity! as EntityTypeCompanyEntity;
          expect(entity.value.companyName, 'Muller & Sons GmbH');
        },
      );
    });

    // NOTE: SystemEntity cannot be serialized with simple encoding because
    // the OpenAPI schema defines it with a nested 'config' object property.
    // Per the OpenAPI spec, simple style only supports flat key-value pairs
    // (RFC 6570 Section 3.2.2), so the generator correctly throws an
    // EncodingException for any SystemEntity instance, even if config is null.
    group('SystemEntity', () {
      test(
        'system entity fails encoding because schema has nested object '
        '(simple encoding limitation per OpenAPI spec)',
        () async {
          final api = buildApi(responseStatus: '200');
          final response = await api.testHeaderRoundtripOneOfDiscriminated(
            entity: const EntityTypeSystemEntity(
              SystemEntity(
                $type: SystemEntityTypeModel.system,
                systemId: 'sys-001',
              ),
            ),
          );

          // Simple encoding does not support types with nested object
          // properties.
          // The generator correctly throws EncodingException because
          // SystemEntity's schema includes a nested 'config' object.
          expect(
            response,
            isA<TonikError<HeadersRoundtripOneofDiscriminatedGet200Response>>(),
          );
          final error =
              response
                  as TonikError<
                    HeadersRoundtripOneofDiscriminatedGet200Response
                  >;
          expect(error.error, isA<EncodingException>());
        },
      );

      test(
        'system entity with primitive fields also fails encoding '
        '(schema-level limitation)',
        () async {
          final api = buildApi(responseStatus: '200');
          final response = await api.testHeaderRoundtripOneOfDiscriminated(
            entity: const EntityTypeSystemEntity(
              SystemEntity(
                $type: SystemEntityTypeModel.system,
                systemId: 'sys-main-002',
                version: '2.5.0',
                active: true,
              ),
            ),
          );

          // Even without config set, the schema defines a nested object,
          // so simple encoding is not supported for this type.
          expect(
            response,
            isA<TonikError<HeadersRoundtripOneofDiscriminatedGet200Response>>(),
          );
          final error =
              response
                  as TonikError<
                    HeadersRoundtripOneofDiscriminatedGet200Response
                  >;
          expect(error.error, isA<EncodingException>());
        },
      );

      test('system entity with nested config object fails encoding '
          '(simple encoding does not support nested objects)', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripOneOfDiscriminated(
          entity: const EntityTypeSystemEntity(
            SystemEntity(
              $type: SystemEntityTypeModel.system,
              systemId: 'sys-003',
              version: '1.0.0',
              active: false,
              config: SystemEntityConfigModel(
                timeout: 5000,
                retries: 3,
              ),
            ),
          ),
        );

        // Simple encoding does not support nested objects.
        // We expect an error for this test.
        expect(response, isA<TonikError<void>>());
        final error = response as TonikError<void>;
        expect(error.error, isA<EncodingException>());
      });
    });

    group('Discriminator behavior', () {
      test(
        'correctly discriminates between person and company entities',
        () async {
          final api = buildApi(responseStatus: '200');

          // Test person
          final personResponse = await api
              .testHeaderRoundtripOneOfDiscriminated(
                entity: const EntityTypePersonEntity(
                  PersonEntity(
                    $type: PersonEntityTypeModel.person,
                    firstName: 'Test',
                  ),
                ),
              );
          expect(
            personResponse,
            isA<
              TonikSuccess<HeadersRoundtripOneofDiscriminatedGet200Response>
            >(),
          );
          final personSuccess =
              personResponse
                  as TonikSuccess<
                    HeadersRoundtripOneofDiscriminatedGet200Response
                  >;
          expect(personSuccess.value.xEntity, isA<EntityTypePersonEntity>());

          // Test company
          final companyResponse = await api
              .testHeaderRoundtripOneOfDiscriminated(
                entity: const EntityTypeCompanyEntity(
                  CompanyEntity(
                    $type: CompanyEntityTypeModel.company,
                    companyName: 'Test Corp',
                  ),
                ),
              );
          expect(
            companyResponse,
            isA<
              TonikSuccess<HeadersRoundtripOneofDiscriminatedGet200Response>
            >(),
          );
          final companySuccess =
              companyResponse
                  as TonikSuccess<
                    HeadersRoundtripOneofDiscriminatedGet200Response
                  >;
          expect(companySuccess.value.xEntity, isA<EntityTypeCompanyEntity>());
        },
      );

      test(
        'system entity cannot be discriminated due to encoding limitation',
        () async {
          final api = buildApi(responseStatus: '200');

          // Test system - fails at encoding stage due to nested object
          // in schema
          final systemResponse = await api
              .testHeaderRoundtripOneOfDiscriminated(
                entity: const EntityTypeSystemEntity(
                  SystemEntity(
                    $type: SystemEntityTypeModel.system,
                    systemId: 'test-sys',
                  ),
                ),
              );
          expect(
            systemResponse,
            isA<TonikError<HeadersRoundtripOneofDiscriminatedGet200Response>>(),
          );
        },
      );
    });

    group('Header encoding verification', () {
      test('verifies correct header encoding for person entity', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripOneOfDiscriminated(
          entity: const EntityTypePersonEntity(
            PersonEntity(
              $type: PersonEntityTypeModel.person,
              firstName: 'Alice',
              age: 25,
            ),
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripOneofDiscriminatedGet200Response>>(),
        );
        final success =
            response
                as TonikSuccess<
                  HeadersRoundtripOneofDiscriminatedGet200Response
                >;

        // Verify the header contains the discriminator and fields
        final requestHeader =
            success.response.requestOptions.headers['x-entity'] as String;
        expect(requestHeader, contains('type'));
        expect(requestHeader, contains('person'));
        expect(requestHeader, contains('first_name'));
        expect(requestHeader, contains('Alice'));
        expect(requestHeader, contains('age'));
        expect(requestHeader, contains('25'));
      });

      test('verifies correct header encoding for company entity', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripOneOfDiscriminated(
          entity: const EntityTypeCompanyEntity(
            CompanyEntity(
              $type: CompanyEntityTypeModel.company,
              companyName: 'BigCo',
              foundedYear: 1999,
            ),
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripOneofDiscriminatedGet200Response>>(),
        );
        final success =
            response
                as TonikSuccess<
                  HeadersRoundtripOneofDiscriminatedGet200Response
                >;

        // Verify the header contains the discriminator and fields
        final requestHeader =
            success.response.requestOptions.headers['x-entity'] as String;
        expect(requestHeader, contains('type'));
        expect(requestHeader, contains('company'));
        expect(requestHeader, contains('company_name'));
        expect(requestHeader, contains('BigCo'));
        expect(requestHeader, contains('founded_year'));
        expect(requestHeader, contains('1999'));
      });
    });
  });
}
