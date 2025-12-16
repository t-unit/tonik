import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('x-dart-name on operations', () {
    test('parses x-dart-name on operation', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'x-dart-name': 'fetchUsers',
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
      final operation = document.operations.firstWhereOrNull(
        (op) => op.operationId == 'getUsers',
      );

      expect(operation, isNotNull);
      expect(operation!.nameOverride, equals('fetchUsers'));
    });

    test('sets nameOverride to null when x-dart-name is absent', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
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
      final operation = document.operations.firstWhereOrNull(
        (op) => op.operationId == 'getUsers',
      );

      expect(operation, isNotNull);
      expect(operation!.nameOverride, isNull);
    });
  });
}
