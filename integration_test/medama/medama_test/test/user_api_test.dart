import 'package:dio/dio.dart';
import 'package:medama_api/medama_api.dart';
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

  UserApi buildUserApi({required String responseStatus}) {
    return UserApi(
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

  group('getUser', () {
    group('request encoding', () {
      test('request path is /user', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/user',
        );
      });

      test('request method is GET', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as GetUserResponse200', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUser(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetUserResponse>>());
        final success = response as TonikSuccess<GetUserResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<GetUserResponse200>());
      });

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        final response200 = success.value as GetUserResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes UserGet', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        final response200 = success.value as GetUserResponse200;
        expect(response200.body.body, isA<UserGet>());
      });

      test('200 response decodes username field', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        final response200 = success.value as GetUserResponse200;
        expect(response200.body.body.username, isA<String>());
      });

      test('200 response decodes settings field', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        final response200 = success.value as GetUserResponse200;
        expect(response200.body.body.settings, isA<UserSettings>());
      });

      test('200 response decodes dateCreated as integer', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        final response200 = success.value as GetUserResponse200;
        expect(response200.body.body.dateCreated, isA<int>());
      });

      test('200 response decodes dateUpdated as integer', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        final response200 = success.value as GetUserResponse200;
        expect(response200.body.body.dateUpdated, isA<int>());
      });
    });

    group('response decoding - error responses', () {
      test('400 response is decoded as GetUserResponse400', () async {
        final api = buildUserApi(responseStatus: '400');

        final response = await api.getUser(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetUserResponse>>());
        final success = response as TonikSuccess<GetUserResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<GetUserResponse400>());
      });

      test('400 response body decodes error object', () async {
        final api = buildUserApi(responseStatus: '400');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        final response400 = success.value as GetUserResponse400;
        expect(response400.body, isA<BadRequestError>());
        expect(
          response400.body.body.error,
          isA<BadRequestErrorBodyErrorModel>(),
        );
        expect(response400.body.body.error.code, isA<int>());
        expect(response400.body.body.error.message, isA<String>());
      });

      test('401 response is decoded as GetUserResponse401', () async {
        final api = buildUserApi(responseStatus: '401');

        final response = await api.getUser(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetUserResponse>>());
        final success = response as TonikSuccess<GetUserResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<GetUserResponse401>());
      });

      test('401 response body decodes error object', () async {
        final api = buildUserApi(responseStatus: '401');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        final response401 = success.value as GetUserResponse401;
        expect(response401.body, isA<UnauthorisedError>());
        expect(response401.body.body.error.code, isA<int>());
      });

      test('404 response is decoded as GetUserResponse404', () async {
        final api = buildUserApi(responseStatus: '404');

        final response = await api.getUser(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetUserResponse>>());
        final success = response as TonikSuccess<GetUserResponse>;
        expect(success.response.statusCode, 404);
        expect(success.value, isA<GetUserResponse404>());
      });

      test('500 response is decoded as GetUserResponse500', () async {
        final api = buildUserApi(responseStatus: '500');

        final response = await api.getUser(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetUserResponse>>());
        final success = response as TonikSuccess<GetUserResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<GetUserResponse500>());
      });

      test('500 response body decodes error object', () async {
        final api = buildUserApi(responseStatus: '500');

        final response = await api.getUser(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserResponse>;
        final response500 = success.value as GetUserResponse500;
        expect(response500.body, isA<InternalServerError>());
        expect(
          response500.body.body.error,
          isA<InternalServerErrorBodyErrorModel>(),
        );
        expect(response500.body.body.error.code, isA<int>());
        expect(response500.body.body.error.message, isA<String>());
      });
    });
  });

  group('patchUser', () {
    group('request encoding - path and method', () {
      test('request path is /user', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'test'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/user',
        );
      });

      test('request method is PATCH', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'test'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        expect(success.response.requestOptions.method, 'PATCH');
      });

      test('content-type header is application/json', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'test'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });
    });

    group('request encoding - body', () {
      test('encodes username as JSON property', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'newUsername'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['username'], 'newUsername');
      });

      test('omits username when not provided', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(password: 'newPassword'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('username'), isFalse);
      });

      test('encodes password as JSON property', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(password: 'secureP@ss123!'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['password'], 'secureP@ss123!');
      });

      test('omits password when not provided', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'test'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('password'), isFalse);
      });

      test('encodes settings as nested JSON object', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(
            settings: UserSettings(
              language: UserSettingsLanguageModel.en,
              blockAbusiveIPs: true,
              blockTorExitNodes: false,
            ),
          ),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['settings'], isA<Map<String, dynamic>>());
      });

      test('encodes settings.language as string', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(
            settings: UserSettings(language: UserSettingsLanguageModel.en),
          ),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        final settings = requestBody['settings'] as Map<String, dynamic>;
        expect(settings['language'], 'en');
      });

      test('encodes settings.blockAbusiveIPs as boolean', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(
            settings: UserSettings(blockAbusiveIPs: true),
          ),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        final settings = requestBody['settings'] as Map<String, dynamic>;
        expect(settings['blockAbusiveIPs'], true);
      });

      test('encodes settings.blockTorExitNodes as boolean', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(
            settings: UserSettings(blockTorExitNodes: false),
          ),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        final settings = requestBody['settings'] as Map<String, dynamic>;
        expect(settings['blockTorExitNodes'], false);
      });

      test('encodes all fields when provided', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(
            username: 'fullUpdate',
            password: 'fullPassword!',
            settings: UserSettings(language: UserSettingsLanguageModel.en),
          ),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['username'], 'fullUpdate');
        expect(requestBody['password'], 'fullPassword!');
        expect(requestBody['settings'], {'language': 'en'});
      });

      test('special characters in username are preserved', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'user+test_123'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['username'], 'user+test_123');
      });

      test('special characters in password are preserved', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(password: r'p@$$w0rd!#%&*<>"'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['password'], r'p@$$w0rd!#%&*<>"');
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as PatchUserResponse200', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'test'),
        );

        expect(response, isA<TonikSuccess<PatchUserResponse>>());
        final success = response as TonikSuccess<PatchUserResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<PatchUserResponse200>());
      });

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'test'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final response200 = success.value as PatchUserResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes UserGet', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'test'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final response200 = success.value as PatchUserResponse200;
        expect(response200.body.body, isA<UserGet>());
      });
    });

    group('response decoding - error responses', () {
      test('400 response is decoded as PatchUserResponse400', () async {
        final api = buildUserApi(responseStatus: '400');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'x'),
        );

        expect(response, isA<TonikSuccess<PatchUserResponse>>());
        final success = response as TonikSuccess<PatchUserResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<PatchUserResponse400>());
      });

      test('400 response body decodes error object', () async {
        final api = buildUserApi(responseStatus: '400');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'x'),
        );

        final success = response as TonikSuccess<PatchUserResponse>;
        final response400 = success.value as PatchUserResponse400;
        expect(response400.body, isA<BadRequestError>());
        expect(
          response400.body.body.error,
          isA<BadRequestErrorBodyErrorModel>(),
        );
        expect(response400.body.body.error.code, isA<int>());
        expect(response400.body.body.error.message, isA<String>());
      });

      test('401 response is decoded as PatchUserResponse401', () async {
        final api = buildUserApi(responseStatus: '401');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'test'),
        );

        expect(response, isA<TonikSuccess<PatchUserResponse>>());
        final success = response as TonikSuccess<PatchUserResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<PatchUserResponse401>());
      });

      test('403 response is decoded as PatchUserResponse403', () async {
        final api = buildUserApi(responseStatus: '403');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'test'),
        );

        expect(response, isA<TonikSuccess<PatchUserResponse>>());
        final success = response as TonikSuccess<PatchUserResponse>;
        expect(success.response.statusCode, 403);
        expect(success.value, isA<PatchUserResponse403>());
      });

      test('404 response is decoded as PatchUserResponse404', () async {
        final api = buildUserApi(responseStatus: '404');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'test'),
        );

        expect(response, isA<TonikSuccess<PatchUserResponse>>());
        final success = response as TonikSuccess<PatchUserResponse>;
        expect(success.response.statusCode, 404);
        expect(success.value, isA<PatchUserResponse404>());
      });

      test('409 response is decoded as PatchUserResponse409', () async {
        final api = buildUserApi(responseStatus: '409');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'existingUser'),
        );

        expect(response, isA<TonikSuccess<PatchUserResponse>>());
        final success = response as TonikSuccess<PatchUserResponse>;
        expect(success.response.statusCode, 409);
        expect(success.value, isA<PatchUserResponse409>());
      });

      test('500 response is decoded as PatchUserResponse500', () async {
        final api = buildUserApi(responseStatus: '500');

        final response = await api.patchUser(
          meSess: 'test_session',
          body: const UserPatch(username: 'test'),
        );

        expect(response, isA<TonikSuccess<PatchUserResponse>>());
        final success = response as TonikSuccess<PatchUserResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<PatchUserResponse500>());
      });
    });
  });

  group('deleteUser', () {
    group('request encoding', () {
      test('request path is /user', () async {
        final api = buildUserApi(responseStatus: '204');

        final response = await api.deleteUser(meSess: 'test_session');

        final success = response as TonikSuccess<DeleteUserResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/user',
        );
      });

      test('request method is DELETE', () async {
        final api = buildUserApi(responseStatus: '204');

        final response = await api.deleteUser(meSess: 'test_session');

        final success = response as TonikSuccess<DeleteUserResponse>;
        expect(success.response.requestOptions.method, 'DELETE');
      });

      test('request has no body', () async {
        final api = buildUserApi(responseStatus: '204');

        final response = await api.deleteUser(meSess: 'test_session');

        final success = response as TonikSuccess<DeleteUserResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 204', () {
      test('204 response is decoded as DeleteUserResponse204', () async {
        final api = buildUserApi(responseStatus: '204');

        final response = await api.deleteUser(meSess: 'test_session');

        expect(response, isA<TonikSuccess<DeleteUserResponse>>());
        final success = response as TonikSuccess<DeleteUserResponse>;
        expect(success.response.statusCode, 204);
        expect(success.value, isA<DeleteUserResponse204>());
      });

      test('204 response has no body content', () async {
        final api = buildUserApi(responseStatus: '204');

        final response = await api.deleteUser(meSess: 'test_session');

        final success = response as TonikSuccess<DeleteUserResponse>;
        final responseData = success.response.data as List<int>?;
        expect(responseData == null || responseData.isEmpty, isTrue);
      });
    });

    group('response decoding - error responses', () {
      test('400 response is decoded as DeleteUserResponse400', () async {
        final api = buildUserApi(responseStatus: '400');

        final response = await api.deleteUser(meSess: 'test_session');

        expect(response, isA<TonikSuccess<DeleteUserResponse>>());
        final success = response as TonikSuccess<DeleteUserResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<DeleteUserResponse400>());
      });

      test('401 response is decoded as DeleteUserResponse401', () async {
        final api = buildUserApi(responseStatus: '401');

        final response = await api.deleteUser(meSess: 'test_session');

        expect(response, isA<TonikSuccess<DeleteUserResponse>>());
        final success = response as TonikSuccess<DeleteUserResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<DeleteUserResponse401>());
      });

      test('403 response is decoded as DeleteUserResponse403', () async {
        final api = buildUserApi(responseStatus: '403');

        final response = await api.deleteUser(meSess: 'test_session');

        expect(response, isA<TonikSuccess<DeleteUserResponse>>());
        final success = response as TonikSuccess<DeleteUserResponse>;
        expect(success.response.statusCode, 403);
        expect(success.value, isA<DeleteUserResponse403>());
      });

      test('404 response is decoded as DeleteUserResponse404', () async {
        final api = buildUserApi(responseStatus: '404');

        final response = await api.deleteUser(meSess: 'test_session');

        expect(response, isA<TonikSuccess<DeleteUserResponse>>());
        final success = response as TonikSuccess<DeleteUserResponse>;
        expect(success.response.statusCode, 404);
        expect(success.value, isA<DeleteUserResponse404>());
      });

      test('500 response is decoded as DeleteUserResponse500', () async {
        final api = buildUserApi(responseStatus: '500');

        final response = await api.deleteUser(meSess: 'test_session');

        expect(response, isA<TonikSuccess<DeleteUserResponse>>());
        final success = response as TonikSuccess<DeleteUserResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<DeleteUserResponse500>());
      });
    });
  });

  group('getUserUsage', () {
    group('request encoding', () {
      test('request path is /user/usage', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUserUsage(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserUsageResponse>;
        expect(
          success.response.requestOptions.path,
          '$baseUrl/user/usage',
        );
      });

      test('request method is GET', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUserUsage(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserUsageResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUserUsage(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserUsageResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as GetUserUsageResponse200', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUserUsage(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetUserUsageResponse>>());
        final success = response as TonikSuccess<GetUserUsageResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<GetUserUsageResponse200>());
      });

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUserUsage(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserUsageResponse>;
        final response200 = success.value as GetUserUsageResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes UserUsageGet', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUserUsage(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserUsageResponse>;
        final response200 = success.value as GetUserUsageResponse200;
        expect(response200.body.body, isA<UserUsageGet>());
      });

      test('200 response decodes cpu field', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUserUsage(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserUsageResponse>;
        final response200 = success.value as GetUserUsageResponse200;
        expect(response200.body.body.cpu, isA<UserUsageGetCpuModel>());
      });

      test('200 response decodes memory field', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUserUsage(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserUsageResponse>;
        final response200 = success.value as GetUserUsageResponse200;
        expect(response200.body.body.memory, isA<UserUsageGetMemoryModel>());
      });

      test('200 response decodes disk field', () async {
        final api = buildUserApi(responseStatus: '200');

        final response = await api.getUserUsage(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserUsageResponse>;
        final response200 = success.value as GetUserUsageResponse200;
        expect(response200.body.body.disk, isA<UserUsageGetDiskModel>());
      });
    });

    group('response decoding - error responses', () {
      test('401 response is decoded as GetUserUsageResponse401', () async {
        final api = buildUserApi(responseStatus: '401');

        final response = await api.getUserUsage(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetUserUsageResponse>>());
        final success = response as TonikSuccess<GetUserUsageResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<GetUserUsageResponse401>());
      });

      test('401 response body decodes error object', () async {
        final api = buildUserApi(responseStatus: '401');

        final response = await api.getUserUsage(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserUsageResponse>;
        final response401 = success.value as GetUserUsageResponse401;
        expect(response401.body, isA<UnauthorisedError>());
        expect(response401.body.body.error.code, isA<int>());
      });

      test('500 response is decoded as GetUserUsageResponse500', () async {
        final api = buildUserApi(responseStatus: '500');

        final response = await api.getUserUsage(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetUserUsageResponse>>());
        final success = response as TonikSuccess<GetUserUsageResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<GetUserUsageResponse500>());
      });

      test('500 response body decodes error object', () async {
        final api = buildUserApi(responseStatus: '500');

        final response = await api.getUserUsage(meSess: 'test_session');

        final success = response as TonikSuccess<GetUserUsageResponse>;
        final response500 = success.value as GetUserUsageResponse500;
        expect(response500.body, isA<InternalServerError>());
        expect(
          response500.body.body.error,
          isA<InternalServerErrorBodyErrorModel>(),
        );
        expect(response500.body.body.error.code, isA<int>());
        expect(response500.body.body.error.message, isA<String>());
      });
    });
  });
}
