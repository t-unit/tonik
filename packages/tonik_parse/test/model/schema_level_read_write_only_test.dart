import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('schema-level readOnly', () {
    test('stores readOnly on ClassModel', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'ServerStatus': {
              'type': 'object',
              'readOnly': true,
              'properties': {
                'uptime': {'type': 'integer'},
                'version': {'type': 'string'},
              },
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<ClassModel>().first;

      expect(model.name, equals('ServerStatus'));
      expect(model.isReadOnly, isTrue);
      expect(model.isWriteOnly, isFalse);
    });

    test('stores readOnly on AliasModel wrapping a primitive', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'ServerId': {
              'type': 'integer',
              'readOnly': true,
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<AliasModel>().first;

      expect(model.name, equals('ServerId'));
      expect(model.isReadOnly, isTrue);
      expect(model.isWriteOnly, isFalse);
    });

    test('stores readOnly on EnumModel', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'ServerRegion': {
              'type': 'string',
              'readOnly': true,
              'enum': ['us-east', 'eu-west'],
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<EnumModel<String>>().first;

      expect(model.name, equals('ServerRegion'));
      expect(model.isReadOnly, isTrue);
      expect(model.isWriteOnly, isFalse);
    });

    test('stores readOnly on ListModel', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'AuditLog': {
              'type': 'array',
              'readOnly': true,
              'items': {'type': 'string'},
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<ListModel>().first;

      expect(model.name, equals('AuditLog'));
      expect(model.isReadOnly, isTrue);
      expect(model.isWriteOnly, isFalse);
    });

    test('stores readOnly on AllOfModel', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Base': {
              'type': 'object',
              'properties': {
                'id': {'type': 'integer'},
              },
            },
            'ReadOnlyComposite': {
              'readOnly': true,
              'allOf': [
                {r'$ref': '#/components/schemas/Base'},
                {
                  'type': 'object',
                  'properties': {
                    'extra': {'type': 'string'},
                  },
                },
              ],
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<AllOfModel>().first;

      expect(model.name, equals('ReadOnlyComposite'));
      expect(model.isReadOnly, isTrue);
      expect(model.isWriteOnly, isFalse);
    });

    test('stores readOnly on OneOfModel', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'ReadOnlyUnion': {
              'readOnly': true,
              'oneOf': [
                {'type': 'string'},
                {'type': 'integer'},
              ],
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<OneOfModel>().first;

      expect(model.name, equals('ReadOnlyUnion'));
      expect(model.isReadOnly, isTrue);
      expect(model.isWriteOnly, isFalse);
    });

    test('stores readOnly on AnyOfModel', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'ReadOnlyAnyOf': {
              'readOnly': true,
              'anyOf': [
                {'type': 'string'},
                {'type': 'integer'},
              ],
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<AnyOfModel>().first;

      expect(model.name, equals('ReadOnlyAnyOf'));
      expect(model.isReadOnly, isTrue);
      expect(model.isWriteOnly, isFalse);
    });
  });

  group('schema-level writeOnly', () {
    test('stores writeOnly on ClassModel', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'PasswordReset': {
              'type': 'object',
              'writeOnly': true,
              'properties': {
                'newPassword': {'type': 'string'},
                'confirmPassword': {'type': 'string'},
              },
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<ClassModel>().first;

      expect(model.name, equals('PasswordReset'));
      expect(model.isWriteOnly, isTrue);
      expect(model.isReadOnly, isFalse);
    });

    test('stores writeOnly on AliasModel wrapping a primitive', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'SecretToken': {
              'type': 'string',
              'writeOnly': true,
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<AliasModel>().first;

      expect(model.name, equals('SecretToken'));
      expect(model.isWriteOnly, isTrue);
      expect(model.isReadOnly, isFalse);
    });

    test('stores writeOnly on EnumModel', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'AuthMethod': {
              'type': 'string',
              'writeOnly': true,
              'enum': ['password', 'token'],
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<EnumModel<String>>().first;

      expect(model.name, equals('AuthMethod'));
      expect(model.isWriteOnly, isTrue);
      expect(model.isReadOnly, isFalse);
    });
  });

  group('schema-level readOnly/writeOnly defaults', () {
    test('defaults to false when not specified on ClassModel', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Simple': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<ClassModel>().first;

      expect(model.isReadOnly, isFalse);
      expect(model.isWriteOnly, isFalse);
    });

    test('defaults to false when not specified on AliasModel', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'MyString': {
              'type': 'string',
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<AliasModel>().first;

      expect(model.isReadOnly, isFalse);
      expect(model.isWriteOnly, isFalse);
    });

    test('defaults to false when not specified on EnumModel', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Color': {
              'type': 'string',
              'enum': ['red', 'green'],
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<EnumModel<String>>().first;

      expect(model.isReadOnly, isFalse);
      expect(model.isWriteOnly, isFalse);
    });
  });

  group('schema-level and property-level flags coexist', () {
    test('property-level flags are independent of schema-level flags', () {
      const spec = {
        'openapi': '3.1.0',
        'info': {'title': 'Test', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'MixedModel': {
              'type': 'object',
              'readOnly': true,
              'properties': {
                'id': {'type': 'integer'},
                'secret': {
                  'type': 'string',
                  'writeOnly': true,
                },
              },
            },
          },
        },
      };

      final api = Importer().import(spec);
      final model = api.models.whereType<ClassModel>().first;

      expect(model.isReadOnly, isTrue);

      // Property-level flags are parsed independently.
      final idProp = model.properties.firstWhere((p) => p.name == 'id');
      expect(idProp.isReadOnly, isFalse);
      expect(idProp.isWriteOnly, isFalse);

      final secretProp = model.properties.firstWhere(
        (p) => p.name == 'secret',
      );
      expect(secretProp.isWriteOnly, isTrue);
      expect(secretProp.isReadOnly, isFalse);
    });
  });
}
