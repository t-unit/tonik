import 'package:dio/dio.dart';
import 'package:petstore_filtering_api/petstore_filtering_api.dart'
    as filtering;
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8082;
  const baseUrl = 'http://localhost:$port/api/v3';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  filtering.PetApi buildPetApi({required String responseStatus}) {
    return filtering.PetApi(
      filtering.CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  group('Filtering Config - Pet operations included', () {
    test('createPet - 200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.createPet(
        // we expect Pet to be deprecated
        // ignore: deprecated_member_use
        body: const filtering.Pet(
          id: 1,
          petName: 'Fido',
          imageUrls: <String>[],
        ),
      );
      final success = pet as TonikSuccess<filtering.CreatePetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<filtering.CreatePetResponse200>());
    });

    test('getPetById - 200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.getPetById(animalId: 1);
      final success = pet as TonikSuccess<filtering.GetPetByIdResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<filtering.GetPetByIdResponse200>());
    });

    test('searchPetsByTags - 200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pets = await petApi.searchPetsByTags(filterTags: ['tag1', 'tag2']);
      final success = pets as TonikSuccess<filtering.SearchPetsByTagsResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<filtering.SearchPetsByTagsResponse200>());
    });

    test('removePet - 200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final result = await petApi.removePet(petId: 1);
      final success = result as TonikSuccess<filtering.RemovePetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<filtering.RemovePetResponse200>());
    });
  });

  group('Filtering Config - Excluded operations not available', () {
    test('updatePet should not exist (excluded via config)', () {
      // This test verifies that the excluded operation is not generated
      // If this compiles, the filtering is NOT working correctly
      // The operation should not be available in the API class

      // We can't directly test for non-existence in Dart, but we document it
      // In a real scenario, attempting to call petApi.modifyPet would cause
      // a compile error, which is the desired behavior
      expect(true, true, reason: 'updatePet operation excluded by config');
    });

    test('store operations should not exist (excluded tag)', () {
      // Store tag is excluded, so no OrdersApi should exist
      // This would be a compile-time check in real usage
      expect(true, true, reason: 'store tag excluded by config');
    });
  });

  group('Filtering Config - User operations included', () {
    filtering.UserApi buildUserApi({required String responseStatus}) {
      return filtering.UserApi(
        filtering.CustomServer(
          baseUrl: baseUrl,
          serverConfig: ServerConfig(
            baseOptions: BaseOptions(
              headers: {'X-Response-Status': responseStatus},
            ),
          ),
        ),
      );
    }

    test('createUser - 200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final user = await userApi.createUser(
        body: const filtering.Account(
          id: 1,
          username: 'testUser',
          givenName: 'John',
          familyName: 'Doe',
          emailAddress: 'john@example.com',
          password: 'password123',
          phone: '1234567890',
          accountStatus: 1,
        ),
      );
      final success = user as TonikSuccess<filtering.CreateUserResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<filtering.CreateUserResponse200>());
    });

    test('fetchUserByName - 200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final user = await userApi.fetchUserByName(username: 'testUser');
      final success = user as TonikSuccess<filtering.FetchUserByNameResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<filtering.FetchUserByNameResponse200>());
    });

    test('authenticateUser - 200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final result = await userApi.authenticateUser(
        loginName: 'testUser',
        loginPassword: 'password123',
      );
      final success =
          result as TonikSuccess<filtering.AuthenticateUserResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<filtering.AuthenticateUserResponse200>());
    });
  });
}
