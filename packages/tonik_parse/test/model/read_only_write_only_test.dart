import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('readOnly and writeOnly property parsing', () {
    const readOnlySpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'User': {
            'type': 'object',
            'properties': {
              'id': {'type': 'integer', 'readOnly': true},
              'name': {'type': 'string'},
            },
          },
        },
      },
    };

    const writeOnlySpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'User': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'password': {'type': 'string', 'writeOnly': true},
            },
          },
        },
      },
    };

    const mixedSpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'User': {
            'type': 'object',
            'required': ['id', 'name', 'password'],
            'properties': {
              'id': {
                'type': 'integer',
                'readOnly': true,
                'description': 'Server-generated ID',
              },
              'name': {'type': 'string'},
              'password': {
                'type': 'string',
                'writeOnly': true,
                'description': 'User password',
              },
              'createdAt': {
                'type': 'string',
                'format': 'date-time',
                'readOnly': true,
              },
            },
          },
        },
      },
    };

    test('imports property with readOnly: true', () {
      final api = Importer().import(readOnlySpec);

      final model = api.models.first as ClassModel;
      final idProperty = model.properties.firstWhere((p) => p.name == 'id');

      expect(idProperty.isReadOnly, isTrue);
      expect(idProperty.isWriteOnly, isFalse);
    });

    test('imports property with readOnly not set defaults to false', () {
      final api = Importer().import(readOnlySpec);

      final model = api.models.first as ClassModel;
      final nameProperty = model.properties.firstWhere((p) => p.name == 'name');

      expect(nameProperty.isReadOnly, isFalse);
      expect(nameProperty.isWriteOnly, isFalse);
    });

    test('imports property with writeOnly: true', () {
      final api = Importer().import(writeOnlySpec);

      final model = api.models.first as ClassModel;
      final passwordProperty = model.properties.firstWhere(
        (p) => p.name == 'password',
      );

      expect(passwordProperty.isWriteOnly, isTrue);
      expect(passwordProperty.isReadOnly, isFalse);
    });

    test('imports property with writeOnly not set defaults to false', () {
      final api = Importer().import(writeOnlySpec);

      final model = api.models.first as ClassModel;
      final nameProperty = model.properties.firstWhere((p) => p.name == 'name');

      expect(nameProperty.isWriteOnly, isFalse);
      expect(nameProperty.isReadOnly, isFalse);
    });

    test('imports mixed readOnly and writeOnly properties', () {
      final api = Importer().import(mixedSpec);

      final model = api.models.first as ClassModel;

      final idProperty = model.properties.firstWhere((p) => p.name == 'id');
      expect(idProperty.isReadOnly, isTrue);
      expect(idProperty.isWriteOnly, isFalse);

      final nameProperty = model.properties.firstWhere((p) => p.name == 'name');
      expect(nameProperty.isReadOnly, isFalse);
      expect(nameProperty.isWriteOnly, isFalse);

      final passwordProperty = model.properties.firstWhere(
        (p) => p.name == 'password',
      );
      expect(passwordProperty.isReadOnly, isFalse);
      expect(passwordProperty.isWriteOnly, isTrue);

      final createdAtProperty = model.properties.firstWhere(
        (p) => p.name == 'createdAt',
      );
      expect(createdAtProperty.isReadOnly, isTrue);
      expect(createdAtProperty.isWriteOnly, isFalse);
    });

    test('preserves other property attributes alongside readOnly', () {
      final api = Importer().import(mixedSpec);

      final model = api.models.first as ClassModel;
      final idProperty = model.properties.firstWhere((p) => p.name == 'id');

      expect(idProperty.isReadOnly, isTrue);
      expect(idProperty.isRequired, isTrue);
      expect(idProperty.description, equals('Server-generated ID'));
      expect(idProperty.model, isA<IntegerModel>());
    });

    test('preserves other property attributes alongside writeOnly', () {
      final api = Importer().import(mixedSpec);

      final model = api.models.first as ClassModel;
      final passwordProperty = model.properties.firstWhere(
        (p) => p.name == 'password',
      );

      expect(passwordProperty.isWriteOnly, isTrue);
      expect(passwordProperty.isRequired, isTrue);
      expect(passwordProperty.description, equals('User password'));
      expect(passwordProperty.model, isA<StringModel>());
    });
  });

  test('inherits access flags from referenced property schemas', () {
    final api = Importer().import({
      'openapi': '3.0.4',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Profile': {
            'type': 'object',
            'properties': {
              'id': {r'$ref': '#/components/schemas/ServerId'},
              'password': {r'$ref': '#/components/schemas/PasswordAlias'},
              'name': {'type': 'string'},
            },
          },
          'ServerId': {'type': 'integer', 'readOnly': true},
          'PasswordAlias': {r'$ref': '#/components/schemas/Password'},
          'Password': {'type': 'string', 'writeOnly': true},
        },
      },
    });
    final profile = api.models.whereType<ClassModel>().single;
    final id = profile.properties.firstWhere((p) => p.name == 'id');
    final password = profile.properties.firstWhere((p) => p.name == 'password');
    final name = profile.properties.firstWhere((p) => p.name == 'name');

    expect(id.isReadOnly, isTrue);
    expect(id.isWriteOnly, isFalse);
    expect(password.isWriteOnly, isTrue);
    expect(password.isReadOnly, isFalse);
    expect(name.isReadOnly, isFalse);
    expect(name.isWriteOnly, isFalse);
  });

  test('inherits referenced access flags in an inline object', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Envelope': {
            'type': 'object',
            'properties': {
              'profile': {
                'type': 'object',
                'properties': {
                  'id': {
                    r'$ref': '#/components/schemas/ServerIdAlias',
                    'readOnly': false,
                  },
                  'password': {r'$ref': '#/components/schemas/Password'},
                },
              },
            },
          },
          'ServerIdAlias': {r'$ref': '#/components/schemas/ServerId'},
          'ServerId': {'type': 'integer', 'readOnly': true},
          'Password': {'type': 'string', 'writeOnly': true},
        },
      },
    });
    final envelope = api.models.whereType<ClassModel>().firstWhere(
      (model) => model.name == 'Envelope',
    );
    final profile = envelope.properties.single.model as ClassModel;
    final id = profile.properties.firstWhere((p) => p.name == 'id');
    final password = profile.properties.firstWhere((p) => p.name == 'password');

    expect(id.isReadOnly, isTrue);
    expect(password.isWriteOnly, isTrue);
  });

  group('readOnly and writeOnly with explicit false', () {
    const explicitFalseSpec = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Model': {
            'type': 'object',
            'properties': {
              'field1': {'type': 'string', 'readOnly': false},
              'field2': {'type': 'string', 'writeOnly': false},
            },
          },
        },
      },
    };

    test('imports property with readOnly: false', () {
      final api = Importer().import(explicitFalseSpec);

      final model = api.models.first as ClassModel;
      final field1 = model.properties.firstWhere((p) => p.name == 'field1');

      expect(field1.isReadOnly, isFalse);
    });

    test('imports property with writeOnly: false', () {
      final api = Importer().import(explicitFalseSpec);

      final model = api.models.first as ClassModel;
      final field2 = model.properties.firstWhere((p) => p.name == 'field2');

      expect(field2.isWriteOnly, isFalse);
    });
  });
}
