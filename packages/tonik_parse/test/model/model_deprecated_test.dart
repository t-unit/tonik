import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('deprecated schemas', () {
    group('ClassModel', () {
      const deprecatedClass = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'DeprecatedModel': {
              'type': 'object',
              'deprecated': true,
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'ActiveModel': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
          },
        },
      };

      test('parses deprecated: true for class model', () {
        final api = Importer().import(deprecatedClass);
        final deprecatedModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'DeprecatedModel',
                )
                as ClassModel;

        expect(deprecatedModel.isDeprecated, isTrue);
      });

      test('parses deprecated: false (default) for class model', () {
        final api = Importer().import(deprecatedClass);
        final activeModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'ActiveModel',
                )
                as ClassModel;

        expect(activeModel.isDeprecated, isFalse);
      });
    });

    group('EnumModel', () {
      const deprecatedEnum = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'DeprecatedStatus': {
              'type': 'string',
              'deprecated': true,
              'enum': ['active', 'inactive'],
            },
            'ActiveStatus': {
              'type': 'string',
              'enum': ['active', 'inactive'],
            },
          },
        },
      };

      test('parses deprecated: true for enum model', () {
        final api = Importer().import(deprecatedEnum);
        final deprecatedModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'DeprecatedStatus',
                )
                as EnumModel;

        expect(deprecatedModel.isDeprecated, isTrue);
      });

      test('parses deprecated: false (default) for enum model', () {
        final api = Importer().import(deprecatedEnum);
        final activeModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'ActiveStatus',
                )
                as EnumModel;

        expect(activeModel.isDeprecated, isFalse);
      });
    });

    group('AllOfModel', () {
      const deprecatedAllOf = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'BaseModel': {
              'type': 'object',
              'properties': {
                'id': {'type': 'integer'},
              },
            },
            'DeprecatedComposite': {
              'deprecated': true,
              'allOf': [
                {r'$ref': '#/components/schemas/BaseModel'},
                {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
              ],
            },
            'ActiveComposite': {
              'allOf': [
                {r'$ref': '#/components/schemas/BaseModel'},
                {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
              ],
            },
          },
        },
      };

      test('parses deprecated: true for allOf model', () {
        final api = Importer().import(deprecatedAllOf);
        final deprecatedModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'DeprecatedComposite',
                )
                as AllOfModel;

        expect(deprecatedModel.isDeprecated, isTrue);
      });

      test('parses deprecated: false (default) for allOf model', () {
        final api = Importer().import(deprecatedAllOf);
        final activeModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'ActiveComposite',
                )
                as AllOfModel;

        expect(activeModel.isDeprecated, isFalse);
      });
    });

    group('OneOfModel', () {
      const deprecatedOneOf = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'DeprecatedUnion': {
              'deprecated': true,
              'oneOf': [
                {'type': 'string'},
                {'type': 'integer'},
              ],
            },
            'ActiveUnion': {
              'oneOf': [
                {'type': 'string'},
                {'type': 'integer'},
              ],
            },
          },
        },
      };

      test('parses deprecated: true for oneOf model', () {
        final api = Importer().import(deprecatedOneOf);
        final deprecatedModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'DeprecatedUnion',
                )
                as OneOfModel;

        expect(deprecatedModel.isDeprecated, isTrue);
      });

      test('parses deprecated: false (default) for oneOf model', () {
        final api = Importer().import(deprecatedOneOf);
        final activeModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'ActiveUnion',
                )
                as OneOfModel;

        expect(activeModel.isDeprecated, isFalse);
      });
    });

    group('AnyOfModel', () {
      const deprecatedAnyOf = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'DeprecatedMixed': {
              'deprecated': true,
              'anyOf': [
                {'type': 'string'},
                {'type': 'integer'},
              ],
            },
            'ActiveMixed': {
              'anyOf': [
                {'type': 'string'},
                {'type': 'integer'},
              ],
            },
          },
        },
      };

      test('parses deprecated: true for anyOf model', () {
        final api = Importer().import(deprecatedAnyOf);
        final deprecatedModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'DeprecatedMixed',
                )
                as AnyOfModel;

        expect(deprecatedModel.isDeprecated, isTrue);
      });

      test('parses deprecated: false (default) for anyOf model', () {
        final api = Importer().import(deprecatedAnyOf);
        final activeModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'ActiveMixed',
                )
                as AnyOfModel;

        expect(activeModel.isDeprecated, isFalse);
      });
    });

    group('Integer EnumModel', () {
      const deprecatedIntEnum = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'DeprecatedPriority': {
              'type': 'integer',
              'deprecated': true,
              'enum': [1, 2, 3],
            },
            'ActivePriority': {
              'type': 'integer',
              'enum': [1, 2, 3],
            },
          },
        },
      };

      test('parses deprecated: true for integer enum model', () {
        final api = Importer().import(deprecatedIntEnum);
        final deprecatedModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'DeprecatedPriority',
                )
                as EnumModel<int>;

        expect(deprecatedModel.isDeprecated, isTrue);
      });

      test('parses deprecated: false (default) for integer enum model', () {
        final api = Importer().import(deprecatedIntEnum);
        final activeModel =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'ActivePriority',
                )
                as EnumModel<int>;

        expect(activeModel.isDeprecated, isFalse);
      });
    });
  });
}
