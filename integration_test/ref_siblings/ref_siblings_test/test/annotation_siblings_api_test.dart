import 'package:dio/dio.dart';
import 'package:ref_siblings_api/ref_siblings_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  const port = 8295;
  const baseUrl = 'http://localhost:$port';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  AnnotationSiblingsApi buildApi({required String responseStatus}) {
    return AnnotationSiblingsApi(
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

  group('health', () {
    test('request path is /health', () async {
      final api = buildApi(responseStatus: '200');

      final response = await api.health();

      final success = response as TonikSuccess<HealthGet200BodyModel>;
      expect(success.response.requestOptions.path, '$baseUrl/health');
    });

    test('request method is GET', () async {
      final api = buildApi(responseStatus: '200');

      final response = await api.health();

      final success = response as TonikSuccess<HealthGet200BodyModel>;
      expect(success.response.requestOptions.method, 'GET');
    });
  });

  group('createDescribedPet', () {
    group('request encoding', () {
      test('request path is /annotation/described-pet', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedPet(
          body: const Pet(name: 'Fluffy'),
        );

        final success = response as TonikSuccess<DescribedPetAlias>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/annotation/described-pet',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedPet(
          body: const Pet(name: 'Fluffy'),
        );

        final success = response as TonikSuccess<DescribedPetAlias>;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('encodes Pet properties correctly', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedPet(
          body: const Pet(name: 'Max', age: 5),
        );

        final success = response as TonikSuccess<DescribedPetAlias>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody['name'], 'Max');
        expect(requestBody['age'], 5);
      });

      test('omits null optional properties', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedPet(
          body: const Pet(name: 'Solo'),
        );

        final success = response as TonikSuccess<DescribedPetAlias>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody['name'], 'Solo');
        expect(requestBody.containsKey('age'), isFalse);
      });
    });

    group('response decoding', () {
      test('200 response decodes into DescribedPetAlias (Pet)', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedPet(
          body: const Pet(name: 'Test'),
        );

        expect(response, isA<TonikSuccess<DescribedPetAlias>>());
        final success = response as TonikSuccess<DescribedPetAlias>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<Pet>());
      });

      test('decodes Pet name correctly', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedPet(
          body: const Pet(name: 'Charlie', age: 3),
        );

        final success = response as TonikSuccess<DescribedPetAlias>;
        expect(success.value.name, 'Charlie');
        expect(success.value.age, 3);
      });

      test('roundtrip preserves all values', () async {
        final api = buildApi(responseStatus: '200');

        const original = Pet(name: 'Buddy', age: 7);

        final response = await api.createDescribedPet(body: original);

        final success = response as TonikSuccess<DescribedPetAlias>;
        expect(success.value, original);
      });
    });
  });

  group('createDeprecatedUser', () {
    group('request encoding', () {
      test('request path is /annotation/deprecated-user', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDeprecatedUser(
          body: const User(
            username: 'testUser',
            email: 'test@example.com',
          ),
        );

        // expected to be deprecated
        // ignore: deprecated_member_use
        final success = response as TonikSuccess<LegacyUser>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/annotation/deprecated-user',
        );
      });

      test('encodes User properties correctly', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDeprecatedUser(
          body: const User(
            username: 'admin',
            email: 'admin@example.com',
          ),
        );

        // expected to be deprecated
        // ignore: deprecated_member_use
        final success = response as TonikSuccess<LegacyUser>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody['username'], 'admin');
        expect(requestBody['email'], 'admin@example.com');
      });
    });

    group('response decoding', () {
      test('200 response decodes into LegacyUser (User)', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDeprecatedUser(
          body: const User(
            username: 'testUser',
            email: 'test@example.com',
          ),
        );

        // expected to be deprecated
        // ignore: deprecated_member_use
        expect(response, isA<TonikSuccess<LegacyUser>>());
        // expected to be deprecated
        // ignore: deprecated_member_use
        final success = response as TonikSuccess<LegacyUser>;
        expect(success.value, isA<User>());
      });

      test('roundtrip preserves all values', () async {
        final api = buildApi(responseStatus: '200');

        const original = User(
          username: 'john doe',
          email: 'john@example.com',
        );

        final response = await api.createDeprecatedUser(body: original);

        // expected to be deprecated
        // ignore: deprecated_member_use
        final success = response as TonikSuccess<LegacyUser>;
        expect(success.value, original);
      });
    });
  });

  group('createDescribedDeprecatedItem', () {
    group('request encoding', () {
      test('request path is /annotation/described-deprecated', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedDeprecatedItem(
          body: const Item(id: 1, title: 'Test Item'),
        );

        // expected to be deprecated
        // ignore: deprecated_member_use
        final success = response as TonikSuccess<OldItem>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/annotation/described-deprecated',
        );
      });

      test('encodes Item properties correctly', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedDeprecatedItem(
          body: const Item(id: 123, title: 'Widget'),
        );

        // expected to be deprecated
        // ignore: deprecated_member_use
        final success = response as TonikSuccess<OldItem>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;

        expect(requestBody['id'], 123);
        expect(requestBody['title'], 'Widget');
      });
    });

    group('response decoding', () {
      test('200 response decodes into OldItem (Item)', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedDeprecatedItem(
          body: const Item(id: 100, title: 'Test'),
        );

        // expected to be deprecated
        // ignore: deprecated_member_use
        expect(response, isA<TonikSuccess<OldItem>>());
        // expected to be deprecated
        // ignore: deprecated_member_use
        final success = response as TonikSuccess<OldItem>;
        expect(success.value, isA<Item>());
      });

      test('roundtrip preserves all values', () async {
        final api = buildApi(responseStatus: '200');

        const original = Item(id: 42, title: 'Gadget');

        final response = await api.createDescribedDeprecatedItem(
          body: original,
        );

        // expected to be deprecated
        // ignore: deprecated_member_use
        final success = response as TonikSuccess<OldItem>;
        expect(success.value, original);
      });
    });
  });
}
