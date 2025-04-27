import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/response_wrapper/response_wrapper_generator.dart';

void main() {
  late DartEmitter emitter;
  late NameManager nameManager;
  late ResponseWrapperGenerator generator;
  late Context testContext;

  setUp(() {
    emitter = DartEmitter(orderDirectives: true, useNullSafetySyntax: true);
    nameManager = NameManager(generator: NameGenerator());
    generator = ResponseWrapperGenerator(
      nameManager: nameManager,
      package: 'test_package',
    );
    testContext = Context.initial();
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
      );
    });

    test('returns the expected Dart filename', () {
      final result = generator.generate(operation);
      expect(result.filename, 'test_operation_response_wrapper.dart');
    });

    test('contains the base class', () {
      final result = generator.generate(operation);
      expect(
        result.code,
        contains('sealed class TestOperationResponseWrapper'),
      );
    });

    test('contains all expected subclasses', () {
      final result = generator.generate(operation);
      expect(result.code, contains('class TestOperationResponseWrapper404'));
      expect(result.code, contains('class TestOperationResponseWrapper200'));
    });
  });

  group('generateClasses', () {
    test('returns proper class definitions for all responses', () {
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
      );
      final classes = generator.generateClasses(operation);
      expect(classes, isNotEmpty);
      final baseClass = classes.first;
      expect(baseClass.name, 'TestOperationResponseWrapper');
      expect(baseClass.sealed, isTrue);
      expect(baseClass.extend, isNull);
      expect(baseClass.fields, isEmpty);

      final subclassNames = classes.skip(1).map((c) => c.name).toSet();
      expect(
        subclassNames,
        containsAll({
          'TestOperationResponseWrapper200',
          'TestOperationResponseWrapper404',
        }),
      );
      for (final subclass in classes.skip(1)) {
        expect(subclass.extend?.symbol, baseClass.name);
        expect(subclass.fields, isEmpty);
        expect(subclass.constructors, isNotEmpty);
      }
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
      );
      expect(() => generator.generateClasses(operation), throwsArgumentError);
    });

    test('single response with multiple content types', () {
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
      );
      final classes = generator.generateClasses(operation);
      expect(classes, hasLength(2));
      expect(classes.first.name, 'TestOperationResponseWrapper');
      expect(classes.last.name, 'TestOperationResponseWrapper200');
    });

    test('multiple responses with single content type each', () {
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
      );
      final classes = generator.generateClasses(operation);
      expect(classes, isNotEmpty);
      final baseClass = classes.first;
      expect(baseClass.name, 'TestOperationResponseWrapper');
      final subclassNames = classes.skip(1).map((c) => c.name).toSet();
      expect(
        subclassNames,
        containsAll({
          'TestOperationResponseWrapper200',
          'TestOperationResponseWrapper404',
        }),
      );
    });

    test('handles DefaultResponseStatus', () {
      final responses = {
        const DefaultResponseStatus(): ResponseObject(
          name: 'DefaultResponse',
          context: testContext,
          description: 'Default',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        ),
      };
      final operation = Operation(
        operationId: 'MyOperation',
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
      );
      final classes = generator.generateClasses(operation);
      expect(classes, hasLength(2));
      expect(classes.first.name, 'MyOperationResponseWrapper');
      expect(classes.last.name, 'MyOperationResponseWrapperDefault');
    });

    test('handles RangeResponseStatus', () {
      final responses = {
        const RangeResponseStatus(min: 200, max: 299): ResponseObject(
          name: 'RangeResponse',
          context: testContext,
          description: 'Range',
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
        const DefaultResponseStatus(): ResponseObject(
          name: 'DefaultResponse',
          context: testContext,
          description: 'Default',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        ),
      };
      final operation = Operation(
        operationId: 'updatePet',
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
      );
      final classes = generator.generateClasses(operation);
      expect(classes, hasLength(4));
      expect(classes[0].name, 'UpdatePetResponseWrapper');
      expect(classes[1].name, 'UpdatePetResponseWrapper2XX');
      expect(classes[2].name, 'UpdatePetResponseWrapper404');
      expect(classes[3].name, 'UpdatePetResponseWrapperDefault');
    });
  });
}
