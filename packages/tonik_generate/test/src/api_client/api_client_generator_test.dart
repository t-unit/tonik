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

  final format =
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;

  setUp(() {
    nameManager = NameManager(generator: NameGenerator());
    generator = ApiClientGenerator(
      nameManager: nameManager,
      package: 'test_package',
    );
    testContext = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('ApiClientGenerator', () {
    group('class generation', () {
      test('generates API client class for a tag', () {
        final operation = Operation(
          operationId: 'getUser',
          context: testContext,
          summary: 'Get user',
          description: 'Get user by ID',
          tags: {const Tag(name: 'users')},
          isDeprecated: false,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
          requestBody: null,
        );

        final generatedClass = generator.generateClass({
          operation,
        }, const Tag(name: 'users'),);

        // Test class definition
        expect(generatedClass.name, 'UsersApi');
        expect(generatedClass.fields.length, 1);
        expect(generatedClass.fields.first.name, '_dio');
        expect(
          generatedClass.fields.first.type?.accept(emitter).toString(),
          'Dio',
        );

        // Test constructor
        final constructor = generatedClass.constructors.first;
        expect(constructor.requiredParameters.length, 1);
        expect(constructor.requiredParameters.first.name, '_dio');
        expect(constructor.requiredParameters.first.toThis, isTrue);
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
            tags: {const Tag(name: 'users')},
            isDeprecated: false,
            path: '/users/{id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            responses: const {},
            requestBody: null,
          );

          generatedClass = generator.generateClass({
            operation,
          }, const Tag(name: 'users'),);
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
            Future<TonikResult<void>> getUser() async => GetUser(_dio).call();
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedMethod)),
          );
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
            tags: {const Tag(name: 'users')},
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
            requestBody: null,
          );

          generatedClass = generator.generateClass({
            operation,
          }, const Tag(name: 'users'),);
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
            Future<TonikResult<void>> getUser({required String id}) async =>
                GetUser(_dio).call(id: id);
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
            tags: {const Tag(name: 'users')},
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
            responses: const {},
            requestBody: null,
          );

          generatedClass = generator.generateClass({
            operation,
          }, const Tag(name: 'users'),);
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
            Future<TonikResult<void>> getUsers({int? limit, int? offset}) async =>
                GetUsers(_dio).call(limit: limit, offset: offset);
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
            tags: {const Tag(name: 'users')},
            isDeprecated: false,
            path: '/users',
            method: HttpMethod.post,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            responses: const {},
            requestBody: RequestBodyObject(
              name: 'createUser',
              context: testContext,
              description: 'User data',
              isRequired: true,
              content: {
                RequestContent(
                  model: ClassModel(
                    name: 'CreateUserRequestBody',
                    properties: [
                      Property(
                        name: 'name',
                        model: StringModel(context: testContext),
                        isRequired: true,
                        isNullable: false,
                        isDeprecated: false,
                      ),
                      Property(
                        name: 'email',
                        model: StringModel(context: testContext),
                        isRequired: true,
                        isNullable: false,
                        isDeprecated: false,
                      ),
                    ],
                    context: testContext,
                  ),
                  contentType: ContentType.json,
                  rawContentType: 'application/json',
                ),
              },
            ),
          );

          generatedClass = generator.generateClass({
            operation,
          }, const Tag(name: 'users'),);
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
            }) async =>
                CreateUser(_dio).call(body: body);
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
            tags: {const Tag(name: 'users')},
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
            requestBody: null,
          );

          generatedClass = generator.generateClass({
            operation,
          }, const Tag(name: 'users'),);
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
            Future<TonikResult<void>> getUser({required String userId}) async =>
                GetUser(_dio).call(userId: userId);
          ''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedMethod)),
          );
        });
      });
    });

    test('generates ready-to-use code and filename', () {
      final operation = Operation(
        operationId: 'getUser',
        context: testContext,
        summary: 'Get user',
        description: 'Get user by ID',
        tags: {const Tag(name: 'users')},
        isDeprecated: false,
        path: '/users/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: const {},
        requestBody: null,
      );

      final result = generator.generate({operation}, const Tag(name: 'users'));

      expect(result.filename, 'users_api.dart');
      expect(result.code, contains('class UsersApi'));
      expect(result.code, contains('final _i1.Dio _dio;'));
      expect(
        result.code,
        contains('_i2.Future<_i3.TonikResult<void>> getUser()'),
      );
    });
  });
}
