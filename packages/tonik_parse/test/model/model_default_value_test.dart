import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('ModelImporter default values', () {
    test('inline property with default sets Property.defaultValue', () {
      final api = Importer().import({
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'WithDefaults': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string', 'default': 'anon'},
                'age': {'type': 'integer', 'default': 0},
                'tags': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'default': <String>[],
                },
              },
            },
          },
        },
      });

      final model = api.models.firstWhere(
        (m) => m is ClassModel && m.name == 'WithDefaults',
      ) as ClassModel;

      final name = model.properties.firstWhere((p) => p.name == 'name');
      final age = model.properties.firstWhere((p) => p.name == 'age');
      final tags = model.properties.firstWhere((p) => p.name == 'tags');

      expect(name.defaultValue, 'anon');
      expect(age.defaultValue, 0);
      expect(tags.defaultValue, <String>[]);
    });

    test('property without default keeps Property.defaultValue null', () {
      final api = Importer().import({
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'NoDefaults': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
          },
        },
      });

      final model = api.models.firstWhere(
        (m) => m is ClassModel && m.name == 'NoDefaults',
      ) as ClassModel;

      final name = model.properties.firstWhere((p) => p.name == 'name');
      expect(name.defaultValue, isNull);
    });

    test(r'property $ref with sibling default wraps target in AliasModel '
        'carrying the sibling default', () {
      final api = Importer().import({
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Country': {'type': 'string'},
            'Address': {
              'type': 'object',
              'properties': {
                'country': {
                  r'$ref': '#/components/schemas/Country',
                  'default': 'DE',
                },
              },
            },
          },
        },
      });

      final address = api.models.firstWhere(
        (m) => m is ClassModel && m.name == 'Address',
      ) as ClassModel;
      final country = address.properties.firstWhere(
        (p) => p.name == 'country',
      );

      expect(country.model, isA<AliasModel>());
      final alias = country.model as AliasModel;
      expect(alias.defaultValue, 'DE');
      expect(country.defaultValue, 'DE');
    });

    test('referenced schema own default surfaces on resolving AliasModel', () {
      final api = Importer().import({
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Country': {'type': 'string', 'default': 'US'},
            'CountryAlias': {r'$ref': '#/components/schemas/Country'},
          },
        },
      });

      final country = api.models.firstWhere(
        (m) => m is AliasModel && m.name == 'Country',
      ) as AliasModel;
      expect(country.defaultValue, 'US');

      final aliasOfCountry = api.models.firstWhere(
        (m) => m is AliasModel && m.name == 'CountryAlias',
      ) as AliasModel;
      expect(aliasOfCountry.defaultValue, 'US');
    });

    test('sibling default overrides referenced schema default', () {
      final api = Importer().import({
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Country': {'type': 'string', 'default': 'US'},
            'CountryOverride': {
              r'$ref': '#/components/schemas/Country',
              'default': 'DE',
            },
          },
        },
      });

      final override = api.models.firstWhere(
        (m) => m is AliasModel && m.name == 'CountryOverride',
      ) as AliasModel;
      expect(override.defaultValue, 'DE');
    });

    test(
      'absent default keyword on a property keeps Property.defaultValue null '
      'and matches explicit null',
      () {
        final api = Importer().import({
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'WithExplicitNull': {
                'type': 'object',
                'properties': {
                  'absent': {'type': 'string'},
                  'present': {
                    'type': 'string',
                    'nullable': true,
                    'default': null,
                  },
                },
              },
            },
          },
        });

        final model = api.models.firstWhere(
          (m) => m is ClassModel && m.name == 'WithExplicitNull',
        ) as ClassModel;
        final absent = model.properties.firstWhere((p) => p.name == 'absent');
        final present = model.properties.firstWhere((p) => p.name == 'present');

        expect(absent.defaultValue, isNull);
        expect(present.defaultValue, isNull);
      },
    );

    test(
      r'property $ref without sibling resolves to AliasModel carrying '
      'the referenced default',
      () {
        final api = Importer().import({
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Country': {'type': 'string', 'default': 'US'},
              'Address': {
                'type': 'object',
                'properties': {
                  'country': {r'$ref': '#/components/schemas/Country'},
                },
              },
            },
          },
        });

        final address = api.models.firstWhere(
          (m) => m is ClassModel && m.name == 'Address',
        ) as ClassModel;
        final country = address.properties.firstWhere(
          (p) => p.name == 'country',
        );

        expect(country.model, isA<AliasModel>());
        expect((country.model as AliasModel).defaultValue, 'US');
      },
    );

    test('AliasModel for primitive named schema carries default', () {
      final api = Importer().import({
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Greeting': {'type': 'string', 'default': 'hello'},
          },
        },
      });

      final greeting = api.models.firstWhere(
        (m) => m is AliasModel && m.name == 'Greeting',
      ) as AliasModel;
      expect(greeting.defaultValue, 'hello');
    });

    test(r'two-hop $ref chain surfaces the terminal default on the head', () {
      final api = Importer().import({
        'openapi': '3.0.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'A': {r'$ref': '#/components/schemas/B'},
            'B': {r'$ref': '#/components/schemas/C'},
            'C': {'type': 'string', 'default': 'X'},
          },
        },
      });

      final a = api.models.firstWhere(
        (m) => m is AliasModel && m.name == 'A',
      ) as AliasModel;
      final b = api.models.firstWhere(
        (m) => m is AliasModel && m.name == 'B',
      ) as AliasModel;
      final c = api.models.firstWhere(
        (m) => m is AliasModel && m.name == 'C',
      ) as AliasModel;

      expect(c.defaultValue, 'X');
      expect(b.defaultValue, 'X');
      expect(a.defaultValue, 'X');
    });

    test(
      r'two-hop $ref chain with reversed declaration order also '
      'surfaces the terminal default',
      () {
        final api = Importer().import({
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'C': {'type': 'string', 'default': 'X'},
              'B': {r'$ref': '#/components/schemas/C'},
              'A': {r'$ref': '#/components/schemas/B'},
            },
          },
        });

        final a = api.models.firstWhere(
          (m) => m is AliasModel && m.name == 'A',
        ) as AliasModel;
        expect(a.defaultValue, 'X');
      },
    );

    test(
      r'bare $ref cycle with sibling default terminates and surfaces '
      'the local default',
      () {
        final api = Importer().import({
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'A': {
                r'$ref': '#/components/schemas/B',
                'default': 'x',
              },
              'B': {r'$ref': '#/components/schemas/A'},
            },
          },
        });

        final a = api.models.firstWhere(
          (m) => m is AliasModel && m.name == 'A',
        ) as AliasModel;
        expect(a.defaultValue, 'x');
      },
    );

    test(
      r'property $ref with non-string sibling default carries the list '
      'value through Property and AliasModel',
      () {
        final api = Importer().import({
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Sizes': {
                'type': 'array',
                'items': {'type': 'integer'},
              },
              'Box': {
                'type': 'object',
                'properties': {
                  'dims': {
                    r'$ref': '#/components/schemas/Sizes',
                    'default': [1, 2, 3],
                  },
                },
              },
            },
          },
        });

        final box = api.models.firstWhere(
          (m) => m is ClassModel && m.name == 'Box',
        ) as ClassModel;
        final dims = box.properties.firstWhere((p) => p.name == 'dims');

        expect(dims.defaultValue, [1, 2, 3]);
        expect(dims.model, isA<AliasModel>());
        expect((dims.model as AliasModel).defaultValue, [1, 2, 3]);
      },
    );

    test(
      r'$defs reference with default surfaces on AliasModel',
      () {
        final api = Importer().import({
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Outer': {
                'type': 'object',
                r'$defs': {
                  'Sub': {'type': 'string', 'default': 'd'},
                },
                'properties': {
                  'sub': {
                    r'$ref': r'#/components/schemas/Outer/$defs/Sub',
                  },
                },
              },
            },
          },
        });

        final outer = api.models.firstWhere(
          (m) => m is ClassModel && m.name == 'Outer',
        ) as ClassModel;
        final sub = outer.properties.firstWhere((p) => p.name == 'sub');
        expect(sub.model, isA<AliasModel>());
        expect((sub.model as AliasModel).defaultValue, 'd');
      },
    );
  });
}
