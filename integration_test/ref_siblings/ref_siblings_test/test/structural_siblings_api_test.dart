import 'package:dio/dio.dart';
import 'package:ref_siblings_api/ref_siblings_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;


  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  StructuralSiblingsApi buildApi({required String responseStatus}) {
    return StructuralSiblingsApi(
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

  group('createExtendedPet', () {
    group('request encoding', () {
      test('request path is /structural/extended-pet', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createExtendedPet(
          body: const ExtendedPet(
            pet: Pet(name: 'Fluffy', age: 3),
            extendedPetModel: ExtendedPetModel(
              nickname: 'Fluff',
              vaccinated: true,
            ),
          ),
        );

        final success = response as TonikSuccess<ExtendedPet>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/structural/extended-pet',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createExtendedPet(
          body: const ExtendedPet(
            pet: Pet(name: 'Fluffy'),
            extendedPetModel: ExtendedPetModel(),
          ),
        );

        final success = response as TonikSuccess<ExtendedPet>;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('request body merges Pet and ExtendedPetModel properties', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createExtendedPet(
          body: const ExtendedPet(
            pet: Pet(name: 'Max', age: 5),
            extendedPetModel: ExtendedPetModel(
              nickname: 'Maxie',
              vaccinated: false,
            ),
          ),
        );

        final success = response as TonikSuccess<ExtendedPet>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        // All properties should be merged at the top level
        expect(requestBody['name'], 'Max');
        expect(requestBody['age'], 5);
        expect(requestBody['nickname'], 'Maxie');
        expect(requestBody['vaccinated'], false);
      });

      test('request body omits null optional properties', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createExtendedPet(
          body: const ExtendedPet(
            pet: Pet(name: 'Solo'),
            extendedPetModel: ExtendedPetModel(),
          ),
        );

        final success = response as TonikSuccess<ExtendedPet>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody['name'], 'Solo');
        expect(requestBody.containsKey('age'), isFalse);
        expect(requestBody.containsKey('nickname'), isFalse);
        expect(requestBody.containsKey('vaccinated'), isFalse);
      });
    });

    group('response decoding', () {
      test('200 response decodes into ExtendedPet', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createExtendedPet(
          body: const ExtendedPet(
            pet: Pet(name: 'Buddy', age: 2),
            extendedPetModel: ExtendedPetModel(
              nickname: 'Bud',
              vaccinated: true,
            ),
          ),
        );

        expect(response, isA<TonikSuccess<ExtendedPet>>());
        final success = response as TonikSuccess<ExtendedPet>;
        expect(success.response.statusCode, 200);
      });

      test('response decodes Pet component correctly', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createExtendedPet(
          body: const ExtendedPet(
            pet: Pet(name: 'Charlie', age: 4),
            extendedPetModel: ExtendedPetModel(),
          ),
        );

        final success = response as TonikSuccess<ExtendedPet>;
        expect(success.value.pet.name, 'Charlie');
        expect(success.value.pet.age, 4);
      });

      test('response decodes ExtendedPetModel component correctly', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createExtendedPet(
          body: const ExtendedPet(
            pet: Pet(name: 'Rex'),
            extendedPetModel: ExtendedPetModel(
              nickname: 'Rexy',
              vaccinated: true,
            ),
          ),
        );

        final success = response as TonikSuccess<ExtendedPet>;
        expect(success.value.extendedPetModel.nickname, 'Rexy');
        expect(success.value.extendedPetModel.vaccinated, true);
      });

      test('roundtrip preserves all values', () async {
        final api = buildApi(responseStatus: '200');

        const original = ExtendedPet(
          pet: Pet(name: 'Luna', age: 3),
          extendedPetModel: ExtendedPetModel(
            nickname: 'Lulu',
            vaccinated: false,
          ),
        );

        final response = await api.createExtendedPet(body: original);

        final success = response as TonikSuccess<ExtendedPet>;
        expect(success.value, original);
      });
    });
  });

  group('createExtendedWithRequired', () {
    group('request encoding', () {
      test('request body includes required microchipId', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createExtendedWithRequired(
          body: const ExtendedWithRequired(
            pet: Pet(name: 'Spot'),
            extendedWithRequiredModel: ExtendedWithRequiredModel(
              microchipId: 'CHIP-001',
            ),
          ),
        );

        final success = response as TonikSuccess<ExtendedWithRequired>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody['name'], 'Spot');
        expect(requestBody['microchipId'], 'CHIP-001');
      });

      test('request body includes optional registrationDate', () async {
        final api = buildApi(responseStatus: '200');

        final testDate = Date(2025, 6, 15);
        final response = await api.createExtendedWithRequired(
          body: ExtendedWithRequired(
            pet: const Pet(name: 'Duke'),
            extendedWithRequiredModel: ExtendedWithRequiredModel(
              microchipId: 'CHIP-002',
              registrationDate: testDate,
            ),
          ),
        );

        final success = response as TonikSuccess<ExtendedWithRequired>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody['microchipId'], 'CHIP-002');
        expect(requestBody['registrationDate'], '2025-06-15');
      });
    });

    group('response decoding', () {
      test('roundtrip preserves required field', () async {
        final api = buildApi(responseStatus: '200');

        const original = ExtendedWithRequired(
          pet: Pet(name: 'Rocky', age: 5),
          extendedWithRequiredModel: ExtendedWithRequiredModel(
            microchipId: 'CHIP-003',
          ),
        );

        final response = await api.createExtendedWithRequired(body: original);

        final success = response as TonikSuccess<ExtendedWithRequired>;
        expect(success.value.pet.name, 'Rocky');
        expect(
          success.value.extendedWithRequiredModel.microchipId,
          'CHIP-003',
        );
      });
    });
  });

  group('createMergedEntity', () {
    group('request encoding', () {
      test('request body merges NamedEntity and allOf members', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createMergedEntity(
          body: MergedEntity(
            namedEntity: const NamedEntity(name: 'Entity-1'),
            timestampedEntity: TimestampedEntity(
              createdAt: DateTime.utc(2025),
            ),
          ),
        );

        final success = response as TonikSuccess<MergedEntity>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody['name'], 'Entity-1');
        expect(requestBody['createdAt'], '2025-01-01T00:00:00.000Z');
      });
    });

    group('response decoding', () {
      test('roundtrip preserves merged properties', () async {
        final api = buildApi(responseStatus: '200');

        final original = MergedEntity(
          namedEntity: const NamedEntity(name: 'Merged'),
          timestampedEntity: TimestampedEntity(
            createdAt: DateTime.utc(2025, 6),
            updatedAt: DateTime.utc(2025, 6, 15),
          ),
        );

        final response = await api.createMergedEntity(body: original);

        final success = response as TonikSuccess<MergedEntity>;
        expect(success.value.namedEntity.name, 'Merged');
        expect(
          success.value.timestampedEntity.createdAt,
          DateTime.utc(2025, 6),
        );
        expect(
          success.value.timestampedEntity.updatedAt,
          DateTime.utc(2025, 6, 15),
        );
      });
    });
  });

  group('createTripleMerge', () {
    group('request encoding', () {
      test('request body merges three schemas', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createTripleMerge(
          body: TripleMerge(
            namedEntity: const NamedEntity(name: 'Triple'),
            timestampedEntity: TimestampedEntity(
              createdAt: DateTime.utc(2025),
            ),
            auditedEntity: const AuditedEntity(createdBy: 'admin'),
          ),
        );

        final success = response as TonikSuccess<TripleMerge>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody['name'], 'Triple');
        expect(requestBody['createdAt'], '2025-01-01T00:00:00.000Z');
        expect(requestBody['createdBy'], 'admin');
      });
    });

    group('response decoding', () {
      test('roundtrip preserves all three components', () async {
        final api = buildApi(responseStatus: '200');

        final original = TripleMerge(
          namedEntity: const NamedEntity(name: 'Full'),
          timestampedEntity: TimestampedEntity(
            createdAt: DateTime.utc(2025),
            updatedAt: DateTime.utc(2025, 6),
          ),
          auditedEntity: const AuditedEntity(
            createdBy: 'user1',
            modifiedBy: 'user2',
          ),
        );

        final response = await api.createTripleMerge(body: original);

        final success = response as TonikSuccess<TripleMerge>;
        expect(success.value, original);
      });
    });
  });
}
