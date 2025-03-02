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
    expect(stringModel, isA<StringModel>());

    final objectModel = inlineAnyOf.models.last;
    expect(objectModel, isA<ClassModel>());

    expect(api.models, contains(objectModel));
    expect(api.models.contains(stringModel), isFalse);
  });

  test('Imports anyOf with reference', () {
    final api = Importer().import(fileContent);

    final referenceAnyOf = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'ReferenceAnyOf',
    );

    expect(referenceAnyOf, isA<AnyOfModel>());
    expect((referenceAnyOf as AnyOfModel).models, hasLength(2));

    final referenceModel = referenceAnyOf.models.first;
    expect(referenceModel, isA<ClassModel>());
    expect((referenceModel as ClassModel).name, 'Reference');

    final stringModel = referenceAnyOf.models.last;
    expect(stringModel, isA<StringModel>());
  });
}
