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
    expect(stringModel, isA<StringModel>());

    final objectModel = inlineOneOf.models.last;
    expect(objectModel, isA<ClassModel>());

    expect(api.models, contains(objectModel));
    expect(api.models.contains(stringModel), isFalse);
  });

  test('Imports oneOf with reference', () {
    final api = Importer().import(fileContent);

    final referenceOneOf = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'ReferenceOneOf',
    );

    expect(referenceOneOf, isA<OneOfModel>());
    expect((referenceOneOf as OneOfModel).models, hasLength(2));

    final referenceModel = referenceOneOf.models.first;
    expect(referenceModel, isA<ClassModel>());
    expect((referenceModel as ClassModel).name, 'Reference');

    final stringModel = referenceOneOf.models.last;
    expect(stringModel, isA<StringModel>());
  });
}
