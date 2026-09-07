import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('required empty-schema property imports as AnyModel', () {
    final api = Importer().import({
      'openapi': '3.0.3',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Setting': {
            'type': 'object',
            'required': ['value'],
            'properties': {'value': <String, dynamic>{}},
          },
        },
      },
    });

    final setting = api.models.whereType<ClassModel>().single;
    final value = setting.properties.single;

    expect(setting.name, 'Setting');
    expect(value.name, 'value');
    expect(value.isRequired, isTrue);
    expect(value.model, isA<AnyModel>());
  });

  test(
    'references to an empty component resolve to its named AnyModel alias',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Setting': {
              'type': 'object',
              'required': ['value'],
              'properties': {
                'value': {r'$ref': '#/components/schemas/AnyValue'},
              },
            },
            'ValueAlias': {r'$ref': '#/components/schemas/AnyValue'},
            'AnyValue': <String, dynamic>{},
          },
        },
      });

      final setting = api.models.whereType<ClassModel>().single;
      final anyValue = api.models.whereType<AliasModel>().firstWhere(
        (model) => model.name == 'AnyValue',
      );
      final valueAlias = api.models.whereType<AliasModel>().firstWhere(
        (model) => model.name == 'ValueAlias',
      );

      expect(anyValue.model, isA<AnyModel>());
      expect(setting.properties.single.model, same(anyValue));
      expect(valueAlias.model, same(anyValue));
    },
  );

  test(
    'unconstrained named schema preserves annotations on its AnyModel alias',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'AnyValue': {
              'description': 'An arbitrary JSON value.',
              'deprecated': true,
              'readOnly': true,
              'x-dart-name': 'JsonValue',
              'default': 42,
              'examples': [7],
            },
          },
        },
      });

      final anyValue = api.models.whereType<AliasModel>().single;

      expect(anyValue.name, 'AnyValue');
      expect(anyValue.model, isA<AnyModel>());
      expect(anyValue.description, 'An arbitrary JSON value.');
      expect(anyValue.isDeprecated, isTrue);
      expect(anyValue.isReadOnly, isTrue);
      expect(anyValue.nameOverride, 'JsonValue');
      expect(anyValue.defaultValue, 42);
      expect(anyValue.examples.single.value, 7);
    },
  );

  test('empty array item schema imports as AnyModel', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Values': {'type': 'array', 'items': <String, dynamic>{}},
        },
      },
    });

    final values = api.models.whereType<ListModel>().single;

    expect(values.content, isA<AnyModel>());
    expect(api.models.whereType<ClassModel>(), isEmpty);
  });
}
