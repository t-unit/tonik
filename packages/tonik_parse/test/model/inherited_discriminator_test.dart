import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_parse/tonik_parse.dart';

void main() {
  group('Inherited discriminator via allOf', () {
    // Pattern from OAS spec:
    // - Parent schema (Pet) has discriminator
    // - Child schemas (Cat, Dog) use allOf to inherit from parent
    // - oneOf/anyOf references children and should inherit the discriminator
    const fileContent = {
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          // Parent schema with discriminator
          'Pet': {
            'type': 'object',
            'required': ['petType'],
            'properties': {
              'petType': {'type': 'string'},
              'name': {'type': 'string'},
            },
            'discriminator': {
              'propertyName': 'petType',
              'mapping': {
                'cat': '#/components/schemas/Cat',
                'dog': '#/components/schemas/Dog',
              },
            },
          },
          // Child schema using allOf to inherit from Pet
          'Cat': {
            'allOf': [
              {r'$ref': '#/components/schemas/Pet'},
              {
                'type': 'object',
                'properties': {
                  'meowVolume': {'type': 'integer'},
                },
              },
            ],
          },
          // Another child schema using allOf to inherit from Pet
          'Dog': {
            'allOf': [
              {r'$ref': '#/components/schemas/Pet'},
              {
                'type': 'object',
                'properties': {
                  'barkVolume': {'type': 'integer'},
                },
              },
            ],
          },
          // oneOf that references children - should inherit discriminator
          // from Pet
          'PetResponse': {
            'oneOf': [
              {r'$ref': '#/components/schemas/Cat'},
              {r'$ref': '#/components/schemas/Dog'},
            ],
          },
          // anyOf that references children - should also inherit discriminator
          'PetRequest': {
            'anyOf': [
              {r'$ref': '#/components/schemas/Cat'},
              {r'$ref': '#/components/schemas/Dog'},
            ],
          },
        },
      },
    };

    test('oneOf inherits discriminator propertyName from parent schema', () {
      final api = Importer().import(fileContent);

      final petResponse = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'PetResponse',
      );

      expect(petResponse, isA<OneOfModel>());
      expect((petResponse as OneOfModel).discriminator, 'petType');
    });

    test(
      'oneOf alternatives have discriminator values from parent mapping',
      () {
        final api = Importer().import(fileContent);

        final petResponse =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'PetResponse',
                )
                as OneOfModel;

        expect(petResponse.models, hasLength(2));

        // Get discriminator values as a set
        final discriminatorValues = petResponse.models
            .map((m) => m.discriminatorValue)
            .toSet();

        expect(discriminatorValues, containsAll(['cat', 'dog']));
      },
    );

    test('anyOf inherits discriminator propertyName from parent schema', () {
      final api = Importer().import(fileContent);

      final petRequest = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'PetRequest',
      );

      expect(petRequest, isA<AnyOfModel>());
      expect((petRequest as AnyOfModel).discriminator, 'petType');
    });

    test(
      'anyOf alternatives have discriminator values from parent mapping',
      () {
        final api = Importer().import(fileContent);

        final petRequest =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'PetRequest',
                )
                as AnyOfModel;

        expect(petRequest.models, hasLength(2));

        // Get discriminator values as a set
        final discriminatorValues = petRequest.models
            .map((m) => m.discriminatorValue)
            .toSet();

        expect(discriminatorValues, containsAll(['cat', 'dog']));
      },
    );
  });

  group('Inherited discriminator without explicit mapping', () {
    // When no mapping is provided, schema names should be used as values
    const fileContent = {
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Animal': {
            'type': 'object',
            'required': ['animalType'],
            'properties': {
              'animalType': {'type': 'string'},
            },
            'discriminator': {
              'propertyName': 'animalType',
              // No mapping - should use schema names
            },
          },
          'Bird': {
            'allOf': [
              {r'$ref': '#/components/schemas/Animal'},
              {
                'type': 'object',
                'properties': {
                  'wingspan': {'type': 'integer'},
                },
              },
            ],
          },
          'Fish': {
            'allOf': [
              {r'$ref': '#/components/schemas/Animal'},
              {
                'type': 'object',
                'properties': {
                  'finCount': {'type': 'integer'},
                },
              },
            ],
          },
          'AnimalChoice': {
            'oneOf': [
              {r'$ref': '#/components/schemas/Bird'},
              {r'$ref': '#/components/schemas/Fish'},
            ],
          },
        },
      },
    };

    test(
      'uses schema names as discriminator values when no mapping provided',
      () {
        final api = Importer().import(fileContent);

        final animalChoice =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'AnimalChoice',
                )
                as OneOfModel;

        expect(animalChoice.discriminator, 'animalType');
        expect(animalChoice.models, hasLength(2));

        // Get discriminator values as a set
        final discriminatorValues = animalChoice.models
            .map((m) => m.discriminatorValue)
            .toSet();

        expect(discriminatorValues, containsAll(['Bird', 'Fish']));
      },
    );
  });

  group(
    'No inherited discriminator when not all alternatives share '
    'parent',
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
                'petType': {'type': 'string'},
              },
              'discriminator': {
                'propertyName': 'petType',
              },
            },
            'Cat': {
              'allOf': [
                {r'$ref': '#/components/schemas/Pet'},
                {
                  'type': 'object',
                  'properties': {
                    'meowVolume': {'type': 'integer'},
                  },
                },
              ],
            },
            // Standalone schema that does NOT inherit from Pet
            'Robot': {
              'type': 'object',
              'properties': {
                'batteryLevel': {'type': 'integer'},
              },
            },
            // oneOf mixing an allOf child and a standalone - no inherited
            // discriminator
            'MixedChoice': {
              'oneOf': [
                {r'$ref': '#/components/schemas/Cat'},
                {r'$ref': '#/components/schemas/Robot'},
              ],
            },
          },
        },
      };

      test(
        'does not inherit discriminator when alternatives have different '
        'parents',
        () {
          final api = Importer().import(fileContent);

          final mixedChoice = api.models.firstWhere(
            (m) => m is NamedModel && m.name == 'MixedChoice',
          );

          expect(mixedChoice, isA<OneOfModel>());
          expect((mixedChoice as OneOfModel).discriminator, isNull);

          // No discriminator values should be set
          for (final model in mixedChoice.models) {
            expect(model.discriminatorValue, isNull);
          }
        },
      );
    },
  );

  group(r'Inherited discriminator via allOf with $defs', () {
    // Pattern where parent schema with discriminator is defined in $defs
    // instead of components/schemas
    const fileContent = {
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Wrapper': {
            r'$defs': {
              // Parent schema with discriminator defined in $defs
              'Animal': {
                'type': 'object',
                'required': ['animalType'],
                'properties': {
                  'animalType': {'type': 'string'},
                  'name': {'type': 'string'},
                },
                'discriminator': {
                  'propertyName': 'animalType',
                  'mapping': {
                    'lion': r'#/components/schemas/Wrapper/$defs/Lion',
                    'eagle': r'#/components/schemas/Wrapper/$defs/Eagle',
                  },
                },
              },
              // Child schema using allOf to inherit from Animal in $defs
              'Lion': {
                'allOf': [
                  {r'$ref': r'#/components/schemas/Wrapper/$defs/Animal'},
                  {
                    'type': 'object',
                    'properties': {
                      'roarVolume': {'type': 'integer'},
                    },
                  },
                ],
              },
              // Another child schema using allOf
              'Eagle': {
                'allOf': [
                  {r'$ref': r'#/components/schemas/Wrapper/$defs/Animal'},
                  {
                    'type': 'object',
                    'properties': {
                      'wingspan': {'type': 'integer'},
                    },
                  },
                ],
              },
            },
            // oneOf that references children from $defs
            'oneOf': [
              {r'$ref': r'#/components/schemas/Wrapper/$defs/Lion'},
              {r'$ref': r'#/components/schemas/Wrapper/$defs/Eagle'},
            ],
          },
        },
      },
    };

    test(r'oneOf inherits discriminator from parent in $defs', () {
      final api = Importer().import(fileContent);

      final wrapper = api.models.firstWhere(
        (m) => m is NamedModel && m.name == 'Wrapper',
      );

      expect(wrapper, isA<OneOfModel>());
      expect((wrapper as OneOfModel).discriminator, 'animalType');
    });

    test(
      r'alternatives have discriminator values from $defs parent mapping',
      () {
        final api = Importer().import(fileContent);

        final wrapper =
            api.models.firstWhere((m) => m is NamedModel && m.name == 'Wrapper')
                as OneOfModel;

        expect(wrapper.models, hasLength(2));

        final discriminatorValues = wrapper.models
            .map((m) => m.discriminatorValue)
            .toSet();

        expect(discriminatorValues, containsAll(['lion', 'eagle']));
      },
    );
  });

  group(r'Inherited discriminator with $defs - no mapping', () {
    // When no mapping is provided, schema names from $defs should be used
    const fileContent = {
      'openapi': '3.1.0',
      'info': {'title': 'Test API', 'version': '1.0.0'},
      'paths': <String, dynamic>{},
      'components': {
        'schemas': {
          'Container': {
            r'$defs': {
              'Shape': {
                'type': 'object',
                'required': ['shapeType'],
                'properties': {
                  'shapeType': {'type': 'string'},
                },
                'discriminator': {
                  'propertyName': 'shapeType',
                  // No mapping - should use schema names
                },
              },
              'Circle': {
                'allOf': [
                  {r'$ref': r'#/components/schemas/Container/$defs/Shape'},
                  {
                    'type': 'object',
                    'properties': {
                      'radius': {'type': 'number'},
                    },
                  },
                ],
              },
              'Square': {
                'allOf': [
                  {r'$ref': r'#/components/schemas/Container/$defs/Shape'},
                  {
                    'type': 'object',
                    'properties': {
                      'side': {'type': 'number'},
                    },
                  },
                ],
              },
            },
            'oneOf': [
              {r'$ref': r'#/components/schemas/Container/$defs/Circle'},
              {r'$ref': r'#/components/schemas/Container/$defs/Square'},
            ],
          },
        },
      },
    };

    test(
      'uses schema names as discriminator values when no mapping provided',
      () {
        final api = Importer().import(fileContent);

        final container =
            api.models.firstWhere(
                  (m) => m is NamedModel && m.name == 'Container',
                )
                as OneOfModel;

        expect(container.discriminator, 'shapeType');
        expect(container.models, hasLength(2));

        final discriminatorValues = container.models
            .map((m) => m.discriminatorValue)
            .toSet();

        expect(discriminatorValues, containsAll(['Circle', 'Square']));
      },
    );
  });
}
