import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('imports named typeless string and integer enums', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Color': {
            'enum': ['red', 'green'],
          },
          'Priority': {
            'enum': [1, 2],
          },
        },
      },
    });

    final color = api.models.whereType<EnumModel<String>>().single;
    final priority = api.models.whereType<EnumModel<int>>().single;
    expect(color.name, 'Color');
    expect(color.values.map((entry) => entry.value), ['red', 'green']);
    expect(color.isNullable, isFalse);
    expect(priority.name, 'Priority');
    expect(priority.values.map((entry) => entry.value), [1, 2]);
    expect(priority.isNullable, isFalse);
    expect(api.models.whereType<ClassModel>(), isEmpty);
  });

  test('keeps inferred scalar enums despite object-only keywords', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Color': {
            'enum': ['red', 'green'],
            'additionalProperties': true,
          },
          'Setting': {
            'type': 'object',
            'properties': {
              'priority': {
                'enum': [1, 2],
                'additionalProperties': false,
                'properties': {
                  'label': {'type': 'string'},
                },
              },
            },
          },
        },
      },
    });

    final color = api.models.whereType<EnumModel<String>>().single;
    final setting = api.models.whereType<ClassModel>().single;
    final priority = setting.properties.single.model as EnumModel<int>;
    expect(color.values.map((entry) => entry.value), ['red', 'green']);
    expect(priority.values.map((entry) => entry.value), [1, 2]);
    expect(api.models.whereType<MapModel>(), isEmpty);
  });

  test('keeps a named typeless date enum and its allowed null', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'DateChoice': {
            'enum': ['2024-01-01', null],
            'format': 'date',
          },
        },
      },
    });

    final choice = api.models.whereType<EnumModel<String>>().single;
    expect(choice.name, 'DateChoice');
    expect(choice.values.map((entry) => entry.value), ['2024-01-01']);
    expect(choice.isNullable, isTrue);
    expect(api.models.whereType<AliasModel>(), isEmpty);
  });

  test(
    'keeps inline typeless enums ahead of format and encoding promotion',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Setting': {
              'type': 'object',
              'required': ['uri', 'encoded'],
              'properties': {
                'uri': {
                  'enum': ['https://example.com', null],
                  'format': 'uri',
                },
                'encoded': {
                  'enum': ['cmVk', null],
                  'format': 'byte',
                  'contentEncoding': 'base64',
                },
              },
            },
          },
        },
      });

      final setting = api.models.whereType<ClassModel>().single;
      final uri = setting.properties.first.model as EnumModel<String>;
      final encoded = setting.properties.last.model as EnumModel<String>;
      expect(uri.values.map((entry) => entry.value), ['https://example.com']);
      expect(encoded.values.map((entry) => entry.value), ['cmVk']);
      expect(uri.isNullable, isTrue);
      expect(encoded.isNullable, isTrue);
    },
  );

  test('imports inline typeless enums and their nullability', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Setting': {
            'type': 'object',
            'properties': {
              'color': {
                'enum': ['red', 'green', null],
              },
              'priority': {
                'enum': [1, 2, null],
              },
            },
          },
        },
      },
    });

    final setting = api.models.whereType<ClassModel>().single;
    final color = setting.properties.first.model as EnumModel<String>;
    final priority = setting.properties.last.model as EnumModel<int>;
    expect(color.values.map((entry) => entry.value), ['red', 'green']);
    expect(priority.values.map((entry) => entry.value), [1, 2]);
    expect(color.isNullable, isTrue);
    expect(priority.isNullable, isTrue);
  });

  test('preserves nullability and references to named typeless enums', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Setting': {
            'type': 'object',
            'properties': {
              'color': {r'$ref': '#/components/schemas/Color'},
              'priority': {r'$ref': '#/components/schemas/Priority'},
            },
          },
          'Color': {
            'enum': ['red', 'green', null],
          },
          'Priority': {
            'enum': [1, 2, null],
          },
        },
      },
    });

    final setting = api.models.whereType<ClassModel>().single;
    final color = api.models.whereType<EnumModel<String>>().single;
    final priority = api.models.whereType<EnumModel<int>>().single;
    expect(setting.properties.first.model, same(color));
    expect(setting.properties.last.model, same(priority));
    expect(color.isNullable, isTrue);
    expect(priority.isNullable, isTrue);
  });

  test('keeps named and inline items-only schemas permissive', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'ItemsOnly': {
            'items': {'type': 'integer'},
          },
          'Setting': {
            'type': 'object',
            'properties': {
              'value': {
                'items': {'type': 'string'},
              },
              'named': {r'$ref': '#/components/schemas/ItemsOnly'},
            },
          },
        },
      },
    });

    final itemsOnly = api.models.whereType<AliasModel>().single;
    final setting = api.models.whereType<ClassModel>().single;
    expect(itemsOnly.name, 'ItemsOnly');
    expect(itemsOnly.model, isA<AnyModel>());
    expect(setting.properties.first.model, isA<AnyModel>());
    expect(setting.properties.last.model, same(itemsOnly));
    expect(api.models.whereType<ListModel>(), isEmpty);
  });

  test('keeps unsupported typeless enum mixtures permissive', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Mixed': {
            'enum': ['red', 1, true, null],
          },
          'Setting': {
            'type': 'object',
            'properties': {
              'value': {
                'enum': ['green', 2],
              },
              'named': {r'$ref': '#/components/schemas/Mixed'},
            },
          },
        },
      },
    });

    final mixed = api.models.whereType<AliasModel>().single;
    final setting = api.models.whereType<ClassModel>().single;
    expect(mixed.name, 'Mixed');
    expect(mixed.model, isA<AnyModel>());
    expect(setting.properties.first.model, isA<AnyModel>());
    expect(setting.properties.last.model, same(mixed));
    expect(api.models.whereType<EnumModel<Object?>>(), isEmpty);
  });

  test('preserves explicitly typed schemas and untyped object properties', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Values': {
            'type': 'array',
            'items': {'type': 'integer'},
          },
          'TypedEnum': {
            'type': 'string',
            'enum': ['red', 1],
          },
          'Setting': {
            'items': {'type': 'integer'},
            'properties': {
              'label': {'type': 'string'},
            },
          },
        },
      },
    });

    final values = api.models.whereType<ListModel>().single;
    final typedEnum = api.models.whereType<EnumModel<String>>().single;
    final setting = api.models.whereType<ClassModel>().single;
    expect(values.content, isA<IntegerModel>());
    expect(typedEnum.values.map((entry) => entry.value), ['red']);
    expect(setting.properties.single.name, 'label');
    expect(setting.properties.single.model, isA<StringModel>());
  });
}
