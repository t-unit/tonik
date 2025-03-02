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
        'InlineAllOf': {
          'allOf': [
            {'type': 'string'},
            {
              'type': 'object',
              'properties': {
                'foo': {'type': 'string'},
              },
            },
          ],
        },
        'ReferenceAllOf': {
          'allOf': [
            {r'$ref': '#/components/schemas/Reference'},
            {'type': 'string'},
          ],
        },
      },
    },
  };

  test('Imports allOf with inline schema', () {
    final api = Importer().import(fileContent);

    final inlineAllOf = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'InlineAllOf',
    );

    expect(inlineAllOf, isA<AllOfModel>());
    expect((inlineAllOf as AllOfModel).models, hasLength(2));

    final stringModel = inlineAllOf.models.first;
    expect(stringModel, isA<StringModel>());

    final objectModel = inlineAllOf.models.last;
    expect(objectModel, isA<ClassModel>());
    expect(api.models, contains(objectModel));
    expect(api.models.contains(stringModel), isFalse);
  });

  test('Imports allOf with reference', () {
    final api = Importer().import(fileContent);

    final referenceAllOf = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'ReferenceAllOf',
    );

    expect(referenceAllOf, isA<AllOfModel>());
    expect((referenceAllOf as AllOfModel).models, hasLength(2));

    final referenceModel = referenceAllOf.models.first;
    expect(referenceModel, isA<ClassModel>());
    expect((referenceModel as ClassModel).name, 'Reference');

    final stringModel = referenceAllOf.models.last;
    expect(stringModel, isA<StringModel>());
  });
}
