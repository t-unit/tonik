import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/name_generator.dart';

void main() {
  group('NameGenerator', () {
    late NameGenerator nameGenerator;

    setUp(() {
      nameGenerator = NameGenerator();
    });

    group('generateClassName', () {
      group('real world examples', () {
        test('anonymous response', () {
          final model = ClassModel(
            properties: const {},
            context: Context.initial().pushAll([
              'paths',
              'pet-findByStatus',
              'get',
              'responses',
              '200',
              'content',
            ]),
          );
          expect(
            nameGenerator.generateModelName(model),
            'PetFindByStatusGetResponses200Content',
          );
        });

        test('preserves numeric components in context paths', () {
          final model = ClassModel(
            properties: const {},
            context: Context.initial().pushAll([
              'paths',
              'pet-store',
              'get',
              'responses',
              '404',
              'content',
            ]),
          );
          expect(
            nameGenerator.generateModelName(model),
            'PetStoreGetResponses404Content',
          );
        });

        test('oneOf model with inline model', () {
          // Create a OneOfModel named Blub with an inline anonymous class model
          final inlineClassModel = ClassModel(
            properties: const {},
            context: Context.initial().pushAll([
              'components',
              'schemas',
              'Blub',
            ]),
          );

          final oneOfModel = OneOfModel(
            name: 'Blub',
            models: {(discriminatorValue: null, model: inlineClassModel)},
            discriminator: null,
            context: Context.initial().pushAll(['components', 'schemas']),
          );

          // First name the oneOf model
          final oneOfName = nameGenerator.generateModelName(oneOfModel);
          // Then name the inline model
          final inlineName = nameGenerator.generateModelName(inlineClassModel);

          expect(oneOfName, 'Blub');
          expect(inlineName, 'BlubModel');
        });

        test('enum parameter in path', () {
          final enumModel = EnumModel<String>(
            values: const {'available', 'pending', 'sold'},
            isNullable: false,
            context: Context.initial().pushAll([
              'paths',
              'pet-findByTags',
              'parameter',
            ]),
          );

          expect(
            nameGenerator.generateModelName(enumModel),
            'PetFindByTagsParameter',
          );
        });
      });

      test('uses model name when available', () {
        final model = ClassModel(
          name: 'UserProfile',
          properties: const {},
          context: Context.initial(),
        );
        expect(nameGenerator.generateModelName(model), 'UserProfile');
      });

      test('converts name to PascalCase', () {
        final model = ClassModel(
          name: 'user_profile',
          properties: const {},
          context: Context.initial(),
        );
        expect(nameGenerator.generateModelName(model), 'UserProfile');
      });

      test('makes duplicate names unique using Model suffix', () {
        final model1 = ClassModel(
          name: 'User',
          properties: const {},
          context: Context.initial(),
        );
        final model2 = ClassModel(
          name: 'User',
          properties: const {},
          context: Context.initial(),
        );
        final model3 = ClassModel(
          name: 'User',
          properties: const {},
          context: Context.initial(),
        );

        final name1 = nameGenerator.generateModelName(model1);
        final name2 = nameGenerator.generateModelName(model2);
        final name3 = nameGenerator.generateModelName(model3);

        expect(name1, 'User');
        expect(name2, 'UserModel');
        expect(name3, 'UserModel2');
      });

      test('removes illegal characters', () {
        final model = ClassModel(
          name: 'User-Profile!123',
          properties: const {},
          context: Context.initial(),
        );
        expect(nameGenerator.generateModelName(model), 'UserProfile123');
      });

      test('combines context path components in PascalCase', () {
        final model = ClassModel(
          properties: const {},
          context: Context.initial().pushAll(['api', 'models', 'user']),
        );

        expect(nameGenerator.generateModelName(model), 'ApiModelsUser');
      });

      test('converts each path component to PascalCase before joining', () {
        final model = ListModel(
          content: StringModel(context: Context.initial()),
          context: Context.initial().pushAll([
            'api',
            'user_management',
            'active_users',
          ]),
        );

        expect(
          nameGenerator.generateModelName(model),
          'ApiUserManagementActiveUsers',
        );
      });

      test('converts explicit names with underscores to PascalCase', () {
        final model = ClassModel(
          name: 'my_class_name',
          properties: const {},
          context: Context.initial(),
        );

        expect(nameGenerator.generateModelName(model), 'MyClassName');
      });

      test('converts names with leading underscores to PascalCase', () {
        final model = ClassModel(
          name: '_my_class_name',
          properties: const {},
          context: Context.initial(),
        );

        expect(nameGenerator.generateModelName(model), 'MyClassName');
      });

      test('uses Anonymous for model without name or context path', () {
        final model = ClassModel(
          properties: const {},
          context: Context.initial(),
        );

        expect(nameGenerator.generateModelName(model), 'Anonymous');
      });

      test('makes anonymous names unique using Model suffix', () {
        final model1 = ClassModel(
          properties: const {},
          context: Context.initial(),
        );
        final model2 = ClassModel(
          properties: const {},
          context: Context.initial(),
        );
        final model3 = ClassModel(
          properties: const {},
          context: Context.initial(),
        );

        final name1 = nameGenerator.generateModelName(model1);
        final name2 = nameGenerator.generateModelName(model2);
        final name3 = nameGenerator.generateModelName(model3);

        expect(name1, 'Anonymous');
        expect(name2, 'AnonymousModel');
        expect(name3, 'AnonymousModel2');
      });

      group('number handling', () {
        test('preserves numbers in class names', () {
          final model = ClassModel(
            name: 'Model23',
            properties: const {},
            context: Context.initial(),
          );
          expect(nameGenerator.generateModelName(model), 'Model23');
        });

        test('removes leading numbers', () {
          final model = ClassModel(
            name: '2Model',
            properties: const {},
            context: Context.initial(),
          );
          expect(nameGenerator.generateModelName(model), 'Model');
        });

        test('removes leading numbers but preserves internal ones', () {
          final model = ClassModel(
            name: '2_Model12String33',
            properties: const {},
            context: Context.initial(),
          );
          expect(nameGenerator.generateModelName(model), 'Model12String33');
        });

        test('handles multiple number segments', () {
          final model = ClassModel(
            name: 'user2_profile3_data4',
            properties: const {},
            context: Context.initial(),
          );
          expect(nameGenerator.generateModelName(model), 'User2Profile3Data4');
        });

        test('handles names with only numbers', () {
          final model = ClassModel(
            name: '123',
            properties: const {},
            context: Context.initial(),
          );
          expect(nameGenerator.generateModelName(model), 'Anonymous');
        });
      });
      group('_sanitizeName', () {
        test('converts underscored name to PascalCase', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                name: 'hello_world_test',
                properties: const {},
                context: Context.initial(),
              ),
            ),
            'HelloWorldTest',
          );
        });

        test('converts name with leading underscore to PascalCase', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                name: '_hello_world',
                properties: const {},
                context: Context.initial(),
              ),
            ),
            'HelloWorld',
          );
        });

        test('removes illegal characters and converts to PascalCase', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                name: 'Hello-World_Test!123',
                properties: const {},
                context: Context.initial(),
              ),
            ),
            'HelloWorldTest123',
          );
        });

        test('handles multiple leading underscores', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                name: '___hello_world_test',
                properties: const {},
                context: Context.initial(),
              ),
            ),
            'HelloWorldTest',
          );
        });

        test('handles mixed case with underscores', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                name: 'My_Class_NAME',
                properties: const {},
                context: Context.initial(),
              ),
            ),
            'MyClassName',
          );
        });
      });

      group('unique name generation', () {
        test('uses original name for first occurrence', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                name: 'Test',
                properties: const {},
                context: Context.initial(),
              ),
            ),
            'Test',
          );
        });

        test('adds Model suffix for second occurrence', () {
          nameGenerator.generateModelName(
            ClassModel(
              name: 'Test',
              properties: const {},
              context: Context.initial(),
            ),
          );

          expect(
            nameGenerator.generateModelName(
              ClassModel(
                name: 'Test',
                properties: const {},
                context: Context.initial(),
              ),
            ),
            'TestModel',
          );
        });

        test('adds number to Model suffix for third occurrence', () {
          nameGenerator
            ..generateModelName(
              ClassModel(
                name: 'Test',
                properties: const {},
                context: Context.initial(),
              ),
            )
            ..generateModelName(
              ClassModel(
                name: 'Test',
                properties: const {},
                context: Context.initial(),
              ),
            );

          expect(
            nameGenerator.generateModelName(
              ClassModel(
                name: 'Test',
                properties: const {},
                context: Context.initial(),
              ),
            ),
            'TestModel2',
          );
        });

        test('handles names that already end with Model', () {
          final model1 = ClassModel(
            name: 'UserModel',
            properties: const {},
            context: Context.initial(),
          );
          final model2 = ClassModel(
            name: 'UserModel',
            properties: const {},
            context: Context.initial(),
          );

          final name1 = nameGenerator.generateModelName(model1);
          final name2 = nameGenerator.generateModelName(model2);

          expect(name1, 'UserModel');
          expect(name2, 'UserModel2');
        });
      });

      group('generateResponseName', () {
        test('uses name when available', () {
          final response = ResponseObject(
            name: 'User',
            description: 'A user object',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );
          expect(nameGenerator.generateResponseName(response), 'User');
        });

        test('converts name to PascalCase', () {
          final response = ResponseObject(
            name: 'user_profile',
            description: 'A user profile',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );
          expect(nameGenerator.generateResponseName(response), 'UserProfile');
        });

        test('makes duplicate response names unique using Response suffix', () {
          final response1 = ResponseObject(
            name: 'User',
            description: 'First user',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );
          final response2 = ResponseObject(
            name: 'User',
            description: 'Second user',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );
          final response3 = ResponseObject(
            name: 'User',
            description: 'Third user',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );

          final name1 = nameGenerator.generateResponseName(response1);
          final name2 = nameGenerator.generateResponseName(response2);
          final name3 = nameGenerator.generateResponseName(response3);

          expect(name1, 'User');
          expect(name2, 'UserResponse');
          expect(name3, 'UserResponse2');
        });

        test('uses context path when name is not available', () {
          final response = ResponseObject(
            name: null,
            description: 'A user object',
            headers: const {},
            bodies: const {},
            context: Context.initial().pushAll(['api', 'models', 'user']),
          );
          expect(nameGenerator.generateResponseName(response), 'ApiModelsUser');
        });

        test('uses Anonymous for response without name or context path', () {
          final response = ResponseObject(
            name: null,
            description: 'A user object',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );
          expect(nameGenerator.generateResponseName(response), 'Anonymous');
        });

        test('preserves numbers in names', () {
          final response = ResponseObject(
            name: 'Model23',
            description: 'A model',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );
          expect(nameGenerator.generateResponseName(response), 'Model23');
        });

        test('handles names that already end with Response', () {
          final response1 = ResponseObject(
            name: 'UserResponse',
            description: 'First user response',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );
          final response2 = ResponseObject(
            name: 'UserResponse',
            description: 'Second user response',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );

          final name1 = nameGenerator.generateResponseName(response1);
          final name2 = nameGenerator.generateResponseName(response2);

          expect(name1, 'UserResponse');
          expect(name2, 'UserResponse2');
        });

        test('ensures global uniqueness with model names', () {
          final model = ClassModel(
            name: 'User',
            properties: const {},
            context: Context.initial(),
          );
          final response = ResponseObject(
            name: 'User',
            description: 'A user object',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );

          final modelName = nameGenerator.generateModelName(model);
          final responseName = nameGenerator.generateResponseName(response);
          final responseName2 = nameGenerator.generateResponseName(response);

          expect(modelName, 'User');
          expect(responseName, 'UserResponse');
          expect(responseName2, 'UserResponse2');

          // Verify model names are also unique against response names
          final modelName2 = nameGenerator.generateModelName(model);
          expect(modelName2, 'UserModel');
        });
      });

      group('generateTagName', () {
        test('generates unique API class names for tags', () {
          final manager = NameGenerator();

          expect(
            manager.generateTagName(const Tag(name: 'pets')),
            equals('PetsApi'),
          );

          expect(
            manager.generateTagName(const Tag(name: 'pets')),
            equals('PetsApi2'),
          );

          expect(
            manager.generateTagName(const Tag(name: 'store_inventory')),
            equals('StoreInventoryApi'),
          );
        });

        test('handles special characters and numbers in tag names', () {
          final manager = NameGenerator();

          expect(
            manager.generateTagName(const Tag(name: '2pets')),
            equals('PetsApi'),
          );

          expect(
            manager.generateTagName(const Tag(name: 'pets-v2')),
            equals('PetsV2Api'),
          );

          expect(
            manager.generateTagName(const Tag(name: '_store_api')),
            equals('StoreApiApi'),
          );
        });
      });
    });
  });
}
