import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/operation/operation_generator.dart';

void main() {
  group('OperationGenerator call method return type', () {
    late OperationGenerator generator;
    late Context context;
    late DartEmitter emitter;
    late NameManager nameManager;
    late NameGenerator nameGenerator;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = OperationGenerator(
        nameManager: nameManager,
        package: 'package:api/api.dart',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    test('returns response wrapper for multiple status codes', () {
      final operation = Operation(
        operationId: 'multiStatus',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/multi',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        securitySchemes: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: 'Success',
            context: context,
            headers: const {},
            description: '',
            bodies: {
              ResponseBody(
                model: StringModel(context: context),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
          const ExplicitResponseStatus(statusCode: 400): ResponseObject(
            name: 'Error',
            context: context,
            headers: const {},
            description: '',
            bodies: {
              ResponseBody(
                model: StringModel(context: context),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        },
      );
      const normalizedParams = NormalizedRequestParameters(
        pathParameters: [],
        queryParameters: [],
        headers: [],
        cookieParameters: [],
      );
      final method = generator.generateCallMethod(operation, normalizedParams);
      expect(
        method.returns?.accept(emitter).toString(),
        'Future<TonikResult<MultiStatusResponse>>',
      );
    });

    test('returns void result for single status code w/o body or headers', () {
      final operation = Operation(
        operationId: 'voidStatus',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/void',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        securitySchemes: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 204): ResponseObject(
            name: 'NoContent',
            context: context,
            headers: const {},
            description: '',
            bodies: const {},
          ),
        },
      );
      const normalizedParams = NormalizedRequestParameters(
        pathParameters: [],
        queryParameters: [],
        headers: [],
        cookieParameters: [],
      );
      final method = generator.generateCallMethod(operation, normalizedParams);
      expect(
        method.returns?.accept(emitter).toString(),
        'Future<TonikResult<void>>',
      );
    });

    test('returns result for single status code with headers', () {
      final operation = Operation(
        operationId: 'headerStatus',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/header',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        securitySchemes: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: 'HeaderResponse',
            context: context,
            headers: {
              'X-Header': ResponseHeaderObject(
                name: 'X-Header',
                description: '',
                explode: false,
                model: StringModel(context: context),
                isRequired: true,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
                context: context,
              ),
            },
            description: '',
            bodies: {
              ResponseBody(
                model: StringModel(context: context),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        },
      );
      const normalizedParams = NormalizedRequestParameters(
        pathParameters: [],
        queryParameters: [],
        headers: [],
        cookieParameters: [],
      );
      final method = generator.generateCallMethod(operation, normalizedParams);
      expect(
        method.returns?.accept(emitter).toString(),
        'Future<TonikResult<HeaderResponse>>',
      );
    });

    test('returns result with model for single status code with body only', () {
      final operation = Operation(
        operationId: 'bodyStatus',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/body',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        securitySchemes: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: 'BodyResponse',
            context: context,
            headers: const {},
            description: '',
            bodies: {
              ResponseBody(
                model: StringModel(context: context),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        },
      );
      const normalizedParams = NormalizedRequestParameters(
        pathParameters: [],
        queryParameters: [],
        headers: [],
        cookieParameters: [],
      );
      final method = generator.generateCallMethod(
        operation,
        normalizedParams,
      );
      expect(
        method.returns?.accept(emitter).toString(),
        'Future<TonikResult<String>>',
      );
    });
  });
}
