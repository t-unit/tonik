import 'package:boolean_schemas_api/boolean_schemas_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8087;
  const baseUrl = 'http://localhost:$port';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  BooleanSchemasApi buildApi({String responseStatus = '200'}) {
    return BooleanSchemasApi(
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

  group('Query parameters - form style', () {
    test('getQueryAny with string value (explode=true)', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: 'query-test');
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryAny with number value', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: 42);
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryAny with boolean value', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: false);
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryAnyNoExplode with string value (explode=false)', () async {
      final api = buildApi();
      final result = await api.getQueryAnyNoExplode(anyValue: 'no-explode');
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryAnyNoExplode with number value', () async {
      final api = buildApi();
      final result = await api.getQueryAnyNoExplode(anyValue: 999);
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });
  });
}
