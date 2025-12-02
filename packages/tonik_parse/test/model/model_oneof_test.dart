import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {'title': 'Test API', 'version': '1.0.0'},
    'paths': <String, dynamic>{},
    'components': {
      'schemas': {
        'Reference': {
          'type': 'object',
          'properties': {
            'foo': {'type': 'string'},
            'bar': {'type': 'number'},
          },
        },
        'InlineOneOf': {
          'oneOf': [
            {'type': 'string'},
            {
              'type': 'object',
              'properties': {
                'foo': {'type': 'string'},
              },
            },
          ],
        },
        'ReferenceOneOf': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Reference'},
            {'type': 'string'},
          ],
        },
        'Discriminator': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Reference'},
            {r'$ref': '#/components/schemas/InlineOneOf'},
          ],
          'discriminator': {
            'propertyName': 'disc',
            'mapping': {
              'ref': '#/components/schemas/Reference',
              'inline': '#/components/schemas/InlineOneOf',
            },
          },
        },
        'SimpleDiscriminator': {
          'oneOf': [
            {r'$ref': '#/components/schemas/Reference'},
            {r'$ref': '#/components/schemas/InlineOneOf'},
          ],
          'discriminator': {'propertyName': 'name'},
        },
        'DeepNested': {
          'oneOf': [
            {'type': 'string'},
            {
              'oneOf': [
                {'type': 'integer'},
                {
                  'oneOf': [
                    {'type': 'boolean'},
                    {
                      'type': 'object',
                      'properties': {
                        'foo': {'type': 'string'},
                      },
                    },
                  ],
                },
              ],
            },
          ],
        },
      },
    },
  };

  test('Imports oneOf with inline schema', () {
    final api = Importer().import(fileContent);

    final inlineOneOf = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'InlineOneOf',
    );

    expect(inlineOneOf, isA<OneOfModel>());
    expect((inlineOneOf as OneOfModel).models, hasLength(2));

    final stringModel = inlineOneOf.models.first;
    expect(stringModel.model, isA<StringModel>());
    expect(stringModel.discriminatorValue, isNull);

    final objectModel = inlineOneOf.models.last;
    expect(objectModel.model, isA<ClassModel>());
    expect(objectModel.discriminatorValue, isNull);

    expect(api.models, contains(objectModel.model));
    expect(api.models.contains(stringModel.model), isFalse);
  });

  test('Imports oneOf with reference', () {
    final api = Importer().import(fileContent);

    final referenceOneOf = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'ReferenceOneOf',
    );

    expect(referenceOneOf, isA<OneOfModel>());
    expect((referenceOneOf as OneOfModel).models, hasLength(2));

    final referenceModel = referenceOneOf.models.first;
    expect(referenceModel.model, isA<ClassModel>());
    expect((referenceModel.model as ClassModel).name, 'Reference');
    expect(referenceModel.discriminatorValue, isNull);

    final stringModel = referenceOneOf.models.last;
    expect(stringModel.model, isA<StringModel>());
    expect(stringModel.discriminatorValue, isNull);
  });

  test('Imports oneOf with discriminator', () {
    final api = Importer().import(fileContent);

    final discriminator = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'Discriminator',
    );

    expect(discriminator, isA<OneOfModel>());
    expect((discriminator as OneOfModel).models, hasLength(2));
    expect(discriminator.discriminator, 'disc');

    final refModel = discriminator.models.first;
    expect(refModel.model, isA<ClassModel>());
    expect(refModel.discriminatorValue, 'ref');

    final inlineModel = discriminator.models.last;
    expect(inlineModel.model, isA<OneOfModel>());
    expect(inlineModel.discriminatorValue, 'inline');
  });

  test('Imports oneOf with discriminator but no mapping', () {
    final api = Importer().import(fileContent);

    final simpleDiscriminator = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'SimpleDiscriminator',
    );

    expect(simpleDiscriminator, isA<OneOfModel>());
    expect((simpleDiscriminator as OneOfModel).models, hasLength(2));
    expect(simpleDiscriminator.discriminator, 'name');

    final refModel = simpleDiscriminator.models.first;
    expect(refModel.model, isA<ClassModel>());
    expect(refModel.discriminatorValue, 'Reference');

    final inlineModel = simpleDiscriminator.models.last;
    expect(inlineModel.model, isA<OneOfModel>());
    expect(inlineModel.discriminatorValue, 'InlineOneOf');
  });

  test('Imports deeply nested oneOf', () {
    final api = Importer().import(fileContent);

    final deepNested = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'DeepNested',
    );

    expect(deepNested, isA<OneOfModel>());
    final level1 = deepNested as OneOfModel;
    expect(level1.models, hasLength(2));
    expect(level1.models.first.model, isA<StringModel>());

    final level2 = level1.models.last.model;
    expect(level2, isA<OneOfModel>());
    expect((level2 as OneOfModel).models, hasLength(2));
    expect(api.models, contains(level2));
    expect(level2.models.first.model, isA<IntegerModel>());

    final level3 = level2.models.last.model;
    expect(level3, isA<OneOfModel>());
    expect((level3 as OneOfModel).models, hasLength(2));
    expect(api.models, contains(level3));
    expect(level3.models.first.model, isA<BooleanModel>());

    final anonymousClass = level3.models.last.model;
    expect(anonymousClass, isA<ClassModel>());
    expect((anonymousClass as ClassModel).name, isNull);
    expect(anonymousClass.properties.length, 1);
    expect(anonymousClass.properties.first.name, 'foo');
    expect(anonymousClass.properties.first.model, isA<StringModel>());

    expect(api.models, contains(anonymousClass));
  });

  test('Imports oneOf with bare type strings as type references', () {
    const fileContent = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'OneOfDirectPrimitive': {
            'oneOf': ['string', 'number'],
          },
        },
      },
    };

    final api = Importer().import(fileContent);

    final oneOfDirectPrimitive = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'OneOfDirectPrimitive',
    );

    expect(oneOfDirectPrimitive, isA<OneOfModel>());
    expect((oneOfDirectPrimitive as OneOfModel).models, hasLength(2));

    final stringModel = oneOfDirectPrimitive.models.first;
    expect(stringModel.model, isA<StringModel>());

    final numberModel = oneOfDirectPrimitive.models.last;
    expect(numberModel.model, isA<NumberModel>());
  });

  group('description', () {
    const oneOfWithDescription = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Pet': {
            'description': 'A pet can be either a cat or a dog',
            'oneOf': [
              {
                'type': 'object',
                'properties': {
                  'bark': {'type': 'boolean'},
                },
              },
              {
                'type': 'object',
                'properties': {
                  'meow': {'type': 'boolean'},
                },
              },
            ],
          },
        },
      },
    };

    const oneOfWithoutDescription = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Animal': {
            'oneOf': [
              {'type': 'string'},
              {'type': 'integer'},
            ],
          },
        },
      },
    };

    test('import oneOf with description', () {
      final api = Importer().import(oneOfWithDescription);
      final model =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'Pet',
              )
              as OneOfModel;

      expect(model.description, 'A pet can be either a cat or a dog');
    });

    test('import oneOf without description', () {
      final api = Importer().import(oneOfWithoutDescription);
      final model =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'Animal',
              )
              as OneOfModel;

      expect(model.description, isNull);
    });
  });
}
