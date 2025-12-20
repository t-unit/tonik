import 'package:dio/dio.dart';
import 'package:petstore_api/petstore_api.dart';
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

  group('updatePet', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final pet = await petApi.modifyPet(
        body: const PetPutBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(id: 1, petName: 'Fido', imageUrls: []),
        ),
      );
      final success = pet as TonikSuccess<ModifyPetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<ModifyPetResponse200>());

      final responseValue = (success.value as ModifyPetResponse200).body;
      expect(responseValue, isA<PetPut200ResponseJson>());
      final responseBody = (responseValue as PetPut200ResponseJson).body;
      expect(responseBody.id, isA<int?>());
      expect(responseBody.petName, isA<String?>());
      expect(responseBody.imageUrls, isA<List<String>>());
      expect(responseBody.tags, isA<List<PetTag>?>());
      expect(responseBody.status, isA<PetStatusModel?>());
      expect(responseBody.category, isA<PetCategory?>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final pet = await petApi.modifyPet(
        body: const PetPutBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(
            id: 2,
            petName: 'Bert',
            imageUrls: ['https://example.com/bert.jpg'],
            tags: [PetTag(id: 1, name: 'tag1')],
            status: PetStatusModel.inStock,
            category: PetCategory(id: 1, name: 'category1'),
          ),
        ),
      );
      final success = pet as TonikSuccess<ModifyPetResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<ModifyPetResponse400>());
    });

    test('404', () async {
      final petApi = buildPetApi(responseStatus: '404');

      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final pet = await petApi.modifyPet(
        body: const PetPutBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(id: 1, petName: 'Fido', imageUrls: []),
        ),
      );
      final success = pet as TonikSuccess<ModifyPetResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<ModifyPetResponse404>());
    });

    test('422', () async {
      final petApi = buildPetApi(responseStatus: '422');

      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final pet = await petApi.modifyPet(
        body: const PetPutBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(id: 1, petName: 'Fido', imageUrls: []),
        ),
      );
      final success = pet as TonikSuccess<ModifyPetResponse>;
      expect(success.response.statusCode, 422);
      expect(success.value, isA<ModifyPetResponse422>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '499');

      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final pet = await petApi.modifyPet(
        body: const PetPutBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(id: 1, petName: 'Fido', imageUrls: []),
        ),
      );
      final success = pet as TonikSuccess<ModifyPetResponse>;
      expect(success.response.statusCode, 499);
      expect(success.value, isA<ModifyPetResponseDefault>());
    });
  });

  group('addPet', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.createPet(
        body: const PetPostBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(
            id: 2,
            petName: 'Alfie',
            imageUrls: ['https://example.com/alfie.jpg'],
            tags: [PetTag(id: 1, name: 'tag1')],
            status: PetStatusModel.reserved,
            category: PetCategory(id: 1, name: 'category1'),
          ),
        ),
      );
      final success = pet as TonikSuccess<CreatePetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<CreatePetResponse200>());
      final responseBody = (success.value as CreatePetResponse200).body;
      expect(responseBody, isA<PetPost200ResponseJson>());
      final body = (responseBody as PetPost200ResponseJson).body;
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      expect(body, isA<Pet>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.createPet(
        body: const PetPostBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(
            id: 2,
            petName: 'Alfie',
            imageUrls: ['https://example.com/alfie.jpg'],
            tags: [PetTag(id: 1, name: 'tag1')],
            status: PetStatusModel.inStock,
            category: PetCategory(id: 1, name: 'category1'),
          ),
        ),
      );
      final success = pet as TonikSuccess<CreatePetResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<CreatePetResponse400>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '123');

      final pet = await petApi.createPet(
        body: const PetPostBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(
            id: 3,
            petName: 'Rex',
            imageUrls: ['https://example.com/rex.jpg'],
            tags: [PetTag(id: -383928, name: 'tag3309')],
            status: PetStatusModel.soldOut,
          ),
        ),
      );
      final success = pet as TonikSuccess<CreatePetResponse>;
      expect(success.response.statusCode, 123);
      expect(success.value, isA<CreatePetResponseDefault>());
    });
  });

  group('findPetsByStatus', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.findPetsByStatus(
        // deprecation is defined by the OpenAPI spec and correct
        // ignore: deprecated_member_use
        petStatus: PetFindByStatusParametersModel.available,
      );
      final success = pet as TonikSuccess<FindPetsByStatusResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<FindPetsByStatusResponse200>());
      final responseBody = (success.value as FindPetsByStatusResponse200).body;
      expect(responseBody, isA<PetFindByStatusGet200ResponseJson>());
      final body = (responseBody as PetFindByStatusGet200ResponseJson).body;
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      expect(body, isA<List<Pet>>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.findPetsByStatus(
        // deprecation is defined by the OpenAPI spec and correct
        // ignore: deprecated_member_use
        petStatus: PetFindByStatusParametersModel.pending,
      );
      final success = pet as TonikSuccess<FindPetsByStatusResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<FindPetsByStatusResponse400>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '321');

      final pet = await petApi.findPetsByStatus(
        // deprecation is defined by the OpenAPI spec and correct
        // ignore: deprecated_member_use
        petStatus: PetFindByStatusParametersModel.sold,
      );
      final success = pet as TonikSuccess<FindPetsByStatusResponse>;
      expect(success.response.statusCode, 321);
      expect(success.value, isA<FindPetsByStatusResponseDefault>());
    });
  });

  group('findPetsByTags', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.searchPetsByTags(filterTags: ['tag1', 'tag2']);
      final success = pet as TonikSuccess<SearchPetsByTagsResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<SearchPetsByTagsResponse200>());
      final responseBody = (success.value as SearchPetsByTagsResponse200).body;
      expect(responseBody, isA<PetFindByTagsGet200ResponseJson>());
      final body = (responseBody as PetFindByTagsGet200ResponseJson).body;
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      expect(body, isA<List<Pet>>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.searchPetsByTags();
      final success = pet as TonikSuccess<SearchPetsByTagsResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<SearchPetsByTagsResponse400>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '321');

      final pet = await petApi.searchPetsByTags(filterTags: ['']);
      final success = pet as TonikSuccess<SearchPetsByTagsResponse>;
      expect(success.response.statusCode, 321);
      expect(success.value, isA<SearchPetsByTagsResponseDefault>());
    });
  });

  group('getPetById', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.getPetById(animalId: 1);
      final success = pet as TonikSuccess<GetPetByIdResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetPetByIdResponse200>());
      final responseBody = (success.value as GetPetByIdResponse200).body;
      expect(responseBody, isA<PetPetIdGet200ResponseJson>());
      final body = (responseBody as PetPetIdGet200ResponseJson).body;
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      expect(body, isA<Pet>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.getPetById(animalId: 999909);
      final success = pet as TonikSuccess<GetPetByIdResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<GetPetByIdResponse400>());
    });

    test('404', () async {
      final petApi = buildPetApi(responseStatus: '404');

      final pet = await petApi.getPetById(animalId: 123);
      final success = pet as TonikSuccess<GetPetByIdResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetPetByIdResponse404>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '456');

      final pet = await petApi.getPetById(animalId: 99489489990);
      final success = pet as TonikSuccess<GetPetByIdResponse>;
      expect(success.response.statusCode, 456);
      expect(success.value, isA<GetPetByIdResponseDefault>());
    });
  });

  group('updatePetWithForm', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.patchPetFromForm(
        petId: 1,
        name: 'Fido',
        status: 'available',
      );
      final success = pet as TonikSuccess<PatchPetFromFormResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<PatchPetFromFormResponse200>());
      final responseBody = (success.value as PatchPetFromFormResponse200).body;
      expect(responseBody, isA<PetPetIdPost200ResponseJson>());
      final body = (responseBody as PetPetIdPost200ResponseJson).body;
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      expect(body, isA<Pet>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.patchPetFromForm(
        petId: 898988998,
        name: 'Fido',
        status: 'test',
      );
      final success = pet as TonikSuccess<PatchPetFromFormResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<PatchPetFromFormResponse400>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '987');

      final pet = await petApi.patchPetFromForm(
        petId: 2,
        name: 'Rex',
        status: 'invalid',
      );
      final success = pet as TonikSuccess<PatchPetFromFormResponse>;
      expect(success.response.statusCode, 987);
      expect(success.value, isA<PatchPetFromFormResponseDefault>());
    });
  });

  group('deletePet', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.removePet(petId: 1);
      final success = pet as TonikSuccess<RemovePetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<RemovePetResponse200>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.removePet(petId: 999909, apiKey: 'test');
      final success = pet as TonikSuccess<RemovePetResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<RemovePetResponse400>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '111');

      final pet = await petApi.removePet(petId: 1, apiKey: '%%%%@@@@@');
      final success = pet as TonikSuccess<RemovePetResponse>;
      expect(success.response.statusCode, 111);
    });
  });

  group('uploadFile', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.uploadPetImage(
        petId: 1,
        imageMetadata: 'test',
      );

      // Note: request body `application/octet-stream` is currently not supported by Tonik.

      final success = pet as TonikSuccess<UploadPetImageResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<UploadPetImageResponse200>());
      final responseBody = (success.value as UploadPetImageResponse200).body;
      expect(responseBody, isA<UploadResponse>());

      final apiResponse = (success.value as UploadPetImageResponse200).body;
      expect(apiResponse.statusCode, isA<int?>());
      expect(apiResponse.$type, isA<String?>());
      expect(apiResponse.message, isA<String?>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.uploadPetImage(petId: -1);

      // Note: request body `application/octet-stream` is currently not supported by Tonik.

      final success = pet as TonikSuccess<UploadPetImageResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<UploadPetImageResponse400>());
    });

    test('404', () async {
      final petApi = buildPetApi(responseStatus: '404');

      final pet = await petApi.uploadPetImage(petId: 123);

      // Note: request body `application/octet-stream` is currently not supported by Tonik.

      final success = pet as TonikSuccess<UploadPetImageResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<UploadPetImageResponse404>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '987');

      final pet = await petApi.uploadPetImage(
        petId: 494,
        imageMetadata: '{"test": "test"}',
      );

      // Note: request body `application/octet-stream` is currently not supported by Tonik.

      final success = pet as TonikSuccess<UploadPetImageResponse>;
      expect(success.response.statusCode, 987);
      expect(success.value, isA<UploadPetImageResponseDefault>());
    });
  });
}
