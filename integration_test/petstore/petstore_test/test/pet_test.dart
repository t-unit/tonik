import 'package:dio/dio.dart';
import 'package:petstore_api/petstore_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8080;
  const baseUrl = 'http://localhost:$port/api/v3';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  PetApi buildPetApi({required String responseStatus}) {
    return PetApi(
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

      final pet = await petApi.updatePet(
        body: const Pet(id: 1, name: 'Fido', photoUrls: []),
      );
      final success = pet as TonikSuccess<UpdatePetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<UpdatePetResponse200>());

      final responseBody = (success.value as UpdatePetResponse200).body;
      expect(responseBody.id, isA<int?>());
      expect(responseBody.name, isA<String?>());
      expect(responseBody.photoUrls, isA<List<String>>());
      expect(responseBody.tags, isA<List<Tag>?>());
      expect(responseBody.status, isA<PetStatus?>());
      expect(responseBody.category, isA<Category?>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.updatePet(
        body: const Pet(
          id: 2,
          name: 'Bert',
          photoUrls: ['https://example.com/bert.jpg'],
          tags: [Tag(id: 1, name: 'tag1')],
          status: PetStatus.available,
          category: Category(id: 1, name: 'category1'),
        ),
      );
      final success = pet as TonikSuccess<UpdatePetResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<UpdatePetResponse400>());
    });

    test('404', () async {
      final petApi = buildPetApi(responseStatus: '404');

      final pet = await petApi.updatePet(
        body: const Pet(id: 1, name: 'Fido', photoUrls: []),
      );
      final success = pet as TonikSuccess<UpdatePetResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<UpdatePetResponse404>());
    });

    test('422', () async {
      final petApi = buildPetApi(responseStatus: '422');

      final pet = await petApi.updatePet(
        body: const Pet(id: 1, name: 'Fido', photoUrls: []),
      );
      final success = pet as TonikSuccess<UpdatePetResponse>;
      expect(success.response.statusCode, 422);
      expect(success.value, isA<UpdatePetResponse422>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '499');

      final pet = await petApi.updatePet(
        body: const Pet(id: 1, name: 'Fido', photoUrls: []),
      );
      final success = pet as TonikSuccess<UpdatePetResponse>;
      expect(success.response.statusCode, 499);
      expect(success.value, isA<UpdatePetResponseDefault>());
    });
  });

  group('addPet', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.addPet(
        body: const Pet(
          id: 2,
          name: 'Alfie',
          photoUrls: ['https://example.com/alfie.jpg'],
          tags: [Tag(id: 1, name: 'tag1')],
          status: PetStatus.available,
          category: Category(id: 1, name: 'category1'),
        ),
      );
      final success = pet as TonikSuccess<AddPetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<AddPetResponse200>());
      final responseBody = (success.value as AddPetResponse200).body;
      expect(responseBody, isA<Pet>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.addPet(
        body: const Pet(
          id: 2,
          name: 'Alfie',
          photoUrls: ['https://example.com/alfie.jpg'],
          tags: [Tag(id: 1, name: 'tag1')],
          status: PetStatus.available,
          category: Category(id: 1, name: 'category1'),
        ),
      );
      final success = pet as TonikSuccess<AddPetResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<AddPetResponse400>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '123');

      final pet = await petApi.addPet(
        body: const Pet(
          id: 3,
          name: 'Rex',
          photoUrls: ['https://example.com/rex.jpg'],
          tags: [Tag(id: -383928, name: 'tag3309')],
          status: PetStatus.pending,
        ),
      );
      final success = pet as TonikSuccess<AddPetResponse>;
      expect(success.response.statusCode, 123);
      expect(success.value, isA<AddPetResponseDefault>());
    });
  });

  group('findPetsByStatus', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.findPetsByStatus(
        status: PetFindByStatusParameters.available,
      );
      final success = pet as TonikSuccess<FindPetsByStatusResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<FindPetsByStatusResponse200>());
      final responseBody = (success.value as FindPetsByStatusResponse200).body;
      expect(responseBody, isA<List<Pet>>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.findPetsByStatus(
        status: PetFindByStatusParameters.pending,
      );
      final success = pet as TonikSuccess<FindPetsByStatusResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<FindPetsByStatusResponse400>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '321');

      final pet = await petApi.findPetsByStatus(
        status: PetFindByStatusParameters.sold,
      );
      final success = pet as TonikSuccess<FindPetsByStatusResponse>;
      expect(success.response.statusCode, 321);
      expect(success.value, isA<FindPetsByStatusResponseDefault>());
    });
  });

  group('findPetsByTags', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.findPetsByTags(tags: ['tag1', 'tag2']);
      final success = pet as TonikSuccess<FindPetsByTagsResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<FindPetsByTagsResponse200>());
      final responseBody = (success.value as FindPetsByTagsResponse200).body;
      expect(responseBody, isA<List<Pet>>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.findPetsByTags();
      final success = pet as TonikSuccess<FindPetsByTagsResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<FindPetsByTagsResponse400>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '321');

      final pet = await petApi.findPetsByTags(tags: ['']);
      final success = pet as TonikSuccess<FindPetsByTagsResponse>;
      expect(success.response.statusCode, 321);
      expect(success.value, isA<FindPetsByTagsResponseDefault>());
    });
  });

  group('getPetById', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.getPetById(petId: 1);
      final success = pet as TonikSuccess<GetPetByIdResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetPetByIdResponse200>());
      final responseBody = (success.value as GetPetByIdResponse200).body;
      expect(responseBody, isA<Pet>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.getPetById(petId: 999909);
      final success = pet as TonikSuccess<GetPetByIdResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<GetPetByIdResponse400>());
    });

    test('404', () async {
      final petApi = buildPetApi(responseStatus: '404');

      final pet = await petApi.getPetById(petId: 123);
      final success = pet as TonikSuccess<GetPetByIdResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetPetByIdResponse404>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '456');

      final pet = await petApi.getPetById(petId: 99489489990);
      final success = pet as TonikSuccess<GetPetByIdResponse>;
      expect(success.response.statusCode, 456);
      expect(success.value, isA<GetPetByIdResponseDefault>());
    });
  });

  group('updatePetWithForm', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.updatePetWithForm(
        petId: 1,
        name: 'Fido',
        status: 'available',
      );
      final success = pet as TonikSuccess<UpdatePetWithFormResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<UpdatePetWithFormResponse200>());
      final responseBody = (success.value as UpdatePetWithFormResponse200).body;
      expect(responseBody, isA<Pet>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.updatePetWithForm(
        petId: 898988998,
        name: 'Fido',
        status: 'test',
      );
      final success = pet as TonikSuccess<UpdatePetWithFormResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<UpdatePetWithFormResponse400>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '987');

      final pet = await petApi.updatePetWithForm(
        petId: 2,
        name: 'Rex',
        status: 'invalid',
      );
      final success = pet as TonikSuccess<UpdatePetWithFormResponse>;
      expect(success.response.statusCode, 987);
      expect(success.value, isA<UpdatePetWithFormResponseDefault>());
    });
  });

  group('deletePet', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.deletePet(petId: 1);
      final success = pet as TonikSuccess<DeletePetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<DeletePetResponse200>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.deletePet(petId: 999909, apiKey: 'test');
      final success = pet as TonikSuccess<DeletePetResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<DeletePetResponse400>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '111');

      final pet = await petApi.deletePet(petId: 1, apiKey: '%%%%@@@@@');
      final success = pet as TonikSuccess<DeletePetResponse>;
      expect(success.response.statusCode, 111);
    });
  });

  group('uploadFile', () {
    test('200', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final pet = await petApi.uploadFile(petId: 1, additionalMetadata: 'test');

      // Note: request body `application/octet-stream` is currently not supported by Tonik.

      final success = pet as TonikSuccess<UploadFileResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<UploadFileResponse200>());
      final responseBody = (success.value as UploadFileResponse200).body;
      expect(responseBody, isA<ApiResponse>());

      final apiResponse = (success.value as UploadFileResponse200).body;
      expect(apiResponse.code, isA<int?>());
      expect(apiResponse.$type, isA<String?>());
      expect(apiResponse.message, isA<String?>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.uploadFile(petId: -1);

      // Note: request body `application/octet-stream` is currently not supported by Tonik.

      final success = pet as TonikSuccess<UploadFileResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<UploadFileResponse400>());
    });

    test('404', () async {
      final petApi = buildPetApi(responseStatus: '404');

      final pet = await petApi.uploadFile(petId: 123);

      // Note: request body `application/octet-stream` is currently not supported by Tonik.

      final success = pet as TonikSuccess<UploadFileResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<UploadFileResponse404>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '987');

      final pet = await petApi.uploadFile(
        petId: 494,
        additionalMetadata: '{"test": "test"}',
      );

      // Note: request body `application/octet-stream` is currently not supported by Tonik.

      final success = pet as TonikSuccess<UploadFileResponse>;
      expect(success.response.statusCode, 987);
      expect(success.value, isA<UploadFileResponseDefault>());
    });
  });
}
