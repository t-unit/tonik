import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  test('resolves component-name mappings in named and inline unions', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Dog': {
            'type': 'object',
            'required': ['bark'],
            'properties': {
              'bark': {'type': 'boolean'},
            },
          },
          'Cat': {
            'type': 'object',
            'required': ['meow'],
            'properties': {
              'meow': {'type': 'string'},
            },
          },
          'PetOne': {
            'oneOf': [
              {r'$ref': '#/components/schemas/Dog'},
              {r'$ref': '#/components/schemas/Cat'},
            ],
            'discriminator': {
              'propertyName': 'petType',
              'mapping': {'dog': 'Dog', 'cat': '#/components/schemas/Cat'},
            },
          },
          'PetAny': {
            'anyOf': [
              {r'$ref': '#/components/schemas/Dog'},
              {r'$ref': '#/components/schemas/Cat'},
            ],
            'discriminator': {
              'propertyName': 'petType',
              'mapping': {'dog': 'Dog', 'cat': 'Cat'},
            },
          },
          'Envelope': {
            'type': 'object',
            'properties': {
              'single': {
                'oneOf': [
                  {r'$ref': '#/components/schemas/Dog'},
                  {r'$ref': '#/components/schemas/Cat'},
                ],
                'discriminator': {
                  'propertyName': 'petType',
                  'mapping': {'dog': 'Dog', 'cat': 'Cat'},
                },
              },
              'multiple': {
                'anyOf': [
                  {r'$ref': '#/components/schemas/Dog'},
                  {r'$ref': '#/components/schemas/Cat'},
                ],
                'discriminator': {
                  'propertyName': 'petType',
                  'mapping': {'dog': 'Dog', 'cat': 'Cat'},
                },
              },
            },
          },
        },
      },
    });

    final namedOne = api.models.whereType<OneOfModel>().singleWhere(
      (model) => model.name == 'PetOne',
    );
    final namedAny = api.models.whereType<AnyOfModel>().singleWhere(
      (model) => model.name == 'PetAny',
    );
    final envelope = api.models.whereType<ClassModel>().singleWhere(
      (model) => model.name == 'Envelope',
    );
    final inlineOne = envelope.properties.first.model as OneOfModel;
    final inlineAny = envelope.properties.last.model as AnyOfModel;

    expect(namedOne.models.map((model) => model.discriminatorValue), [
      'dog',
      'cat',
    ]);
    expect(namedAny.models.map((model) => model.discriminatorValue), [
      'dog',
      'cat',
    ]);
    expect(inlineOne.models.map((model) => model.discriminatorValue), [
      'dog',
      'cat',
    ]);
    expect(inlineAny.models.map((model) => model.discriminatorValue), [
      'dog',
      'cat',
    ]);
  });

  test('resolves component-name mappings inherited through allOf', () {
    final api = Importer().import({
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Pet': {
            'type': 'object',
            'properties': {
              'petType': {'type': 'string'},
            },
            'discriminator': {
              'propertyName': 'petType',
              'mapping': {'dog': 'Dog', 'cat': 'Cat'},
            },
          },
          'Dog': {
            'allOf': [
              {r'$ref': '#/components/schemas/Pet'},
              {
                'type': 'object',
                'required': ['bark'],
                'properties': {
                  'bark': {'type': 'boolean'},
                },
              },
            ],
          },
          'Cat': {
            'allOf': [
              {r'$ref': '#/components/schemas/Pet'},
              {
                'type': 'object',
                'required': ['meow'],
                'properties': {
                  'meow': {'type': 'string'},
                },
              },
            ],
          },
          'PetOne': {
            'oneOf': [
              {r'$ref': '#/components/schemas/Dog'},
              {r'$ref': '#/components/schemas/Cat'},
            ],
          },
          'PetAny': {
            'anyOf': [
              {r'$ref': '#/components/schemas/Dog'},
              {r'$ref': '#/components/schemas/Cat'},
            ],
          },
        },
      },
    });

    final one = api.models.whereType<OneOfModel>().single;
    final any = api.models.whereType<AnyOfModel>().single;
    expect(one.discriminator, 'petType');
    expect(any.discriminator, 'petType');
    expect(one.models.map((model) => model.discriminatorValue), ['dog', 'cat']);
    expect(any.models.map((model) => model.discriminatorValue), ['dog', 'cat']);
  });

  test(
    'does not confuse names or relative URIs with other schema locations',
    () {
      final api = Importer().import({
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Dog': {'type': 'string'},
            'Namespace': {
              r'$defs': {
                'Dog': {'type': 'integer'},
                'Unknown': {'type': 'boolean'},
              },
            },
            'LocalDefinitions': {
              'oneOf': [
                {r'$ref': r'#/components/schemas/Namespace/$defs/Dog'},
                {r'$ref': r'#/components/schemas/Namespace/$defs/Unknown'},
              ],
              'discriminator': {
                'propertyName': 'kind',
                'mapping': {'known': 'Dog', 'unknown': 'Unknown'},
              },
            },
            'RelativeMapping': {
              'anyOf': [
                {r'$ref': '#/components/schemas/Dog'},
              ],
              'discriminator': {
                'propertyName': 'kind',
                'mapping': {'relative': './Dog', 'unknown': 'Missing'},
              },
            },
          },
        },
      });

      final definitions = api.models.whereType<OneOfModel>().single;
      final relative = api.models.whereType<AnyOfModel>().single;
      expect(definitions.models.first.discriminatorValue, 'Dog');
      expect(definitions.models.last.discriminatorValue, 'Unknown');
      expect(relative.models.single.discriminatorValue, 'Dog');
    },
  );
}
