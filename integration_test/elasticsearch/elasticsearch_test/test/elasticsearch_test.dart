import 'dart:convert';

import 'package:elasticsearch_api/elasticsearch_api.dart';
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

  test('gets index statistics and serializes query flags', () async {
    final api = IndicesApi(buildServer(responseStatus: '200'));

    final result = await api.indicesStats(includeSegmentFileSizes: true);

    final response = requireSuccess(result).value;
    expect(response.shards.typesShardStatistics.successful.typesUint, 2);
    expect(response.shards.typesShardStatistics.failed.typesUint, 0);
    expect(response.indices, contains('products'));
    final request = await imposterServer.takeRequest();
    expect(request.method, 'GET');
    expect(request.uri.path, '/_stats');
    expect(request.uri.queryParameters['include_segment_file_sizes'], 'true');
  });

  test('bulk updates API keys using the array union variant', () async {
    final api = SecurityApi(buildServer(responseStatus: '200'));

    final result = await api.securityBulkUpdateApiKeys(
      body: const SecurityApiKeyBulkUpdatePostBodyBodyModel(
        ids: SecurityApiKeyBulkUpdatePostBodyBodyIdsOneOfModelList([
          'key-a',
          'key-b',
        ]),
        roleDescriptors: {},
      ),
    );

    final response = requireSuccess(result).value;
    expect(response.updated, ['key-a', 'key-b']);
    expect(response.noops, isEmpty);
    final request = await imposterServer.takeRequest();
    expect(request.method, 'POST');
    expect(request.uri.path, '/_security/api_key/_bulk_update');
    expect(jsonDecode(request.body!), {
      'ids': ['key-a', 'key-b'],
      'role_descriptors': <String, Object?>{},
    });
  });

  test('bulk updates an API key using the string union variant', () async {
    final api = SecurityApi(buildServer(responseStatus: '200'));

    final result = await api.securityBulkUpdateApiKeys(
      body: const SecurityApiKeyBulkUpdatePostBodyBodyModel(
        ids: SecurityApiKeyBulkUpdatePostBodyBodyIdsOneOfModelString('key-a'),
      ),
    );

    final response = requireSuccess(result).value;
    expect(response.updated, isEmpty);
    expect(response.noops, ['key-a']);
    final request = await imposterServer.takeRequest();
    expect(request.method, 'POST');
    expect(request.uri.path, '/_security/api_key/_bulk_update');
    expect(jsonDecode(request.body!), {'ids': 'key-a'});
  });
}
