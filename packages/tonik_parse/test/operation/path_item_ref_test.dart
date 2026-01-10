import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group(r'path item $ref resolution', () {
    test('resolves path item reference from components/pathItems', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/pets': {
            r'$ref': '#/components/pathItems/PetOperations',
          },
        },
        'components': {
          'pathItems': {
            'PetOperations': {
              'get': {
                'operationId': 'listPets',
                'responses': {
                  '200': {'description': 'Success'},
                },
              },
              'post': {
                'operationId': 'createPet',
                'responses': {
                  '201': {'description': 'Created'},
                },
              },
            },
          },
        },
      };

      final api = Importer().import(spec);

      final listOperation = api.operations.firstWhereOrNull(
        (o) => o.operationId == 'listPets',
      );
      expect(listOperation, isNotNull);
      expect(listOperation?.method, HttpMethod.get);
      expect(listOperation?.path, '/pets');

      final createOperation = api.operations.firstWhereOrNull(
        (o) => o.operationId == 'createPet',
      );
      expect(createOperation, isNotNull);
      expect(createOperation?.method, HttpMethod.post);
      expect(createOperation?.path, '/pets');
    });

    test('follows reference chain in path items', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/items': {
            r'$ref': '#/components/pathItems/AliasPath',
          },
        },
        'components': {
          'pathItems': {
            'OriginalPath': {
              'get': {
                'operationId': 'getItems',
                'responses': {
                  '200': {'description': 'Success'},
                },
              },
            },
            'AliasPath': {
              r'$ref': '#/components/pathItems/OriginalPath',
            },
          },
        },
      };

      final api = Importer().import(spec);

      final operation = api.operations.firstWhereOrNull(
        (o) => o.operationId == 'getItems',
      );
      expect(operation, isNotNull);
      expect(operation?.method, HttpMethod.get);
      expect(operation?.path, '/items');
    });

    test('resolves path item with parameters', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/items/{id}': {
            r'$ref': '#/components/pathItems/ItemById',
          },
        },
        'components': {
          'pathItems': {
            'ItemById': {
              'parameters': [
                {
                  'name': 'id',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'string'},
                },
              ],
              'get': {
                'operationId': 'getItemById',
                'responses': {
                  '200': {'description': 'Success'},
                },
              },
            },
          },
        },
      };

      final api = Importer().import(spec);

      final operation = api.operations.firstWhereOrNull(
        (o) => o.operationId == 'getItemById',
      );
      expect(operation, isNotNull);
      expect(operation?.pathParameters, hasLength(1));
      expect(operation?.pathParameters.first.resolve().rawName, 'id');
    });

    test('throws on non-local path item reference', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/external': {
            r'$ref': 'https://example.com/pathItems/External',
          },
        },
      };

      expect(() => Importer().import(spec), throwsA(isA<UnimplementedError>()));
    });

    test('throws on missing referenced path item', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/missing': {
            r'$ref': '#/components/pathItems/NonExistent',
          },
        },
        'components': {
          'pathItems': <String, dynamic>{},
        },
      };

      expect(() => Importer().import(spec), throwsA(isA<ArgumentError>()));
    });
  });
}
