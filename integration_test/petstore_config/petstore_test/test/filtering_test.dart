import 'package:dio/dio.dart';
import 'package:petstore_filtering_api/petstore_filtering_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/api/v3';
  });

  AnimalsApi buildPetApi({required String responseStatus}) {
    return AnimalsApi(
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

  group('Filtering Config - Pet operations included', () {
    test('createPet - 200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.createPet(
        body: const PetPostBodyRequestBodyJson(
          // we expect Pet to be deprecated
          // ignore: deprecated_member_use
          Pet(
            id: 1,
            petName: 'Fido',
            imageUrls: <String>[],
          ),
        ),
      );
      final success = pet as TonikSuccess<CreatePetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<CreatePetResponse200>());
    });

    test('getPetById - 200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.getPetById(animalId: 1);
      final success = pet as TonikSuccess<GetPetByIdResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetPetByIdResponse200>());
    });

    test('searchPetsByTags - 200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pets = await petApi.searchPetsByTags(filterTags: ['tag1', 'tag2']);
      final success = pets as TonikSuccess<SearchPetsByTagsResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<SearchPetsByTagsResponse200>());
    });

    test('removePet - 200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final result = await petApi.removePet(petId: 1);
      final success = result as TonikSuccess<RemovePetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<RemovePetResponse200>());
    });
  });

  group('Filtering Config - User operations included', () {
    AccountsApi buildUserApi({required String responseStatus}) {
      return AccountsApi(
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

    test('createUser - 200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final user = await userApi.createUser(
        body: const UserPostBodyRequestBodyJson(
          Account(
            id: 1,
            username: 'testUser',
            givenName: 'John',
            familyName: 'Doe',
            emailAddress: 'john@example.com',
            password: 'password123',
            phone: '1234567890',
            accountStatus: 1,
          ),
        ),
      );
      final success = user as TonikSuccess<CreateUserResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<CreateUserResponse200>());
    });

    test('fetchUserByName - 200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final user = await userApi.fetchUserByName(username: 'testUser');
      final success = user as TonikSuccess<FetchUserByNameResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<FetchUserByNameResponse200>());
    });

    test('authenticateUser - 200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final result = await userApi.authenticateUser(
        loginName: 'testUser',
        loginPassword: 'password123',
      );
      final success = result as TonikSuccess<AuthenticateUserResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<AuthenticateUserResponse200>());
    });
  });
}
