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

  test('null required query values are omitted', () async {
    final api = QueryApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(headers: {'X-Response-Status': '204'}),
      ),
    );

    final response = await api.testRequiredNullableQuery(
      q: null,
      qd: null,
      sp: null,
      anyQ: null,
    );

    expect(response, isTonikSuccess);
    final request = await imposterServer.takeRequest();
    expect(request.uri.query, '');
  });

  test('empty required query string is sent', () async {
    final api = QueryApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(headers: {'X-Response-Status': '204'}),
      ),
    );

    final response = await api.testRequiredNullableQuery(
      q: '',
      qd: null,
      sp: null,
      anyQ: 'value',
    );

    expect(response, isTonikSuccess);
    final request = await imposterServer.takeRequest();
    expect(request.uri.query, 'q=&anyQ=value');
  });
}
