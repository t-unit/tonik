import 'package:dio/dio.dart';
import 'package:query_parameters_api/query_parameters_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

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
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  test('ampersand in a parameter name is percent-encoded', () async {
    final api = buildQueryApi(responseStatus: '204');
    final response = await api.testFormSpecialNames(qAmpersandA: 'hello');

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.requestOptions.uri.query, 'q%26a=hello');
  });

  test('equals in a parameter name is percent-encoded', () async {
    final api = buildQueryApi(responseStatus: '204');
    final response = await api.testFormSpecialNames(aEqualsB: 'v');

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(success.response.requestOptions.uri.query, 'a%3Db=v');
  });

  test('special names keep their pair structure when parsed by a server',
      () async {
    final api = buildQueryApi(responseStatus: '204');
    final response = await api.testFormSpecialNames(
      qAmpersandA: 'hello',
      aEqualsB: 'v',
    );

    expect(response, isA<TonikSuccess<void>>());
    final success = response as TonikSuccess<void>;
    expect(
      success.response.requestOptions.uri.query,
      'q%26a=hello&a%3Db=v',
    );
    expect(
      Uri.splitQueryString(success.response.requestOptions.uri.query),
      {'q&a': 'hello', 'a=b': 'v'},
    );
  });
}
