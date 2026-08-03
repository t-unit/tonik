import 'package:boolean_schemas_api/boolean_schemas_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  BooleanSchemasApi buildApi({String responseStatus = '200'}) {
    return BooleanSchemasApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  group('Header parameters - simple style', () {
    test('getHeaderAny with string value', () async {
      final api = buildApi();
      final result = await api.getHeaderAny(anyValue: 'header-test');
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test('getHeaderAny with number value', () async {
      final api = buildApi();
      final result = await api.getHeaderAny(anyValue: 123);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test('getHeaderAny with boolean value', () async {
      final api = buildApi();
      final result = await api.getHeaderAny(anyValue: true);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test('getHeaderAnyExplode with simple style and explode', () async {
      final api = buildApi();
      final result = await api.getHeaderAnyExplode(anyValue: 'explode-header');
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test('getHeaderAnyExplode with number value', () async {
      final api = buildApi();
      final result = await api.getHeaderAnyExplode(anyValue: 456);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test('getHeaderAnyExplode with array value', () async {
      final api = buildApi();
      final result = await api.getHeaderAnyExplode(anyValue: [1, 2, 3]);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });

    test('getHeaderAnyExplode with object value', () async {
      final api = buildApi();
      final result = await api.getHeaderAnyExplode(anyValue: {'key': 'value'});
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
    });
  });

  group('Response headers with AnyModel', () {
    test('getResponseHeaders returns headers with any values', () async {
      final api = buildApi();
      final result = await api.getResponseHeaders();
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.response.headers.value('X-Any-Header'), isNotNull);
      final responseData = success.value;
      expect(responseData.body.status, 'ok');
    });

    test('getResponseHeaders includes X-Any-Header', () async {
      final api = buildApi();
      final result = await api.getResponseHeaders();
      final success = requireSuccess(result);

      final anyHeader = success.response.headers.value('X-Any-Header');
      expect(anyHeader, isNotNull);
      expect(anyHeader, isNotEmpty);
    });
  });
}
