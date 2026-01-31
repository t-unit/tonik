import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late ApiClientGenerator generator;
  late NameManager nameManager;
  late Context testContext;
  late DartEmitter emitter;
  late List<Server> testServers;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameManager = NameManager(generator: NameGenerator());
    generator = ApiClientGenerator(
      nameManager: nameManager,
      package: 'package:test_package/test_package.dart',
    );
    testContext = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);

    testServers = [
      const Server(
        url: 'https://api.example.com',
        description: 'Production server',
      ),
    ];
  });

  group('ApiClientGenerator', () {
    group('class generation', () {
      test('generates API client class for a tag', () {
        final operation = Operation(
          operationId: 'getUser',
          context: testContext,
          summary: 'Get user',
          description: 'Get user by ID',
          tags: {Tag(name: 'users')},
          isDeprecated: false,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          {operation},
          Tag(name: 'users'),
          testServers,
        );

        // Test class definition
        expect(generatedClass.name, 'UsersApi');
        expect(generatedClass.fields.length, 1);
        expect(generatedClass.fields.first.name, '_getUser');
        expect(
          generatedClass.fields.first.type?.accept(emitter).toString(),
          'GetUser',
        );

        // Get server base class name
        final serverNames = nameManager.serverNames(testServers);
        final serverBaseClassName = serverNames.baseName;

        // Test constructor
        final constructor = generatedClass.constructors.first;
        expect(constructor.requiredParameters.length, 1);
        expect(constructor.requiredParameters.first.name, 'server');
        expect(constructor.requiredParameters.first.toThis, isFalse);
        expect(
          constructor.requiredParameters.first.type?.accept(emitter).toString(),
          serverBaseClassName,
        );

        // Test constructor initializers
        expect(constructor.initializers.length, 1);
        final initializerCode = constructor.initializers.first
            .accept(emitter)
            .toString();
        expect(
          initializerCode,
          '_getUser = GetUser(server.dio)',
        );
      });

      test('generates API client class with server instead of Dio', () {
        final operation = Operation(
          operationId: 'getUser',
          context: testContext,
          summary: 'Get user',
          description: 'Get user by ID',
          tags: {Tag(name: 'users')},
          isDeprecated: false,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          {operation},
          Tag(name: 'users'),
          testServers,
        );

        // Test class definition
        expect(generatedClass.name, 'UsersApi');
        expect(generatedClass.fields.length, 1);
        expect(generatedClass.fields.first.name, '_getUser');
        expect(
          generatedClass.fields.first.type?.accept(emitter).toString(),
          'GetUser',
        );

        // Get server base class name
        final serverNames = nameManager.serverNames(testServers);
        final serverBaseClassName = serverNames.baseName;

        // Test constructor
        final constructor = generatedClass.constructors.first;
        expect(constructor.requiredParameters.length, 1);
        expect(constructor.requiredParameters.first.name, 'server');
        expect(constructor.requiredParameters.first.toThis, isFalse);
        expect(
          constructor.requiredParameters.first.type?.accept(emitter).toString(),
          serverBaseClassName,
        );

        // Test constructor initializers
        expect(constructor.initializers.length, 1);
        final initializerCode = constructor.initializers.first
            .accept(emitter)
            .toString();
        expect(
          initializerCode,
          '_getUser = GetUser(server.dio)',
        );
      });

      test(
        'generates API client class with doc string for a tag with description',
        () {
          final operation = Operation(
            operationId: 'getUser',
            context: testContext,
            summary: 'Get user',
            description: 'Get user by ID',
            tags: {
              Tag(
                name: 'users',
                description: 'User management API',
              ),
            },
            isDeprecated: false,
            path: '/users/{id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final generatedClass = generator.generateClass(
            {operation},
            Tag(
              name: 'users',
              description: 'User management API',
            ),
            testServers,
          );

          // Test class has documentation
          expect(generatedClass.docs, isNotEmpty);
          expect(generatedClass.docs.first, '/// User management API');
        },
      );

      test('generates API client class with multiline doc string', () {
        final operation = Operation(
          operationId: 'getUser',
          context: testContext,
          summary: 'Get user',
          description: 'Get user by ID',
          tags: {
            Tag(
              name: 'users',
              description: 'User management API\nWith multiple lines',
            ),
          },
          isDeprecated: false,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          {operation},
          Tag(
            name: 'users',
            description: 'User management API\nWith multiple lines',
          ),
          testServers,
        );

        // Test class has multiline documentation
        expect(generatedClass.docs, isNotEmpty);
        expect(generatedClass.docs.length, 2);
        expect(generatedClass.docs[0], '/// User management API');
        expect(generatedClass.docs[1], '/// With multiple lines');
      });
    });

    group('method generation', () {
      group('basic method', () {
        late Class generatedClass;
        late Operation operation;

        setUp(() {
          operation = Operation(
            operationId: 'getUser',
            context: testContext,
            summary: 'Get user',
            description: 'Get user by ID',
            tags: {Tag(name: 'users')},
            isDeprecated: false,
            path: '/users/{id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          generatedClass = generator.generateClass(
            {operation},
            Tag(name: 'users'),
            testServers,
          );
        });

        test('generates method with correct signature', () {
          final method = generatedClass.methods.first;
          expect(method.name, 'getUser');
          expect(method.modifier, MethodModifier.async);
          expect(
            method.returns?.accept(emitter).toString(),
            'Future<TonikResult<void>>',
          );
        });

        test('generates method body with operation call', () {
          final generatedCode = format(
            generatedClass.accept(emitter).toString(),
          );

          const expectedMethod = '''
            Future<TonikResult<void>> getUser() async => _getUser();
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedMethod)),
          );
        });

        test('generates method with doc string from operation '
            'summary and description', () {
          final method = generatedClass.methods.first;

          // Check that method has documentation
          expect(method.docs, isNotEmpty);
          expect(method.docs, contains('/// Get user'));
          expect(method.docs, contains('/// Get user by ID'));
        });
      });

      group('method with path parameters', () {
        late Class generatedClass;
        late Operation operation;

        setUp(() {
          operation = Operation(
            operationId: 'getUser',
            context: testContext,
            summary: 'Get user',
            description: 'Get user by ID',
            tags: {
              Tag(name: 'users'),
            },
            isDeprecated: false,
            path: '/users/{id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: {
              PathParameterObject(
                name: 'id',
                rawName: 'id',
                description: 'User ID',
                isRequired: true,
                isDeprecated: false,
                allowEmptyValue: false,
                explode: false,
                model: StringModel(context: testContext),
                encoding: PathParameterEncoding.simple,
                context: testContext,
              ),
            },
            responses: const {},
            securitySchemes: const {},
            cookieParameters: const {},
          );

          generatedClass = generator.generateClass(
            {operation},
            Tag(name: 'users'),
            testServers,
          );
        });

        test('generates method with path parameter', () {
          final method = generatedClass.methods.first;
          expect(method.name, 'getUser');
          expect(method.optionalParameters.length, 1);
          expect(method.optionalParameters.first.name, 'id');
          expect(
            method.optionalParameters.first.type?.accept(emitter).toString(),
            'String',
          );
        });

        test('generates method body with path parameter', () {
          final generatedCode = format(
            generatedClass.accept(emitter).toString(),
          );

          const expectedMethod = '''
            Future<TonikResult<void>> getUser({required String id}) async => _getUser(id: id);
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedMethod)),
          );
        });
      });

      group('method with query parameters', () {
        late Class generatedClass;
        late Operation operation;

        setUp(() {
          operation = Operation(
            operationId: 'getUsers',
            context: testContext,
            summary: 'Get users',
            description: 'Get users with filters',
            tags: {Tag(name: 'users')},
            isDeprecated: false,
            path: '/users',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: {
              QueryParameterObject(
                name: 'limit',
                rawName: 'limit',
                description: 'Limit results',
                isRequired: false,
                isDeprecated: false,
                allowEmptyValue: false,
                allowReserved: false,
                explode: false,
                model: IntegerModel(context: testContext),
                encoding: QueryParameterEncoding.form,
                context: testContext,
              ),
              QueryParameterObject(
                name: 'offset',
                rawName: 'offset',
                description: 'Offset results',
                isRequired: false,
                isDeprecated: false,
                allowEmptyValue: false,
                allowReserved: false,
                explode: false,
                model: IntegerModel(context: testContext),
                encoding: QueryParameterEncoding.form,
                context: testContext,
              ),
            },
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          generatedClass = generator.generateClass(
            {operation},
            Tag(name: 'users'),
            testServers,
          );
        });

        test('generates method with query parameters', () {
          final method = generatedClass.methods.first;
          expect(method.name, 'getUsers');
          expect(method.optionalParameters.length, 2);
          expect(method.optionalParameters[0].name, 'limit');
          expect(method.optionalParameters[1].name, 'offset');
          expect(
            method.optionalParameters[0].type?.accept(emitter).toString(),
            'int?',
          );
          expect(
            method.optionalParameters[1].type?.accept(emitter).toString(),
            'int?',
          );
        });

        test('generates method body with query parameters', () {
          final generatedCode = format(
            generatedClass.accept(emitter).toString(),
          );

          const expectedMethod = '''
            Future<TonikResult<void>> getUsers({int? limit, int? offset}) async => _getUsers(limit: limit, offset: offset);
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedMethod)),
          );
        });
      });

      group('method with request body', () {
        late Class generatedClass;
        late Operation operation;

        setUp(() {
          operation = Operation(
            operationId: 'createUser',
            context: testContext,
            summary: 'Create user',
            description: 'Create a new user',
            tags: {
              Tag(name: 'users'),
            },
            isDeprecated: false,
            path: '/users',
            method: HttpMethod.post,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            requestBody: RequestBodyObject(
              description: 'User data',
              isRequired: true,
              name: 'createUser',
              content: {
                RequestContent(
                  contentType: ContentType.json,
                  rawContentType: 'application/json',
                  model: ClassModel(
                    isDeprecated: false,
                    name: 'CreateUserRequestBody',
                    properties: [
                      Property(
                        name: 'name',
                        model: StringModel(context: testContext),
                        isRequired: true,
                        isNullable: false,
                        isDeprecated: false,
                      ),
                    ],
                    context: testContext,
                  ),
                ),
              },
              context: testContext,
            ),
            securitySchemes: const {},
          );

          generatedClass = generator.generateClass(
            {operation},
            Tag(name: 'users'),
            testServers,
          );
        });

        test('generates method with request body', () {
          final method = generatedClass.methods.first;
          expect(method.name, 'createUser');
          expect(method.optionalParameters.length, 1);
          expect(method.optionalParameters.first.name, 'body');
          expect(
            method.optionalParameters.first.type?.accept(emitter).toString(),
            'CreateUserRequestBody',
          );
        });

        test('generates method body with request body', () {
          final generatedCode = format(
            generatedClass.accept(emitter).toString(),
          );

          const expectedMethod = '''
            Future<TonikResult<void>> createUser({
              required CreateUserRequestBody body,
            }) async => _createUser(body: body);
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedMethod)),
          );
        });
      });

      group('method with aliased parameters', () {
        late Class generatedClass;
        late Operation operation;

        setUp(() {
          operation = Operation(
            operationId: 'getUser',
            context: testContext,
            summary: 'Get user',
            description: 'Get user by ID',
            tags: {Tag(name: 'users')},
            isDeprecated: false,
            path: '/users/{user_id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: {
              PathParameterAlias(
                name: 'myAlias',
                parameter: PathParameterObject(
                  name: null,
                  rawName: 'user_id',
                  description: 'User ID',
                  isRequired: true,
                  isDeprecated: false,
                  allowEmptyValue: false,
                  explode: false,
                  encoding: PathParameterEncoding.simple,
                  model: StringModel(context: testContext),
                  context: testContext,
                ),
                context: testContext,
              ),
            },
            responses: const {},
            securitySchemes: const {},
            cookieParameters: const {},
          );

          generatedClass = generator.generateClass(
            {operation},
            Tag(name: 'users'),
            testServers,
          );
        });

        test('generates method with aliased parameter', () {
          final method = generatedClass.methods.first;
          expect(method.name, 'getUser');
          expect(method.optionalParameters.length, 1);
          expect(method.optionalParameters.first.name, 'userId');
          expect(
            method.optionalParameters.first.type?.accept(emitter).toString(),
            'String',
          );
        });

        test('generates method body with aliased parameter', () {
          final generatedCode = format(
            generatedClass.accept(emitter).toString(),
          );

          const expectedMethod = '''
            Future<TonikResult<void>> getUser({required String userId}) async => _getUser(userId: userId);
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedMethod)),
          );
        });
      });

      group('method with only summary or description', () {
        test('generates method with doc string from only summary', () {
          final operation = Operation(
            operationId: 'getUser',
            context: testContext,
            summary: 'Get user',
            tags: {Tag(name: 'users')},
            isDeprecated: false,
            path: '/users/{id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final generatedClass = generator.generateClass(
            {operation},
            Tag(name: 'users'),
            testServers,
          );

          final method = generatedClass.methods.first;

          // Check that method has documentation with only summary
          expect(method.docs, isNotEmpty);
          expect(method.docs, contains('/// Get user'));
          expect(method.docs.length, 1);
        });

        test('generates method with doc string from only description', () {
          final operation = Operation(
            operationId: 'getUser',
            context: testContext,
            description: 'Get user by ID',
            tags: {Tag(name: 'users')},
            isDeprecated: false,
            path: '/users/{id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final generatedClass = generator.generateClass(
            {operation},
            Tag(name: 'users'),
            testServers,
          );

          final method = generatedClass.methods.first;

          // Check that method has documentation with only description
          expect(method.docs, isNotEmpty);
          expect(method.docs, contains('/// Get user by ID'));
          expect(method.docs.length, 1);
        });

        test('generates method with multiline doc strings', () {
          final operation = Operation(
            operationId: 'getUser',
            context: testContext,
            summary: 'Get user\ndetails',
            description: 'Get user by ID\nand return profile data',
            tags: {Tag(name: 'users')},
            isDeprecated: false,
            path: '/users/{id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final generatedClass = generator.generateClass(
            {operation},
            Tag(name: 'users'),
            testServers,
          );

          final method = generatedClass.methods.first;

          // Check that method has multiline documentation
          expect(method.docs, isNotEmpty);
          expect(method.docs.length, 4);

          expect(method.docs[0], '/// Get user');
          expect(method.docs[1], '/// details');
          expect(method.docs[2], '/// Get user by ID');
          expect(method.docs[3], '/// and return profile data');
        });
      });

      group('method with real operation docs ordering', () {
        test('places description before summary', () {
          final operation = Operation(
            operationId: 'getUser',
            context: testContext,
            summary: 'Get user',
            description: 'Get user by ID',
            tags: {Tag(name: 'users')},
            isDeprecated: false,
            path: '/users/{id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final generatedClass = generator.generateClass(
            {operation},
            Tag(name: 'users'),
            testServers,
          );

          final method = generatedClass.methods.first;

          // Check documentation order
          expect(method.docs, isNotEmpty);
          expect(method.docs.length, 2);

          expect(method.docs[0], '/// Get user');
          expect(method.docs[1], '/// Get user by ID');
        });

        test('works with multiline doc comments', () {
          final operation = Operation(
            operationId: 'getUser',
            context: testContext,
            summary: 'Get user\nwith details',
            description: 'Get user by ID\nand return profile data',
            tags: {Tag(name: 'users')},
            isDeprecated: false,
            path: '/users/{id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final generatedClass = generator.generateClass(
            {operation},
            Tag(name: 'users'),
            testServers,
          );

          final method = generatedClass.methods.first;

          // Check documentation order with multiline comments
          expect(method.docs, isNotEmpty);
          expect(method.docs.length, 4);

          expect(method.docs[0], '/// Get user');
          expect(method.docs[1], '/// with details');
          expect(method.docs[2], '/// Get user by ID');
          expect(method.docs[3], '/// and return profile data');
        });
      });
    });

    group('parameter descriptions in docs', () {
      test('includes parameter descriptions in method doc comments', () {
        final operation = Operation(
          operationId: 'getUser',
          context: testContext,
          summary: 'Get user',
          description: 'Get user by ID',
          tags: {Tag(name: 'users')},
          isDeprecated: false,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {
            QueryParameterObject(
              name: 'includeDetails',
              rawName: 'include_details',
              description: 'Whether to include additional details',
              isRequired: false,
              isDeprecated: false,
              allowEmptyValue: false,
              allowReserved: false,
              explode: false,
              model: BooleanModel(context: testContext),
              encoding: QueryParameterEncoding.form,
              context: testContext,
            ),
          },
          pathParameters: {
            PathParameterObject(
              name: 'id',
              rawName: 'id',
              description: 'The unique user identifier',
              isRequired: true,
              isDeprecated: false,
              allowEmptyValue: false,
              explode: false,
              model: IntegerModel(context: testContext),
              encoding: PathParameterEncoding.simple,
              context: testContext,
            ),
          },
          responses: const {},
          securitySchemes: const {},
          cookieParameters: const {},
        );

        final generatedClass = generator.generateClass(
          {operation},
          Tag(name: 'users'),
          testServers,
        );

        final method = generatedClass.methods.first;

        // Check that parameter descriptions are in the docs.
        expect(method.docs, contains('/// [id] The unique user identifier'));
        expect(
          method.docs,
          contains(
            '/// [includeDetails] Whether to include additional details',
          ),
        );
      });

      test('includes overridden description from parameter alias', () {
        final originalParam = QueryParameterObject(
          name: 'limit',
          rawName: 'limit',
          description: 'Original description from component',
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: IntegerModel(context: testContext),
          encoding: QueryParameterEncoding.form,
          context: testContext,
        );

        final aliasParam = QueryParameterAlias(
          name: 'limit',
          parameter: originalParam,
          context: testContext,
          description: 'Overridden description from reference',
        );

        final operation = Operation(
          operationId: 'listUsers',
          context: testContext,
          summary: 'List users',
          tags: {Tag(name: 'users')},
          isDeprecated: false,
          path: '/users',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {aliasParam},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          {operation},
          Tag(name: 'users'),
          testServers,
        );

        final method = generatedClass.methods.first;

        // Check that the overridden description is used.
        expect(
          method.docs,
          contains('/// [limit] Overridden description from reference'),
        );
      });
    });

    test('generates ready-to-use code and filename', () {
      final operation = Operation(
        operationId: 'getUser',
        context: testContext,
        summary: 'Get user',
        description: 'Get user by ID',
        tags: {Tag(name: 'users')},
        isDeprecated: false,
        path: '/users/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      final result = generator.generate(
        {operation},
        Tag(name: 'users'),
        testServers,
      );

      expect(result.filename, 'users_api.dart');
      expect(result.code, contains('class UsersApi'));
      expect(
        result.code,
        contains('_i2.Future<_i3.TonikResult<void>> getUser()'),
      );
    });
  });
}
