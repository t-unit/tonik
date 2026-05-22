import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
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
      nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );
      generator = OperationGenerator(
        nameManager: nameManager,
        package: 'api',
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

    test(
      'pure-Never response body emits try/catch without final-var assignment',
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
                  model: NeverModel(context: context),
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

        const expectedMethod = r'''
Future<TonikResult<Never>> call({CancelToken? cancelToken}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;
  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/')
        ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}'
        : '${_$baseUri.path}/${_$pathResult.join('/')}';
    _$uri = _$baseUri.replace(path: _$newPath);
    _$data = _data();
    _$options = _options();
  } on Object catch (exception, stackTrace) {
    return TonikError(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.encoding,
      response: null,
    );
  }
  final Response<List<int>> _$response;
  try {
    _$response = await _dio.requestUri<List<int>>(
      _$uri,
      data: _$data,
      options: _$options,
      cancelToken: cancelToken,
    );
  } on DioException catch (exception, stackTrace) {
    if (exception.type == DioExceptionType.cancel) {
      return TonikError(
        exception,
        stackTrace: stackTrace,
        type: TonikErrorType.cancelled,
        response: exception.response,
      );
    }
    return TonikError(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.network,
      response: exception.response,
    );
  } on Object catch (exception, stackTrace) {
    return TonikError(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.network,
      response: null,
    );
  }
  try {
    _parseResponse(_$response);
  } on Object catch (exception, stackTrace) {
    return TonikError(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.decoding,
      response: _$response,
    );
  }
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

    // `isNeverParseReturn` also guards against `Never?` to keep the
    // unassigned try/catch branch unreachable when the parse method is not
    // statically guaranteed to throw. The current core model graph does not
    // expose a way to construct a single-body operation whose parse-response
    // type renders as `Never?` (NeverModel has no isNullable field; named
    // alias chains drop nullability via the NamedModel branch in
    // typeReference), so this case is not exercised by a unit test — but the
    // guard prevents a regression if future model changes ever permit it.

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
