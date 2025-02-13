import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/tonic_parse.dart';

void main() {
  const simpleAlias = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
    },
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {
          'type': 'string',
        },
      },
    },
  };

  const nestedAlias = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
    },
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {
          'type': 'string',
        },
        'NestedModel': {
          r'$ref': '#/components/schemas/SimpleModel',
        },
        'DoubleNestedModel': {
          r'$ref': '#/components/schemas/NestedModel',
        },
      },
    },
  };

  test('import simple alias model', () {
    final api = Importer().import(simpleAlias);

    final alias = api.models.first;
    expect(alias, isA<AliasModel>());
    expect((alias as AliasModel).name, 'SimpleModel');
    expect(alias.model, isA<StringModel>());
    expect(alias.context.path, ['components', 'schemas']);
  });

  test('import nested alias model', () {
    final api = Importer().import(nestedAlias);

    final nested = api.models.firstWhere(
      (model) => model is AliasModel && model.name == 'NestedModel',
    );
    expect(nested, isA<AliasModel>());
    expect((nested as AliasModel).name, 'NestedModel');
    expect(nested.model, isA<AliasModel>());

    final simple = nested.model as AliasModel;
    expect(simple.name, 'SimpleModel');
    expect(simple.model, isA<StringModel>());

    expect(nested.context.path, ['components', 'schemas']);
  });

  test('import double nested alias model', () {
    final api = Importer().import(nestedAlias);

    final doubleNested = api.models.firstWhere(
      (model) => model is AliasModel && model.name == 'DoubleNestedModel',
    );
    expect(doubleNested, isA<AliasModel>());
    expect((doubleNested as AliasModel).name, 'DoubleNestedModel');
    expect(doubleNested.model, isA<AliasModel>());

    final nested = doubleNested.model as AliasModel;
    expect(nested.name, 'NestedModel');
    expect(nested.model, isA<AliasModel>());

    final simple = nested.model as AliasModel;
    expect(simple.name, 'SimpleModel');
    expect(simple.model, isA<StringModel>());

    expect(doubleNested.context.path, ['components', 'schemas']);
  });
}
