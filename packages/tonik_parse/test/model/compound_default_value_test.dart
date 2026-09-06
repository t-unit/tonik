import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('referenced compound schemas retain their enclosing defaults', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, Object?>{},
      'components': {
        'schemas': {
          'RetryCount': {
            'type': 'integer',
            'allOf': [
              {'type': 'integer'},
            ],
            'default': 3,
          },
          'Choice': {
            'oneOf': [
              {'type': 'integer'},
              {'type': 'string'},
            ],
            'default': 0,
          },
          'Enabled': {
            'anyOf': [
              {'type': 'boolean'},
              {'type': 'string'},
            ],
            'default': false,
          },
          'Config': {
            'type': 'object',
            'properties': {
              'retries': {r'$ref': '#/components/schemas/RetryCount'},
              'choice': {r'$ref': '#/components/schemas/Choice'},
              'enabled': {r'$ref': '#/components/schemas/Enabled'},
            },
          },
        },
      },
    });
    final retries = api.models.whereType<AllOfModel>().single;
    final choice = api.models.whereType<OneOfModel>().single;
    final enabled = api.models.whereType<AnyOfModel>().single;
    final config = api.models.whereType<ClassModel>().single;
    final retriesProperty = config.properties.firstWhere(
      (p) => p.name == 'retries',
    );
    final choiceProperty = config.properties.firstWhere(
      (p) => p.name == 'choice',
    );
    final enabledProperty = config.properties.firstWhere(
      (p) => p.name == 'enabled',
    );

    expect(retries.defaultValue, 3);
    expect(choice.defaultValue, 0);
    expect(enabled.defaultValue, isFalse);
    expect(retriesProperty.effectiveDefaultValue, 3);
    expect(choiceProperty.effectiveDefaultValue, 0);
    expect(enabledProperty.effectiveDefaultValue, isFalse);
  });

  test(
    'alias and property defaults take precedence over compound defaults',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, Object?>{},
        'components': {
          'schemas': {
            'Outer': {r'$ref': '#/components/schemas/Alias'},
            'Alias': {r'$ref': '#/components/schemas/RetryCount'},
            'Override': {
              r'$ref': '#/components/schemas/RetryCount',
              'default': 2,
            },
            'RetryCount': {
              'allOf': [
                {'type': 'integer'},
              ],
              'default': 3,
            },
            'Config': {
              'type': 'object',
              'properties': {
                'aliased': {r'$ref': '#/components/schemas/Outer'},
                'aliasOverride': {r'$ref': '#/components/schemas/Override'},
                'localOverride': {
                  r'$ref': '#/components/schemas/Outer',
                  'default': 0,
                },
                'nullLocal': {
                  r'$ref': '#/components/schemas/RetryCount',
                  'default': null,
                },
              },
            },
          },
        },
      });
      final outer = api.models.whereType<AliasModel>().firstWhere(
        (m) => m.name == 'Outer',
      );
      final config = api.models.whereType<ClassModel>().single;
      final aliased = config.properties.firstWhere((p) => p.name == 'aliased');
      final aliasOverride = config.properties.firstWhere(
        (p) => p.name == 'aliasOverride',
      );
      final localOverride = config.properties.firstWhere(
        (p) => p.name == 'localOverride',
      );
      final nullLocal = config.properties.firstWhere(
        (p) => p.name == 'nullLocal',
      );

      expect(outer.defaultValue, 3);
      expect(aliased.effectiveDefaultValue, 3);
      expect(aliasOverride.effectiveDefaultValue, 2);
      expect(localOverride.effectiveDefaultValue, 0);
      // A schema default:null retains the existing fallback to the target.
      expect(nullLocal.effectiveDefaultValue, 3);
    },
  );

  test('inline compound array items retain their enclosing defaults', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, Object?>{},
      'components': {
        'schemas': {
          'Retries': {
            'type': 'array',
            'items': {
              'allOf': [
                {'type': 'integer'},
              ],
              'default': 3,
            },
          },
          'Choices': {
            'type': 'array',
            'items': {
              'oneOf': [
                {'type': 'integer'},
              ],
              'default': 0,
            },
          },
          'Flags': {
            'type': 'array',
            'items': {
              'anyOf': [
                {'type': 'boolean'},
              ],
              'default': false,
            },
          },
        },
      },
    });
    final retries = api.models.whereType<ListModel>().firstWhere(
      (m) => m.name == 'Retries',
    );
    final choices = api.models.whereType<ListModel>().firstWhere(
      (m) => m.name == 'Choices',
    );
    final flags = api.models.whereType<ListModel>().firstWhere(
      (m) => m.name == 'Flags',
    );

    expect((retries.content as AllOfModel).defaultValue, 3);
    expect((choices.content as OneOfModel).defaultValue, 0);
    expect((flags.content as AnyOfModel).defaultValue, isFalse);
  });

  test('a defs reference preserves the compound default', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, Object?>{},
      'components': {
        'schemas': {
          'Config': {
            'type': 'object',
            r'$defs': {
              'Enabled': {
                'anyOf': [
                  {'type': 'boolean'},
                ],
                'default': false,
              },
            },
            'properties': {
              'enabled': {
                r'$ref': r'#/components/schemas/Config/$defs/Enabled',
              },
            },
          },
        },
      },
    });
    final config = api.models.whereType<ClassModel>().single;

    expect(config.properties.single.effectiveDefaultValue, isFalse);
  });

  test('absent and null compound defaults do not inherit branch defaults', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, Object?>{},
      'components': {
        'schemas': {
          'Branch': {'type': 'integer', 'default': 7},
          'Absent': {
            'oneOf': [
              {r'$ref': '#/components/schemas/Branch'},
            ],
          },
          'ExplicitNull': {
            'anyOf': [
              {r'$ref': '#/components/schemas/Branch'},
            ],
            'default': null,
          },
          'Config': {
            'type': 'object',
            'properties': {
              'absent': {r'$ref': '#/components/schemas/Absent'},
              'explicitNull': {r'$ref': '#/components/schemas/ExplicitNull'},
            },
          },
        },
      },
    });
    final absent = api.models.whereType<OneOfModel>().single;
    final explicitNull = api.models.whereType<AnyOfModel>().single;
    final config = api.models.whereType<ClassModel>().single;
    final absentProperty = config.properties.firstWhere(
      (p) => p.name == 'absent',
    );
    final nullProperty = config.properties.firstWhere(
      (p) => p.name == 'explicitNull',
    );

    expect(absent.defaultValue, isNull);
    expect(explicitNull.defaultValue, isNull);
    expect(absentProperty.effectiveDefaultValue, isNull);
    expect(nullProperty.effectiveDefaultValue, isNull);
  });

  test('named and inline type arrays preserve defaults', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, Object?>{},
      'components': {
        'schemas': {
          'Value': {
            'type': ['integer', 'string'],
            'default': 0,
          },
          'Values': {
            'type': 'array',
            'items': {
              'type': ['integer', 'string'],
              'default': 0,
            },
          },
          'Config': {
            'type': 'object',
            'properties': {
              'value': {r'$ref': '#/components/schemas/Value'},
            },
          },
        },
      },
    });
    final value = api.models.whereType<OneOfModel>().firstWhere(
      (m) => m.name == 'Value',
    );
    final values = api.models.whereType<ListModel>().single;
    final config = api.models.whereType<ClassModel>().single;

    expect(value.defaultValue, 0);
    expect((values.content as OneOfModel).defaultValue, 0);
    expect(config.properties.single.effectiveDefaultValue, 0);
  });

  test('named and property structural ref wrappers preserve defaults', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, Object?>{},
      'components': {
        'schemas': {
          'Base': {'type': 'object'},
          'Named': {
            r'$ref': '#/components/schemas/Base',
            'properties': {
              'count': {'type': 'integer'},
            },
            'default': {'count': 3},
          },
          'Config': {
            'type': 'object',
            'properties': {
              'value': {
                r'$ref': '#/components/schemas/Base',
                'properties': {
                  'count': {'type': 'integer'},
                },
                'default': {'count': 3},
              },
            },
          },
        },
      },
    });
    final named = api.models.whereType<AllOfModel>().firstWhere(
      (m) => m.name == 'Named',
    );
    final config = api.models.whereType<ClassModel>().firstWhere(
      (m) => m.name == 'Config',
    );
    final propertyModel = config.properties.single.model as AllOfModel;

    expect(named.defaultValue, {'count': 3});
    expect(propertyModel.defaultValue, {'count': 3});
  });

  test('parameters in every location can use referenced compound defaults', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': {
        '/items/{retries}': {
          'get': {
            'operationId': 'getItem',
            'parameters': [
              {
                'name': 'retries',
                'in': 'path',
                'required': true,
                'schema': {r'$ref': '#/components/schemas/RetryAlias'},
              },
              {
                'name': 'choice',
                'in': 'query',
                'schema': {r'$ref': '#/components/schemas/Choice'},
              },
              {
                'name': 'enabled',
                'in': 'header',
                'schema': {r'$ref': '#/components/schemas/Enabled'},
              },
              {
                'name': 'attempts',
                'in': 'cookie',
                'schema': {r'$ref': '#/components/schemas/RetryAlias'},
              },
            ],
            'responses': {
              '200': {'description': 'OK'},
            },
          },
        },
      },
      'components': {
        'schemas': {
          'RetryAlias': {r'$ref': '#/components/schemas/RetryCount'},
          'RetryCount': {
            'allOf': [
              {'type': 'integer'},
            ],
            'default': 3,
          },
          'Choice': {
            'oneOf': [
              {'type': 'integer'},
            ],
            'default': 0,
          },
          'Enabled': {
            'anyOf': [
              {'type': 'boolean'},
            ],
            'default': false,
          },
        },
      },
    });

    expect(api.pathParameters.single.resolve().effectiveDefaultValue, 3);
    expect(api.queryParameters.single.resolve().effectiveDefaultValue, 0);
    expect(api.requestHeaders.single.resolve().effectiveDefaultValue, isFalse);
    expect(api.cookieParameters.single.resolve().effectiveDefaultValue, 3);
  });
}
