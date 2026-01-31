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

  WebsiteApi buildWebsiteApi({required String responseStatus}) {
    return WebsiteApi(
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

  group('getWebsites', () {
    group('request encoding - path and method', () {
      test('request path is /websites', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsites(meSess: 'test_session');

        final success = response as TonikSuccess<GetWebsitesResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8104/websites',
        );
      });

      test('request method is GET', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsites(meSess: 'test_session');

        final success = response as TonikSuccess<GetWebsitesResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsites(meSess: 'test_session');

        final success = response as TonikSuccess<GetWebsitesResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('request encoding - query parameters', () {
      test('summary=true query parameter is encoded correctly', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsites(
          meSess: 'test_session',
          summary: true,
        );

        final success = response as TonikSuccess<GetWebsitesResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['summary'], 'true');
      });

      test('summary=false query parameter is encoded correctly', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsites(
          meSess: 'test_session',
          summary: false,
        );

        final success = response as TonikSuccess<GetWebsitesResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters['summary'], 'false');
      });

      test('summary is omitted when not provided', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsites(meSess: 'test_session');

        final success = response as TonikSuccess<GetWebsitesResponse>;
        final uri = success.response.requestOptions.uri;
        expect(uri.queryParameters.containsKey('summary'), isFalse);
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as GetWebsitesResponse200', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsites(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetWebsitesResponse>>());
        final success = response as TonikSuccess<GetWebsitesResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<GetWebsitesResponse200>());
      });

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsites(meSess: 'test_session');

        final success = response as TonikSuccess<GetWebsitesResponse>;
        final response200 = success.value as GetWebsitesResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes as list of WebsiteGet', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsites(meSess: 'test_session');

        final success = response as TonikSuccess<GetWebsitesResponse>;
        final response200 = success.value as GetWebsitesResponse200;
        expect(response200.body.body, isA<List<WebsiteGet>>());
      });

      test('200 response decodes website hostname field', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsites(meSess: 'test_session');

        final success = response as TonikSuccess<GetWebsitesResponse>;
        final response200 = success.value as GetWebsitesResponse200;
        if (response200.body.body.isNotEmpty) {
          expect(response200.body.body.first.hostname, isA<String>());
        }
      });
    });

    group('response decoding - error responses', () {
      test('400 response is decoded as GetWebsitesResponse400', () async {
        final api = buildWebsiteApi(responseStatus: '400');

        final response = await api.getWebsites(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetWebsitesResponse>>());
        final success = response as TonikSuccess<GetWebsitesResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<GetWebsitesResponse400>());
      });

      test('400 response body decodes error object', () async {
        final api = buildWebsiteApi(responseStatus: '400');

        final response = await api.getWebsites(meSess: 'test_session');

        final success = response as TonikSuccess<GetWebsitesResponse>;
        final response400 = success.value as GetWebsitesResponse400;
        expect(response400.body, isA<BadRequestError>());
        expect(
          response400.body.body.error,
          isA<BadRequestErrorBodyErrorModel>(),
        );
        expect(response400.body.body.error.code, isA<int>());
        expect(response400.body.body.error.message, isA<String>());
      });

      test('401 response is decoded as GetWebsitesResponse401', () async {
        final api = buildWebsiteApi(responseStatus: '401');

        final response = await api.getWebsites(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetWebsitesResponse>>());
        final success = response as TonikSuccess<GetWebsitesResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<GetWebsitesResponse401>());
      });

      test('404 response is decoded as GetWebsitesResponse404', () async {
        final api = buildWebsiteApi(responseStatus: '404');

        final response = await api.getWebsites(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetWebsitesResponse>>());
        final success = response as TonikSuccess<GetWebsitesResponse>;
        expect(success.response.statusCode, 404);
        expect(success.value, isA<GetWebsitesResponse404>());
      });

      test('500 response is decoded as GetWebsitesResponse500', () async {
        final api = buildWebsiteApi(responseStatus: '500');

        final response = await api.getWebsites(meSess: 'test_session');

        expect(response, isA<TonikSuccess<GetWebsitesResponse>>());
        final success = response as TonikSuccess<GetWebsitesResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<GetWebsitesResponse500>());
      });

      test('500 response body decodes error object', () async {
        final api = buildWebsiteApi(responseStatus: '500');

        final response = await api.getWebsites(meSess: 'test_session');

        final success = response as TonikSuccess<GetWebsitesResponse>;
        final response500 = success.value as GetWebsitesResponse500;
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

  group('postWebsites', () {
    group('request encoding - path and method', () {
      test('request path is /websites', () async {
        final api = buildWebsiteApi(responseStatus: '201');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'test.com'),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8104/websites',
        );
      });

      test('request method is POST', () async {
        final api = buildWebsiteApi(responseStatus: '201');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'test.com'),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        expect(success.response.requestOptions.method, 'POST');
      });

      test('content-type header is application/json', () async {
        final api = buildWebsiteApi(responseStatus: '201');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'test.com'),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });
    });

    group('request encoding - body', () {
      test('encodes hostname as JSON property', () async {
        final api = buildWebsiteApi(responseStatus: '201');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'my-app.example.org'),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['hostname'], 'my-app.example.org');
      });

      test('hostname with subdomain is encoded correctly', () async {
        final api = buildWebsiteApi(responseStatus: '201');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'api.staging.example.com'),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['hostname'], 'api.staging.example.com');
      });

      test('hostname with port number is encoded correctly', () async {
        final api = buildWebsiteApi(responseStatus: '201');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'localhost:3000'),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['hostname'], 'localhost:3000');
      });

      test('hostname with hyphen is encoded correctly', () async {
        final api = buildWebsiteApi(responseStatus: '201');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'my-cool-website.com'),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['hostname'], 'my-cool-website.com');
      });
    });

    group('response decoding - 201', () {
      test('201 response is decoded as PostWebsitesResponse201', () async {
        final api = buildWebsiteApi(responseStatus: '201');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'test.com'),
        );

        expect(response, isA<TonikSuccess<PostWebsitesResponse>>());
        final success = response as TonikSuccess<PostWebsitesResponse>;
        expect(success.response.statusCode, 201);
        expect(success.value, isA<PostWebsitesResponse201>());
      });

      test('201 response decodes X-Api-Commit header', () async {
        final api = buildWebsiteApi(responseStatus: '201');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'test.com'),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        final response201 = success.value as PostWebsitesResponse201;
        expect(response201.body.xApiCommit, isA<String?>());
      });

      test('201 response body decodes WebsiteGet', () async {
        final api = buildWebsiteApi(responseStatus: '201');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'test.com'),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        final response201 = success.value as PostWebsitesResponse201;
        expect(response201.body.body, isA<WebsiteGet>());
      });

      test('201 response decodes website hostname', () async {
        final api = buildWebsiteApi(responseStatus: '201');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'test.com'),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        final response201 = success.value as PostWebsitesResponse201;
        expect(response201.body.body.hostname, isA<String>());
      });
    });

    group('response decoding - error responses', () {
      test('400 response is decoded as PostWebsitesResponse400', () async {
        final api = buildWebsiteApi(responseStatus: '400');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: ''),
        );

        expect(response, isA<TonikSuccess<PostWebsitesResponse>>());
        final success = response as TonikSuccess<PostWebsitesResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<PostWebsitesResponse400>());
      });

      test('400 response body decodes error object', () async {
        final api = buildWebsiteApi(responseStatus: '400');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: ''),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        final response400 = success.value as PostWebsitesResponse400;
        expect(response400.body, isA<BadRequestError>());
        expect(
          response400.body.body.error,
          isA<BadRequestErrorBodyErrorModel>(),
        );
        expect(response400.body.body.error.code, isA<int>());
        expect(response400.body.body.error.message, isA<String>());
      });

      test('401 response is decoded as PostWebsitesResponse401', () async {
        final api = buildWebsiteApi(responseStatus: '401');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'test.com'),
        );

        expect(response, isA<TonikSuccess<PostWebsitesResponse>>());
        final success = response as TonikSuccess<PostWebsitesResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<PostWebsitesResponse401>());
      });

      test('403 response is decoded as PostWebsitesResponse403', () async {
        final api = buildWebsiteApi(responseStatus: '403');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'test.com'),
        );

        expect(response, isA<TonikSuccess<PostWebsitesResponse>>());
        final success = response as TonikSuccess<PostWebsitesResponse>;
        expect(success.response.statusCode, 403);
        expect(success.value, isA<PostWebsitesResponse403>());
      });

      test('409 response is decoded as PostWebsitesResponse409', () async {
        final api = buildWebsiteApi(responseStatus: '409');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'existing.com'),
        );

        expect(response, isA<TonikSuccess<PostWebsitesResponse>>());
        final success = response as TonikSuccess<PostWebsitesResponse>;
        expect(success.response.statusCode, 409);
        expect(success.value, isA<PostWebsitesResponse409>());
      });

      test('409 response body decodes error object', () async {
        final api = buildWebsiteApi(responseStatus: '409');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'existing.com'),
        );

        final success = response as TonikSuccess<PostWebsitesResponse>;
        final response409 = success.value as PostWebsitesResponse409;
        expect(response409.body, isA<ConflictError>());
        expect(response409.body.body.error, isA<ConflictErrorBodyErrorModel>());
        expect(response409.body.body.error.code, isA<int>());
        expect(response409.body.body.error.message, isA<String>());
      });

      test('500 response is decoded as PostWebsitesResponse500', () async {
        final api = buildWebsiteApi(responseStatus: '500');

        final response = await api.postWebsites(
          body: const WebsiteCreate(hostname: 'test.com'),
        );

        expect(response, isA<TonikSuccess<PostWebsitesResponse>>());
        final success = response as TonikSuccess<PostWebsitesResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<PostWebsitesResponse500>());
      });
    });
  });

  group('getWebsitesId', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8104/websites/example.com',
        );
      });

      test('request method is GET', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        expect(success.response.requestOptions.method, 'GET');
      });

      test('request has no body', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('request encoding - path parameter', () {
      test('hostname with subdomain is encoded correctly', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'app.example.com',
        );

        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8104/websites/app.example.com',
        );
      });

      test('hostname with port is encoded correctly', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'localhost:8080',
        );

        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8104/websites/localhost%3A8080',
        );
      });

      test('hostname with hyphens is encoded correctly', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'my-cool-app.io',
        );

        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8104/websites/my-cool-app.io',
        );
      });
    });

    group('response decoding - 200', () {
      test('200 response is decoded as GetWebsitesIdResponse200', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsitesIdResponse>>());
        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<GetWebsitesIdResponse200>());
      });

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        final response200 = success.value as GetWebsitesIdResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes WebsiteGet', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        final response200 = success.value as GetWebsitesIdResponse200;
        expect(response200.body.body, isA<WebsiteGet>());
      });

      test('200 response decodes website hostname', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        final response200 = success.value as GetWebsitesIdResponse200;
        expect(response200.body.body.hostname, isA<String>());
      });

      test('200 response decodes optional summary field', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        final response200 = success.value as GetWebsitesIdResponse200;
        expect(
          response200.body.body.summary,
          anyOf(isNull, isA<WebsiteGetSummaryModel>()),
        );
      });
    });

    group('response decoding - error responses', () {
      test('400 response is decoded as GetWebsitesIdResponse400', () async {
        final api = buildWebsiteApi(responseStatus: '400');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'invalid',
        );

        expect(response, isA<TonikSuccess<GetWebsitesIdResponse>>());
        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<GetWebsitesIdResponse400>());
      });

      test('401 response is decoded as GetWebsitesIdResponse401', () async {
        final api = buildWebsiteApi(responseStatus: '401');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsitesIdResponse>>());
        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<GetWebsitesIdResponse401>());
      });

      test('404 response is decoded as GetWebsitesIdResponse404', () async {
        final api = buildWebsiteApi(responseStatus: '404');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'unknown.com',
        );

        expect(response, isA<TonikSuccess<GetWebsitesIdResponse>>());
        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        expect(success.response.statusCode, 404);
        expect(success.value, isA<GetWebsitesIdResponse404>());
      });

      test('404 response body decodes error object', () async {
        final api = buildWebsiteApi(responseStatus: '404');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'unknown.com',
        );

        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        final response404 = success.value as GetWebsitesIdResponse404;
        expect(response404.body, isA<NotFoundError>());
        expect(response404.body.body.error, isA<NotFoundErrorBodyErrorModel>());
        expect(response404.body.body.error.code, isA<int>());
        expect(response404.body.body.error.message, isA<String>());
      });

      test('500 response is decoded as GetWebsitesIdResponse500', () async {
        final api = buildWebsiteApi(responseStatus: '500');

        final response = await api.getWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<GetWebsitesIdResponse>>());
        final success = response as TonikSuccess<GetWebsitesIdResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<GetWebsitesIdResponse500>());
      });
    });
  });

  group('patchWebsitesId', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(hostname: 'new.com'),
        );

        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8104/websites/example.com',
        );
      });

      test('request method is PATCH', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(hostname: 'new.com'),
        );

        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        expect(success.response.requestOptions.method, 'PATCH');
      });

      test('content-type header is application/json', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(hostname: 'new.com'),
        );

        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        expect(
          success.response.requestOptions.contentType,
          'application/json',
        );
      });
    });

    group('request encoding - body', () {
      test('encodes hostname in body as JSON property', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(hostname: 'updated-hostname.com'),
        );

        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody['hostname'], 'updated-hostname.com');
      });

      test('omits hostname in body when not provided', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(),
        );

        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        final requestBody =
            success.response.requestOptions.data as Map<String, dynamic>;
        expect(requestBody.containsKey('hostname'), isFalse);
      });

      test(
        'hostname with special characters in body is encoded correctly',
        () async {
          final api = buildWebsiteApi(responseStatus: '200');

          final response = await api.patchWebsitesId(
            meSess: 'test_session',
            hostname: 'example.com',
            body: const WebsitePatch(hostname: 'my-new-app.io'),
          );

          final success = response as TonikSuccess<PatchWebsitesIdResponse>;
          final requestBody =
              success.response.requestOptions.data as Map<String, dynamic>;
          expect(requestBody['hostname'], 'my-new-app.io');
        },
      );
    });

    group('response decoding - 200', () {
      test('200 response is decoded as PatchWebsitesIdResponse200', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(hostname: 'new.com'),
        );

        expect(response, isA<TonikSuccess<PatchWebsitesIdResponse>>());
        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        expect(success.response.statusCode, 200);
        expect(success.value, isA<PatchWebsitesIdResponse200>());
      });

      test('200 response decodes X-Api-Commit header', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(hostname: 'new.com'),
        );

        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        final response200 = success.value as PatchWebsitesIdResponse200;
        expect(response200.body.xApiCommit, isA<String?>());
      });

      test('200 response body decodes WebsiteGet', () async {
        final api = buildWebsiteApi(responseStatus: '200');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(hostname: 'new.com'),
        );

        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        final response200 = success.value as PatchWebsitesIdResponse200;
        expect(response200.body.body, isA<WebsiteGet>());
      });
    });

    group('response decoding - error responses', () {
      test('400 response is decoded as PatchWebsitesIdResponse400', () async {
        final api = buildWebsiteApi(responseStatus: '400');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(hostname: ''),
        );

        expect(response, isA<TonikSuccess<PatchWebsitesIdResponse>>());
        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<PatchWebsitesIdResponse400>());
      });

      test('401 response is decoded as PatchWebsitesIdResponse401', () async {
        final api = buildWebsiteApi(responseStatus: '401');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(hostname: 'new.com'),
        );

        expect(response, isA<TonikSuccess<PatchWebsitesIdResponse>>());
        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<PatchWebsitesIdResponse401>());
      });

      test('403 response is decoded as PatchWebsitesIdResponse403', () async {
        final api = buildWebsiteApi(responseStatus: '403');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(hostname: 'new.com'),
        );

        expect(response, isA<TonikSuccess<PatchWebsitesIdResponse>>());
        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        expect(success.response.statusCode, 403);
        expect(success.value, isA<PatchWebsitesIdResponse403>());
      });

      test('404 response is decoded as PatchWebsitesIdResponse404', () async {
        final api = buildWebsiteApi(responseStatus: '404');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'unknown.com',
          body: const WebsitePatch(hostname: 'new.com'),
        );

        expect(response, isA<TonikSuccess<PatchWebsitesIdResponse>>());
        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        expect(success.response.statusCode, 404);
        expect(success.value, isA<PatchWebsitesIdResponse404>());
      });

      test('500 response is decoded as PatchWebsitesIdResponse500', () async {
        final api = buildWebsiteApi(responseStatus: '500');

        final response = await api.patchWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
          body: const WebsitePatch(hostname: 'new.com'),
        );

        expect(response, isA<TonikSuccess<PatchWebsitesIdResponse>>());
        final success = response as TonikSuccess<PatchWebsitesIdResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<PatchWebsitesIdResponse500>());
      });
    });
  });

  group('deleteWebsitesId', () {
    group('request encoding - path and method', () {
      test('request path includes hostname parameter', () async {
        final api = buildWebsiteApi(responseStatus: '204');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8104/websites/example.com',
        );
      });

      test('request method is DELETE', () async {
        final api = buildWebsiteApi(responseStatus: '204');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        expect(success.response.requestOptions.method, 'DELETE');
      });

      test('request has no body', () async {
        final api = buildWebsiteApi(responseStatus: '204');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        expect(success.response.requestOptions.data, isNull);
      });
    });

    group('request encoding - path parameter', () {
      test('hostname with subdomain is encoded correctly', () async {
        final api = buildWebsiteApi(responseStatus: '204');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'api.example.com',
        );

        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8104/websites/api.example.com',
        );
      });

      test('hostname with port is encoded correctly', () async {
        final api = buildWebsiteApi(responseStatus: '204');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'localhost:3000',
        );

        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        expect(
          success.response.requestOptions.path,
          'http://localhost:8104/websites/localhost%3A3000',
        );
      });
    });

    group('response decoding - 204', () {
      test('204 response is decoded as DeleteWebsitesIdResponse204', () async {
        final api = buildWebsiteApi(responseStatus: '204');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<DeleteWebsitesIdResponse>>());
        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        expect(success.response.statusCode, 204);
        expect(success.value, isA<DeleteWebsitesIdResponse204>());
      });

      test('204 response has no body content', () async {
        final api = buildWebsiteApi(responseStatus: '204');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        final responseData = success.response.data as List<int>?;
        expect(responseData == null || responseData.isEmpty, isTrue);
      });
    });

    group('response decoding - error responses', () {
      test('400 response is decoded as DeleteWebsitesIdResponse400', () async {
        final api = buildWebsiteApi(responseStatus: '400');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'invalid',
        );

        expect(response, isA<TonikSuccess<DeleteWebsitesIdResponse>>());
        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        expect(success.response.statusCode, 400);
        expect(success.value, isA<DeleteWebsitesIdResponse400>());
      });

      test('401 response is decoded as DeleteWebsitesIdResponse401', () async {
        final api = buildWebsiteApi(responseStatus: '401');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<DeleteWebsitesIdResponse>>());
        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        expect(success.response.statusCode, 401);
        expect(success.value, isA<DeleteWebsitesIdResponse401>());
      });

      test('403 response is decoded as DeleteWebsitesIdResponse403', () async {
        final api = buildWebsiteApi(responseStatus: '403');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<DeleteWebsitesIdResponse>>());
        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        expect(success.response.statusCode, 403);
        expect(success.value, isA<DeleteWebsitesIdResponse403>());
      });

      test('404 response is decoded as DeleteWebsitesIdResponse404', () async {
        final api = buildWebsiteApi(responseStatus: '404');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'unknown.com',
        );

        expect(response, isA<TonikSuccess<DeleteWebsitesIdResponse>>());
        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        expect(success.response.statusCode, 404);
        expect(success.value, isA<DeleteWebsitesIdResponse404>());
      });

      test('500 response is decoded as DeleteWebsitesIdResponse500', () async {
        final api = buildWebsiteApi(responseStatus: '500');

        final response = await api.deleteWebsitesId(
          meSess: 'test_session',
          hostname: 'example.com',
        );

        expect(response, isA<TonikSuccess<DeleteWebsitesIdResponse>>());
        final success = response as TonikSuccess<DeleteWebsitesIdResponse>;
        expect(success.response.statusCode, 500);
        expect(success.value, isA<DeleteWebsitesIdResponse500>());
      });
    });
  });
}
