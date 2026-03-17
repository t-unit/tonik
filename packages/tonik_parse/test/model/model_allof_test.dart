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

    expect(api.models, contains(anonymousClass));
  });

  test('Imports allOf with bare type strings as type references', () {
    const fileContent = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'AllOfDirectPrimitive': {
            'allOf': ['integer', 'number'],
          },
        },
      },
    };

    final api = Importer().import(fileContent);

    final allOfDirectPrimitive = api.models.firstWhere(
      (m) => m is NamedModel && m.name == 'AllOfDirectPrimitive',
    );

    expect(allOfDirectPrimitive, isA<AllOfModel>());
    expect((allOfDirectPrimitive as AllOfModel).models, hasLength(2));

    final integerModel = allOfDirectPrimitive.models.first;
    expect(integerModel, isA<IntegerModel>());

    final numberModel = allOfDirectPrimitive.models.last;
    expect(numberModel, isA<NumberModel>());
  });

  group('description', () {
    const allOfWithDescription = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'ExtendedUser': {
            'description': 'A user with extended attributes',
            'allOf': [
              {
                'type': 'object',
                'properties': {
                  'id': {'type': 'integer'},
                },
              },
              {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
              },
            ],
          },
        },
      },
    };

    const allOfWithoutDescription = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'CombinedModel': {
            'allOf': [
              {
                'type': 'object',
                'properties': {
                  'foo': {'type': 'string'},
                },
              },
            ],
          },
        },
      },
    };

    test('import allOf with description', () {
      final api = Importer().import(allOfWithDescription);
      final model =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'ExtendedUser',
              )
              as AllOfModel;

      expect(model.description, 'A user with extended attributes');
    });

    test('import allOf without description', () {
      final api = Importer().import(allOfWithoutDescription);
      final model =
          api.models.firstWhere(
                (m) => m is NamedModel && m.name == 'CombinedModel',
              )
              as AllOfModel;

      expect(model.description, isNull);
    });
  });

  group('bare ref alias identity in allOf', () {
    // Schemas are ordered so that the allOf referencing Base is declared
    // BEFORE Base itself. This triggers the bug where _resolveReference
    // creates a named AliasModel that is never added to models, and the
    // import() loop later creates a second instance.
    const specWithRefBeforeDeclaration = {
      'openapi': '3.0.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          // Composite is declared first and references Base via allOf
          'Composite': {
            'allOf': [
              {r'$ref': '#/components/schemas/Base'},
              {
                'type': 'object',
                'properties': {
                  'extra': {'type': 'string'},
                },
              },
            ],
          },
          // Base is a bare $ref alias (declared after Composite)
          'Base': {
            r'$ref': '#/components/schemas/Compact',
          },
          // Compact is the actual object
          'Compact': {
            'type': 'object',
            'properties': {
              'id': {'type': 'string'},
            },
          },
        },
      },
    };

    test(
      'allOf member and top-level model are the identical object '
      'when allOf is processed before the bare ref alias',
      () {
        final api = Importer().import(specWithRefBeforeDeclaration);

        final composite = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Composite',
        ) as AllOfModel;

        // The first allOf member should be the Base alias
        final baseInAllOf = composite.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Base',
        );

        // Base should also exist in the top-level models set
        final baseInModels = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Base',
        );

        // They must be the SAME object instance
        expect(identical(baseInAllOf, baseInModels), isTrue);
      },
    );

    test(
      'bare ref alias is present in models set even when first resolved '
      'through an allOf reference path',
      () {
        final api = Importer().import(specWithRefBeforeDeclaration);

        final baseModel = api.models.where(
          (m) => m is NamedModel && m.name == 'Base',
        );

        // Exactly one Base model should exist
        expect(baseModel, hasLength(1));
        expect(baseModel.first, isA<AliasModel>());
      },
    );

    test(
      'x-dart-name override is applied correctly when model was first '
      'created through the allOf resolution path',
      () {
        const specWithOverride = {
          'openapi': '3.0.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Composite': {
                'allOf': [
                  {r'$ref': '#/components/schemas/Base'},
                  {
                    'type': 'object',
                    'properties': {
                      'extra': {'type': 'string'},
                    },
                  },
                ],
              },
              'Base': {
                r'$ref': '#/components/schemas/Compact',
                'x-dart-name': 'MyCustomBase',
              },
              'Compact': {
                'type': 'object',
                'properties': {
                  'id': {'type': 'string'},
                },
              },
            },
          },
        };

        final api = Importer().import(specWithOverride);

        final baseModel = api.models.firstWhere(
          (m) => m is NamedModel && m.name == 'Base',
        ) as NamedModel;

        expect(baseModel.nameOverride, 'MyCustomBase');
      },
    );
  });
}
