import 'package:dio/dio.dart';
import 'package:medama_api/medama_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  const port = 8101;
  const baseUrl = 'http://localhost:$port';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  AuthenticationApi buildAuthApi({required String responseStatus}) {
    return AuthenticationApi(
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

  group('postAuthLogin', () {
    group('request encoding', () {
      test('request path is /auth/login', () async {
        final api = buildAuthApi(responseStatus: '200');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'testUser', password: 'testPass'),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8101/auth/login',
        );
      });

      test('request method is POST', () async {
        final api = buildAuthApi(responseStatus: '200');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'testUser', password: 'testPass'),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('content-type header is application/json', () async {
        final api = buildAuthApi(responseStatus: '200');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'testUser', password: 'testPass'),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });

      test('request body encodes username as JSON property', () async {
        final api = buildAuthApi(responseStatus: '200');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'myUser', password: 'myPass'),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['username'], 'myUser');
      });

      test('request body encodes password as JSON property', () async {
        final api = buildAuthApi(responseStatus: '200');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'myUser', password: 'myPass'),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['password'], 'myPass');
      });

      test(
        'request body contains only username and password properties',
        () async {
          final api = buildAuthApi(responseStatus: '200');

          final response = await api.postAuthLogin(
            body: const AuthLogin(username: 'user', password: 'pass'),
          );

          final success = response as TonikSuccess<PostAuthLoginResponse>;
          final requestBody =
              success.response.requestOptions.data as Map<String, dynamic>;
          expect(requestBody.keys, unorderedEquals(['username', 'password']));
        },
      );

      test('special characters in username are preserved in JSON', () async {
        final api = buildAuthApi(responseStatus: '200');

        final response = await api.postAuthLogin(
          body: const AuthLogin(
            username: 'user+test@example.com',
            password: 'pass',
          ),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['username'], 'user+test@example.com');
      });

      test('special characters in password are preserved in JSON', () async {
        final api = buildAuthApi(responseStatus: '200');

        final response = await api.postAuthLogin(
          body: const AuthLogin(
            username: 'user',
            password: r'p@$$w0rd!#%&*',
          ),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['password'], r'p@$$w0rd!#%&*');
      });

      test('unicode characters in credentials are preserved in JSON', () async {
        final api = buildAuthApi(responseStatus: '200');

        final response = await api.postAuthLogin(
          body: const AuthLogin(
            username: 'użytkownik',
            password: '密码🔐',
          ),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['username'], 'użytkownik');
        expect(requestBody['password'], '密码🔐');
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as PostAuthLoginResponse200', () async {
        final api = buildAuthApi(responseStatus: '200');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'testUser', password: 'testPass'),
        );

        expect(response, isA<TonikSuccess<PostAuthLoginResponse>>());
        final success = response as TonikSuccess<PostAuthLoginResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<PostAuthLoginResponse200>());
      });

      test('200 response decodes Set-Cookie header', () async {
        final api = buildAuthApi(responseStatus: '200');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'testUser', password: 'testPass'),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        final response200 = success.value as PostAuthLoginResponse200;

        // The Set-Cookie header should be decoded into the response body
        expect(response200.body.setCookie, isA<String>());
      });

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildAuthApi(responseStatus: '200');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'testUser', password: 'testPass'),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        final response200 = success.value as PostAuthLoginResponse200;

        // X-Api-Commit is optional per spec
        expect(response200.body.xApiCommit, isA<String?>());
      });
    });

    group('response decoding - 400', () {
      test('400 response is decoded as PostAuthLoginResponse400', () async {
        final api = buildAuthApi(responseStatus: '400');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'x', password: 'y'),
        );

        expect(response, isA<TonikSuccess<PostAuthLoginResponse>>());
        final success = response as TonikSuccess<PostAuthLoginResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<PostAuthLoginResponse400>());
      });

      test('400 response body decodes error object', () async {
        final api = buildAuthApi(responseStatus: '400');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'x', password: 'y'),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        final response400 = success.value as PostAuthLoginResponse400;

        expect(response400.body, isA<BadRequestError>());
        expect(
          response400.body.body.error,
          isA<BadRequestErrorBodyErrorModel>(),
        );
        expect(response400.body.body.error.code, isA<int>());
        expect(response400.body.body.error.message, isA<String>());
      });

      test('400 response decodes X-Api-Commit header', () async {
        final api = buildAuthApi(responseStatus: '400');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'x', password: 'y'),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        final response400 = success.value as PostAuthLoginResponse400;

        // X-Api-Commit is optional per spec
        expect(response400.body.xApiCommit, isA<String?>());
      });
    });

    group('response decoding - 401', () {
      test('401 response is decoded as PostAuthLoginResponse401', () async {
        final api = buildAuthApi(responseStatus: '401');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'wrong', password: 'wrong'),
        );

        expect(response, isA<TonikSuccess<PostAuthLoginResponse>>());
        final success = response as TonikSuccess<PostAuthLoginResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<PostAuthLoginResponse401>());
      });

      test('401 response body decodes error object', () async {
        final api = buildAuthApi(responseStatus: '401');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'wrong', password: 'wrong'),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        final response401 = success.value as PostAuthLoginResponse401;

        expect(response401.body, isA<UnauthorisedError>());
        expect(
          response401.body.body.error,
          isA<UnauthorisedErrorBodyErrorModel>(),
        );
        expect(response401.body.body.error.code, isA<int>());
        expect(response401.body.body.error.message, isA<String>());
      });
    });

    group('response decoding - 500', () {
      test('500 response is decoded as PostAuthLoginResponse500', () async {
        final api = buildAuthApi(responseStatus: '500');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'test', password: 'test'),
        );

        expect(response, isA<TonikSuccess<PostAuthLoginResponse>>());
        final success = response as TonikSuccess<PostAuthLoginResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<PostAuthLoginResponse500>());
      });

      test('500 response body decodes error object', () async {
        final api = buildAuthApi(responseStatus: '500');

        final response = await api.postAuthLogin(
          body: const AuthLogin(username: 'test', password: 'test'),
        );

        final success = response as TonikSuccess<PostAuthLoginResponse>;
        final response500 = success.value as PostAuthLoginResponse500;

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

  group('postAuthLogout', () {
    group('request encoding', () {
      test('request path is /auth/logout', () async {
        final api = buildAuthApi(responseStatus: '204');

        final response = await api.postAuthLogout();

        final success = response as TonikSuccess<PostAuthLogoutResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8101/auth/logout',
        );
      });

      test('request method is POST', () async {
        final api = buildAuthApi(responseStatus: '204');

        final response = await api.postAuthLogout();

        final success = response as TonikSuccess<PostAuthLogoutResponse>;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('request has no body', () async {
        final api = buildAuthApi(responseStatus: '204');

        final response = await api.postAuthLogout();

        final success = response as TonikSuccess<PostAuthLogoutResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('response decoding - 204', () {
      test('204 response is decoded as PostAuthLogoutResponse204', () async {
        final api = buildAuthApi(responseStatus: '204');

        final response = await api.postAuthLogout();

        expect(response, isA<TonikSuccess<PostAuthLogoutResponse>>());
        final success = response as TonikSuccess<PostAuthLogoutResponse>;
        expect(success.response.statusCode, 204);
        expect(success.value, isA<PostAuthLogoutResponse204>());
      });

      test('204 response has no body content', () async {
        final api = buildAuthApi(responseStatus: '204');

        final response = await api.postAuthLogout();

        final success = response as TonikSuccess<PostAuthLogoutResponse>;
        // 204 No Content should have empty body
        final responseData = success.response.data as List<int>?;
        expect(responseData == null || responseData.isEmpty, isTrue);
      });
    });

    group('response decoding - 401', () {
      test('401 response is decoded as PostAuthLogoutResponse401', () async {
        final api = buildAuthApi(responseStatus: '401');

        final response = await api.postAuthLogout();

        expect(response, isA<TonikSuccess<PostAuthLogoutResponse>>());
        final success = response as TonikSuccess<PostAuthLogoutResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<PostAuthLogoutResponse401>());
      });

      test('401 response body decodes error object', () async {
        final api = buildAuthApi(responseStatus: '401');

        final response = await api.postAuthLogout();

        final success = response as TonikSuccess<PostAuthLogoutResponse>;
        final response401 = success.value as PostAuthLogoutResponse401;

        expect(response401.body, isA<UnauthorisedError>());
        expect(
          response401.body.body.error,
          isA<UnauthorisedErrorBodyErrorModel>(),
        );
        expect(response401.body.body.error.code, isA<int>());
      });
    });

    group('response decoding - 500', () {
      test('500 response is decoded as PostAuthLogoutResponse500', () async {
        final api = buildAuthApi(responseStatus: '500');

        final response = await api.postAuthLogout();

        expect(response, isA<TonikSuccess<PostAuthLogoutResponse>>());
        final success = response as TonikSuccess<PostAuthLogoutResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<PostAuthLogoutResponse500>());
      });

      test('500 response body decodes error object', () async {
        final api = buildAuthApi(responseStatus: '500');

        final response = await api.postAuthLogout();

        final success = response as TonikSuccess<PostAuthLogoutResponse>;
        final response500 = success.value as PostAuthLogoutResponse500;

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
