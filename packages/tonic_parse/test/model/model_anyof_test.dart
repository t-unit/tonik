import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/tonic_parse.dart';

void main() {
  const fileContent = {
    'openapi': '3.0.0',
    'info': {
      'title': 'Test API',
      'version': '1.0.0',
    },
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
}
