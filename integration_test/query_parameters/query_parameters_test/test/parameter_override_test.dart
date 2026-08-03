import 'package:query_parameters_api/query_parameters_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  QueryApi buildQueryApi({required String responseStatus}) {
    return QueryApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  test(
    'operation-level override emits the status query key exactly once',
    () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testParameterOverride(status: 'active');

      expect(response, isTonikSuccess);

      final success = requireSuccess(response);
      expect(success.response.requestOptions.uri.query, 'status=active');
    },
  );
}
