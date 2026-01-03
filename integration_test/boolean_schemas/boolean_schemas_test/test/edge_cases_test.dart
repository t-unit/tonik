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

  group('Edge cases with null and empty values', () {
    test('echoJsonAny with null anyData returns null', () async {
      final api = buildApi();
      const original = ObjectWithAny(name: 'null-edge-case', anyData: null);

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.data,
        {'name': 'null-edge-case', 'anyData': null},
      );

      final body = success.value;
      expect(body.name, 'null-edge-case');
      expect(body.anyData, isNull);
    });

    test('echoJsonAny with empty object anyData', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'empty-object',
        anyData: <String, Object?>{},
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.data,
        {'name': 'empty-object', 'anyData': <String, Object?>{}},
      );

      final body = success.value;
      expect(body.name, 'empty-object');
      expect(body.anyData, <String, Object?>{});
    });

    test('echoJsonAny with empty array anyData', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'empty-array',
        anyData: <Object?>[],
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.data,
        {'name': 'empty-array', 'anyData': <Object?>[]},
      );

      final body = success.value;
      expect(body.name, 'empty-array');
      expect(body.anyData, <Object?>[]);
    });
  });

  group('Edge cases with deeply nested structures', () {
    test(
      'echoJsonAny with deeply nested structure preserves all levels',
      () async {
        final api = buildApi();
        const original = ObjectWithAny(
          name: 'deep-nesting',
          anyData: {
            'level1': {
              'level2': {
                'level3': [
                  {
                    'level4': 'deep-value',
                  },
                ],
              },
            },
          },
        );

        final result = await api.echoJsonAny(body: original);
        final success = result as TonikSuccess<ObjectWithAny>;
        expect(success.response.statusCode, 200);
        expect(
          success.response.requestOptions.data,
          {
            'name': 'deep-nesting',
            'anyData': {
              'level1': {
                'level2': {
                  'level3': [
                    {'level4': 'deep-value'},
                  ],
                },
              },
            },
          },
        );

        final body = success.value;
        expect(body.name, 'deep-nesting');
        expect(body.anyData, {
          'level1': {
            'level2': {
              'level3': [
                {'level4': 'deep-value'},
              ],
            },
          },
        });
      },
    );

    test('echoJsonAny with multiple nesting types', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'mixed-nesting',
        anyData: {
          'arrays': [
            [1, 2],
            [3, 4],
          ],
          'objects': [
            {'a': 1},
            {'b': 2},
          ],
          'mixed': [
            'string',
            123,
            {'key': 'value'},
          ],
        },
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'mixed-nesting');
      expect(body.anyData, isA<Map<String, Object?>>());
    });
  });

  group('Edge cases with special characters', () {
    test('echoJsonAny with special characters in string', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'special-chars',
        anyData: 'Hello "world" with \\backslash and \ttab',
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.data,
        {
          'name': 'special-chars',
          'anyData': 'Hello "world" with \\backslash and \ttab',
        },
      );

      final body = success.value;
      expect(body.name, 'special-chars');
      expect(body.anyData, 'Hello "world" with \\backslash and \ttab');
    });

    test('echoJsonAny with unicode in anyData', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'unicode-test',
        anyData: '日本語 emoji 🎉 and symbols ™®©',
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.data,
        {'name': 'unicode-test', 'anyData': '日本語 emoji 🎉 and symbols ™®©'},
      );

      final body = success.value;
      expect(body.name, 'unicode-test');
      expect(body.anyData, '日本語 emoji 🎉 and symbols ™®©');
    });

    test('echoJsonAny with newlines and tabs', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'whitespace-test',
        anyData: 'Line 1\nLine 2\tTabbed\rCarriage return',
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'whitespace-test');
      expect(body.anyData, contains('\n'));
      expect(body.anyData, contains('\t'));
    });
  });

  group('Edge cases with large numbers', () {
    test('echoJsonAny with large integer', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'large-int',
        anyData: 9007199254740991, // Max safe integer in JavaScript
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'large-int');
      expect(body.anyData, 9007199254740991);
    });

    test('echoJsonAny with small decimal', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'small-decimal',
        anyData: 0.0000001,
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'small-decimal');
    });

    test('echoJsonAny with negative numbers', () async {
      final api = buildApi();
      const original = ObjectWithAny(
        name: 'negative',
        anyData: -999.999,
      );

      final result = await api.echoJsonAny(body: original);
      final success = result as TonikSuccess<ObjectWithAny>;
      expect(success.response.statusCode, 200);

      final body = success.value;
      expect(body.name, 'negative');
      expect(body.anyData, -999.999);
    });
  });
}
