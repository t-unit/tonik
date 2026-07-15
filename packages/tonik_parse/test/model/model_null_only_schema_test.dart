import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.1.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'Nothing': {'type': 'null'},
        'NothingTypeArray': {
          'type': ['null'],
        },
        'Nope': false,
        'Holder': {
          'type': 'object',
          'properties': {
            'viaRef': {r'$ref': '#/components/schemas/Nothing'},
            'inline': {'type': 'null'},
            'nullItems': {
              'type': 'array',
              'items': {'type': 'null'},
            },
          },
          'required': ['viaRef', 'inline', 'nullItems'],
        },
        'HolderWithAdditionalProperties': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
          'additionalProperties': {'type': 'null'},
        },
        'NullValueMap': {
          'type': 'object',
          'additionalProperties': {'type': 'null'},
        },
      },
    },
  };

  Model named(ApiDocument api, String name) =>
      api.models.firstWhere((m) => m is NamedModel && m.name == name);

  ClassModel holder(ApiDocument api, String name) =>
      named(api, name) as ClassModel;

  group('named null-only schema', () {
    test('imports as a named alias of a nullable NeverModel', () {
      final api = Importer().import(fileContent);
      final model = named(api, 'Nothing') as AliasModel;

      expect(model.name, 'Nothing');
      final never = model.model as NeverModel;
      expect(never.isNullable, isTrue);
    });

    test('type array form imports as a named alias of a nullable NeverModel',
        () {
      final api = Importer().import(fileContent);
      final model = named(api, 'NothingTypeArray') as AliasModel;

      final never = model.model as NeverModel;
      expect(never.isNullable, isTrue);
    });

    test('is effectively nullable', () {
      final api = Importer().import(fileContent);
      final model = named(api, 'Nothing');

      expect(model.isEffectivelyNullable, isTrue);
    });

    test('boolean false schema stays a non-nullable NeverModel', () {
      final api = Importer().import(fileContent);
      final model = named(api, 'Nope') as AliasModel;

      final never = model.model as NeverModel;
      expect(never.isNullable, isFalse);
    });
  });

  group('null-only schema in properties', () {
    test('ref to a null-only component resolves to the named alias', () {
      final api = Importer().import(fileContent);
      final property = holder(api, 'Holder').properties.firstWhere(
        (p) => p.name == 'viaRef',
      );

      final alias = property.model as AliasModel;
      expect(alias.name, 'Nothing');
      expect(alias.isEffectivelyNullable, isTrue);
    });

    test('inline null-only property imports as a nullable NeverModel', () {
      final api = Importer().import(fileContent);
      final property = holder(api, 'Holder').properties.firstWhere(
        (p) => p.name == 'inline',
      );

      final never = property.model as NeverModel;
      expect(never.isNullable, isTrue);
      expect(property.isNullable, isTrue);
    });
  });

  group('null-only schema as list items', () {
    test('imports as nullable NeverModel content', () {
      final api = Importer().import(fileContent);
      final property = holder(api, 'Holder').properties.firstWhere(
        (p) => p.name == 'nullItems',
      );

      final list = property.model as ListModel;
      expect(list.isContentNullable, isTrue);
      final never = list.content as NeverModel;
      expect(never.isNullable, isTrue);
    });
  });

  group('null-only schema as additionalProperties', () {
    test('imports as nullable NeverModel policy value without alias wrap', () {
      final api = Importer().import(fileContent);
      final model = holder(api, 'HolderWithAdditionalProperties');

      final policy =
          model.additionalPropertiesPolicy as AllowedAdditionalProperties;
      final never = policy.valueModel as NeverModel;
      expect(never.isNullable, isTrue);
    });

    test('imports as nullable NeverModel map value', () {
      final api = Importer().import(fileContent);
      final model = named(api, 'NullValueMap') as MapModel;

      expect(model.isValueNullable, isTrue);
      final never = model.valueModel as NeverModel;
      expect(never.isNullable, isTrue);
    });
  });
}
