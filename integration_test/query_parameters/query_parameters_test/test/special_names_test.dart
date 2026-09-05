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

  test('ampersand in a parameter name is percent-encoded', () async {
    final api = buildQueryApi(responseStatus: '204');
    final response = await api.testFormSpecialNames(qAmpersandA: 'hello');

    expect(response, isTonikSuccess);
    requireSuccess(response);
    final recordedRequest = await imposterServer.takeRequest();
    expect(recordedRequest.uri.query, 'q%26a=hello');
  });

  test('equals in a parameter name is percent-encoded', () async {
    final api = buildQueryApi(responseStatus: '204');
    final response = await api.testFormSpecialNames(aEqualsB: 'v');

    expect(response, isTonikSuccess);
    requireSuccess(response);
    final recordedRequest = await imposterServer.takeRequest();
    expect(recordedRequest.uri.query, 'a%3Db=v');
  });

  test(
    'special names keep their pair structure when parsed by a server',
    () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormSpecialNames(
        qAmpersandA: 'hello',
        aEqualsB: 'v',
      );

      expect(response, isTonikSuccess);
      requireSuccess(response);
      final recordedRequest = await imposterServer.takeRequest();
      expect(recordedRequest.uri.query, 'q%26a=hello&a%3Db=v');
      expect(Uri.splitQueryString(recordedRequest.uri.query), {
        'q&a': 'hello',
        'a=b': 'v',
      });
    },
  );
}
