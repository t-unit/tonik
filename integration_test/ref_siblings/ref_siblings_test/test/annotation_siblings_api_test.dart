import 'dart:convert';

import 'package:ref_siblings_api/ref_siblings_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  AnnotationSiblingsApi buildApi({required String responseStatus}) {
    return AnnotationSiblingsApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  group('health', () {
    test('request path is /health', () async {
      final api = buildApi(responseStatus: '200');

      final response = await api.health();

      requireSuccess(response);
      final recordedRequest = await imposterServer.takeRequest();
      expect(recordedRequest.uri.toString(), '$baseUrl/health');
    });

    test('request method is GET', () async {
      final api = buildApi(responseStatus: '200');

      final response = await api.health();

      requireSuccess(response);
      final recordedRequest = await imposterServer.takeRequest();
      expect(recordedRequest.method, 'GET');
    });
  });

  group('createDescribedPet', () {
    group('request encoding', () {
      test('request path is /annotation/described-pet', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedPet(
          body: const Pet(name: 'Fluffy'),
        );

        requireSuccess(response);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.uri.toString(),
          '$baseUrl/annotation/described-pet',
        );
      });

      test('request method is POST', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedPet(
          body: const Pet(name: 'Fluffy'),
        );

        requireSuccess(response);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.method, 'POST');
      });

      test('encodes Pet properties correctly', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedPet(
          body: const Pet(name: 'Max', age: 5),
        );

        requireSuccess(response);
        final recordedRequest = await imposterServer.takeRequest();
        final requestBody =
            jsonDecode(recordedRequest.body!) as Map<String, dynamic>;

        expect(requestBody['name'], 'Max');
        expect(requestBody['age'], 5);
      });

      test('omits null optional properties', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedPet(
          body: const Pet(name: 'Solo'),
        );

        requireSuccess(response);
        final recordedRequest = await imposterServer.takeRequest();
        final requestBody =
            jsonDecode(recordedRequest.body!) as Map<String, dynamic>;

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

        expect(
          response,
          isTonikSuccess,
        );
        final success = requireSuccess(response);
        expect(success.response.statusCode, 200);
        expect(success.value, isA<Pet>());
      });

      test('decodes Pet name correctly', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedPet(
          body: const Pet(name: 'Charlie', age: 3),
        );

        final success = requireSuccess(response);
        expect(success.value.name, 'Charlie');
        expect(success.value.age, 3);
      });

      test('roundtrip preserves all values', () async {
        final api = buildApi(responseStatus: '200');

        const original = Pet(name: 'Buddy', age: 7);

        final response = await api.createDescribedPet(body: original);

        final success = requireSuccess(response);
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

        final success = requireSuccess(response);
        // expected to be deprecated
        // ignore: deprecated_member_use
        expect(success.value, isA<LegacyUser>());
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.uri.toString(),
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

        final success = requireSuccess(response);
        // expected to be deprecated
        // ignore: deprecated_member_use
        expect(success.value, isA<LegacyUser>());
        final recordedRequest = await imposterServer.takeRequest();
        final requestBody =
            jsonDecode(recordedRequest.body!) as Map<String, dynamic>;

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

        expect(response, isTonikSuccess);
        final success = requireSuccess(response);
        // expected to be deprecated
        // ignore: deprecated_member_use
        expect(success.value, isA<LegacyUser>());
      });

      test('roundtrip preserves all values', () async {
        final api = buildApi(responseStatus: '200');

        const original = User(
          username: 'john doe',
          email: 'john@example.com',
        );

        final response = await api.createDeprecatedUser(body: original);

        final success = requireSuccess(response);
        // expected to be deprecated
        // ignore: deprecated_member_use
        expect(success.value, isA<LegacyUser>());
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

        final success = requireSuccess(response);
        // expected to be deprecated
        // ignore: deprecated_member_use
        expect(success.value, isA<OldItem>());
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.uri.toString(),
          '$baseUrl/annotation/described-deprecated',
        );
      });

      test('encodes Item properties correctly', () async {
        final api = buildApi(responseStatus: '200');

        final response = await api.createDescribedDeprecatedItem(
          body: const Item(id: 123, title: 'Widget'),
        );

        final success = requireSuccess(response);
        // expected to be deprecated
        // ignore: deprecated_member_use
        expect(success.value, isA<OldItem>());
        final recordedRequest = await imposterServer.takeRequest();
        final requestBody =
            jsonDecode(recordedRequest.body!) as Map<String, dynamic>;

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

        expect(response, isTonikSuccess);
        final success = requireSuccess(response);
        // expected to be deprecated
        // ignore: deprecated_member_use
        expect(success.value, isA<OldItem>());
      });

      test('roundtrip preserves all values', () async {
        final api = buildApi(responseStatus: '200');

        const original = Item(id: 42, title: 'Gadget');

        final response = await api.createDescribedDeprecatedItem(
          body: original,
        );

        final success = requireSuccess(response);
        // expected to be deprecated
        // ignore: deprecated_member_use
        expect(success.value, isA<OldItem>());
        expect(success.value, original);
      });
    });
  });
}
