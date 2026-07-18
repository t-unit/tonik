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

  group('form object with unset optional members and allowEmptyValue', () {
    test('omits unset optional members from explode and non-explode params',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPartialObject(
        filter: const PartialFilter(name: 'alice'),
        sort: const PartialFilter(name: 'alice'),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'name=alice&sort=name,alice',
      );
    });

    test('keeps a defined empty-string member as a named empty value',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormPartialObject(
        filter: const PartialFilter(name: 'alice', nickname: ''),
        sort: const PartialFilter(name: 'alice', nickname: ''),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'name=alice&nickname=&sort=name,alice,nickname,',
      );
    });
  });
}
