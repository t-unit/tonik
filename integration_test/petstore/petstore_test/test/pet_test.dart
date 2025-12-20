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

      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final pet = await petApi.updatePet(
        body: const PetPutBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(id: 1, name: 'Fido', photoUrls: []),
        ),
      );
      final success = pet as TonikSuccess<UpdatePetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<UpdatePetResponse200>());

      final responseBody = (success.value as UpdatePetResponse200).body;
      expect(responseBody, isA<PetPut200ResponseJson>());
      final body = (responseBody as PetPut200ResponseJson).body;

      expect(body.id, isA<int?>());
      expect(body.name, isA<String?>());
      expect(body.photoUrls, isA<List<String>>());
      expect(body.tags, isA<List<Tag>?>());
      expect(body.status, isA<PetStatusModel?>());
      expect(body.category, isA<Category?>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final pet = await petApi.updatePet(
        body: const PetPutBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(
            id: 2,
            name: 'Bert',
            photoUrls: ['https://example.com/bert.jpg'],
            tags: [Tag(id: 1, name: 'tag1')],
            status: PetStatusModel.available,
            category: Category(id: 1, name: 'category1'),
          ),
        ),
      );
      final success = pet as TonikSuccess<UpdatePetResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<UpdatePetResponse400>());
    });

    test('404', () async {
      final petApi = buildPetApi(responseStatus: '404');

      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final pet = await petApi.updatePet(
        body: const PetPutBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(id: 1, name: 'Fido', photoUrls: []),
        ),
      );
      final success = pet as TonikSuccess<UpdatePetResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<UpdatePetResponse404>());
    });

    test('422', () async {
      final petApi = buildPetApi(responseStatus: '422');

      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final pet = await petApi.updatePet(
        body: const PetPutBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(id: 1, name: 'Fido', photoUrls: []),
        ),
      );
      final success = pet as TonikSuccess<UpdatePetResponse>;
      expect(success.response.statusCode, 422);
      expect(success.value, isA<UpdatePetResponse422>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '499');

      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      final pet = await petApi.updatePet(
        body: const PetPutBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(id: 1, name: 'Fido', photoUrls: []),
        ),
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
        body: const PetPostBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(
            id: 2,
            name: 'Alfie',
            photoUrls: ['https://example.com/alfie.jpg'],
            tags: [Tag(id: 1, name: 'tag1')],
            status: PetStatusModel.available,
            category: Category(id: 1, name: 'category1'),
          ),
        ),
      );
      final success = pet as TonikSuccess<AddPetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<AddPetResponse200>());
      final responseBody = (success.value as AddPetResponse200).body;
      expect(responseBody, isA<PetPost200ResponseJson>());
      final body = (responseBody as PetPost200ResponseJson).body;
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      expect(body, isA<Pet>());
    });

    test('400', () async {
      final petApi = buildPetApi(responseStatus: '400');

      final pet = await petApi.addPet(
        body: const PetPostBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(
            id: 2,
            name: 'Alfie',
            photoUrls: ['https://example.com/alfie.jpg'],
            tags: [Tag(id: 1, name: 'tag1')],
            status: PetStatusModel.available,
            category: Category(id: 1, name: 'category1'),
          ),
        ),
      );
      final success = pet as TonikSuccess<AddPetResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<AddPetResponse400>());
    });

    test('default', () async {
      final petApi = buildPetApi(responseStatus: '123');

      final pet = await petApi.addPet(
        body: const PetPostBodyRequestBodyJson(
          // deprecation is defined by the OpenAPI spec and correct
          // ignore: deprecated_member_use
          Pet(
            id: 3,
            name: 'Rex',
            photoUrls: ['https://example.com/rex.jpg'],
            tags: [Tag(id: -383928, name: 'tag3309')],
            status: PetStatusModel.pending,
          ),
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
        // deprecation is defined by the OpenAPI spec and correct
        // ignore: deprecated_member_use
        status: PetFindByStatusParametersModel.available,
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
        status: PetFindByStatusParametersModel.pending,
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
        status: PetFindByStatusParametersModel.sold,
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
      expect(responseBody, isA<PetFindByTagsGet200ResponseJson>());
      final body = (responseBody as PetFindByTagsGet200ResponseJson).body;
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      expect(body, isA<List<Pet>>());
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
      expect(responseBody, isA<PetPetIdGet200ResponseJson>());
      final body = (responseBody as PetPetIdGet200ResponseJson).body;
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      expect(body, isA<Pet>());
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
      expect(responseBody, isA<PetPetIdPost200ResponseJson>());
      final body = (responseBody as PetPetIdPost200ResponseJson).body;
      // deprecation is defined by the OpenAPI spec and correct
      // ignore: deprecated_member_use
      expect(body, isA<Pet>());
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

  group('getPetHealth', () {
    test('200 with custom content type', () async {
      final petApi = buildPetApi(responseStatus: '200');

      final health = await petApi.getPetHealth(petId: 123);
      final success = health as TonikSuccess<GetPetHealthResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetPetHealthResponse200>());

      final responseBody = (success.value as GetPetHealthResponse200).body;
      expect(responseBody.$type, isA<String?>());
      expect(responseBody.title, isA<String?>());
      expect(responseBody.status, isA<int?>());
      expect(responseBody.detail, isA<String?>());
      expect(responseBody.petId, 123);
      expect(
        responseBody.healthStatus,
        isA<PetPetIdHealthGet200BodyHealthStatusModel?>(),
      );
    });

    test('404', () async {
      final petApi = buildPetApi(responseStatus: '404');

      final health = await petApi.getPetHealth(petId: 999);
      final success = health as TonikSuccess<GetPetHealthResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetPetHealthResponse404>());
    });
  });
}
