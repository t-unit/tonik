import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/tonic_parse.dart';

void main() {
  const simple = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {
          'type': 'object',
          'required': ['name'],
          'properties': {
            'name': {'type': 'string'},
            'age': {'type': 'integer', 'deprecated': true},
            'isActive': {'type': 'boolean', 'nullable': true},
          },
        },
      },
    },
  };

  const recursive = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {
          'type': 'object',
          'properties': {
            'nested': {r'$ref': '#/components/schemas/SimpleModel'},
          },
        },
      },
    },
  };

  const reference = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {
          'type': 'object',
          'properties': {
            'nested': {r'$ref': '#/components/schemas/Referenced'},
          },
        },
        'Referenced': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
        },
      },
    },
  };

  const inlineReference = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {
          'type': 'object',
          'properties': {
            'nested': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
          },
        },
      },
    },
  };

  const nestedInlineReference = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {
          'type': 'object',
          'properties': {
            'nested': {
              'type': 'object',
              'properties': {
                'name': {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
              },
            },
          },
        },
      },
    },
  };

  test('import simple class model', () {
    final api = Importer().import(simple);
    expect(api.models, hasLength(1));

    final model = api.models.first;
    expect(model, isA<ClassModel>());
    expect((model as ClassModel).name, 'SimpleModel');
  });

  test('import required property', () {
    final api = Importer().import(simple);

    final model = api.models.first as ClassModel;
    final name = model.properties.firstWhere((p) => p.name == 'name');
    expect(name.model, isA<StringModel>());
    expect(name.isRequired, isTrue);
  });

  test('import nullable property', () {
    final api = Importer().import(simple);

    final model = api.models.first as ClassModel;
    final isActive = model.properties.firstWhere((p) => p.name == 'isActive');
    expect(isActive.model, isA<BooleanModel>());
    expect(isActive.isNullable, isTrue);
  });

  test('import deprecated property', () {
    final api = Importer().import(simple);

    final model = api.models.first as ClassModel;
    final age = model.properties.firstWhere((p) => p.name == 'age');
    expect(age.model, isA<IntegerModel>());
    expect(age.isDeprecated, isTrue);
  });

  test('import recursive property', () {
    final api = Importer().import(recursive);
    expect(api.models, hasLength(1));

    final model = api.models.first as ClassModel;
    final nested = model.properties.firstWhere((p) => p.name == 'nested');
    expect(nested.model, isA<ClassModel>());
    expect((nested.model as ClassModel).name, 'SimpleModel');
    expect(nested.model.context.path, ['components', 'schemas']);
  });

  test('import referenced property', () {
    final api = Importer().import(reference);
    expect(api.models, hasLength(2));

    final model = api.models.first as ClassModel;
    final nested = model.properties.firstWhere((p) => p.name == 'nested');
    expect(nested.model, isA<ClassModel>());
    expect((nested.model as ClassModel).name, 'Referenced');
    expect(nested.model.context.path, ['components', 'schemas']);

    final referenced = api.models.last as ClassModel;
    expect(referenced.name, 'Referenced');
  });

  test('import inline referenced property', () {
    final api = Importer().import(inlineReference);
    expect(api.models, hasLength(2));

    final model = api.models.first as ClassModel;
    final nested = model.properties.firstWhere((p) => p.name == 'nested');
    expect(nested.model, isA<ClassModel>());
    expect((nested.model as ClassModel).name, isNull);
    expect(nested.model.context.path, [
      'components',
      'schemas',
      'SimpleModel',
      'nested',
    ]);

    final referenced = api.models.last as ClassModel;
    expect(referenced.name, isNull);
    expect(referenced, model.properties.first.model);
  });

  test('import nested inline referenced property', () {
    final api = Importer().import(nestedInlineReference);
    expect(api.models, hasLength(3));

    final classModels = api.models.whereType<ClassModel>();

    final model = classModels.firstWhereOrNull((m) => m.name == 'SimpleModel');
    expect(model?.name, 'SimpleModel');

    final nested = model?.properties.first.model;
    expect(nested, isA<ClassModel>());
    expect(classModels, contains(nested));

    final nestedNested = (nested! as ClassModel).properties.first.model;
    expect(nestedNested, isA<ClassModel>());
    expect(classModels, contains(nestedNested));

    expect((nestedNested as ClassModel).name, isNull);
    expect(nestedNested.context.path, [
      'components',
      'schemas',
      'SimpleModel',
      'nested',
      'name',
    ]);
  });
}
