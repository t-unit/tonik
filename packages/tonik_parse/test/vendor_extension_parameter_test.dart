import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('x-dart-name on query parameters', () {
    test('parses x-dart-name on query parameter', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'parameters': [
                {
                  'name': 'user_id',
                  'in': 'query',
                  'x-dart-name': 'userId',
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'Success',
                },
              },
            },
          },
        },
      };

      final document = Importer().import(spec);
      final queryParam = document.queryParameters
          .whereType<QueryParameterObject>()
          .firstWhereOrNull((p) => p.rawName == 'user_id');

      expect(queryParam, isNotNull);
      expect(queryParam!.nameOverride, 'userId');
    });

    test('sets nameOverride to null when x-dart-name is absent', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'parameters': [
                {
                  'name': 'user_id',
                  'in': 'query',
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'Success',
                },
              },
            },
          },
        },
      };

      final document = Importer().import(spec);
      final queryParam = document.queryParameters
          .whereType<QueryParameterObject>()
          .firstWhereOrNull((p) => p.rawName == 'user_id');

      expect(queryParam, isNotNull);
      expect(queryParam!.nameOverride, isNull);
    });
  });

  group('x-dart-name on path parameters', () {
    test('parses x-dart-name on path parameter', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/users/{user_id}': {
            'get': {
              'operationId': 'getUserById',
              'parameters': [
                {
                  'name': 'user_id',
                  'in': 'path',
                  'required': true,
                  'x-dart-name': 'userId',
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'Success',
                },
              },
            },
          },
        },
      };

      final document = Importer().import(spec);
      final pathParam = document.pathParameters
          .whereType<PathParameterObject>()
          .firstWhereOrNull(
            (p) => p.rawName == 'user_id',
          );

      expect(pathParam, isNotNull);
      expect(pathParam!.nameOverride, 'userId');
    });

    test('sets nameOverride to null when x-dart-name is absent', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/users/{user_id}': {
            'get': {
              'operationId': 'getUserById',
              'parameters': [
                {
                  'name': 'user_id',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'Success',
                },
              },
            },
          },
        },
      };

      final document = Importer().import(spec);
      final pathParam = document.pathParameters
          .whereType<PathParameterObject>()
          .firstWhereOrNull((p) => p.rawName == 'user_id');

      expect(pathParam, isNotNull);
      expect(pathParam!.nameOverride, isNull);
    });
  });

  group('x-dart-name on request headers', () {
    test('parses x-dart-name on request header', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'parameters': [
                {
                  'name': 'x-custom-header',
                  'in': 'header',
                  'x-dart-name': 'customHeader',
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'Success',
                },
              },
            },
          },
        },
      };

      final document = Importer().import(spec);
      final header = document.requestHeaders
          .whereType<RequestHeaderObject>()
          .firstWhereOrNull((h) => h.rawName == 'x-custom-header');

      expect(header, isNotNull);
      expect(header!.nameOverride, 'customHeader');
    });

    test('sets nameOverride to null when x-dart-name is absent', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'parameters': [
                {
                  'name': 'x-custom-header',
                  'in': 'header',
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'Success',
                },
              },
            },
          },
        },
      };

      final document = Importer().import(spec);
      final header = document.requestHeaders
          .whereType<RequestHeaderObject>()
          .firstWhereOrNull((h) => h.rawName == 'x-custom-header');

      expect(header, isNotNull);
      expect(header!.nameOverride, isNull);
    });
  });
}
