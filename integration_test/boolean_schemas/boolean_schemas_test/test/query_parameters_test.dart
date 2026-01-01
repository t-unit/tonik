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

    test('getQueryAny with object value', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: {'key': 'value'});
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryAny with array value', () async {
      final api = buildApi();
      final result = await api.getQueryAny(anyValue: [1, 2, 3]);
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

    test('getQueryAnyNoExplode with array value', () async {
      final api = buildApi();
      final result = await api.getQueryAnyNoExplode(anyValue: ['a', 'b', 'c']);
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });
  });

  group('Query parameters - spaceDelimited style', () {
    test('getQuerySpaceDelimitedAny with array value', () async {
      final api = buildApi();
      final result = await api.getQuerySpaceDelimitedAny(
        anyValue: ['a', 'b', 'c'],
      );
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQuerySpaceDelimitedAny with string value', () async {
      final api = buildApi();
      final result = await api.getQuerySpaceDelimitedAny(
        anyValue: 'space-delimited',
      );
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQuerySpaceDelimitedAny with number array', () async {
      final api = buildApi();
      final result = await api.getQuerySpaceDelimitedAny(anyValue: [1, 2, 3]);
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });
  });

  group('Query parameters - pipeDelimited style', () {
    test('getQueryPipeDelimitedAny with array value', () async {
      final api = buildApi();
      final result = await api.getQueryPipeDelimitedAny(anyValue: [1, 2, 3]);
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryPipeDelimitedAny with string value', () async {
      final api = buildApi();
      final result = await api.getQueryPipeDelimitedAny(
        anyValue: 'pipe-delimited',
      );
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryPipeDelimitedAny with mixed array', () async {
      final api = buildApi();
      final result = await api.getQueryPipeDelimitedAny(
        anyValue: ['x', 10, true],
      );
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });
  });

  group('Query parameters - deepObject style', () {
    test('getQueryDeepObjectAny with object value', () async {
      final api = buildApi();
      final result = await api.getQueryDeepObjectAny(
        anyValue: {'nested': 'value', 'count': 42},
      );
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryDeepObjectAny with complex nested object', () async {
      final api = buildApi();
      final result = await api.getQueryDeepObjectAny(
        anyValue: {
          'level1': {'level2': 'deep'},
          'array': [1, 2],
        },
      );
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });

    test('getQueryDeepObjectAny with string value', () async {
      final api = buildApi();
      final result = await api.getQueryDeepObjectAny(anyValue: 'simple');
      final success = result as TonikSuccess;
      expect(success.response.statusCode, 200);
    });
  });
}
