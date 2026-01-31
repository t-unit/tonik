import 'package:boolean_schemas_api/boolean_schemas_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

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
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  group('NeverModel code generation verification', () {
    test('getPathNever generates valid API method', () {
      final api = buildApi();
      // This test only verifies that the method was generated
      // It cannot be called at runtime because Never cannot be instantiated
      expect(api.getPathNever, isA<Function>());
    });

    test('getQueryNever generates valid API method', () {
      final api = buildApi();
      expect(api.getQueryNever, isA<Function>());
    });

    test('getHeaderNever generates valid API method', () {
      final api = buildApi();
      expect(api.getHeaderNever, isA<Function>());
    });

    test('postJsonNever generates valid API method', () {
      final api = buildApi();
      expect(api.postJsonNever, isA<Function>());
    });

    test('postPureNever generates valid API method', () {
      final api = buildApi();
      expect(api.postPureNever, isA<Function>());
    });

    test('postFormNever generates valid API method', () {
      final api = buildApi();
      expect(api.postFormNever, isA<Function>());
    });

    test('getResponseNever generates valid API method', () {
      final api = buildApi();
      expect(api.getResponseNever, isA<Function>());
    });
  });

  group('NeverModel in responses', () {
    test('ObjectWithNever type can be used in response types', () {
      // Verify that ObjectWithNever is generated and can be referenced
      const obj = ObjectWithNever(name: 'test');
      expect(obj, isA<ObjectWithNever>());
      expect(obj.neverField, isNull);
    });

    test('FormWithNever type can be used in request types', () {
      // Verify that FormWithNever is generated and can be referenced
      const form = FormWithNever(name: 'test');
      expect(form, isA<FormWithNever>());
      expect(form.neverField, isNull);
    });
  });
}
