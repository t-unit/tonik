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
        'InlineAnyOf': {
          'anyOf': [
            {'type': 'string'},
            {
              'type': 'object',
              'properties': {
                'foo': {'type': 'string'},
              },
            },
          ],
        },
        'ReferenceAnyOf': {
          'anyOf': [
            {r'$ref': '#/components/schemas/Reference'},
            {'type': 'string'},
          ],
        },
        'Discriminator': {
          'anyOf': [
            {r'$ref': '#/components/schemas/Reference'},
            {r'$ref': '#/components/schemas/InlineAnyOf'},
          ],
          'discriminator': {
            'propertyName': 'disc',
            'mapping': {
              'ref': '#/components/schemas/Reference',
              'inline': '#/components/schemas/InlineAnyOf',
            },
          },
        },
        'SimpleDiscriminator': {
          'anyOf': [
            {r'$ref': '#/components/schemas/Reference'},
            {r'$ref': '#/components/schemas/InlineAnyOf'},
          ],
          'discriminator': {'propertyName': 'disc'},
        },
        'DeepNestedAnyOf': {
          'anyOf': [
            {'type': 'string'},
            {
              'anyOf': [
                {'type': 'integer'},
                {
                  'anyOf': [
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

  test('Imports anyOf with inline schema', () {
    final api = Importer().import(fileContent);

    final inlineAnyOf = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'InlineAnyOf',
    );

    expect(inlineAnyOf, isA<AnyOfModel>());
    expect((inlineAnyOf as AnyOfModel).models, hasLength(2));

    final stringModel = inlineAnyOf.models.first;
    expect(stringModel.model, isA<StringModel>());
    expect(stringModel.discriminatorValue, isNull);

    final objectModel = inlineAnyOf.models.last;
    expect(objectModel.model, isA<ClassModel>());
    expect(objectModel.discriminatorValue, isNull);

    expect(api.models, contains(objectModel.model));
    expect(api.models.contains(stringModel.model), isFalse);
  });

  test('Imports anyOf with reference', () {
    final api = Importer().import(fileContent);

    final referenceAnyOf = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'ReferenceAnyOf',
    );

    expect(referenceAnyOf, isA<AnyOfModel>());
    expect((referenceAnyOf as AnyOfModel).models, hasLength(2));

    final referenceModel = referenceAnyOf.models.first;
    expect(referenceModel.model, isA<ClassModel>());
    expect((referenceModel.model as ClassModel).name, 'Reference');
    expect(referenceModel.discriminatorValue, isNull);

    final stringModel = referenceAnyOf.models.last;
    expect(stringModel.model, isA<StringModel>());
    expect(stringModel.discriminatorValue, isNull);
  });

  test('Imports anyOf with discriminator', () {
    final api = Importer().import(fileContent);

    final discriminator = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'Discriminator',
    );

    expect(discriminator, isA<AnyOfModel>());
    expect((discriminator as AnyOfModel).models, hasLength(2));
    expect(discriminator.discriminator, 'disc');

    final refModel = discriminator.models.first;
    expect(refModel.model, isA<ClassModel>());
    expect(refModel.discriminatorValue, 'ref');

    final inlineModel = discriminator.models.last;
    expect(inlineModel.model, isA<AnyOfModel>());
    expect(inlineModel.discriminatorValue, 'inline');
  });

  test('Imports anyOf with discriminator but no mapping', () {
    final api = Importer().import(fileContent);

    final simpleDiscriminator = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'SimpleDiscriminator',
    );

    expect(simpleDiscriminator, isA<AnyOfModel>());
    expect((simpleDiscriminator as AnyOfModel).models, hasLength(2));
    expect(simpleDiscriminator.discriminator, 'disc');

    final refModel = simpleDiscriminator.models.first;
    expect(refModel.model, isA<ClassModel>());
    expect(refModel.discriminatorValue, 'Reference');

    final inlineModel = simpleDiscriminator.models.last;
    expect(inlineModel.model, isA<AnyOfModel>());
    expect(inlineModel.discriminatorValue, 'InlineAnyOf');
  });

  test('Imports deeply nested anyOf', () {
    final api = Importer().import(fileContent);

    final deepNested = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'DeepNestedAnyOf',
    );

    expect(deepNested, isA<AnyOfModel>());
    final level1 = deepNested as AnyOfModel;
    expect(level1.models, hasLength(2));
    expect(level1.models.first.model, isA<StringModel>());

    final level2 = level1.models.last.model;
    expect(level2, isA<AnyOfModel>());
    expect((level2 as AnyOfModel).models, hasLength(2));
    expect(api.models, contains(level2));
    expect(level2.models.first.model, isA<IntegerModel>());

    final level3 = level2.models.last.model;
    expect(level3, isA<AnyOfModel>());
    expect((level3 as AnyOfModel).models, hasLength(2));
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

  test('Imports anyOf with bare type strings as type references', () {
    const fileContent = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'AnyOfDirectPrimitive': {
            'anyOf': ['string', 'boolean'],
          },
        },
      },
    };

    final api = Importer().import(fileContent);

    final anyOfDirectPrimitive = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'AnyOfDirectPrimitive',
    );

    expect(anyOfDirectPrimitive, isA<AnyOfModel>());
    expect((anyOfDirectPrimitive as AnyOfModel).models, hasLength(2));

    final stringModel = anyOfDirectPrimitive.models.first;
    expect(stringModel.model, isA<StringModel>());

    final booleanModel = anyOfDirectPrimitive.models.last;
    expect(booleanModel.model, isA<BooleanModel>());
  });

  group('description', () {
    const anyOfWithDescription = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Payload': {
            'description': 'The request payload can be text or binary',
            'anyOf': [
              {'type': 'string'},
              {
                'type': 'object',
                'properties': {
                  'data': {'type': 'string'},
                },
              },
            ],
          },
        },
      },
    };

    const anyOfWithoutDescription = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Mixed': {
            'anyOf': [
              {'type': 'string'},
              {'type': 'integer'},
            ],
          },
        },
      },
    };

    test('import anyOf with description', () {
      final api = Importer().import(anyOfWithDescription);
      final model =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'Payload',
              )
              as AnyOfModel;

      expect(model.description, 'The request payload can be text or binary');
    });

    test('import anyOf without description', () {
      final api = Importer().import(anyOfWithoutDescription);
      final model =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'Mixed',
              )
              as AnyOfModel;

      expect(model.description, isNull);
    });
  });
}
