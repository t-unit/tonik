import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_parse/tonic_parse.dart';

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
              'inline': '#/components/schemas/InlineOneOf',
              'ref': '#/components/schemas/Reference',
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
}
