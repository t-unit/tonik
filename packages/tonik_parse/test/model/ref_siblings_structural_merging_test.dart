import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group(r'$ref + properties structural merging', () {
    test(r'creates AllOfModel when $ref has properties sibling', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Pet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'age': {'type': 'integer'},
              },
            },
            'ExtendedPet': {
              r'$ref': '#/components/schemas/Pet',
              'properties': {
                'nickname': {'type': 'string'},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final extendedPet = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'ExtendedPet',
      );
      expect(extendedPet, isNotNull);

      expect(extendedPet, isA<AllOfModel>());
      final allOfModel = extendedPet! as AllOfModel;

      expect(allOfModel.models, hasLength(2));

      final petRef = allOfModel.models.whereType<ClassModel>().firstWhereOrNull(
        (m) => m.name == 'Pet',
      );
      expect(petRef, isNotNull);
      expect(
        petRef!.properties.map((p) => p.name),
        containsAll(['name', 'age']),
      );

      final inlineClass = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull(
            (m) => m.name != 'Pet',
          );
      expect(inlineClass, isNotNull);
      expect(inlineClass!.properties.map((p) => p.name), contains('nickname'));

      expect(api.models, contains(inlineClass));
    });

    test(r'preserves required field from $ref + properties', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'BaseModel': {
              'type': 'object',
              'properties': {
                'id': {'type': 'integer'},
              },
              'required': ['id'],
            },
            'ExtendedModel': {
              r'$ref': '#/components/schemas/BaseModel',
              'properties': {
                'extraField': {'type': 'string'},
              },
              'required': ['extraField'],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final extendedModel = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'ExtendedModel',
      );
      expect(extendedModel, isNotNull);

      expect(extendedModel, isA<AllOfModel>());
      final allOfModel = extendedModel! as AllOfModel;

      final inlineClass = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull(
            (m) => m.properties.any((p) => p.name == 'extraField'),
          );
      expect(inlineClass, isNotNull);
      final extraField = inlineClass!.properties.firstWhereOrNull(
        (p) => p.name == 'extraField',
      );
      expect(extraField, isNotNull);
      expect(extraField!.isRequired, isTrue);

      expect(api.models, contains(inlineClass));
    });

    test(r'handles $ref + properties + description', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Pet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'DescribedExtendedPet': {
              r'$ref': '#/components/schemas/Pet',
              'description': 'An extended pet with a tag',
              'properties': {
                'tag': {'type': 'string'},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final described = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'DescribedExtendedPet',
      );
      expect(described, isNotNull);

      expect(described, isA<AllOfModel>());
      final allOfModel = described! as AllOfModel;
      expect(allOfModel.description, 'An extended pet with a tag');
      expect(allOfModel.models, hasLength(2));

      final petRef = allOfModel.models.whereType<ClassModel>().firstWhereOrNull(
        (m) => m.name == 'Pet',
      );
      expect(petRef, isNotNull);
      expect(petRef!.properties.map((p) => p.name), contains('name'));

      final inlineClass = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull((m) => m.name != 'Pet');
      expect(inlineClass, isNotNull);
      expect(inlineClass!.properties.map((p) => p.name), contains('tag'));
      expect(api.models, contains(inlineClass));
    });

    test(r'handles $ref + properties with nullable type array', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Pet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'NullableExtendedPet': {
              r'$ref': '#/components/schemas/Pet',
              'type': ['object', 'null'],
              'properties': {
                'optionalTag': {'type': 'string'},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final nullable = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'NullableExtendedPet',
      );
      expect(nullable, isNotNull);

      expect(nullable, isA<AllOfModel>());
      final allOfModel = nullable! as AllOfModel;
      expect(allOfModel.isNullable, isTrue);
      expect(allOfModel.models, hasLength(2));

      final petRef = allOfModel.models.whereType<ClassModel>().firstWhereOrNull(
        (m) => m.name == 'Pet',
      );
      expect(petRef, isNotNull);
      expect(petRef!.properties.map((p) => p.name), contains('name'));

      final inlineClass = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull((m) => m.name != 'Pet');
      expect(inlineClass, isNotNull);
      expect(
        inlineClass!.properties.map((p) => p.name),
        contains('optionalTag'),
      );
      expect(api.models, contains(inlineClass));
    });
  });

  group(r'$ref + allOf structural merging', () {
    test(r'prepends $ref target to allOf list', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'NamedEntity': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'TimestampedEntity': {
              'type': 'object',
              'properties': {
                'createdAt': {'type': 'string', 'format': 'date-time'},
              },
            },
            'MergedEntity': {
              r'$ref': '#/components/schemas/NamedEntity',
              'allOf': [
                {r'$ref': '#/components/schemas/TimestampedEntity'},
              ],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final merged = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'MergedEntity',
      );
      expect(merged, isNotNull);

      expect(merged, isA<AllOfModel>());
      final allOfModel = merged! as AllOfModel;

      expect(allOfModel.models, hasLength(2));

      final namedEntity = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull(
            (m) => m.name == 'NamedEntity',
          );
      expect(namedEntity, isNotNull);
      expect(namedEntity!.properties.map((p) => p.name), contains('name'));

      final timestamped = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull(
            (m) => m.name == 'TimestampedEntity',
          );
      expect(timestamped, isNotNull);
      expect(
        timestamped!.properties.map((p) => p.name),
        contains('createdAt'),
      );
    });

    test(r'handles $ref + allOf with inline schemas', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'BaseEntity': {
              'type': 'object',
              'properties': {
                'id': {'type': 'integer'},
              },
            },
            'EnhancedEntity': {
              r'$ref': '#/components/schemas/BaseEntity',
              'allOf': [
                {
                  'type': 'object',
                  'properties': {
                    'extra': {'type': 'string'},
                  },
                },
              ],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final enhanced = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'EnhancedEntity',
      );
      expect(enhanced, isNotNull);

      expect(enhanced, isA<AllOfModel>());
      final allOfModel = enhanced! as AllOfModel;
      expect(allOfModel.models, hasLength(2));

      final baseEntity = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull(
            (m) => m.name == 'BaseEntity',
          );
      expect(baseEntity, isNotNull);
      expect(baseEntity!.properties.map((p) => p.name), contains('id'));

      final inlineClass = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull(
            (m) => m.name != 'BaseEntity',
          );
      expect(inlineClass, isNotNull);
      expect(inlineClass!.properties.map((p) => p.name), contains('extra'));

      expect(api.models, contains(inlineClass));
    });

    test(r'handles $ref + allOf with multiple allOf members', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'A': {
              'type': 'object',
              'properties': {
                'a': {'type': 'string'},
              },
            },
            'B': {
              'type': 'object',
              'properties': {
                'b': {'type': 'string'},
              },
            },
            'C': {
              'type': 'object',
              'properties': {
                'c': {'type': 'string'},
              },
            },
            'Combined': {
              r'$ref': '#/components/schemas/A',
              'allOf': [
                {r'$ref': '#/components/schemas/B'},
                {r'$ref': '#/components/schemas/C'},
              ],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final combined = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'Combined',
      );
      expect(combined, isNotNull);

      expect(combined, isA<AllOfModel>());
      final allOfModel = combined! as AllOfModel;

      expect(allOfModel.models, hasLength(3));

      final names = allOfModel.models
          .whereType<ClassModel>()
          .map((m) => m.name)
          .toSet();
      expect(names, containsAll(['A', 'B', 'C']));
    });
  });

  group(r'$ref + oneOf structural merging', () {
    test('creates AllOfModel with nested OneOfModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Pet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'Dog': {
              'type': 'object',
              'properties': {
                'breed': {'type': 'string'},
              },
            },
            'Cat': {
              'type': 'object',
              'properties': {
                'color': {'type': 'string'},
              },
            },
            'SpecificPet': {
              r'$ref': '#/components/schemas/Pet',
              'oneOf': [
                {r'$ref': '#/components/schemas/Dog'},
                {r'$ref': '#/components/schemas/Cat'},
              ],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final specificPet = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'SpecificPet',
      );
      expect(specificPet, isNotNull);

      expect(specificPet, isA<AllOfModel>());
      final allOfModel = specificPet! as AllOfModel;

      expect(allOfModel.models, hasLength(2));

      final petModel = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull(
            (m) => m.name == 'Pet',
          );
      expect(petModel, isNotNull);

      final oneOfModel = allOfModel.models.whereType<OneOfModel>().firstOrNull;
      expect(oneOfModel, isNotNull);
      expect(oneOfModel!.models, hasLength(2));

      final oneOfNames = oneOfModel.models.map((m) {
        final model = m.model;
        return model is ClassModel ? model.name : null;
      }).toSet();
      expect(oneOfNames, containsAll(['Dog', 'Cat']));

      expect(api.models, contains(oneOfModel));
    });

    test(r'handles $ref + oneOf with discriminator', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Animal': {
              'type': 'object',
              'properties': {
                'type': {'type': 'string'},
              },
            },
            'Dog': {
              'type': 'object',
              'properties': {
                'breed': {'type': 'string'},
              },
            },
            'Cat': {
              'type': 'object',
              'properties': {
                'color': {'type': 'string'},
              },
            },
            'DiscriminatedPet': {
              r'$ref': '#/components/schemas/Animal',
              'oneOf': [
                {r'$ref': '#/components/schemas/Dog'},
                {r'$ref': '#/components/schemas/Cat'},
              ],
              'discriminator': {
                'propertyName': 'type',
                'mapping': {
                  'dog': '#/components/schemas/Dog',
                  'cat': '#/components/schemas/Cat',
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final discriminated = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'DiscriminatedPet',
      );
      expect(discriminated, isNotNull);

      expect(discriminated, isA<AllOfModel>());
      final allOfModel = discriminated! as AllOfModel;
      expect(allOfModel.models, hasLength(2));

      final animalModel = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull((m) => m.name == 'Animal');
      expect(animalModel, isNotNull);
      expect(animalModel!.properties.map((p) => p.name), contains('type'));

      final oneOfModel = allOfModel.models.whereType<OneOfModel>().firstOrNull;
      expect(oneOfModel, isNotNull);
      expect(oneOfModel!.discriminator, 'type');
      expect(oneOfModel.models, hasLength(2));

      final oneOfNames = oneOfModel.models.map((m) {
        final model = m.model;
        return model is ClassModel ? model.name : null;
      }).toSet();
      expect(oneOfNames, containsAll(['Dog', 'Cat']));
      expect(api.models, contains(oneOfModel));
    });
  });

  group(r'$ref + anyOf structural merging', () {
    test('creates AllOfModel with nested AnyOfModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'BaseRecord': {
              'type': 'object',
              'properties': {
                'id': {'type': 'integer'},
              },
            },
            'OptionA': {
              'type': 'object',
              'properties': {
                'optionA': {'type': 'boolean'},
              },
            },
            'OptionB': {
              'type': 'object',
              'properties': {
                'optionB': {'type': 'boolean'},
              },
            },
            'FlexibleRecord': {
              r'$ref': '#/components/schemas/BaseRecord',
              'anyOf': [
                {r'$ref': '#/components/schemas/OptionA'},
                {r'$ref': '#/components/schemas/OptionB'},
              ],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final flexible = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'FlexibleRecord',
      );
      expect(flexible, isNotNull);

      expect(flexible, isA<AllOfModel>());
      final allOfModel = flexible! as AllOfModel;

      expect(allOfModel.models, hasLength(2));

      final baseRecord = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull(
            (m) => m.name == 'BaseRecord',
          );
      expect(baseRecord, isNotNull);

      final anyOfModel = allOfModel.models.whereType<AnyOfModel>().firstOrNull;
      expect(anyOfModel, isNotNull);
      expect(anyOfModel!.models, hasLength(2));

      expect(api.models, contains(anyOfModel));
    });

    test(r'handles $ref + anyOf with discriminator', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Shape': {
              'type': 'object',
              'properties': {
                'shapeType': {'type': 'string'},
              },
            },
            'Circle': {
              'type': 'object',
              'properties': {
                'radius': {'type': 'number'},
              },
            },
            'Square': {
              'type': 'object',
              'properties': {
                'side': {'type': 'number'},
              },
            },
            'DiscriminatedShape': {
              r'$ref': '#/components/schemas/Shape',
              'anyOf': [
                {r'$ref': '#/components/schemas/Circle'},
                {r'$ref': '#/components/schemas/Square'},
              ],
              'discriminator': {
                'propertyName': 'shapeType',
                'mapping': {
                  'circle': '#/components/schemas/Circle',
                  'square': '#/components/schemas/Square',
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final discriminated = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'DiscriminatedShape',
      );
      expect(discriminated, isNotNull);

      expect(discriminated, isA<AllOfModel>());
      final allOfModel = discriminated! as AllOfModel;
      expect(allOfModel.models, hasLength(2));

      final shapeModel = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull((m) => m.name == 'Shape');
      expect(shapeModel, isNotNull);
      expect(shapeModel!.properties.map((p) => p.name), contains('shapeType'));

      final anyOfModel = allOfModel.models.whereType<AnyOfModel>().firstOrNull;
      expect(anyOfModel, isNotNull);
      expect(anyOfModel!.discriminator, 'shapeType');
      expect(anyOfModel.models, hasLength(2));

      final anyOfNames = anyOfModel.models.map((m) {
        final model = m.model;
        return model is ClassModel ? model.name : null;
      }).toSet();
      expect(anyOfNames, containsAll(['Circle', 'Square']));
      expect(api.models, contains(anyOfModel));
    });
  });

  group(r'$ref + multiple structural siblings', () {
    test(r'handles $ref + properties + allOf combined', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Base': {
              'type': 'object',
              'properties': {
                'baseField': {'type': 'string'},
              },
            },
            'Mixin': {
              'type': 'object',
              'properties': {
                'mixinField': {'type': 'integer'},
              },
            },
            'ComplexMerge': {
              r'$ref': '#/components/schemas/Base',
              'allOf': [
                {r'$ref': '#/components/schemas/Mixin'},
              ],
              'properties': {
                'ownField': {'type': 'boolean'},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final complex = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'ComplexMerge',
      );
      expect(complex, isNotNull);

      expect(complex, isA<AllOfModel>());
      final allOfModel = complex! as AllOfModel;

      expect(allOfModel.models, hasLength(3));

      final baseModel = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull(
            (m) => m.name == 'Base',
          );
      expect(baseModel, isNotNull);
      expect(baseModel!.properties.map((p) => p.name), contains('baseField'));

      final mixinModel = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull(
            (m) => m.name == 'Mixin',
          );
      expect(mixinModel, isNotNull);
      expect(mixinModel!.properties.map((p) => p.name), contains('mixinField'));

      final inlineClass = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull(
            (m) => m.name != 'Base' && m.name != 'Mixin',
          );
      expect(inlineClass, isNotNull);
      expect(inlineClass!.properties.map((p) => p.name), contains('ownField'));

      expect(api.models, contains(inlineClass));
    });
  });

  group(r'$ref structural merging edge cases', () {
    test(
      'circular refs with structural siblings do not cause infinite loops',
      () {
        const fileContent = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'TreeNode': {
                'type': 'object',
                'properties': {
                  'value': {'type': 'string'},
                  'children': {
                    'type': 'array',
                    'items': {r'$ref': '#/components/schemas/TreeNode'},
                  },
                },
              },
              'ExtendedTreeNode': {
                r'$ref': '#/components/schemas/TreeNode',
                'properties': {
                  'metadata': {'type': 'string'},
                },
              },
            },
          },
        };

        final api = Importer().import(fileContent);

        final extended = api.models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == 'ExtendedTreeNode',
        );
        expect(extended, isNotNull);

        expect(extended, isA<AllOfModel>());
        final allOfModel = extended! as AllOfModel;
        expect(allOfModel.models, hasLength(2));

        final treeNode = allOfModel.models
            .whereType<ClassModel>()
            .firstWhereOrNull((m) => m.name == 'TreeNode');
        expect(treeNode, isNotNull);
        expect(
          treeNode!.properties.map((p) => p.name),
          containsAll(['value', 'children']),
        );

        final inlineClass = allOfModel.models
            .whereType<ClassModel>()
            .firstWhereOrNull((m) => m.name != 'TreeNode');
        expect(inlineClass, isNotNull);
        expect(
          inlineClass!.properties.map((p) => p.name),
          contains('metadata'),
        );
        expect(api.models, contains(inlineClass));
      },
    );

    test(
      r'nested $ref siblings (ref target also has $ref with siblings)',
      () {
        const fileContent = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Level0': {
                'type': 'object',
                'properties': {
                  'level0Field': {'type': 'string'},
                },
              },
              'Level1': {
                r'$ref': '#/components/schemas/Level0',
                'properties': {
                  'level1Field': {'type': 'string'},
                },
              },
              'Level2': {
                r'$ref': '#/components/schemas/Level1',
                'properties': {
                  'level2Field': {'type': 'string'},
                },
              },
            },
          },
        };

        final api = Importer().import(fileContent);

        // Verify Level1 structure
        final level1 = api.models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == 'Level1',
        );
        expect(level1, isNotNull);
        expect(level1, isA<AllOfModel>());
        final level1AllOf = level1! as AllOfModel;
        expect(level1AllOf.models, hasLength(2));

        final level0InLevel1 = level1AllOf.models
            .whereType<ClassModel>()
            .firstWhereOrNull((m) => m.name == 'Level0');
        expect(level0InLevel1, isNotNull);
        expect(
          level0InLevel1!.properties.map((p) => p.name),
          contains('level0Field'),
        );

        final level1Inline = level1AllOf.models
            .whereType<ClassModel>()
            .firstWhereOrNull((m) => m.name != 'Level0');
        expect(level1Inline, isNotNull);
        expect(
          level1Inline!.properties.map((p) => p.name),
          contains('level1Field'),
        );
        expect(api.models, contains(level1Inline));

        // Verify Level2 structure
        final level2 = api.models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == 'Level2',
        );
        expect(level2, isNotNull);
        expect(level2, isA<AllOfModel>());
        final level2AllOf = level2! as AllOfModel;
        expect(level2AllOf.models, hasLength(2));

        final level1InLevel2 = level2AllOf.models
            .whereType<AllOfModel>()
            .firstOrNull;
        expect(level1InLevel2, isNotNull);
        expect(level1InLevel2!.models, hasLength(2));

        final level2Inline = level2AllOf.models
            .whereType<ClassModel>()
            .firstOrNull;
        expect(level2Inline, isNotNull);
        expect(
          level2Inline!.properties.map((p) => p.name),
          contains('level2Field'),
        );
        expect(api.models, contains(level2Inline));
      },
    );

    test(r'$ref + only deprecated (no structural) creates AliasModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'NewPet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'LegacyPet': {
              r'$ref': '#/components/schemas/NewPet',
              'deprecated': true,
              'description': 'Use NewPet instead',
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final legacy = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'LegacyPet',
      );
      expect(legacy, isNotNull);

      expect(legacy, isA<AliasModel>());
      final aliasModel = legacy! as AliasModel;
      expect(aliasModel.isDeprecated, isTrue);
      expect(aliasModel.description, 'Use NewPet instead');
      expect(aliasModel.model, isA<ClassModel>());
      expect((aliasModel.model as ClassModel).name, 'NewPet');
    });

    test(r'$ref without any siblings still resolves correctly', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'OriginalPet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'PetAlias': {
              r'$ref': '#/components/schemas/OriginalPet',
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final alias = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'PetAlias',
      );
      expect(alias, isNotNull);

      // Simple $ref without siblings should create AliasModel
      expect(alias, isA<AliasModel>());
      final aliasModel = alias! as AliasModel;
      expect(aliasModel.model, isA<ClassModel>());
      expect((aliasModel.model as ClassModel).name, 'OriginalPet');
    });

    test(r'$ref + properties in nested schema position', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Address': {
              'type': 'object',
              'properties': {
                'street': {'type': 'string'},
              },
            },
            'Person': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'homeAddress': {
                  r'$ref': '#/components/schemas/Address',
                  'properties': {
                    'isPrimary': {'type': 'boolean'},
                  },
                },
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final person = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'Person',
      );
      expect(person, isNotNull);

      expect(person, isA<ClassModel>());
      final personClass = person! as ClassModel;
      expect(personClass.properties, hasLength(2));
      expect(
        personClass.properties.map((p) => p.name),
        containsAll(['name', 'homeAddress']),
      );

      final homeAddressProperty = personClass.properties.firstWhereOrNull(
        (p) => p.name == 'homeAddress',
      );
      expect(homeAddressProperty, isNotNull);

      expect(homeAddressProperty!.model, isA<AllOfModel>());
      final allOfModel = homeAddressProperty.model as AllOfModel;
      expect(allOfModel.models, hasLength(2));

      final addressRef = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull((m) => m.name == 'Address');
      expect(addressRef, isNotNull);
      expect(addressRef!.properties.map((p) => p.name), contains('street'));

      final inlineClass = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull((m) => m.name != 'Address');
      expect(inlineClass, isNotNull);
      expect(
        inlineClass!.properties.map((p) => p.name),
        contains('isPrimary'),
      );
      expect(api.models, contains(inlineClass));
    });
  });

  group(r'$ref + structural siblings with nullable', () {
    test(
      r'$ref + properties + type: [null] creates nullable AllOfModel',
      () {
        const fileContent = {
          'openapi': '3.1.0',
          'info': {'title': 'Test API', 'version': '1.0.0'},
          'paths': <String, dynamic>{},
          'components': {
            'schemas': {
              'Pet': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
              },
              'NullableExtendedPet': {
                r'$ref': '#/components/schemas/Pet',
                'type': ['object', 'null'],
                'properties': {
                  'extraField': {'type': 'string'},
                },
              },
            },
          },
        };

        final api = Importer().import(fileContent);

        final nullable = api.models.firstWhereOrNull(
          (m) => m is NamedModel && m.name == 'NullableExtendedPet',
        );
        expect(nullable, isNotNull);

        expect(nullable, isA<AllOfModel>());
        final allOfModel = nullable! as AllOfModel;
        expect(allOfModel.isNullable, isTrue);
        expect(allOfModel.models, hasLength(2));

        final petRef = allOfModel.models
            .whereType<ClassModel>()
            .firstWhereOrNull((m) => m.name == 'Pet');
        expect(petRef, isNotNull);
        expect(petRef!.properties.map((p) => p.name), contains('name'));

        final inlineClass = allOfModel.models
            .whereType<ClassModel>()
            .firstWhereOrNull((m) => m.name != 'Pet');
        expect(inlineClass, isNotNull);
        expect(
          inlineClass!.properties.map((p) => p.name),
          contains('extraField'),
        );
        expect(api.models, contains(inlineClass));
      },
    );

    test(r'$ref + oneOf + type: [null] creates nullable AllOfModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Base': {
              'type': 'object',
              'properties': {
                'id': {'type': 'integer'},
              },
            },
            'OptionA': {
              'type': 'object',
              'properties': {
                'a': {'type': 'string'},
              },
            },
            'OptionB': {
              'type': 'object',
              'properties': {
                'b': {'type': 'string'},
              },
            },
            'NullableUnion': {
              r'$ref': '#/components/schemas/Base',
              'type': ['object', 'null'],
              'oneOf': [
                {r'$ref': '#/components/schemas/OptionA'},
                {r'$ref': '#/components/schemas/OptionB'},
              ],
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final nullable = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'NullableUnion',
      );
      expect(nullable, isNotNull);

      expect(nullable, isA<AllOfModel>());
      final allOfModel = nullable! as AllOfModel;
      expect(allOfModel.isNullable, isTrue);
      expect(allOfModel.models, hasLength(2));

      final baseModel = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull((m) => m.name == 'Base');
      expect(baseModel, isNotNull);
      expect(baseModel!.properties.map((p) => p.name), contains('id'));

      final oneOfModel = allOfModel.models.whereType<OneOfModel>().firstOrNull;
      expect(oneOfModel, isNotNull);
      expect(oneOfModel!.models, hasLength(2));

      final oneOfNames = oneOfModel.models.map((m) {
        final model = m.model;
        return model is ClassModel ? model.name : null;
      }).toSet();
      expect(oneOfNames, containsAll(['OptionA', 'OptionB']));
      expect(api.models, contains(oneOfModel));
    });
  });

  group(r'$ref structural merging preserves deprecation', () {
    test(r'$ref + properties + deprecated creates deprecated AllOfModel', () {
      const fileContent = {
        'openapi': '3.1.0',
        'info': {'title': 'Test API', 'version': '1.0.0'},
        'paths': <String, dynamic>{},
        'components': {
          'schemas': {
            'Pet': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
            'DeprecatedExtendedPet': {
              r'$ref': '#/components/schemas/Pet',
              'deprecated': true,
              'properties': {
                'legacyField': {'type': 'string'},
              },
            },
          },
        },
      };

      final api = Importer().import(fileContent);

      final deprecated = api.models.firstWhereOrNull(
        (m) => m is NamedModel && m.name == 'DeprecatedExtendedPet',
      );
      expect(deprecated, isNotNull);

      expect(deprecated, isA<AllOfModel>());
      final allOfModel = deprecated! as AllOfModel;
      expect(allOfModel.isDeprecated, isTrue);
      expect(allOfModel.models, hasLength(2));

      final petRef = allOfModel.models.whereType<ClassModel>().firstWhereOrNull(
        (m) => m.name == 'Pet',
      );
      expect(petRef, isNotNull);
      expect(petRef!.properties.map((p) => p.name), contains('name'));

      final inlineClass = allOfModel.models
          .whereType<ClassModel>()
          .firstWhereOrNull((m) => m.name != 'Pet');
      expect(inlineClass, isNotNull);
      expect(
        inlineClass!.properties.map((p) => p.name),
        contains('legacyField'),
      );
      expect(api.models, contains(inlineClass));
    });
  });
}
