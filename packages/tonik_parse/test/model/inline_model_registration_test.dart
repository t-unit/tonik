import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('inline unnamed models are registered in api.models', () {
    group(r'array items with $ref + annotation siblings', () {
      test(
        r'array items with $ref + nullable type array '
        'registers unnamed AliasModel',
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
                'Container': {
                  'type': 'object',
                  'properties': {
                    'nullablePets': {
                      'type': 'array',
                      'items': {
                        r'$ref': '#/components/schemas/Pet',
                        'type': ['object', 'null'],
                      },
                    },
                  },
                },
              },
            },
          };

          final api = Importer().import(fileContent);

          final pet = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'Pet',
          );
          expect(pet, isA<ClassModel>());

          final container = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'Container',
          );
          expect(container, isA<ClassModel>());

          final containerClass = container! as ClassModel;
          final nullablePetsProp = containerClass.properties.firstWhereOrNull(
            (p) => p.name == 'nullablePets',
          );
          expect(nullablePetsProp, isNotNull);
          expect(nullablePetsProp!.model, isA<ListModel>());

          final listModel = nullablePetsProp.model as ListModel;
          expect(listModel.content, isA<AliasModel>());

          final aliasContent = listModel.content as AliasModel;
          expect(aliasContent.isNullable, isTrue);
          expect(aliasContent.model, pet);

          // All models must be registered
          expect(api.models, containsAll([pet, container, aliasContent]));
        },
      );

      test(
        r'array items with $ref + description registers unnamed AliasModel',
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
                'Container': {
                  'type': 'object',
                  'properties': {
                    'describedPets': {
                      'type': 'array',
                      'items': {
                        r'$ref': '#/components/schemas/Pet',
                        'description': 'A pet with documentation',
                      },
                    },
                  },
                },
              },
            },
          };

          final api = Importer().import(fileContent);

          final container = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'Container',
          );
          expect(container, isNotNull);

          final containerClass = container! as ClassModel;
          final describedPetsProp = containerClass.properties.firstWhereOrNull(
            (p) => p.name == 'describedPets',
          );
          expect(describedPetsProp, isNotNull);

          final listModel = describedPetsProp!.model as ListModel;
          expect(listModel.content, isA<AliasModel>());

          final aliasContent = listModel.content as AliasModel;
          expect(aliasContent.description, 'A pet with documentation');

          final pet = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'Pet',
          );
          expect(aliasContent.model, pet);

          // All models must be registered
          expect(api.models, containsAll([pet, container, aliasContent]));
        },
      );

      test(
        r'array items with $ref + deprecated registers unnamed AliasModel',
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
                'Container': {
                  'type': 'object',
                  'properties': {
                    'deprecatedPets': {
                      'type': 'array',
                      'items': {
                        r'$ref': '#/components/schemas/Pet',
                        'deprecated': true,
                      },
                    },
                  },
                },
              },
            },
          };

          final api = Importer().import(fileContent);

          final container = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'Container',
          );
          expect(container, isNotNull);

          final containerClass = container! as ClassModel;
          final deprecatedPetsProp = containerClass.properties.firstWhereOrNull(
            (p) => p.name == 'deprecatedPets',
          );
          expect(deprecatedPetsProp, isNotNull);

          final listModel = deprecatedPetsProp!.model as ListModel;
          expect(listModel.content, isA<AliasModel>());

          final aliasContent = listModel.content as AliasModel;
          expect(aliasContent.isDeprecated, isTrue);

          final pet = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'Pet',
          );
          expect(aliasContent.model, pet);

          // All models must be registered
          expect(api.models, containsAll([pet, container, aliasContent]));
        },
      );
    });

    group(r'object properties with $ref + annotation siblings', () {
      test(
        r'property with $ref + nullable captures nullability on Property',
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
                'Owner': {
                  'type': 'object',
                  'properties': {
                    'optionalPet': {
                      r'$ref': '#/components/schemas/Pet',
                      'type': ['object', 'null'],
                    },
                  },
                },
              },
            },
          };

          final api = Importer().import(fileContent);

          final owner = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'Owner',
          );
          expect(owner, isNotNull);

          final pet = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'Pet',
          );
          expect(pet, isA<ClassModel>());

          final ownerClass = owner! as ClassModel;
          final optionalPetProp = ownerClass.properties.firstWhereOrNull(
            (p) => p.name == 'optionalPet',
          );
          expect(optionalPetProp, isNotNull);

          expect(optionalPetProp!.model, pet);
          expect(optionalPetProp.isNullable, isTrue);

          // All models must be registered
          expect(api.models, containsAll([pet, owner]));
        },
      );
    });

    group(r'nested array items with $ref + structural siblings', () {
      test(
        r'array items with $ref + properties registers unnamed AllOfModel',
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
                'Container': {
                  'type': 'object',
                  'properties': {
                    'extendedPets': {
                      'type': 'array',
                      'items': {
                        r'$ref': '#/components/schemas/Pet',
                        'properties': {
                          'extraField': {'type': 'string'},
                        },
                      },
                    },
                  },
                },
              },
            },
          };

          final api = Importer().import(fileContent);

          final container = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'Container',
          );
          expect(container, isNotNull);

          final containerClass = container! as ClassModel;
          final extendedPetsProp = containerClass.properties.firstWhereOrNull(
            (p) => p.name == 'extendedPets',
          );
          expect(extendedPetsProp, isNotNull);

          final listModel = extendedPetsProp!.model as ListModel;
          expect(listModel.content, isA<AllOfModel>());

          final allOfContent = listModel.content as AllOfModel;

          // The AllOfModel should be registered for code generation
          expect(
            api.models.contains(allOfContent),
            isTrue,
            reason:
                'AllOfModel for array items with structural siblings '
                'should be registered in api.models',
          );

          // The inline ClassModel from properties should also be registered
          final inlineClass = allOfContent.models.firstWhereOrNull(
            (m) => m is ClassModel && m.name == null,
          );
          expect(inlineClass, isNotNull);
          expect(
            api.models.contains(inlineClass),
            isTrue,
            reason:
                'Inline ClassModel from structural siblings should be '
                'registered in api.models',
          );
        },
      );
    });

    group('deeply nested inline models', () {
      test(
        r'nested $ref with siblings in array items registers all models',
        () {
          const fileContent = {
            'openapi': '3.1.0',
            'info': {'title': 'Test API', 'version': '1.0.0'},
            'paths': <String, dynamic>{},
            'components': {
              'schemas': {
                'User': {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                  },
                },
                'Item': {
                  'type': 'object',
                  'properties': {
                    'id': {'type': 'integer'},
                  },
                },
                'Container': {
                  'type': 'object',
                  'properties': {
                    'items': {
                      'type': 'array',
                      'items': {
                        r'$ref': '#/components/schemas/Item',
                        'properties': {
                          'owner': {
                            r'$ref': '#/components/schemas/User',
                            'type': ['object', 'null'],
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          };

          final api = Importer().import(fileContent);

          final user = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'User',
          );
          expect(user, isA<ClassModel>());

          final item = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'Item',
          );
          expect(item, isA<ClassModel>());

          final container = api.models.firstWhereOrNull(
            (m) => m is NamedModel && m.name == 'Container',
          );
          expect(container, isA<ClassModel>());

          final containerClass = container! as ClassModel;
          final itemsProp = containerClass.properties.firstWhereOrNull(
            (p) => p.name == 'items',
          );
          expect(itemsProp, isNotNull);

          final listModel = itemsProp!.model as ListModel;
          expect(listModel.content, isA<AllOfModel>());

          final allOfContent = listModel.content as AllOfModel;

          final inlineClass = allOfContent.models
              .whereType<ClassModel>()
              .firstWhereOrNull(
                (m) => m.properties.any((p) => p.name == 'owner'),
              );
          expect(inlineClass, isNotNull);

          final ownerProp = inlineClass!.properties.firstWhereOrNull(
            (p) => p.name == 'owner',
          );
          expect(ownerProp, isNotNull);
          expect(ownerProp!.model, user);
          expect(ownerProp.isNullable, isTrue);

          // All models must be registered
          expect(
            api.models,
            containsAll([user, item, container, allOfContent, inlineClass]),
          );
        },
      );
    });
  });
}
