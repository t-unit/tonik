import 'package:dio/dio.dart';
import 'package:ref_siblings_api/ref_siblings_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8295;
  const baseUrl = 'http://localhost:$port';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  NullableSiblingsApi buildApi({required String responseStatus}) {
    return NullableSiblingsApi(
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

  group('createOptionalPet', () {
    group('request encoding', () {
      test('request path is /nullable/optional-pet', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createOptionalPet(
          body: const ContainerWithOptionalPet(
            requiredPet: Pet(name: 'Required'),
          ),
        );

        final success = response as TonikSuccess<ContainerWithOptionalPet>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/nullable/optional-pet',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createOptionalPet(
          body: const ContainerWithOptionalPet(
            requiredPet: Pet(name: 'Required'),
          ),
        );

        final success = response as TonikSuccess<ContainerWithOptionalPet>;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('encodes requiredPet as nested object', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createOptionalPet(
          body: const ContainerWithOptionalPet(
            requiredPet: Pet(name: 'Fluffy', age: 3),
          ),
        );

        final success = response as TonikSuccess<ContainerWithOptionalPet>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody['requiredPet'], isA<Map<String, dynamic>>());
        final requiredPet = requestBody['requiredPet'] as Map<String, dynamic>;
        expect(requiredPet['name'], 'Fluffy');
        expect(requiredPet['age'], 3);
      });

      test('encodes optionalPet when present', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createOptionalPet(
          body: const ContainerWithOptionalPet(
            requiredPet: Pet(name: 'Required'),
            optionalPet: Pet(name: 'Optional', age: 2),
          ),
        );

        final success = response as TonikSuccess<ContainerWithOptionalPet>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody.containsKey('optionalPet'), isTrue);
        final optionalPet = requestBody['optionalPet'] as Map<String, dynamic>;
        expect(optionalPet['name'], 'Optional');
        expect(optionalPet['age'], 2);
      });

      test('omits optionalPet when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createOptionalPet(
          body: const ContainerWithOptionalPet(
            requiredPet: Pet(name: 'Required'),
          ),
        );

        final success = response as TonikSuccess<ContainerWithOptionalPet>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody.containsKey('optionalPet'), isFalse);
      });
    });

    group('response decoding', () {
      test('200 response decodes into ContainerWithOptionalPet', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createOptionalPet(
          body: const ContainerWithOptionalPet(
            requiredPet: Pet(name: 'Test'),
          ),
        );

        expect(response, isA<TonikSuccess<ContainerWithOptionalPet>>());
        final success = response as TonikSuccess<ContainerWithOptionalPet>;
        expect(success.response.statusCode, 200);
      });

      test('decodes requiredPet correctly', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createOptionalPet(
          body: const ContainerWithOptionalPet(
            requiredPet: Pet(name: 'Echo', age: 5),
          ),
        );

        final success = response as TonikSuccess<ContainerWithOptionalPet>;
        expect(success.value.requiredPet.name, 'Echo');
        expect(success.value.requiredPet.age, 5);
      });

      test('decodes optionalPet when present', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createOptionalPet(
          body: const ContainerWithOptionalPet(
            requiredPet: Pet(name: 'Required'),
            optionalPet: Pet(name: 'Optional', age: 3),
          ),
        );

        final success = response as TonikSuccess<ContainerWithOptionalPet>;
        expect(success.value.optionalPet, isNotNull);
        expect(success.value.optionalPet!.name, 'Optional');
        expect(success.value.optionalPet!.age, 3);
      });

      test('decodes optionalPet as null when omitted', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createOptionalPet(
          body: const ContainerWithOptionalPet(
            requiredPet: Pet(name: 'Solo'),
          ),
        );

        final success = response as TonikSuccess<ContainerWithOptionalPet>;
        expect(success.value.optionalPet, isNull);
      });

      test('roundtrip preserves all values when optionalPet present', () async {
        final api = buildApi(responseStatus: '200');

        const original = ContainerWithOptionalPet(
          requiredPet: Pet(name: 'Charlie', age: 4),
          optionalPet: Pet(name: 'Luna', age: 2),
        );

        final response = await api.createOptionalPet(body: original);

        final success = response as TonikSuccess<ContainerWithOptionalPet>;
        expect(success.value, original);
      });

      test('roundtrip preserves values when optionalPet null', () async {
        final api = buildApi(responseStatus: '200');

        const original = ContainerWithOptionalPet(
          requiredPet: Pet(name: 'Max', age: 6),
        );

        final response = await api.createOptionalPet(body: original);

        final success = response as TonikSuccess<ContainerWithOptionalPet>;
        expect(success.value, original);
      });
    });
  });

  group('createDescribedOptionalPet', () {
    group('request encoding', () {
      test('request path is /nullable/described-optional', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedOptionalPet(
          body: const ContainerWithDescribedOptionalPet(),
        );

        final success =
            response as TonikSuccess<ContainerWithDescribedOptionalPet>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/nullable/described-optional',
        );
      });

      test('encodes pet when present', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedOptionalPet(
          body: const ContainerWithDescribedOptionalPet(
            pet: Pet(name: 'Whiskers', age: 5),
          ),
        );

        final success =
            response as TonikSuccess<ContainerWithDescribedOptionalPet>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody.containsKey('pet'), isTrue);
        final pet = requestBody['pet'] as Map<String, dynamic>;
        expect(pet['name'], 'Whiskers');
        expect(pet['age'], 5);
      });

      test('omits pet when null', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedOptionalPet(
          body: const ContainerWithDescribedOptionalPet(),
        );

        final success =
            response as TonikSuccess<ContainerWithDescribedOptionalPet>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody.containsKey('pet'), isFalse);
      });
    });

    group('response decoding', () {
      test('decodes pet when present', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedOptionalPet(
          body: const ContainerWithDescribedOptionalPet(
            pet: Pet(name: 'Mittens', age: 3),
          ),
        );

        final success =
            response as TonikSuccess<ContainerWithDescribedOptionalPet>;
        expect(success.value.pet, isNotNull);
        expect(success.value.pet!.name, 'Mittens');
        expect(success.value.pet!.age, 3);
      });

      test('decodes pet as null when omitted', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedOptionalPet(
          body: const ContainerWithDescribedOptionalPet(),
        );

        final success =
            response as TonikSuccess<ContainerWithDescribedOptionalPet>;
        expect(success.value.pet, isNull);
      });

      test('roundtrip preserves values', () async {
        final api = buildApi(responseStatus: '200');

        const original = ContainerWithDescribedOptionalPet(
          pet: Pet(name: 'Shadow', age: 4),
        );

        final response = await api.createDescribedOptionalPet(body: original);

        final success =
            response as TonikSuccess<ContainerWithDescribedOptionalPet>;
        expect(success.value, original);
      });
    });
  });
}
