import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('x-dart-name on schemas', () {
    test('parses x-dart-name on simple schema', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SimpleModel': {
              'type': 'object',
              'x-dart-name': 'CustomName',
              'properties': {
                'name': {'type': 'string'},
              },
            },
          },
        },
      };

      final document = Importer().import(spec);
      final model =
          document.models.firstWhereOrNull(
                (m) => m is NamedModel && m.name == 'SimpleModel',
              )
              as ClassModel?;

      expect(model, isNotNull);
      expect(model!.nameOverride, equals('CustomName'));
    });

    test('sets nameOverride to null when x-dart-name is absent', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SimpleModel': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
          },
        },
      };

      final document = Importer().import(spec);
      final model =
          document.models.firstWhereOrNull(
                (m) => m is NamedModel && m.name == 'SimpleModel',
              )
              as ClassModel?;

      expect(model, isNotNull);
      expect(model!.nameOverride, isNull);
    });

    test('parses x-dart-name on property', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SimpleModel': {
              'type': 'object',
              'properties': {
                'name': {
                  'type': 'string',
                  'x-dart-name': 'customPropertyName',
                },
              },
            },
          },
        },
      };

      final document = Importer().import(spec);
      final model =
          document.models.firstWhereOrNull(
                (m) => m is NamedModel && m.name == 'SimpleModel',
              )
              as ClassModel?;

      expect(model, isNotNull);

      final nameProperty = model!.properties.firstWhereOrNull(
        (p) => p.name == 'name',
      );
      expect(nameProperty, isNotNull);
      expect(nameProperty!.nameOverride, equals('customPropertyName'));
    });

    test('sets property nameOverride to null when x-dart-name is absent', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SimpleModel': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
          },
        },
      };

      final document = Importer().import(spec);
      final model =
          document.models.firstWhereOrNull(
                (m) => m is NamedModel && m.name == 'SimpleModel',
              )
              as ClassModel?;

      expect(model, isNotNull);

      final nameProperty = model!.properties.firstWhereOrNull(
        (p) => p.name == 'name',
      );
      expect(nameProperty, isNotNull);
      expect(nameProperty!.nameOverride, isNull);
    });
  });

  group('x-dart-enum on enum schemas', () {
    test('parses x-dart-enum value mappings', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Status': {
              'type': 'string',
              'enum': ['active', 'inactive', 'pending'],
              'x-dart-enum': ['isActive', 'isInactive', 'isPending'],
            },
          },
        },
      };

      final document = Importer().import(spec);
      final model =
          document.models.firstWhereOrNull(
                (m) => m is NamedModel && m.name == 'Status',
              )
              as EnumModel<String>?;

      expect(model, isNotNull);
      expect(model!.values.length, equals(3));

      final activeEntry = model.values.firstWhereOrNull(
        (e) => e.value == 'active',
      );
      expect(activeEntry, isNotNull);
      expect(activeEntry!.nameOverride, equals('isActive'));

      final inactiveEntry = model.values.firstWhereOrNull(
        (e) => e.value == 'inactive',
      );
      expect(inactiveEntry, isNotNull);
      expect(inactiveEntry!.nameOverride, equals('isInactive'));

      final pendingEntry = model.values.firstWhereOrNull(
        (e) => e.value == 'pending',
      );
      expect(pendingEntry, isNotNull);
      expect(pendingEntry!.nameOverride, equals('isPending'));
    });

    test('sets enum value nameOverride to null when x-dart-enum is absent', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Status': {
              'type': 'string',
              'enum': ['active', 'inactive'],
            },
          },
        },
      };

      final document = Importer().import(spec);
      final model =
          document.models.firstWhereOrNull(
                (m) => m is NamedModel && m.name == 'Status',
              )
              as EnumModel<String>?;

      expect(model, isNotNull);
      expect(model!.values.length, equals(2));

      for (final entry in model.values) {
        expect(entry.nameOverride, isNull);
      }
    });

    test('handles partial x-dart-enum mappings', () {
      const spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Status': {
              'type': 'string',
              'enum': ['active', 'inactive', 'pending'],
              'x-dart-enum': ['isActive', 'inactive', 'pending'],
            },
          },
        },
      };

      final document = Importer().import(spec);
      final model =
          document.models.firstWhereOrNull(
                (m) => m is NamedModel && m.name == 'Status',
              )
              as EnumModel<String>?;

      expect(model, isNotNull);
      expect(model!.values.length, equals(3));

      final activeEntry = model.values.firstWhereOrNull(
        (e) => e.value == 'active',
      );
      expect(activeEntry, isNotNull);
      expect(activeEntry!.nameOverride, equals('isActive'));

      final inactiveEntry = model.values.firstWhereOrNull(
        (e) => e.value == 'inactive',
      );
      expect(inactiveEntry, isNotNull);
      expect(inactiveEntry!.nameOverride, equals('inactive'));
    });
  });
}
