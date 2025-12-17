import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('x-dart-name on tags', () {
    test('parses x-dart-name on tag', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/pet': {
            'get': {
              'operationId': 'getPet',
              'tags': ['pet'],
              'responses': {
                '200': {'description': 'Success'},
              },
            },
          },
        },
        'tags': [
          {
            'name': 'pet',
            'description': 'Pet operations',
            'x-dart-name': 'animals',
          },
        ],
      };

      final document = Importer().import(spec);
      final getPet = document.operations.firstWhereOrNull(
        (op) => op.operationId == 'getPet',
      );

      expect(getPet, isNotNull);
      expect(getPet!.tags, hasLength(1));

      final tag = getPet.tags.first;
      expect(tag.name, equals('pet'));
      expect(tag.nameOverride, equals('animals'));
      expect(tag.description, equals('Pet operations'));
    });

    test('sets nameOverride to null when x-dart-name is absent', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/pet': {
            'get': {
              'operationId': 'getPet',
              'tags': ['pet'],
              'responses': {
                '200': {'description': 'Success'},
              },
            },
          },
        },
        'tags': [
          {
            'name': 'pet',
            'description': 'Pet operations',
          },
        ],
      };

      final document = Importer().import(spec);
      final getPet = document.operations.firstWhereOrNull(
        (op) => op.operationId == 'getPet',
      );

      expect(getPet, isNotNull);
      expect(getPet!.tags, hasLength(1));

      final tag = getPet.tags.first;
      expect(tag.name, equals('pet'));
      expect(tag.nameOverride, isNull);
    });

    test('parses x-dart-name on multiple tags', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/pet': {
            'get': {
              'operationId': 'getPet',
              'tags': ['pet', 'store'],
              'responses': {
                '200': {'description': 'Success'},
              },
            },
          },
        },
        'tags': [
          {
            'name': 'pet',
            'description': 'Pet operations',
            'x-dart-name': 'animals',
          },
          {
            'name': 'store',
            'description': 'Store operations',
            'x-dart-name': 'orders',
          },
        ],
      };

      final document = Importer().import(spec);
      final getPet = document.operations.firstWhereOrNull(
        (op) => op.operationId == 'getPet',
      );

      expect(getPet, isNotNull);
      expect(getPet!.tags, hasLength(2));

      final petTag = getPet.tags.firstWhereOrNull((t) => t.name == 'pet');
      expect(petTag, isNotNull);
      expect(petTag!.nameOverride, equals('animals'));

      final storeTag = getPet.tags.firstWhereOrNull((t) => t.name == 'store');
      expect(storeTag, isNotNull);
      expect(storeTag!.nameOverride, equals('orders'));
    });
  });
}
