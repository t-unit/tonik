import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';

void main() {
  group('NameGenerator', () {
    late NameGenerator nameGenerator;
    late Set<String> usedNames;

    setUp(() {
      nameGenerator = NameGenerator();
      usedNames = <String>{};
    });

    group('generateClassName', () {
      group('real world examples', () {
        test('anonymous response', () {
          final model = ClassModel(
            isDeprecated: false,
            properties: const [],
            context: Context.initial().pushAll([
              'paths',
              'pet-findByStatus',
              'get',
              'responses',
              '200',
              'content',
            ]),
            examples: const [],
          );
          expect(
            nameGenerator.generateModelName(model, usedNames),
            'PetFindByStatusGetResponses200ContentModel',
          );
        });

        test('preserves numeric components in context paths', () {
          final model = ClassModel(
            isDeprecated: false,
            properties: const [],
            context: Context.initial().pushAll([
              'paths',
              'pet-store',
              'get',
              'responses',
              '404',
              'content',
            ]),
            examples: const [],
          );
          expect(
            nameGenerator.generateModelName(model, usedNames),
            'PetStoreGetResponses404ContentModel',
          );
        });

        test(r'prefixes $ when path starts with digits (Twilio-style)', () {
          final model = ClassModel(
            isDeprecated: false,
            properties: const [],
            context: Context.initial().pushAll([
              'paths',
              '2010-04-01-Accounts.json',
              'get',
              'responses',
              '200',
              'content',
            ]),
            examples: const [],
          );
          expect(
            nameGenerator.generateModelName(model, usedNames),
            r'$20100401AccountsJsonGetResponses200ContentModel',
          );
        });

        test('oneOf model with inline model', () {
          final inlineClassModel = ClassModel(
            isDeprecated: false,
            properties: const [],
            context: Context.initial().pushAll([
              'components',
              'schemas',
              'Blub',
            ]),
            examples: const [],
          );

          final oneOfModel = OneOfModel(
            isDeprecated: false,
            name: 'Blub',
            models: {(discriminatorValue: null, model: inlineClassModel)},
            context: Context.initial().pushAll(['components', 'schemas']),
            examples: const [],
          );

          // First name the oneOf model
          final oneOfName = nameGenerator.generateModelName(
            oneOfModel,
            usedNames,
          );
          // Then name the inline model
          final inlineName = nameGenerator.generateModelName(
            inlineClassModel,
            usedNames,
          );

          expect(oneOfName, 'Blub');
          expect(inlineName, 'BlubModel');
        });

        test('enum parameter in path', () {
          final enumModel = EnumModel<String>(
            isDeprecated: false,
            values: {
              const EnumEntry(value: 'available'),
              const EnumEntry(value: 'pending'),
              const EnumEntry(value: 'sold'),
            },
            isNullable: false,
            context: Context.initial().pushAll([
              'paths',
              'pet-findByTags',
              'parameter',
            ]),
            examples: const [],
          );

          expect(
            nameGenerator.generateModelName(enumModel, usedNames),
            'PetFindByTagsParameterModel',
          );
        });
      });

      test('uses model name when available', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'UserProfile',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        expect(
          nameGenerator.generateModelName(model, usedNames),
          'UserProfile',
        );
      });

      test('converts name to PascalCase', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'user_profile',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        expect(
          nameGenerator.generateModelName(model, usedNames),
          'UserProfile',
        );
      });

      test('makes duplicate names unique using Model suffix', () {
        final model1 = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        final model2 = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        final model3 = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );

        final name1 = nameGenerator.generateModelName(model1, usedNames);
        final name2 = nameGenerator.generateModelName(model2, usedNames);
        final name3 = nameGenerator.generateModelName(model3, usedNames);

        expect(name1, 'User');
        expect(name2, 'UserModel');
        expect(name3, 'UserModel2');
      });

      test('removes illegal characters', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'User-Profile!123',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        expect(
          nameGenerator.generateModelName(model, usedNames),
          'UserProfile123',
        );
      });

      test('preserves dollar sign characters', () {
        final model = ClassModel(
          isDeprecated: false,
          name: r'$UserProfile',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        expect(
          nameGenerator.generateModelName(model, usedNames),
          r'$UserProfile',
        );
      });

      test('preserves dollar sign in compound names', () {
        final model = ClassModel(
          isDeprecated: false,
          name: r'$raw_user_data',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        expect(
          nameGenerator.generateModelName(model, usedNames),
          r'$RawUserData',
        );
      });

      test('suffixes names differing only in dollar signs', () {
        final model1 = ClassModel(
          isDeprecated: false,
          name: r'$User',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        final model2 = ClassModel(
          isDeprecated: false,
          name: r'$$User',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );

        expect(nameGenerator.generateModelName(model1, usedNames), r'$User');
        expect(
          nameGenerator.generateModelName(model2, usedNames),
          r'$$UserModel',
        );
      });

      test('suffixes hoisted dollar names differing only in dollar signs', () {
        final model1 = ClassModel(
          isDeprecated: false,
          name: r'Foo$Bar',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        final model2 = ClassModel(
          isDeprecated: false,
          name: r'$Foo$Bar',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );

        expect(nameGenerator.generateModelName(model1, usedNames), r'$FooBar');
        expect(
          nameGenerator.generateModelName(model2, usedNames),
          r'$$FooBarModel',
        );
      });

      test('suffixes a dollar-prefixed name colliding with its plain form', () {
        final model1 = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        final model2 = ClassModel(
          isDeprecated: false,
          name: r'$User',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );

        expect(nameGenerator.generateModelName(model1, usedNames), 'User');
        expect(
          nameGenerator.generateModelName(model2, usedNames),
          r'$UserModel',
        );
      });

      test('combines context path components in PascalCase', () {
        final model = ClassModel(
          isDeprecated: false,
          properties: const [],
          context: Context.initial().pushAll(['api', 'models', 'user']),
          examples: const [],
        );

        expect(
          nameGenerator.generateModelName(model, usedNames),
          'ApiModelsUserModel',
        );
      });

      test('converts each path component to PascalCase before joining', () {
        final model = ListModel(
          content: StringModel(context: Context.initial()),
          context: Context.initial().pushAll([
            'api',
            'user_management',
            'active_users',
          ]),
          examples: const [],
        );

        expect(
          nameGenerator.generateModelName(model, usedNames),
          'ApiUserManagementActiveUsersModel',
        );
      });

      test('converts explicit names with underscores to PascalCase', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'my_class_name',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );

        expect(
          nameGenerator.generateModelName(model, usedNames),
          'MyClassName',
        );
      });

      test('converts names with leading underscores to PascalCase', () {
        final model = ClassModel(
          isDeprecated: false,
          name: '_my_class_name',
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );

        expect(
          nameGenerator.generateModelName(model, usedNames),
          'MyClassName',
        );
      });

      test('uses Anonymous for model without name or context path', () {
        final model = ClassModel(
          isDeprecated: false,
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );

        expect(
          nameGenerator.generateModelName(model, usedNames),
          'AnonymousModel',
        );
      });

      test('makes anonymous names unique using Model suffix', () {
        final model1 = ClassModel(
          isDeprecated: false,
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        final model2 = ClassModel(
          isDeprecated: false,
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );
        final model3 = ClassModel(
          isDeprecated: false,
          properties: const [],
          context: Context.initial(),
          examples: const [],
        );

        final name1 = nameGenerator.generateModelName(model1, usedNames);
        final name2 = nameGenerator.generateModelName(model2, usedNames);
        final name3 = nameGenerator.generateModelName(model3, usedNames);

        expect(name1, 'AnonymousModel');
        expect(name2, 'AnonymousModel2');
        expect(name3, 'AnonymousModel3');
      });

      group('number handling', () {
        test('preserves numbers in class names', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'Model23',
            properties: const [],
            context: Context.initial(),
            examples: const [],
          );
          expect(nameGenerator.generateModelName(model, usedNames), 'Model23');
        });

        test('removes leading numbers', () {
          final model = ClassModel(
            isDeprecated: false,
            name: '2Model',
            properties: const [],
            context: Context.initial(),
            examples: const [],
          );
          expect(nameGenerator.generateModelName(model, usedNames), 'Model');
        });

        test('removes leading numbers but preserves internal ones', () {
          final model = ClassModel(
            isDeprecated: false,
            name: '2_Model12String33',
            properties: const [],
            context: Context.initial(),
            examples: const [],
          );
          expect(
            nameGenerator.generateModelName(model, usedNames),
            'Model12String33',
          );
        });

        test('handles multiple number segments', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'user2_profile3_data4',
            properties: const [],
            context: Context.initial(),
            examples: const [],
          );
          expect(
            nameGenerator.generateModelName(model, usedNames),
            'User2Profile3Data4',
          );
        });

        test('handles names with only numbers', () {
          final model = ClassModel(
            isDeprecated: false,
            name: '123',
            properties: const [],
            context: Context.initial(),
            examples: const [],
          );
          expect(
            nameGenerator.generateModelName(model, usedNames),
            'Anonymous',
          );
        });
      });
      group('_sanitizeName', () {
        test('converts underscored name to PascalCase', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                isDeprecated: false,
                name: 'hello_world_test',
                properties: const [],
                context: Context.initial(),
                examples: const [],
              ),
              usedNames,
            ),
            'HelloWorldTest',
          );
        });

        test('converts name with leading underscore to PascalCase', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                isDeprecated: false,
                name: '_hello_world',
                properties: const [],
                context: Context.initial(),
                examples: const [],
              ),
              usedNames,
            ),
            'HelloWorld',
          );
        });

        test('removes illegal characters and converts to PascalCase', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                isDeprecated: false,
                name: 'Hello-World_Test!123',
                properties: const [],
                context: Context.initial(),
                examples: const [],
              ),
              usedNames,
            ),
            'HelloWorldTest123',
          );
        });

        test('handles multiple leading underscores', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                isDeprecated: false,
                name: '___hello_world_test',
                properties: const [],
                context: Context.initial(),
                examples: const [],
              ),
              usedNames,
            ),
            'HelloWorldTest',
          );
        });

        test('handles mixed case with underscores', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                isDeprecated: false,
                name: 'My_Class_NAME',
                properties: const [],
                context: Context.initial(),
                examples: const [],
              ),
              usedNames,
            ),
            'MyClassName',
          );
        });

        test('treats dots as word separators in schema names', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                isDeprecated: false,
                name: 'billing.credit_balance_transaction',
                properties: const [],
                context: Context.initial(),
                examples: const [],
              ),
              usedNames,
            ),
            'BillingCreditBalanceTransaction',
          );
        });
      });

      group('unique name generation', () {
        test('uses original name for first occurrence', () {
          expect(
            nameGenerator.generateModelName(
              ClassModel(
                isDeprecated: false,
                name: 'Test',
                properties: const [],
                context: Context.initial(),
                examples: const [],
              ),
              usedNames,
            ),
            'Test',
          );
        });

        test('adds Model suffix for second occurrence', () {
          nameGenerator.generateModelName(
            ClassModel(
              isDeprecated: false,
              name: 'Test',
              properties: const [],
              context: Context.initial(),
              examples: const [],
            ),
            usedNames,
          );

          expect(
            nameGenerator.generateModelName(
              ClassModel(
                isDeprecated: false,
                name: 'Test',
                properties: const [],
                context: Context.initial(),
                examples: const [],
              ),
              usedNames,
            ),
            'TestModel',
          );
        });

        test('adds number to Model suffix for third occurrence', () {
          nameGenerator
            ..generateModelName(
              ClassModel(
                isDeprecated: false,
                name: 'Test',
                properties: const [],
                context: Context.initial(),
                examples: const [],
              ),
              usedNames,
            )
            ..generateModelName(
              ClassModel(
                isDeprecated: false,
                name: 'Test',
                properties: const [],
                context: Context.initial(),
                examples: const [],
              ),
              usedNames,
            );

          expect(
            nameGenerator.generateModelName(
              ClassModel(
                isDeprecated: false,
                name: 'Test',
                properties: const [],
                context: Context.initial(),
                examples: const [],
              ),
              usedNames,
            ),
            'TestModel2',
          );
        });

        test('handles names that already end with Model', () {
          final model1 = ClassModel(
            isDeprecated: false,
            name: 'UserModel',
            properties: const [],
            context: Context.initial(),
            examples: const [],
          );
          final model2 = ClassModel(
            isDeprecated: false,
            name: 'UserModel',
            properties: const [],
            context: Context.initial(),
            examples: const [],
          );

          final name1 = nameGenerator.generateModelName(model1, usedNames);
          final name2 = nameGenerator.generateModelName(model2, usedNames);

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
          expect(
            nameGenerator.generateResponseName(response, usedNames),
            'User',
          );
        });

        test('converts name to PascalCase', () {
          final response = ResponseObject(
            name: 'user_profile',
            description: 'A user profile',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );
          expect(
            nameGenerator.generateResponseName(response, usedNames),
            'UserProfile',
          );
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

          final name1 = nameGenerator.generateResponseName(
            response1,
            usedNames,
          );
          final name2 = nameGenerator.generateResponseName(
            response2,
            usedNames,
          );
          final name3 = nameGenerator.generateResponseName(
            response3,
            usedNames,
          );

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
          expect(
            nameGenerator.generateResponseName(response, usedNames),
            'ApiModelsUserResponse',
          );
        });

        test('uses Anonymous for response without name or context path', () {
          final response = ResponseObject(
            name: null,
            description: 'A user object',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );
          expect(
            nameGenerator.generateResponseName(response, usedNames),
            'AnonymousResponse',
          );
        });

        test('preserves numbers in names', () {
          final response = ResponseObject(
            name: 'Model23',
            description: 'A model',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );
          expect(
            nameGenerator.generateResponseName(response, usedNames),
            'Model23',
          );
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

          final name1 = nameGenerator.generateResponseName(
            response1,
            usedNames,
          );
          final name2 = nameGenerator.generateResponseName(
            response2,
            usedNames,
          );

          expect(name1, 'UserResponse');
          expect(name2, 'UserResponse2');
        });

        test('ensures global uniqueness with model names', () {
          final model = ClassModel(
            isDeprecated: false,
            name: 'User',
            properties: const [],
            context: Context.initial(),
            examples: const [],
          );
          final response = ResponseObject(
            name: 'User',
            description: 'A user object',
            headers: const {},
            bodies: const {},
            context: Context.initial(),
          );

          final modelName = nameGenerator.generateModelName(model, usedNames);
          final responseName = nameGenerator.generateResponseName(
            response,
            usedNames,
          );
          final responseName2 = nameGenerator.generateResponseName(
            response,
            usedNames,
          );

          expect(modelName, 'User');
          expect(responseName, 'UserResponse');
          expect(responseName2, 'UserResponse2');

          // Verify model names are also unique against response names
          final modelName2 = nameGenerator.generateModelName(model, usedNames);
          expect(modelName2, 'UserModel');
        });
      });

      group('generateTagName', () {
        test('generates unique API class names for tags', () {
          final manager = NameGenerator();
          final usedNames = <String>{};

          expect(
            manager.generateTagName(Tag(name: 'pets'), usedNames),
            'PetsApi',
          );

          expect(
            manager.generateTagName(Tag(name: 'pets'), usedNames),
            'PetsApi2',
          );

          expect(
            manager.generateTagName(Tag(name: 'store_inventory'), usedNames),
            'StoreInventoryApi',
          );
        });

        test('handles special characters and numbers in tag names', () {
          final manager = NameGenerator();
          final usedNames = <String>{};

          expect(
            manager.generateTagName(Tag(name: '2pets'), usedNames),
            'PetsApi',
          );

          expect(
            manager.generateTagName(Tag(name: 'pets-v2'), usedNames),
            'PetsV2Api',
          );

          expect(
            manager.generateTagName(Tag(name: '_store_api'), usedNames),
            'StoreApiApi',
          );
        });
      });
    });

    group('generateRequestBodyNames', () {
      test('generates base name and no subclass names for single content', () {
        final requestBody = RequestBodyObject(
          name: 'user',
          context: Context.initial(),
          description: '',
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: Context.initial()),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        );

        final (baseName, subclassNames) = nameGenerator
            .generateRequestBodyNames(requestBody, usedNames);
        expect(baseName, 'User');
        expect(subclassNames, isEmpty);
      });

      test(
        'generates base name and subclass names for multiple content types',
        () {
          final requestBody = RequestBodyObject(
            name: 'user',
            context: Context.initial(),
            description: '',
            isRequired: true,
            content: {
              RequestContent(
                model: StringModel(context: Context.initial()),
                contentType: ContentType.json,
                rawContentType: 'application/json',
                examples: const [],
              ),
              RequestContent(
                model: StringModel(context: Context.initial()),
                contentType: ContentType.json,
                rawContentType: 'application/x-www-form-urlencoded',
                examples: const [],
              ),
            },
          );

          final (baseName, subclassNames) = nameGenerator
              .generateRequestBodyNames(requestBody, usedNames);
          expect(baseName, 'User');
          expect(subclassNames, {
            'application/json': 'UserJson',
            'application/x-www-form-urlencoded': 'UserXWwwFormUrlencoded',
          });
        },
      );

      test('makes duplicate subclass names unique', () {
        final requestBody = RequestBodyObject(
          name: 'user',
          context: Context.initial(),
          description: '',
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: Context.initial()),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
            RequestContent(
              model: StringModel(context: Context.initial()),
              contentType: ContentType.json,
              rawContentType: 'application/json+v2',
              examples: const [],
            ),
          },
        );

        // First call to generate names
        final (baseName1, subclassNames1) = nameGenerator
            .generateRequestBodyNames(requestBody, usedNames);
        expect(baseName1, 'User');
        expect(subclassNames1, {
          'application/json': 'UserJson',
          'application/json+v2': 'UserJsonV2',
        });

        // Second call with same content types should get different names
        final (baseName2, subclassNames2) = nameGenerator
            .generateRequestBodyNames(requestBody, usedNames);
        expect(baseName2, 'UserRequestBody');
        expect(subclassNames2, {
          'application/json': 'UserRequestBodyJson',
          'application/json+v2': 'UserRequestBodyJsonV2',
        });
      });

      test('handles request body aliases', () {
        final originalBody = RequestBodyObject(
          name: 'user',
          context: Context.initial(),
          description: '',
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: Context.initial()),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
            RequestContent(
              model: StringModel(context: Context.initial()),
              contentType: ContentType.json,
              rawContentType: 'application/x-www-form-urlencoded',
              examples: const [],
            ),
          },
        );

        final aliasBody = RequestBodyAlias(
          name: 'userAlias',
          context: Context.initial(),
          requestBody: originalBody,
        );

        final (baseName, subclassNames) = nameGenerator
            .generateRequestBodyNames(aliasBody, usedNames);
        expect(baseName, 'UserAlias');
        expect(subclassNames, isEmpty);
      });
    });

    group('generateResponseWrapperNames', () {
      test('generates base name and one subclass per status', () {
        final responses = {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: 'SuccessResponse',
            context: Context.initial(),
            description: 'Success',
            headers: const {},
            bodies: {
              ResponseBody(
                model: StringModel(context: Context.initial()),
                rawContentType: 'application/json',
                contentType: ContentType.json,
                examples: const [],
              ),
              ResponseBody(
                model: StringModel(context: Context.initial()),
                rawContentType: 'application/xml',
                contentType: ContentType.json,
                examples: const [],
              ),
            },
          ),
          const ExplicitResponseStatus(statusCode: 404): ResponseObject(
            name: 'NotFoundResponse',
            context: Context.initial(),
            description: 'Not found',
            headers: const {},
            bodies: {
              ResponseBody(
                model: StringModel(context: Context.initial()),
                rawContentType: 'text/plain',
                contentType: ContentType.json,
                examples: const [],
              ),
            },
          ),
        };
        final (baseName, subclassNames) = nameGenerator
            .generateResponseWrapperNames(
              'TestOperation',
              responses,
              usedNames,
            );

        expect(baseName, 'TestOperationResponse');
        expect(subclassNames.keys, containsAll(responses.keys));
        expect(
          subclassNames[const ExplicitResponseStatus(statusCode: 200)],
          'TestOperationResponse200',
        );
        expect(
          subclassNames[const ExplicitResponseStatus(statusCode: 404)],
          'TestOperationResponse404',
        );
        expect(subclassNames.length, 2);
      });

      test(
        'only adds ResponseWrapper suffix when Response is already taken',
        () {
          final response = ResponseObject(
            name: 'GetPetResponse',
            context: Context.initial(),
            description: 'Response',
            headers: const {},
            bodies: const {},
          );

          expect(
            nameGenerator.generateResponseName(response, usedNames),
            'GetPetResponse',
          );

          final responses = {
            const DefaultResponseStatus(): ResponseObject(
              name: null,
              context: Context.initial(),
              description: 'Default',
              headers: const {},
              bodies: {
                ResponseBody(
                  model: StringModel(context: Context.initial()),
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
            const RangeResponseStatus(min: 200, max: 299): ResponseObject(
              name: null,
              context: Context.initial(),
              description: 'Range',
              headers: const {},
              bodies: {
                ResponseBody(
                  model: StringModel(context: Context.initial()),
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
          };
          final (baseName, subclassNames) = nameGenerator
              .generateResponseWrapperNames('GetPet', responses, usedNames);

          expect(baseName, 'GetPetResponseWrapper');
          expect(subclassNames.keys, containsAll(responses.keys));
          expect(
            subclassNames[const DefaultResponseStatus()],
            'GetPetResponseWrapperDefault',
          );

          expect(
            subclassNames[const RangeResponseStatus(min: 200, max: 299)],
            'GetPetResponseWrapper2XX',
          );
        },
      );

      test('generates correct names for Default and Range statuses', () {
        final responses = {
          const DefaultResponseStatus(): ResponseObject(
            name: 'DefaultResponse',
            context: Context.initial(),
            description: 'Default',
            headers: const {},
            bodies: {
              ResponseBody(
                model: StringModel(context: Context.initial()),
                rawContentType: 'application/json',
                contentType: ContentType.json,
                examples: const [],
              ),
            },
          ),
          const RangeResponseStatus(min: 200, max: 299): ResponseObject(
            name: 'RangeResponse',
            context: Context.initial(),
            description: 'Range',
            headers: const {},
            bodies: {
              ResponseBody(
                model: StringModel(context: Context.initial()),
                rawContentType: 'application/json',
                contentType: ContentType.json,
                examples: const [],
              ),
            },
          ),
        };
        final (baseName, subclassNames) = nameGenerator
            .generateResponseWrapperNames(
              'TestOperation',
              responses,
              usedNames,
            );

        expect(baseName, 'TestOperationResponse');
        expect(subclassNames.keys, containsAll(responses.keys));
        expect(
          subclassNames[const DefaultResponseStatus()],
          'TestOperationResponseDefault',
        );
        expect(
          subclassNames[const RangeResponseStatus(min: 200, max: 299)],
          'TestOperationResponse2XX',
        );
        expect(subclassNames.length, 2);
      });

      test('does not generate multiple subclasses for multiple bodies '
          'in a single response', () {
        final responses = {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: 'MultiBodyResponse',
            context: Context.initial(),
            description: 'Multi',
            headers: const {},
            bodies: {
              ResponseBody(
                model: StringModel(context: Context.initial()),
                rawContentType: 'application/json',
                contentType: ContentType.json,
                examples: const [],
              ),
              ResponseBody(
                model: StringModel(context: Context.initial()),
                rawContentType: 'application/xml',
                contentType: ContentType.json,
                examples: const [],
              ),
            },
          ),
        };
        final (baseName, subclassNames) = nameGenerator
            .generateResponseWrapperNames(
              'TestOperation',
              responses,
              usedNames,
            );

        expect(baseName, 'TestOperationResponse');
        expect(
          subclassNames.keys,
          contains(const ExplicitResponseStatus(statusCode: 200)),
        );
        expect(
          subclassNames[const ExplicitResponseStatus(statusCode: 200)],
          'TestOperationResponse200',
        );
        expect(subclassNames.length, 1);
      });
    });

    group('generateResponseImplementationName', () {
      test('generates unique names for different content types', () {
        final response = ResponseObject(
          name: 'UserResponse',
          context: Context.initial(),
          description: 'A user response',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: Context.initial()),
              rawContentType: 'application/json',
              contentType: ContentType.json,
              examples: const [],
            ),
            ResponseBody(
              model: StringModel(context: Context.initial()),
              rawContentType: 'application/xml',
              contentType: ContentType.json,
              examples: const [],
            ),
          },
        );

        final baseName = nameGenerator.generateResponseName(
          response,
          usedNames,
        );
        final jsonName = nameGenerator.generateResponseImplementationName(
          baseName,
          ResponseBody(
            model: StringModel(context: Context.initial()),
            rawContentType: 'application/json',
            contentType: ContentType.json,
            examples: const [],
          ),
          usedNames,
        );
        final xmlName = nameGenerator.generateResponseImplementationName(
          baseName,
          ResponseBody(
            model: StringModel(context: Context.initial()),
            rawContentType: 'application/xml',
            contentType: ContentType.json,
            examples: const [],
          ),
          usedNames,
        );

        expect(jsonName, 'UserResponseJson');
        expect(xmlName, 'UserResponseXml');
      });

      test('handles duplicate content types', () {
        final response = ResponseObject(
          name: 'UserResponse',
          context: Context.initial(),
          description: 'A user response',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: Context.initial()),
              rawContentType: 'application/json',
              contentType: ContentType.json,
              examples: const [],
            ),
            ResponseBody(
              model: StringModel(context: Context.initial()),
              rawContentType: 'application/json',
              contentType: ContentType.json,
              examples: const [],
            ),
          },
        );

        final baseName = nameGenerator.generateResponseName(
          response,
          usedNames,
        );
        final name1 = nameGenerator.generateResponseImplementationName(
          baseName,
          ResponseBody(
            model: StringModel(context: Context.initial()),
            rawContentType: 'application/json',
            contentType: ContentType.json,
            examples: const [],
          ),
          usedNames,
        );
        final name2 = nameGenerator.generateResponseImplementationName(
          baseName,
          ResponseBody(
            model: StringModel(context: Context.initial()),
            rawContentType: 'application/json',
            contentType: ContentType.json,
            examples: const [],
          ),
          usedNames,
        );

        expect(name1, 'UserResponseJson');
        expect(name2, 'UserResponseJson2');
      });

      test('handles content types with version numbers', () {
        final response = ResponseObject(
          name: 'UserResponse',
          context: Context.initial(),
          description: 'A user response',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: Context.initial()),
              rawContentType: 'application/json+v2',
              contentType: ContentType.json,
              examples: const [],
            ),
          },
        );

        final baseName = nameGenerator.generateResponseName(
          response,
          usedNames,
        );
        final name = nameGenerator.generateResponseImplementationName(
          baseName,
          ResponseBody(
            model: StringModel(context: Context.initial()),
            rawContentType: 'application/json+v2',
            contentType: ContentType.json,
            examples: const [],
          ),
          usedNames,
        );

        expect(name, 'UserResponseJsonV2');
      });

      test('handles content types with no subtype', () {
        final response = ResponseObject(
          name: 'UserResponse',
          context: Context.initial(),
          description: 'A user response',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: Context.initial()),
              rawContentType: 'application',
              contentType: ContentType.json,
              examples: const [],
            ),
          },
        );

        final baseName = nameGenerator.generateResponseName(
          response,
          usedNames,
        );
        final name = nameGenerator.generateResponseImplementationName(
          baseName,
          ResponseBody(
            model: StringModel(context: Context.initial()),
            rawContentType: 'application',
            contentType: ContentType.json,
            examples: const [],
          ),
          usedNames,
        );

        expect(name, 'UserResponseApplication');
      });
    });

    group('Server names', () {
      test('generates names based on subdomain differences', () {
        final generator = NameGenerator();
        final usedNames = <String>{};
        final servers = [
          const Server(url: 'https://api.example.com'),
          const Server(url: 'https://staging.example.com'),
          const Server(url: 'https://dev.example.com'),
        ];

        final result = generator.generateServerNames(servers, usedNames);

        expect(result.serverMap.length, 3);
        expect(result.serverMap[servers[0]], 'ApiServer');
        expect(result.serverMap[servers[1]], 'StagingServer');
        expect(result.serverMap[servers[2]], 'DevServer');
        expect(result.customName, 'CustomServer');
        expect(result.baseName, 'Server');
      });

      test('generates names based on multi-level subdomain differences', () {
        final generator = NameGenerator();
        final usedNames = <String>{};
        final servers = [
          const Server(url: 'https://api.dev.example.com'),
          const Server(
            url: 'https://api.staging.example.com',
          ),
          const Server(url: 'https://api.prod.example.com'),
        ];

        final result = generator.generateServerNames(servers, usedNames);

        expect(result.serverMap.length, 3);
        expect(result.serverMap[servers[0]], 'ApiDevServer');
        expect(result.serverMap[servers[1]], 'ApiStagingServer');
        expect(result.serverMap[servers[2]], 'ApiProdServer');
        expect(result.customName, 'CustomServer');
        expect(result.baseName, 'Server');
      });

      test(
        'generates names based on host differences when subdomains are equal',
        () {
          final generator = NameGenerator();
          final usedNames = <String>{};
          final servers = [
            const Server(url: 'https://api.example.com'),
            const Server(url: 'https://api.acme.com'),
            const Server(url: 'https://api.test.com'),
          ];

          final result = generator.generateServerNames(servers, usedNames);

          expect(result.serverMap.length, 3);
          expect(result.serverMap[servers[0]], 'ExampleServer');
          expect(result.serverMap[servers[1]], 'AcmeServer');
          expect(result.serverMap[servers[2]], 'TestServer');
          expect(result.customName, 'CustomServer');
          expect(result.baseName, 'Server');
        },
      );

      test('generates names based on path differences with equal '
          'domains and subdomains', () {
        final generator = NameGenerator();
        final usedNames = <String>{};
        final servers = [
          const Server(url: 'https://api.example.com/v1'),
          const Server(url: 'https://api.example.com/v2'),
          const Server(url: 'https://api.example.com/beta'),
        ];

        final result = generator.generateServerNames(servers, usedNames);

        expect(result.serverMap.length, 3);
        expect(result.serverMap[servers[0]], 'V1Server');
        expect(result.serverMap[servers[1]], 'V2Server');
        expect(result.serverMap[servers[2]], 'BetaServer');
        expect(result.customName, 'CustomServer');
        expect(result.baseName, 'Server');
      });

      test(
        'adds numeric suffixes as a last resort when all other parts are equal',
        () {
          final generator = NameGenerator();
          final usedNames = <String>{};
          final servers = [
            const Server(url: 'https://api.example.com', description: 'a'),
            const Server(url: 'https://api.example.com', description: 'b'),
            const Server(url: 'https://api.example.com', description: 'c'),
          ];

          final result = generator.generateServerNames(servers, usedNames);

          expect(result.serverMap.length, 3);
          expect(result.serverMap[servers[0]], 'Server2');
          expect(result.serverMap[servers[1]], 'Server3');
          expect(result.serverMap[servers[2]], 'Server4');
          expect(result.customName, 'CustomServer');
          expect(result.baseName, 'Server');
        },
      );

      test(
        'uses numeric suffix when CustomServer is already taken',
        () {
          final generator = NameGenerator();
          final usedNames = <String>{};
          final servers = [
            const Server(
              url: 'https://custom.server.com',
              description: 'Custom Server',
            ),
          ];

          final result = generator.generateServerNames(servers, usedNames);

          expect(result.serverMap.length, 1);
          expect(result.serverMap[servers[0]], 'CustomServer');
          expect(result.customName, 'CustomServer2');
          expect(result.baseName, 'Server');
        },
      );

      test('uses default names on invalid URLs', () {
        final generator = NameGenerator();
        final usedNames = <String>{};
        final servers = [
          const Server(url: 'This is not a URI'),
          const Server(
            url: 'https://staging.example.com/v1',
          ),
          const Server(url: 'https://api.acme.com/v1'),
          const Server(url: 'https://api.example.com/v2'),
        ];

        final result = generator.generateServerNames(servers, usedNames);

        expect(result.serverMap.length, 4);
        expect(result.serverMap[servers[0]], 'Server2');
        expect(result.serverMap[servers[1]], 'Server3');
        expect(result.serverMap[servers[2]], 'Server4');
        expect(result.serverMap[servers[3]], 'Server5');
        expect(result.customName, 'CustomServer');
        expect(result.baseName, 'Server');
      });
    });

    group('keyword schema names', () {
      test('escapes Function schema name with dollar prefix', () {
        final model = ClassModel(
          name: 'Function',
          isDeprecated: false,
          properties: const [],
          context: Context.initial().pushAll([
            'components',
            'schemas',
            'Function',
          ]),
          examples: const [],
        );
        expect(nameGenerator.generateModelName(model, usedNames), r'$Function');
      });

      test('escapes lowercase function schema name with dollar prefix', () {
        final model = ClassModel(
          name: 'function',
          isDeprecated: false,
          properties: const [],
          context: Context.initial().pushAll([
            'components',
            'schemas',
            'function',
          ]),
          examples: const [],
        );
        // _sanitizeName('function') → 'Function' (PascalCase)
        // ensureValidClassName('Function') matches exactly → '$Function'
        expect(nameGenerator.generateModelName(model, usedNames), r'$Function');
      });

      test('does not escape PascalCase keyword class names', () {
        // PascalCase versions of keywords are valid Dart class names
        final model = ClassModel(
          name: 'dynamic',
          isDeprecated: false,
          properties: const [],
          context: Context.initial().pushAll([
            'components',
            'schemas',
            'dynamic',
          ]),
          examples: const [],
        );
        // _sanitizeName('dynamic') → 'Dynamic' (PascalCase)
        // 'Dynamic' is not in allKeywords (only 'dynamic' is)
        expect(nameGenerator.generateModelName(model, usedNames), 'Dynamic');
      });

      test('does not escape non-keyword schema names', () {
        final model = ClassModel(
          name: 'User',
          isDeprecated: false,
          properties: const [],
          context: Context.initial().pushAll([
            'components',
            'schemas',
            'User',
          ]),
          examples: const [],
        );
        expect(nameGenerator.generateModelName(model, usedNames), 'User');
      });

      test('does not escape dart:core type names (prefixed imports)', () {
        for (final name in ['Enum', 'Error', 'Object', 'String', 'List']) {
          final model = ClassModel(
            name: name,
            isDeprecated: false,
            properties: const [],
            context: Context.initial().pushAll([
              'components',
              'schemas',
              name,
            ]),
            examples: const [],
          );
          expect(
            nameGenerator.generateModelName(model, usedNames),
            name,
            reason: '$name is valid because dart:core is imported with prefix',
          );
          // Reset the generator for each iteration to avoid uniqueness suffixes
          nameGenerator = NameGenerator();
          usedNames = <String>{};
        }
      });
    });

    group('keyword operation names', () {
      test('does not escape PascalCase switch operation name', () {
        final operation = Operation(
          operationId: 'switch',
          context: Context.initial(),
          tags: const {},
          isDeprecated: false,
          path: '/test',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );
        // PascalCase 'Switch' is a valid Dart class name
        expect(
          nameGenerator.generateOperationName(operation, usedNames),
          'Switch',
        );
      });

      test('does not escape PascalCase return operation name', () {
        final operation = Operation(
          operationId: 'return',
          context: Context.initial(),
          tags: const {},
          isDeprecated: false,
          path: '/test',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );
        // PascalCase 'Return' is a valid Dart class name
        expect(
          nameGenerator.generateOperationName(operation, usedNames),
          'Return',
        );
      });

      test('escapes function operationId with dollar prefix', () {
        final operation = Operation(
          operationId: 'function',
          context: Context.initial(),
          tags: const {},
          isDeprecated: false,
          path: '/test',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );
        // 'Function' is a built-in identifier (stored with capital F)
        expect(
          nameGenerator.generateOperationName(operation, usedNames),
          r'$Function',
        );
      });
    });

    group('keyword tag names', () {
      test('escapes Function tag name with dollar prefix', () {
        final tag = Tag(name: 'Function');
        expect(
          nameGenerator.generateTagName(tag, usedNames),
          r'$FunctionApi',
        );
      });

      test('does not escape PascalCase keyword tag names', () {
        // 'Default' and 'Switch' are valid Dart class names
        final defaultTag = Tag(name: 'default');
        expect(
          nameGenerator.generateTagName(defaultTag, usedNames),
          'DefaultApi',
        );
      });
    });

    group('fileNameForClass', () {
      test('converts a PascalCase class name to a snake_case file name', () {
        expect(NameGenerator.fileNameForClass('FooBar'), 'foo_bar.dart');
      });

      test('maps a dollar-prefixed class name to the same file name as its '
          'plain form', () {
        expect(NameGenerator.fileNameForClass(r'$User'), 'user.dart');
        expect(NameGenerator.fileNameForClass('User'), 'user.dart');
      });

      test('keeps the leading underscore for digit-leading class names', () {
        expect(
          NameGenerator.fileNameForClass(r'$20100401Test'),
          '_20100401_test.dart',
        );
      });

      test('falls back to the raw snake_case form when stripping would empty '
          'the name', () {
        expect(NameGenerator.fileNameForClass(r'$'), '_.dart');
      });
    });

    group('generateDefaultMemberName', () {
      test('returns <propertyName>Default when nothing collides', () {
        expect(
          nameGenerator.generateDefaultMemberName(
            propertyName: 'name',
            reservedNames: const <String>{'name'},
          ),
          'nameDefault',
        );
      });

      test('appends numeric suffix starting at 2 on collision', () {
        expect(
          nameGenerator.generateDefaultMemberName(
            propertyName: 'value',
            reservedNames: const <String>{'value', 'valueDefault'},
          ),
          'valueDefault2',
        );
      });

      test('skips occupied numeric suffixes', () {
        expect(
          nameGenerator.generateDefaultMemberName(
            propertyName: 'value',
            reservedNames: const <String>{
              'value',
              'valueDefault',
              'valueDefault2',
              'valueDefault3',
            },
          ),
          'valueDefault4',
        );
      });

      test('does not mutate the reservedNames set', () {
        final reserved = <String>{'name', 'nameDefault'};
        nameGenerator.generateDefaultMemberName(
          propertyName: 'name',
          reservedNames: reserved,
        );
        expect(reserved, <String>{'name', 'nameDefault'});
      });
    });

    group('generateAdditionalPropertiesFieldName', () {
      test('returns additionalProperties when nothing collides', () {
        expect(
          nameGenerator.generateAdditionalPropertiesFieldName(
            reservedNames: const <String>{'name', 'count'},
          ),
          'additionalProperties',
        );
      });

      test('appends numeric suffix starting at 2 on collision', () {
        expect(
          nameGenerator.generateAdditionalPropertiesFieldName(
            reservedNames: const <String>{'additionalProperties'},
          ),
          'additionalProperties2',
        );
      });

      test('skips occupied numeric suffixes', () {
        expect(
          nameGenerator.generateAdditionalPropertiesFieldName(
            reservedNames: const <String>{
              'additionalProperties',
              'additionalProperties2',
            },
          ),
          'additionalProperties3',
        );
      });
    });
  });
}
