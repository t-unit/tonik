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
        'DeepNestedAllOf': {
          'allOf': [
            {
              'type': 'object',
              'properties': {
                'type': {'type': 'string'},
              },
            },
            {
              'allOf': [
                {
                  'type': 'object',
                  'properties': {
                    'id': {'type': 'integer'},
                  },
                },
                {
                  'allOf': [
                    {
                      'type': 'object',
                      'properties': {
                        'active': {'type': 'boolean'},
                      },
                    },
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

  test('Imports deeply nested allOf', () {
    final api = Importer().import(fileContent);

    final deepNested = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'DeepNestedAllOf',
    );

    expect(deepNested, isA<AllOfModel>());
    final level1 = deepNested as AllOfModel;
    expect(level1.models, hasLength(2));
    expect(level1.models.first, isA<ClassModel>());
    expect((level1.models.first as ClassModel).properties.first.name, 'type');

    final level2 = level1.models.last;
    expect(level2, isA<AllOfModel>());
    expect((level2 as AllOfModel).models, hasLength(2));
    expect(api.models, contains(level2));
    expect(level2.models.first, isA<ClassModel>());
    expect((level2.models.first as ClassModel).properties.first.name, 'id');

    final level3 = level2.models.last;
    expect(level3, isA<AllOfModel>());
    expect((level3 as AllOfModel).models, hasLength(2));
    expect(api.models, contains(level3));
    expect(level3.models.first, isA<ClassModel>());
    expect((level3.models.first as ClassModel).properties.first.name, 'active');

    final anonymousClass = level3.models.last;
    expect(anonymousClass, isA<ClassModel>());
    expect((anonymousClass as ClassModel).name, isNull);
    expect(anonymousClass.properties.length, 1);
    expect(anonymousClass.properties.first.name, 'foo');
    expect(anonymousClass.properties.first.model, isA<StringModel>());

    // Verify the anonymous class model is added to the models set
    expect(api.models, contains(anonymousClass));
  });
}
