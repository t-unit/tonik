import 'package:boolean_schemas_api/boolean_schemas_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

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

  group('Form-urlencoded body with AnyModel', () {
    test('echoFormAny roundtrip with form data', () async {
      final api = buildApi();
      const original = FormWithAny(
        name: 'form-test',
        anyValue: 'form-any-value',
        count: 123,
      );

      final result = await api.echoFormAny(body: original);
      final success = result as TonikSuccess<FormWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'form-test');
      expect(body.anyValue, 'form-any-value');
      expect(body.count, 123);
    });

    test('echoFormAny with complex anyValue', () async {
      final api = buildApi();
      const original = FormWithAny(
        name: 'complex-form',
        anyValue: {
          'nested': 'object',
          'array': [1, 2, 3],
        },
        count: 456,
      );

      final result = await api.echoFormAny(body: original);
      final success = result as TonikSuccess<FormWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'complex-form');
    });

    test('echoFormAny with null anyValue', () async {
      final api = buildApi();
      const original = FormWithAny(
        name: 'null-form',
        anyValue: null,
        count: 0,
      );

      final result = await api.echoFormAny(body: original);
      final success = result as TonikSuccess<FormWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'null-form');
    });

    test('echoFormAny with number anyValue', () async {
      final api = buildApi();
      const original = FormWithAny(
        name: 'number-form',
        anyValue: 42.5,
        count: 10,
      );

      final result = await api.echoFormAny(body: original);
      final success = result as TonikSuccess<FormWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'number-form');
    });

    test('echoFormAny with boolean anyValue', () async {
      final api = buildApi();
      const original = FormWithAny(
        name: 'bool-form',
        anyValue: true,
        count: 1,
      );

      final result = await api.echoFormAny(body: original);
      final success = result as TonikSuccess<FormWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'bool-form');
    });
  });
}
