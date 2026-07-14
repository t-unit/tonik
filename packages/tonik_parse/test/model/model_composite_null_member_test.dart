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
        'Cat': {
          'type': 'object',
          'properties': {
            'meow': {'type': 'string'},
          },
          'required': ['meow'],
        },
        'Dog': {
          'type': 'object',
          'properties': {
            'bark': {'type': 'string'},
          },
          'required': ['bark'],
        },
        'Nothing': {'type': 'null'},
        'OneOfWithInlineNull': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Cat'},
            {r'$ref': '#/components/schemas/Dog'},
            {'type': 'null'},
          ],
        },
        'OneOfWithNullRef': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Cat'},
            {r'$ref': '#/components/schemas/Nothing'},
          ],
        },
        'OneOfWithNullTypeArray': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Cat'},
            {
              'type': ['null'],
            },
          ],
        },
        'OneOfOnlyNull': {
          'oneOf': [
            {'type': 'null'},
          ],
        },
        'OneOfWithoutNull': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Cat'},
            {r'$ref': '#/components/schemas/Dog'},
          ],
        },
        'AnyOfWithInlineNull': {
          'anyOf': [
            {r'$ref': '#/components/schemas/Cat'},
            {'type': 'null'},
          ],
        },
        'AnyOfWithNullRef': {
          'anyOf': [
            {r'$ref': '#/components/schemas/Cat'},
            {r'$ref': '#/components/schemas/Nothing'},
          ],
        },
        'HolderWithInlineComposites': {
          'type': 'object',
          'properties': {
            'oneOfValue': {
              'oneOf': [
                {'type': 'string'},
                {'type': 'null'},
              ],
            },
            'anyOfValue': {
              'anyOf': [
                {'type': 'string'},
                {'type': 'null'},
              ],
            },
          },
        },
      },
    },
  };

  OneOfModel oneOf(ApiDocument api, String name) =>
      api.models.firstWhere((m) => m is NamedModel && m.name == name)
          as OneOfModel;

  AnyOfModel anyOf(ApiDocument api, String name) =>
      api.models.firstWhere((m) => m is NamedModel && m.name == name)
          as AnyOfModel;

  group('oneOf with null type member', () {
    test('inline null member is folded into isNullable', () {
      final api = Importer().import(fileContent);
      final model = oneOf(api, 'OneOfWithInlineNull');

      expect(model.isNullable, isTrue);
      expect(model.models, hasLength(2));
      expect(
        model.models.map((m) => (m.model as ClassModel).name),
        unorderedEquals(['Cat', 'Dog']),
      );
    });

    test('null member referenced via ref is folded into isNullable', () {
      final api = Importer().import(fileContent);
      final model = oneOf(api, 'OneOfWithNullRef');

      expect(model.isNullable, isTrue);
      expect(model.models, hasLength(1));
      expect((model.models.single.model as ClassModel).name, 'Cat');
    });

    test('null member in type array form is folded into isNullable', () {
      final api = Importer().import(fileContent);
      final model = oneOf(api, 'OneOfWithNullTypeArray');

      expect(model.isNullable, isTrue);
      expect(model.models, hasLength(1));
      expect((model.models.single.model as ClassModel).name, 'Cat');
    });

    test('oneOf with only a null member keeps an empty model set', () {
      final api = Importer().import(fileContent);
      final model = oneOf(api, 'OneOfOnlyNull');

      expect(model.isNullable, isTrue);
      expect(model.models, isEmpty);
    });

    test('oneOf without null member stays non-nullable', () {
      final api = Importer().import(fileContent);
      final model = oneOf(api, 'OneOfWithoutNull');

      expect(model.isNullable, isFalse);
      expect(model.models, hasLength(2));
    });

    test('inline oneOf property with null member is folded', () {
      final api = Importer().import(fileContent);
      final holder =
          api.models.firstWhere(
                (m) =>
                    m is NamedModel &&
                    m.name == 'HolderWithInlineComposites',
              )
              as ClassModel;

      final property = holder.properties.firstWhere(
        (p) => p.name == 'oneOfValue',
      );
      final model = property.model as OneOfModel;

      expect(model.isNullable, isTrue);
      expect(model.models, hasLength(1));
      expect(model.models.single.model, isA<StringModel>());
    });
  });

  group('anyOf with null type member', () {
    test('inline null member is folded into isNullable', () {
      final api = Importer().import(fileContent);
      final model = anyOf(api, 'AnyOfWithInlineNull');

      expect(model.isNullable, isTrue);
      expect(model.models, hasLength(1));
      expect((model.models.single.model as ClassModel).name, 'Cat');
    });

    test('null member referenced via ref is folded into isNullable', () {
      final api = Importer().import(fileContent);
      final model = anyOf(api, 'AnyOfWithNullRef');

      expect(model.isNullable, isTrue);
      expect(model.models, hasLength(1));
      expect((model.models.single.model as ClassModel).name, 'Cat');
    });

    test('inline anyOf property with null member is folded', () {
      final api = Importer().import(fileContent);
      final holder =
          api.models.firstWhere(
                (m) =>
                    m is NamedModel &&
                    m.name == 'HolderWithInlineComposites',
              )
              as ClassModel;

      final property = holder.properties.firstWhere(
        (p) => p.name == 'anyOfValue',
      );
      final model = property.model as AnyOfModel;

      expect(model.isNullable, isTrue);
      expect(model.models, hasLength(1));
      expect(model.models.single.model, isA<StringModel>());
    });
  });
}
