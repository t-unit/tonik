import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/api_client/api_client_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/operation_generator.dart';

void main() {
  late NameManager nameManager;
  late Context testContext;
  late DartEmitter emitter;
  late List<Server> testServers;

  setUp(() {
    nameManager = NameManager(generator: NameGenerator());
    testContext = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);

    testServers = [
      const Server(
        url: 'https://api.example.com',
        description: 'Production server',
      ),
    ];
  });

  group('ApiClientGenerator operation deprecation', () {
    late ApiClientGenerator generator;

    setUp(() {
      generator = ApiClientGenerator(
        nameManager: nameManager,
        package: 'package:test_package/test_package.dart',
      );
    });

    test(
      'adds @Deprecated annotation to method when operation is deprecated',
      () {
        final deprecatedOperation = Operation(
          operationId: 'getLegacyUser',
          context: testContext,
          summary: 'Get legacy user',
          description: 'This endpoint is deprecated',
          tags: {Tag(name: 'users')},
          isDeprecated: true,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          {deprecatedOperation},
          Tag(name: 'users'),
          testServers,
        );

        final method = generatedClass.methods.firstWhere(
          (m) => m.name == 'getLegacyUser',
        );

        final hasDeprecatedAnnotation = method.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isTrue);
      },
    );

    test(
      'does not add @Deprecated annotation to method when operation '
      'is not deprecated',
      () {
        final activeOperation = Operation(
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
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          {activeOperation},
          Tag(name: 'users'),
          testServers,
        );

        final method = generatedClass.methods.firstWhere(
          (m) => m.name == 'getUser',
        );

        final hasDeprecatedAnnotation = method.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isFalse);
      },
    );
  });

  group('OperationGenerator class deprecation', () {
    late OperationGenerator generator;

    setUp(() {
      generator = OperationGenerator(
        nameManager: nameManager,
        package: 'package:test_package/test_package.dart',
      );
    });

    test(
      'adds @Deprecated annotation to operation class when operation '
      'is deprecated',
      () {
        final deprecatedOperation = Operation(
          operationId: 'getLegacyUser',
          context: testContext,
          summary: 'Get legacy user',
          description: 'This endpoint is deprecated',
          tags: {Tag(name: 'users')},
          isDeprecated: true,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          deprecatedOperation,
          'GetLegacyUser',
        );

        final hasDeprecatedAnnotation = generatedClass.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isTrue);
      },
    );

    test(
      'does not add @Deprecated annotation to operation class when '
      'operation is not deprecated',
      () {
        final activeOperation = Operation(
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
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          activeOperation,
          'GetUser',
        );

        final hasDeprecatedAnnotation = generatedClass.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isFalse);
      },
    );
  });

  group('ApiClientGenerator deprecated parameters', () {
    late ApiClientGenerator generator;
    late DartEmitter emitter;

    setUp(() {
      generator = ApiClientGenerator(
        nameManager: nameManager,
        package: 'package:test_package/test_package.dart',
      );
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    test(
      'adds @Deprecated annotation to deprecated query parameter',
      () {
        final operationWithDeprecatedQueryParam = Operation(
          operationId: 'getUsers',
          context: testContext,
          summary: 'Get users',
          description: 'Get list of users',
          tags: {Tag(name: 'users')},
          isDeprecated: false,
          path: '/users',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {
            QueryParameterObject(
              name: 'legacyFilter',
              rawName: 'legacy_filter',
              description: 'Use filter instead',
              isRequired: false,
              isDeprecated: true,
              allowEmptyValue: false,
              allowReserved: false,
              explode: true,
              model: StringModel(context: testContext),
              encoding: QueryParameterEncoding.form,
              context: testContext,
            ),
          },
          pathParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          {operationWithDeprecatedQueryParam},
          Tag(name: 'users'),
          testServers,
        );

        final method = generatedClass.methods.firstWhere(
          (m) => m.name == 'getUsers',
        );

        final deprecatedParam = method.optionalParameters.firstWhere(
          (p) => p.name == 'legacyFilter',
        );

        final hasDeprecatedAnnotation = deprecatedParam.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isTrue);
      },
    );

    test(
      'adds @Deprecated annotation to deprecated path parameter',
      () {
        final operationWithDeprecatedPathParam = Operation(
          operationId: 'getUserLegacy',
          context: testContext,
          summary: 'Get user by legacy ID',
          description: 'Get user',
          tags: {Tag(name: 'users')},
          isDeprecated: false,
          path: '/users/{legacyId}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: {
            PathParameterObject(
              name: 'legacyId',
              rawName: 'legacyId',
              description: 'Use id instead',
              isRequired: true,
              isDeprecated: true,
              allowEmptyValue: false,
              explode: false,
              model: StringModel(context: testContext),
              encoding: PathParameterEncoding.simple,
              context: testContext,
            ),
          },
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          {operationWithDeprecatedPathParam},
          Tag(name: 'users'),
          testServers,
        );

        final method = generatedClass.methods.firstWhere(
          (m) => m.name == 'getUserLegacy',
        );

        final deprecatedParam = method.optionalParameters.firstWhere(
          (p) => p.name == 'legacyId',
        );

        final hasDeprecatedAnnotation = deprecatedParam.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isTrue);
      },
    );

    test(
      'adds @Deprecated annotation to deprecated header parameter',
      () {
        final operationWithDeprecatedHeader = Operation(
          operationId: 'getUser',
          context: testContext,
          summary: 'Get user',
          description: 'Get user by ID',
          tags: {Tag(name: 'users')},
          isDeprecated: false,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: {
            RequestHeaderObject(
              name: 'xLegacyAuth',
              rawName: 'X-Legacy-Auth',
              description: 'Use Authorization header instead',
              isRequired: false,
              isDeprecated: true,
              allowEmptyValue: false,
              explode: false,
              model: StringModel(context: testContext),
              encoding: HeaderParameterEncoding.simple,
              context: testContext,
            ),
          },
          queryParameters: const {},
          pathParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          {operationWithDeprecatedHeader},
          Tag(name: 'users'),
          testServers,
        );

        final method = generatedClass.methods.firstWhere(
          (m) => m.name == 'getUser',
        );

        final deprecatedParam = method.optionalParameters.firstWhere(
          (p) => p.name == 'legacyAuth',
        );

        final hasDeprecatedAnnotation = deprecatedParam.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isTrue);
      },
    );

    test(
      'does not add @Deprecated annotation to non-deprecated parameters',
      () {
        final operationWithActiveParams = Operation(
          operationId: 'getUsers',
          context: testContext,
          summary: 'Get users',
          description: 'Get list of users',
          tags: {Tag(name: 'users')},
          isDeprecated: false,
          path: '/users',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {
            QueryParameterObject(
              name: 'filter',
              rawName: 'filter',
              description: 'Filter users',
              isRequired: false,
              isDeprecated: false,
              allowEmptyValue: false,
              allowReserved: false,
              explode: true,
              model: StringModel(context: testContext),
              encoding: QueryParameterEncoding.form,
              context: testContext,
            ),
          },
          pathParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          {operationWithActiveParams},
          Tag(name: 'users'),
          testServers,
        );

        final method = generatedClass.methods.firstWhere(
          (m) => m.name == 'getUsers',
        );

        final param = method.optionalParameters.firstWhere(
          (p) => p.name == 'filter',
        );

        final hasDeprecatedAnnotation = param.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isFalse);
      },
    );
  });
}
