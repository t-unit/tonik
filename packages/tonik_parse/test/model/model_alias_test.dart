import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const simpleAlias = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {'type': 'string'},
      },
    },
  };

  const nestedAlias = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'SimpleModel': {'type': 'string'},
        'NestedModel': {r'$ref': '#/components/schemas/SimpleModel'},
        'DoubleNestedModel': {r'$ref': '#/components/schemas/NestedModel'},
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

  group('resolved getter', () {
    test('resolves to non-alias model directly', () {
      final context = Context.initial();
      final stringModel = StringModel(context: context);
      final alias = AliasModel(
        name: 'TestAlias',
        model: stringModel,
        context: context,
      );

      expect(alias.resolved, stringModel);
    });

    test('resolves single-level alias', () {
      final context = Context.initial();
      final stringModel = StringModel(context: context);
      final innerAlias = AliasModel(
        name: 'InnerAlias',
        model: stringModel,
        context: context,
      );
      final outerAlias = AliasModel(
        name: 'OuterAlias',
        model: innerAlias,
        context: context,
      );

      expect(outerAlias.resolved, stringModel);
    });

    test('resolves multi-level alias', () {
      final context = Context.initial();
      final stringModel = StringModel(context: context);
      final level3 = AliasModel(
        name: 'Level3',
        model: stringModel,
        context: context,
      );
      final level2 = AliasModel(
        name: 'Level2',
        model: level3,
        context: context,
      );
      final level1 = AliasModel(
        name: 'Level1',
        model: level2,
        context: context,
      );

      expect(level1.resolved, stringModel);
    });
  });
}
