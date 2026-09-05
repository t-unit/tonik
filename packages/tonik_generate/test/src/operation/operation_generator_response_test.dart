import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/operation/operation_generator.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';

void main() {
  group('OperationGenerator call method return type', () {
    late OperationGenerator generator;
    late Context context;
    late DartEmitter emitter;
    late NameManager nameManager;
    late NameGenerator nameGenerator;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );
      generator = OperationGenerator(
        nameManager: nameManager,
        package: 'api',
        backendGenerator: const DioBackendGenerator(),
        defaultsCache: OperationDefaultsCache(
          nameManager: nameManager,
          package: 'api',
        ),
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
                examples: const [],
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
                examples: const [],
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
        'Future<TonikResult<MultiStatusResponse,Response<Object?>>>',
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
        'Future<TonikResult<void,Response<Object?>>>',
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
                examples: const [],
              ),
            },
            description: '',
            bodies: {
              ResponseBody(
                model: StringModel(context: context),
                rawContentType: 'application/json',
                contentType: ContentType.json,
                examples: const [],
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
        'Future<TonikResult<HeaderResponse,Response<Object?>>>',
      );
    });

    test(
      'pure-Never response body delegates its parser without a cast',
      () {
        final operation = Operation(
          operationId: 'pureNeverBodyStatus',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/pure-never-body',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          securitySchemes: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: NeverModel(context: context, isNullable: false),
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                  examples: const [],
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

        const expectedMethod = '''
Future<TonikResult<Never, Response<Object?>>> call({TonikCancellation? cancellation}) {
  return this.execute(
    cancellation: cancellation,
    prepare: () => DioOperationRequest(
      path: _path(),
      query: null,
      data: _data(),
      options: _options(),
    ),
    decode: _parseResponse,
  );
}
''';
        final format = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    // `Never?` is the shape an inline `{type: "null"}` response schema imports
    // as. The nullable type and parser must be preserved through delegation.
    test(
      'nullable Never response body delegates its nullable parser',
      () {
        final operation = Operation(
          operationId: 'nullableNeverBodyOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/nullable-never-body',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          securitySchemes: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: NeverModel(context: context, isNullable: true),
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                  examples: const [],
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
          'Future<TonikResult<Never?,Response<Object?>>>',
        );

        const expectedMethod = '''
Future<TonikResult<Never?, Response<Object?>>> call({TonikCancellation? cancellation}) {
  return this.execute(
    cancellation: cancellation,
    prepare: () => DioOperationRequest(
      path: _path(),
      query: null,
      data: _data(),
      options: _options(),
    ),
    decode: _parseResponse,
  );
}
''';
        final format = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

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
                examples: const [],
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
        'Future<TonikResult<String,Response<Object?>>>',
      );
    });
  });
}
