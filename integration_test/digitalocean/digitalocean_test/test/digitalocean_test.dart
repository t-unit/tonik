import 'dart:convert';

import 'package:digitalocean_api/digitalocean_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  CustomServer buildServer({required String responseStatus}) => CustomServer(
    baseUrl: baseUrl,
    serverConfig: testServerConfig(
      headers: {'X-Response-Status': responseStatus},
    ),
  );

  test('gets the default project and response rate limit', () async {
    final api = ProjectsApi(buildServer(responseStatus: '200'));

    final result = await api.projectsGetDefault();

    final response =
        requireSuccess(result).value as ProjectsGetDefaultResponse200;
    expect(
      response.body.body.project?.projectBase.id,
      'addb4547-6bab-419a-8542-76263a033cf6',
    );
    expect(response.body.body.project?.projectBase.name, 'Default');
    expect(
      response.body.body.project?.projectBase.createdAt,
      DateTime.utc(2017, 10, 19, 21, 44, 20),
    );
    expect(response.body.body.project?.projectModel.isDefault, isTrue);
    expect(response.body.ratelimitLimit, 5000);
    final request = await imposterServer.takeRequest();
    expect(request.method, 'GET');
    expect(request.uri.path, '/v2/projects/default');
  });

  test('resizes a vector database with a JSON body', () async {
    final api = VectorDatabasesApi(buildServer(responseStatus: '200'));

    final result = await api.vectorDatabasesPostResize(
      id: 'vector-42',
      body: const VectordbResizeVectorDbRequest(
        id: 'vector-42',
        size: 'medium',
      ),
    );

    final response =
        requireSuccess(result).value as VectorDatabasesPostResizeResponse200;
    expect(response.body.body.vectorDb?.id, 'vector-42');
    expect(response.body.body.vectorDb?.name, 'Product search');
    final request = await imposterServer.takeRequest();
    expect(request.method, 'POST');
    expect(request.uri.path, '/v2/vector-databases/vector-42/resize');
    expect(jsonDecode(request.body!), {'id': 'vector-42', 'size': 'medium'});
  });

  test('decodes a missing default project response', () async {
    final api = ProjectsApi(buildServer(responseStatus: '404'));

    final result = await api.projectsGetDefault();

    final response =
        requireSuccess(result).value as ProjectsGetDefaultResponse404;
    expect(response.body.body.id, 'not_found');
    expect(response.body.body.message, 'Default project not found');
    expect(response.body.body.requestId, 'request-42');
    expect(
      (await imposterServer.takeRequest()).uri.path,
      '/v2/projects/default',
    );
  });
}
