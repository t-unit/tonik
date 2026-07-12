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

  test('operation-level override emits the status query key exactly once',
      () async {
    final api = buildQueryApi(responseStatus: '204');
    final response = await api.testParameterOverride(status: 'active');

    expect(response, isA<TonikSuccess<void>>());

    final success = response as TonikSuccess<void>;
    expect(success.response.requestOptions.uri.query, 'status=active');
  });
}
