import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/response_wrapper/response_wrapper_generator.dart';

void main() {
  late NameManager nameManager;
  late ResponseWrapperGenerator generator;
  late Context testContext;
  late DartEmitter emitter;

  setUp(() {
    nameManager = NameManager(generator: NameGenerator());
    generator = ResponseWrapperGenerator(
      nameManager: nameManager,
      package: 'test_package',
    );
    testContext = Context.initial();
    emitter = DartEmitter();
  });

  group('generate', () {
    late Operation operation;

    setUp(() {
      final responses = {
        const ExplicitResponseStatus(statusCode: 200): ResponseObject(
          name: 'SuccessResponse',
          context: testContext,
          description: 'Success',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'application/xml',
              contentType: ContentType.json,
            ),
          },
        ),
        const ExplicitResponseStatus(statusCode: 404): ResponseObject(
          name: 'NotFoundResponse',
          context: testContext,
          description: 'Not found',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'text/plain',
              contentType: ContentType.json,
            ),
          },
        ),
      };
      operation = Operation(
        operationId: 'testOperation',
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: responses,
        requestBody: null,
        securitySchemes: const {},
      );
    });

    test('returns the expected Dart filename', () {
      final result = generator.generate(operation);
      expect(result.filename, 'test_operation_response.dart');
    });

    test('contains the base class', () {
      final result = generator.generate(operation);
      expect(result.code, contains('sealed class TestOperationResponse'));
    });

    test('contains all expected subclasses', () {
      final result = generator.generate(operation);
      expect(result.code, contains('class TestOperationResponse404'));
      expect(result.code, contains('class TestOperationResponse200'));
    });
  });

  group('generateClasses', () {
    test('returns proper body property and constructor for all responses', () {
      final responses = {
        const ExplicitResponseStatus(statusCode: 200): ResponseObject(
          name: 'SuccessResponse',
          context: testContext,
          description: 'Success',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'application/xml',
              contentType: ContentType.json,
            ),
          },
        ),
        const ExplicitResponseStatus(statusCode: 404): ResponseObject(
          name: 'NotFoundResponse',
          context: testContext,
          description: 'Not found',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'text/plain',
              contentType: ContentType.json,
            ),
          },
        ),
      };
      final operation = Operation(
        operationId: 'TestOperation',
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: responses,
        requestBody: null,
        securitySchemes: const {},
      );
      final classes = generator.generateClasses(operation);
      expect(classes, isNotEmpty);
      final baseClass = classes.first;
      expect(baseClass.name, 'TestOperationResponse');
      expect(baseClass.sealed, isTrue);
      expect(baseClass.extend, isNull);
      expect(baseClass.fields, isEmpty);

      final subclassNames = classes.skip(1).map((c) => c.name).toSet();
      expect(
        subclassNames,
        containsAll({'TestOperationResponse200', 'TestOperationResponse404'}),
      );
      // 200 has multiple bodies, so should have a body
      // field referencing SuccessResponse
      // 404 has one body, so has body field of type String
      final subclass200 = classes.firstWhere(
        (c) => c.name == 'TestOperationResponse200',
      );
      final subclass404 = classes.firstWhere(
        (c) => c.name == 'TestOperationResponse404',
      );
      expect(subclass200.fields.length, 1);
      expect(subclass200.fields.first.name, 'body');
      expect(subclass200.fields.first.type?.symbol, 'SuccessResponse');
      expect(subclass404.fields.length, 1);
      expect(subclass404.fields.first.name, 'body');
      expect(subclass404.fields.first.type?.symbol, 'String');

      // Constructor for 200 and 404 should have body as named,
      // required argument
      final ctor200 = subclass200.constructors.first;
      final ctor404 = subclass404.constructors.first;
      expect(
        ctor200.optionalParameters.any(
          (p) => p.name == 'body' && p.named && p.required,
        ),
        isTrue,
      );
      expect(
        ctor404.optionalParameters.any(
          (p) => p.name == 'body' && p.named && p.required,
        ),
        isTrue,
      );
    });

    test('throws if there are no responses', () {
      final responses = <ResponseStatus, Response>{};
      final operation = Operation(
        operationId: 'TestOperation',
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: responses,
        requestBody: null,
        securitySchemes: const {},
      );
      expect(() => generator.generateClasses(operation), throwsArgumentError);
    });

    test('generated subclasses have equals and hashCode methods', () {
      final responses = {
        const ExplicitResponseStatus(statusCode: 200): ResponseObject(
          name: 'SuccessResponse',
          context: testContext,
          description: 'Success',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'text/plain',
              contentType: ContentType.json,
            ),
          },
        ),
      };
      final operation = Operation(
        operationId: 'TestOperation',
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: responses,
        requestBody: null,
        securitySchemes: const {},
      );

      final classes = generator.generateClasses(operation);
      final subclass = classes.firstWhere(
        (c) => c.name == 'TestOperationResponse200',
      );

      // Verify equals method exists
      expect(subclass.methods.any((m) => m.name == 'operator =='), isTrue);

      // Verify hashCode getter exists
      expect(
        subclass.methods.any(
          (m) => m.name == 'hashCode' && m.type == MethodType.getter,
        ),
        isTrue,
      );
    });

    test('generated subclasses have @immutable annotation', () {
      final responses = {
        const ExplicitResponseStatus(statusCode: 200): ResponseObject(
          name: 'SuccessResponse',
          context: testContext,
          description: 'Success',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'text/plain',
              contentType: ContentType.json,
            ),
          },
        ),
      };
      final operation = Operation(
        operationId: 'TestOperation',
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: responses,
        requestBody: null,
        securitySchemes: const {},
      );

      final classes = generator.generateClasses(operation);
      final subclass = classes.firstWhere(
        (c) => c.name == 'TestOperationResponse200',
      );

      // Verify @immutable annotation exists
      expect(subclass.annotations.length, 1);
      final annotation = subclass.annotations.first;
      expect(annotation.accept(emitter).toString(), 'immutable');
    });

    test(
      'body property references response class for multiple content types',
      () {
        final responses = {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: 'MultiContentResponse',
            context: testContext,
            description: 'Multi content',
            headers: const {},
            bodies: {
              ResponseBody(
                model: StringModel(context: testContext),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
              ResponseBody(
                model: StringModel(context: testContext),
                rawContentType: 'application/xml',
                contentType: ContentType.json,
              ),
            },
          ),
        };
        final operation = Operation(
          operationId: 'TestOperation',
          context: testContext,
          summary: null,
          description: null,
          tags: const {},
          isDeprecated: false,
          path: '/test',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: responses,
          requestBody: null,
          securitySchemes: const {},
        );
        final classes = generator.generateClasses(operation);
        expect(classes, hasLength(2));
        expect(classes.first.name, 'TestOperationResponse');
        expect(classes.last.name, 'TestOperationResponse200');
        // Should have a body property referencing the response class
        final subclass = classes.last;
        expect(subclass.fields.length, 1);
        expect(subclass.fields.first.name, 'body');
        expect(subclass.fields.first.type?.symbol, 'MultiContentResponse');
        // Constructor should take 'body' as named, required argument
        final ctor = subclass.constructors.first;
        expect(
          ctor.optionalParameters.any(
            (p) => p.name == 'body' && p.named && p.required,
          ),
          isTrue,
        );
      },
    );

    test('body property is correct type for each single-content response', () {
      final responses = {
        const ExplicitResponseStatus(statusCode: 200): ResponseObject(
          name: 'SuccessResponse',
          context: testContext,
          description: 'Success',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        ),
        const ExplicitResponseStatus(statusCode: 404): ResponseObject(
          name: 'NotFoundResponse',
          context: testContext,
          description: 'Not found',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'text/plain',
              contentType: ContentType.json,
            ),
          },
        ),
      };
      final operation = Operation(
        operationId: 'TestOperation',
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: responses,
        requestBody: null,
        securitySchemes: const {},
      );
      final classes = generator.generateClasses(operation);
      expect(classes, isNotEmpty);
      final baseClass = classes.first;
      expect(baseClass.name, 'TestOperationResponse');
      final subclassNames = classes.skip(1).map((c) => c.name).toSet();
      expect(
        subclassNames,
        containsAll({'TestOperationResponse200', 'TestOperationResponse404'}),
      );
      // Both should have a body property of type String
      final subclass200 = classes.firstWhere(
        (c) => c.name == 'TestOperationResponse200',
      );
      final subclass404 = classes.firstWhere(
        (c) => c.name == 'TestOperationResponse404',
      );
      expect(subclass200.fields.length, 1);
      expect(subclass200.fields.first.name, 'body');
      expect(subclass200.fields.first.type?.symbol, 'String');
      expect(subclass404.fields.length, 1);
      expect(subclass404.fields.first.name, 'body');
      expect(subclass404.fields.first.type?.symbol, 'String');
      // Constructor should take 'body' as named, required argument
      final ctor200 = subclass200.constructors.first;
      final ctor404 = subclass404.constructors.first;
      expect(
        ctor200.optionalParameters.any(
          (p) => p.name == 'body' && p.named && p.required,
        ),
        isTrue,
      );
      expect(
        ctor404.optionalParameters.any(
          (p) => p.name == 'body' && p.named && p.required,
        ),
        isTrue,
      );
    });

    test(
      'body property type matches single-body, multi-body, and header cases',
      () {
        final responses = {
          const ExplicitResponseStatus(statusCode: 201): ResponseObject(
            name: 'CreatedResponse',
            context: testContext,
            description: 'Created',
            headers: const {},
            bodies: {
              ResponseBody(
                model: IntegerModel(context: testContext),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
          const ExplicitResponseStatus(statusCode: 400): ResponseObject(
            name: 'BadRequestResponse',
            context: testContext,
            description: 'Bad request',
            headers: const {},
            bodies: {
              ResponseBody(
                model: StringModel(context: testContext),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
          const ExplicitResponseStatus(statusCode: 409): ResponseObject(
            name: 'ConflictResponse',
            context: testContext,
            description: 'Conflict',
            headers: {
              'X-Error': ResponseHeaderObject(
                model: StringModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                context: testContext,
                name: null,
                description: '',
                explode: false,
                encoding: ResponseHeaderEncoding.simple,
              ),
            },
            bodies: {
              ResponseBody(
                model: StringModel(context: testContext),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
          const ExplicitResponseStatus(statusCode: 500): ResponseObject(
            name: 'ServerErrorResponse',
            context: testContext,
            description: 'Server error',
            headers: const {},
            bodies: {
              ResponseBody(
                model: StringModel(context: testContext),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
              ResponseBody(
                model: IntegerModel(context: testContext),
                rawContentType: 'application/xml',
                contentType: ContentType.json,
              ),
            },
          ),
        };
        final operation = Operation(
          operationId: 'CreateEntity',
          context: testContext,
          summary: null,
          description: null,
          tags: const {},
          isDeprecated: false,
          path: '/entity',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: responses,
          requestBody: null,
          securitySchemes: const {},
        );
        final classes = generator.generateClasses(operation);
        final subclass201 = classes.firstWhere(
          (c) => c.name == 'CreateEntityResponse201',
        );
        final subclass400 = classes.firstWhere(
          (c) => c.name == 'CreateEntityResponse400',
        );
        final subclass409 = classes.firstWhere(
          (c) => c.name == 'CreateEntityResponse409',
        );
        final subclass500 = classes.firstWhere(
          (c) => c.name == 'CreateEntityResponse500',
        );

        // Should have a 'body' property for all, but type differs
        expect(subclass201.fields.any((f) => f.name == 'body'), isTrue);
        expect(subclass400.fields.any((f) => f.name == 'body'), isTrue);
        expect(subclass409.fields.any((f) => f.name == 'body'), isTrue);
        expect(subclass500.fields.any((f) => f.name == 'body'), isTrue);

        // Check the type of the 'body' property
        final bodyField201 = subclass201.fields.firstWhere(
          (f) => f.name == 'body',
        );
        final bodyField400 = subclass400.fields.firstWhere(
          (f) => f.name == 'body',
        );
        final bodyField409 = subclass409.fields.firstWhere(
          (f) => f.name == 'body',
        );
        final bodyField500 = subclass500.fields.firstWhere(
          (f) => f.name == 'body',
        );
        // IntegerModel for 201, StringModel for 400, ConflictResponse
        // for 409, ServerErrorResponse for 500
        expect(bodyField201.type?.symbol, 'int');
        expect(bodyField400.type?.symbol, 'String');
        expect(bodyField409.type?.symbol, 'ConflictResponse');
        expect(bodyField500.type?.symbol, 'ServerErrorResponse');
      },
    );

    test('subclass has body property for ResponseAlias resolving '
        'to single-body, no-header ResponseObject', () {
      final aliasTarget = ResponseObject(
        name: 'AliasTarget',
        context: testContext,
        description: 'Alias target',
        headers: const {},
        bodies: {
          ResponseBody(
            model: IntegerModel(context: testContext),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
      );
      final responses = {
        const ExplicitResponseStatus(statusCode: 201): ResponseAlias(
          name: 'CreatedAlias',
          response: aliasTarget,
          context: testContext,
        ),
      };
      final operation = Operation(
        operationId: 'CreateEntityAlias',
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
        path: '/entity/alias',
        method: HttpMethod.post,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: responses,
        requestBody: null,
        securitySchemes: const {},
      );
      final classes = generator.generateClasses(operation);
      final subclass201 = classes.firstWhere(
        (c) => c.name == 'CreateEntityAliasResponse201',
      );
      // Should have a 'body' property
      expect(subclass201.fields.any((f) => f.name == 'body'), isTrue);
      final bodyField = subclass201.fields.firstWhere((f) => f.name == 'body');
      expect(bodyField.type?.symbol, 'int');

      // Check that the constructor takes 'body' as a named, required argument
      final ctor = subclass201.constructors.first;
      expect(
        ctor.optionalParameters.any(
          (p) => p.name == 'body' && p.named && p.required,
        ),
        isTrue,
      );
    });
  });
}
