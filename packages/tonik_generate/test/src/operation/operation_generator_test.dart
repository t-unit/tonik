import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/operation/operation_generator.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';

void main() {
  group('OperationGenerator', () {
    late OperationGenerator generator;
    late Context context;
    late DartEmitter emitter;
    late NameManager nameManager;
    late NameGenerator nameGenerator;

    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );
      generator = OperationGenerator(
        nameManager: nameManager,
        package: 'api',
        defaultsCache: OperationDefaultsCache(
          nameManager: nameManager,
          package: 'api',
        ),
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    group('generateCallMethod', () {
      test('generates call method for operation without parameters', () {
        final operation = Operation(
          operationId: 'getUsers',
          context: context,
          summary: 'Get users',
          description: 'Gets a list of users',
          tags: const {},
          isDeprecated: false,
          path: '/users',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        const expectedMethod = r'''
Future<TonikResult<void>> call({CancelToken? cancelToken}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
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

  return TonikSuccess(null, _$response);
}
''';

        const normalizedParams = NormalizedRequestParameters(
          pathParameters: [],
          cookieParameters: [],
          queryParameters: [],
          headers: [],
        );

        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );

        expect(method, isA<Method>());
        expect(
          method.returns?.accept(emitter).toString(),
          'Future<TonikResult<void>>',
        );
        expect(method.modifier, MethodModifier.async);
        expect(method.name, 'call');
        expect(method.requiredParameters, isEmpty);
        expect(method.optionalParameters, hasLength(1));
        final cancelParam = method.optionalParameters.first;
        expect(cancelParam.name, 'cancelToken');
        expect(
          cancelParam.type?.accept(emitter).toString(),
          'CancelToken?',
        );
        expect(cancelParam.named, isTrue);
        expect(cancelParam.required, isFalse);

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      });

      test('generates call method with header parameters', () {
        final requestHeader = RequestHeaderObject(
          name: 'X-My-Header',
          rawName: 'X-My-Header',
          description: 'A custom header',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          model: StringModel(context: context),
          encoding: HeaderParameterEncoding.simple,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'operationWithHeader',
          context: context,
          summary: 'Operation with header',
          description: 'An operation that requires a header',
          tags: const {},
          isDeprecated: false,
          path: '/with-header',
          method: HttpMethod.get,
          headers: {requestHeader},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        const expectedMethod = r'''
Future<TonikResult<void>> call({
  required String myHeader,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
    _$uri = _$baseUri.replace(path: _$newPath);
    _$data = _data();
    _$options = _options(myHeader: myHeader);
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

  return TonikSuccess(null, _$response);
}
''';

        final normalizedParams = NormalizedRequestParameters(
          pathParameters: const [],
          cookieParameters: const [],
          queryParameters: const [],
          headers: [(normalizedName: 'myHeader', parameter: requestHeader)],
        );

        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );

        expect(method, isA<Method>());
        expect(
          method.returns?.accept(emitter).toString(),
          'Future<TonikResult<void>>',
        );
        expect(method.modifier, MethodModifier.async);
        expect(method.name, 'call');

        expect(method.optionalParameters, hasLength(2));
        final param = method.optionalParameters.first;
        expect(param.name, 'myHeader');
        expect(param.type?.accept(emitter).toString(), 'String');
        expect(param.named, isTrue);
        expect(param.required, isTrue);

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      });

      test('generates method with proper error handling and return type', () {
        final operation = Operation(
          operationId: 'deletePet',
          context: context,
          summary: 'Delete a pet',
          description: 'Deletes a pet by ID',
          tags: const {},
          isDeprecated: false,
          path: '/pet/{petId}',
          method: HttpMethod.delete,
          headers: const {},
          queryParameters: const {},
          pathParameters: {
            PathParameterObject(
              name: 'petId',
              rawName: 'petId',
              description: 'ID of pet to delete',
              isRequired: true,
              isDeprecated: false,
              allowEmptyValue: false,
              explode: false,
              encoding: PathParameterEncoding.simple,
              model: IntegerModel(context: context),
              context: context,
              examples: const [],
              defaultValue: null,
            ),
          },
          responses: const {},
          securitySchemes: const {},
          cookieParameters: const {},
        );

        const expectedMethod = r'''
Future<TonikResult<void>> call({
  required int petId,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;
  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path(petId: petId);
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
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
  return TonikSuccess(null, _$response);
}
''';

        final normalizedParams = NormalizedRequestParameters(
          pathParameters: [
            (
              normalizedName: 'petId',
              parameter: PathParameterObject(
                name: 'petId',
                rawName: 'petId',
                description: 'ID of pet to delete',
                isRequired: true,
                isDeprecated: false,
                allowEmptyValue: false,
                explode: false,
                encoding: PathParameterEncoding.simple,
                model: IntegerModel(context: context),
                context: context,
                examples: const [],
                defaultValue: null,
              ),
            ),
          ],
          queryParameters: [],
          headers: [],
          cookieParameters: [],
        );

        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );

        expect(method, isA<Method>());
        expect(
          method.returns?.accept(emitter).toString(),
          'Future<TonikResult<void>>',
        );
        expect(method.name, 'call');
        expect(method.modifier, MethodModifier.async);
        expect(method.optionalParameters, hasLength(2));
        final param = method.optionalParameters.first;
        expect(param.name, 'petId');
        expect(param.type?.accept(emitter).toString(), 'int');
        expect(param.named, isTrue);
        expect(param.required, isTrue);

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      });

      test('handles errors and success for operation without parameters', () {
        final operation = Operation(
          operationId: 'listPets',
          context: context,
          summary: 'List all pets',
          description: 'Lists all pets in the system',
          tags: const {},
          isDeprecated: false,
          path: '/pets',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        const expectedMethod = r'''
Future<TonikResult<void>> call({CancelToken? cancelToken}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
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

  return TonikSuccess(null, _$response);
}
''';

        const normalizedParams = NormalizedRequestParameters(
          pathParameters: [],
          cookieParameters: [],
          queryParameters: [],
          headers: [],
        );

        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );

        expect(method, isA<Method>());
        expect(
          method.returns?.accept(emitter).toString(),
          'Future<TonikResult<void>>',
        );
        expect(method.name, 'call');
        expect(method.modifier, MethodModifier.async);
        expect(method.requiredParameters, isEmpty);
        expect(method.optionalParameters, hasLength(1));

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      });

      test('generates call method with query parameters', () {
        final queryParam1 = QueryParameterObject(
          name: 'filter',
          rawName: 'filter',
          description: 'Filter results',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          model: StringModel(context: context),
          context: context,
          allowReserved: false,
          examples: const [],
          defaultValue: null,
        );

        final queryParam2 = QueryParameterObject(
          name: 'sort',
          rawName: 'sort',
          description: 'Sort direction',
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          model: StringModel(context: context),
          context: context,
          allowReserved: false,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'searchUsers',
          context: context,
          summary: 'Search users',
          description: 'Search users with filters',
          tags: const {},
          isDeprecated: false,
          path: '/users/search',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {queryParam1, queryParam2},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        const expectedMethod = r'''
Future<TonikResult<void>> call({
  required String filter,
  String? sort,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
    _$uri = _$baseUri.replace(
      path: _$newPath,
      query: _queryParameters(filter: filter, sort: sort),
    );
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
  return TonikSuccess(null, _$response);
}
''';

        final normalizedParams = NormalizedRequestParameters(
          pathParameters: const [],
          cookieParameters: const [],
          queryParameters: [
            (normalizedName: 'filter', parameter: queryParam1),
            (normalizedName: 'sort', parameter: queryParam2),
          ],
          headers: const [],
        );

        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );

        expect(method, isA<Method>());
        expect(
          method.returns?.accept(emitter).toString(),
          'Future<TonikResult<void>>',
        );
        expect(method.name, 'call');
        expect(method.modifier, MethodModifier.async);
        expect(method.optionalParameters, hasLength(3));
        final param1 = method.optionalParameters.first;
        final param2 = method.optionalParameters.toList()[1];
        expect(param1.name, 'filter');
        expect(param1.type?.accept(emitter).toString(), 'String');
        expect(param1.named, isTrue);
        expect(param1.required, isTrue);
        expect(param2.name, 'sort');
        expect(param2.type?.accept(emitter).toString(), 'String?');
        expect(param2.named, isTrue);
        expect(param2.required, isFalse);

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      });

      test(
        'generates call method w/o request body parameter when body is null',
        () {
          final operation = Operation(
            operationId: 'operationWithoutBody',
            context: context,
            summary: 'Operation without body',
            description: 'An operation that has no request body',
            tags: const {},
            isDeprecated: false,
            path: '/no-body',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          const normalizedParams = NormalizedRequestParameters(
            pathParameters: [],
            cookieParameters: [],
            queryParameters: [],
            headers: [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          expect(method.optionalParameters, hasLength(1));
          expect(method.optionalParameters.first.name, 'cancelToken');
          expect(method.requiredParameters, isEmpty);
        },
      );

      test(
        'generates call method with single content type request body parameter',
        () {
          final requestBody = RequestBodyObject(
            name: 'singleBody',
            context: context,
            description: 'A single content type body',
            isRequired: true,
            content: {
              RequestContent(
                model: StringModel(context: context),
                contentType: ContentType.json,
                rawContentType: 'application/json',
                examples: const [],
              ),
            },
          );

          final operation = Operation(
            operationId: 'operationWithSingleBody',
            context: context,
            summary: 'Operation with single body',
            description: 'An operation that has a single content type body',
            tags: const {},
            isDeprecated: false,
            path: '/single-body',
            method: HttpMethod.post,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            requestBody: requestBody,
            securitySchemes: const {},
          );

          const normalizedParams = NormalizedRequestParameters(
            pathParameters: [],
            cookieParameters: [],
            queryParameters: [],
            headers: [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          expect(method.optionalParameters, hasLength(2));
          final param = method.optionalParameters.first;
          expect(param.type?.accept(emitter).toString(), 'String');
          expect(param.required, isTrue);
          expect(param.name, 'body');
        },
      );

      test(
        'generates call method w/ multiple content type request body parameter',
        () {
          final requestBody = RequestBodyObject(
            name: 'multiBody',
            context: context,
            description: 'A multiple content type body',
            isRequired: true,
            content: {
              RequestContent(
                model: StringModel(context: context),
                contentType: ContentType.json,
                rawContentType: 'application/json',
                examples: const [],
              ),
              RequestContent(
                model: IntegerModel(context: context),
                contentType: ContentType.json,
                rawContentType: 'application/xml',
                examples: const [],
              ),
            },
          );

          final operation = Operation(
            operationId: 'operationWithMultiBody',
            context: context,
            summary: 'Operation with multiple body',
            description: 'An operation that has multiple content type bodies',
            tags: const {},
            isDeprecated: false,
            path: '/multi-body',
            method: HttpMethod.post,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            requestBody: requestBody,
            securitySchemes: const {},
          );

          const normalizedParams = NormalizedRequestParameters(
            pathParameters: [],
            cookieParameters: [],
            queryParameters: [],
            headers: [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          expect(method.optionalParameters, hasLength(2));
          final param = method.optionalParameters.first;
          expect(param.type?.accept(emitter).toString(), 'MultiBody');
          expect(param.required, isTrue);
          expect(param.name, 'body');
        },
      );

      test(
        'generates call method with await _data for multipart request body',
        () {
          final multipartModel = ClassModel(
            name: 'UploadForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );

          final requestBody = RequestBodyObject(
            name: 'upload',
            context: context,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: multipartModel,
                contentType: ContentType.multipart,
                rawContentType: 'multipart/form-data',
                multipartEncoding: _multipartEncoding(multipartModel, {
                  'name': const PartEncoding(
                    contentType: ContentType.text,
                    rawContentType: 'text/plain',
                    headers: null,
                    style: EncodingStyle.form,
                    explode: true,
                    allowReserved: false,
                  ),
                }),
                examples: const [],
              ),
            },
          );

          final operation = Operation(
            operationId: 'uploadForm',
            context: context,
            summary: 'Upload form',
            description: 'Upload a form',
            tags: const {},
            isDeprecated: false,
            path: '/upload',
            method: HttpMethod.post,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            requestBody: requestBody,
            securitySchemes: const {},
          );

          const normalizedParams = NormalizedRequestParameters(
            pathParameters: [],
            cookieParameters: [],
            queryParameters: [],
            headers: [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          const expectedMethod = r'''
Future<TonikResult<void>> call({
  required UploadForm body,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
    _$uri = _$baseUri.replace(path: _$newPath);
    _$data = await _data(body: body);
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

  return TonikSuccess(null, _$response);
}
''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(expectedMethod),
          );
        },
      );

      test(
        'prioritizes body parameter for request body with conflicting names',
        () {
          final requestBody = RequestBodyObject(
            name: 'singleBody',
            context: context,
            description: 'A single content type body',
            isRequired: true,
            content: {
              RequestContent(
                model: StringModel(context: context),
                contentType: ContentType.json,
                rawContentType: 'application/json',
                examples: const [],
              ),
            },
          );

          final headerParam = RequestHeaderObject(
            name: 'body',
            rawName: 'body',
            description: 'A header named body',
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            explode: false,
            model: StringModel(context: context),
            encoding: HeaderParameterEncoding.simple,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final queryParam = QueryParameterObject(
            name: 'body',
            rawName: 'body',
            description: 'A query param named body',
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            explode: false,
            encoding: QueryParameterEncoding.form,
            model: StringModel(context: context),
            context: context,
            allowReserved: false,
            examples: const [],
            defaultValue: null,
          );

          final pathParam = PathParameterObject(
            name: 'body',
            rawName: 'body',
            description: 'A path param named body',
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            explode: false,
            encoding: PathParameterEncoding.simple,
            model: StringModel(context: context),
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'operationWithNameConflicts',
            context: context,
            summary: 'Operation with conflicting parameter names',
            description: 'An operation that has parameters named body',
            tags: const {},
            isDeprecated: false,
            path: '/conflict/{body}',
            method: HttpMethod.post,
            headers: {headerParam},
            queryParameters: {queryParam},
            pathParameters: {pathParam},
            responses: const {},
            requestBody: requestBody,
            securitySchemes: const {},
            cookieParameters: const {},
          );

          final normalizedParams = NormalizedRequestParameters(
            pathParameters: [(normalizedName: 'body', parameter: pathParam)],
            queryParameters: [(normalizedName: 'body', parameter: queryParam)],
            headers: [(normalizedName: 'body', parameter: headerParam)],
            cookieParameters: [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );
          final bodyParam = method.optionalParameters.firstWhere(
            (p) => p.type?.accept(emitter).toString() == 'String',
          );
          expect(bodyParam.name, 'body');
          expect(bodyParam.required, isTrue);
          final headerBodyParam = method.optionalParameters.firstWhere(
            (p) => p.name == 'bodyHeader',
          );
          expect(headerBodyParam.type?.accept(emitter).toString(), 'String');
          expect(headerBodyParam.required, isTrue);

          final queryBodyParam = method.optionalParameters.firstWhere(
            (p) => p.name == 'bodyQuery',
          );
          expect(queryBodyParam.type?.accept(emitter).toString(), 'String');
          expect(queryBodyParam.required, isTrue);

          final pathBodyParam = method.optionalParameters.firstWhere(
            (p) => p.name == 'bodyPath',
          );
          expect(pathBodyParam.type?.accept(emitter).toString(), 'String');
          expect(pathBodyParam.required, isTrue);
        },
      );

      test('generates call method with parsing and error handling for '
          'non-void return', () {
        final operation = Operation(
          operationId: 'parseTest',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/parse',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          securitySchemes: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: 'ParseResponse',
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
          cookieParameters: [],
          queryParameters: [],
          headers: [],
        );

        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );

        const expectedMethod = r'''
Future<TonikResult<String>> call({CancelToken? cancelToken}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
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

  final String _$parsedResponse;
  try {
    _$parsedResponse = _parseResponse(_$response);
  } on Object catch (exception, stackTrace) {
    return TonikError(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.decoding,
      response: _$response,
    );
  }

  return TonikSuccess(_$parsedResponse, _$response);
}
''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      });

      test('generates call method with parsing for void return', () {
        final operation = Operation(
          operationId: 'voidParseTest',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/void-parse',
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
          cookieParameters: [],
          queryParameters: [],
          headers: [],
        );
        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );
        const expectedMethod = r'''
Future<TonikResult<void>> call({CancelToken? cancelToken}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
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

  return TonikSuccess(null, _$response);
}
''';
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      });

      test(
        'generates call method with List return type preserving generics',
        () {
          final operation = Operation(
            operationId: 'getActivePets',
            context: context,
            summary: 'Get active pets',
            description: 'Gets a list of active pets',
            tags: const {},
            isDeprecated: false,
            path: '/pets/active',
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
                    model: ListModel(
                      content: ClassModel(
                        name: 'ActivePet',
                        properties: [],
                        isDeprecated: false,
                        context: context,
                        examples: const [],
                      ),
                      context: context,
                      examples: const [],
                    ),
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
            cookieParameters: [],
            queryParameters: [],
            headers: [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          const expectedMethod = r'''
Future<TonikResult<List<ActivePet>>> call({CancelToken? cancelToken}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
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

  final List<ActivePet> _$parsedResponse;
  try {
    _$parsedResponse = _parseResponse(_$response);
  } on Object catch (exception, stackTrace) {
    return TonikError(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.decoding,
      response: _$response,
    );
  }

  return TonikSuccess(_$parsedResponse, _$response);
}
''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(expectedMethod),
          );
        },
      );

      test('does not generate parsing code for operations with no '
          'responses', () {
        final operation = Operation(
          operationId: 'noResponseOperation',
          context: context,
          summary: 'Operation with no responses',
          description:
              'Tests that no parsing is added when no responses are defined',
          tags: const {},
          isDeprecated: false,
          path: '/no-responses',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {}, // Empty responses map
          securitySchemes: const {},
        );

        const normalizedParams = NormalizedRequestParameters(
          pathParameters: [],
          cookieParameters: [],
          queryParameters: [],
          headers: [],
        );

        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );

        const expectedMethod = r'''
Future<TonikResult<void>> call({CancelToken? cancelToken}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
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

  return TonikSuccess(null, _$response);
}
''';

        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(expectedMethod),
        );
      });

      test(
        'generates cancelToken parameter with correct type and optionality',
        () {
          final operation = Operation(
            operationId: 'cancelTest',
            context: context,
            summary: 'Cancel test',
            description: 'Tests cancelToken generation',
            tags: const {},
            isDeprecated: false,
            path: '/cancel',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          const normalizedParams = NormalizedRequestParameters(
            pathParameters: [],
            cookieParameters: [],
            queryParameters: [],
            headers: [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          // cancelToken should be the last optional parameter
          final cancelParam = method.optionalParameters.last;
          expect(cancelParam.name, 'cancelToken');
          expect(
            cancelParam.type?.accept(emitter).toString(),
            'CancelToken?',
          );
          expect(cancelParam.named, isTrue);
          expect(cancelParam.required, isFalse);
        },
      );

      test(
        'generates cancelToken as last parameter when other params exist',
        () {
          final pathParam = PathParameterObject(
            name: 'id',
            rawName: 'id',
            description: 'ID',
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            explode: false,
            encoding: PathParameterEncoding.simple,
            model: IntegerModel(context: context),
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'cancelWithParams',
            context: context,
            summary: 'Cancel with params',
            description: 'Tests cancelToken ordering',
            tags: const {},
            isDeprecated: false,
            path: '/cancel/{id}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: {pathParam},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final normalizedParams = NormalizedRequestParameters(
            pathParameters: [
              (normalizedName: 'id', parameter: pathParam),
            ],
            queryParameters: const [],
            headers: const [],
            cookieParameters: const [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          expect(method.optionalParameters, hasLength(2));
          expect(method.optionalParameters.first.name, 'id');
          expect(method.optionalParameters.last.name, 'cancelToken');
        },
      );

      test(
        'generates cancel-specific error handling in network catch block',
        () {
          final operation = Operation(
            operationId: 'cancelErrorHandling',
            context: context,
            summary: 'Cancel error handling',
            description: 'Tests cancel error handling generation',
            tags: const {},
            isDeprecated: false,
            path: '/cancel-error',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          const normalizedParams = NormalizedRequestParameters(
            pathParameters: [],
            cookieParameters: [],
            queryParameters: [],
            headers: [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          const expectedMethod = r'''
Future<TonikResult<void>> call({CancelToken? cancelToken}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
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

  return TonikSuccess(null, _$response);
}
''';

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(expectedMethod),
          );
        },
      );

      test(
        'renames query parameter colliding with built-in cancelToken',
        () {
          final queryParam = QueryParameterObject(
            name: 'cancelToken',
            rawName: 'cancelToken',
            description: null,
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: StringModel(context: context),
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'getA',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/a',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: {queryParam},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          const expectedMethod = r'''
Future<TonikResult<void>> call({
  required String cancelTokenQuery,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
    _$uri = _$baseUri.replace(
      path: _$newPath,
      query: _queryParameters(cancelTokenQuery: cancelTokenQuery),
    );
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

  return TonikSuccess(null, _$response);
}
''';

          final cls = generator.generateClass(operation, 'GetA');
          final method = cls.methods.firstWhere((m) => m.name == 'call');

          final paramNames = method.optionalParameters
              .map((p) => p.name)
              .toList();
          expect(paramNames, ['cancelTokenQuery', 'cancelToken']);

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(expectedMethod),
          );
        },
      );

      test(
        'renames query parameter colliding with built-in cancelToken when '
        'request body is also present',
        () {
          final requestBody = RequestBodyObject(
            name: 'singleBody',
            context: context,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: StringModel(context: context),
                contentType: ContentType.json,
                rawContentType: 'application/json',
                examples: const [],
              ),
            },
          );

          final queryParam = QueryParameterObject(
            name: 'cancelToken',
            rawName: 'cancelToken',
            description: null,
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: StringModel(context: context),
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'postA',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/a',
            method: HttpMethod.post,
            headers: const {},
            queryParameters: {queryParam},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            requestBody: requestBody,
            securitySchemes: const {},
          );

          const expectedMethod = r'''
Future<TonikResult<void>> call({
  required String body,
  required String cancelTokenQuery,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
    _$uri = _$baseUri.replace(
      path: _$newPath,
      query: _queryParameters(cancelTokenQuery: cancelTokenQuery),
    );
    _$data = _data(body: body);
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

  return TonikSuccess(null, _$response);
}
''';

          final cls = generator.generateClass(operation, 'PostA');
          final method = cls.methods.firstWhere((m) => m.name == 'call');

          final paramNames = method.optionalParameters
              .map((p) => p.name)
              .toList();
          expect(paramNames, ['body', 'cancelTokenQuery', 'cancelToken']);

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(expectedMethod),
          );
        },
      );

      test(
        'renames path parameter colliding with built-in cancelToken',
        () {
          final pathParam = PathParameterObject(
            name: 'cancelToken',
            rawName: 'cancelToken',
            description: null,
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            explode: false,
            encoding: PathParameterEncoding.simple,
            model: StringModel(context: context),
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'getA',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/a/{cancelToken}',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: {pathParam},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          const expectedMethod = r'''
Future<TonikResult<void>> call({
  required String cancelTokenPath,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path(cancelTokenPath: cancelTokenPath);
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
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

  return TonikSuccess(null, _$response);
}
''';

          final cls = generator.generateClass(operation, 'GetA');
          final method = cls.methods.firstWhere((m) => m.name == 'call');

          final paramNames = method.optionalParameters
              .map((p) => p.name)
              .toList();
          expect(paramNames, ['cancelTokenPath', 'cancelToken']);

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(expectedMethod),
          );
        },
      );

      test(
        'renames header parameter colliding with built-in cancelToken',
        () {
          final header = RequestHeaderObject(
            name: 'cancelToken',
            rawName: 'cancelToken',
            description: null,
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            explode: false,
            model: StringModel(context: context),
            encoding: HeaderParameterEncoding.simple,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'getA',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/a',
            method: HttpMethod.get,
            headers: {header},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          const expectedMethod = r'''
Future<TonikResult<void>> call({
  required String cancelTokenHeader,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
    _$uri = _$baseUri.replace(path: _$newPath);
    _$data = _data();
    _$options = _options(cancelTokenHeader: cancelTokenHeader);
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

  return TonikSuccess(null, _$response);
}
''';

          final cls = generator.generateClass(operation, 'GetA');
          final method = cls.methods.firstWhere((m) => m.name == 'call');

          final paramNames = method.optionalParameters
              .map((p) => p.name)
              .toList();
          expect(paramNames, ['cancelTokenHeader', 'cancelToken']);

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(expectedMethod),
          );
        },
      );

      test(
        'renames cookie parameter colliding with built-in cancelToken',
        () {
          final cookie = CookieParameterObject(
            name: 'cancelToken',
            rawName: 'cancelToken',
            description: null,
            isRequired: true,
            isDeprecated: false,
            explode: false,
            model: StringModel(context: context),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'getA',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/a',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: {cookie},
            responses: const {},
            securitySchemes: const {},
          );

          const expectedMethod = r'''
Future<TonikResult<void>> call({
  required String cancelTokenCookie,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
    _$uri = _$baseUri.replace(path: _$newPath);
    _$data = _data();
    _$options = _options(cancelTokenCookie: cancelTokenCookie);
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

  return TonikSuccess(null, _$response);
}
''';

          final cls = generator.generateClass(operation, 'GetA');
          final method = cls.methods.firstWhere((m) => m.name == 'call');

          final paramNames = method.optionalParameters
              .map((p) => p.name)
              .toList();
          expect(paramNames, ['cancelTokenCookie', 'cancelToken']);

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(expectedMethod),
          );
        },
      );

      test(
        'renames query parameter that sanitizes to cancelToken',
        () {
          final queryParam = QueryParameterObject(
            name: 'Cancel-Token',
            rawName: 'Cancel-Token',
            description: null,
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: StringModel(context: context),
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'getA',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/a',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: {queryParam},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          const expectedMethod = r'''
Future<TonikResult<void>> call({
  required String cancelTokenQuery,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
    _$uri = _$baseUri.replace(
      path: _$newPath,
      query: _queryParameters(cancelTokenQuery: cancelTokenQuery),
    );
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

  return TonikSuccess(null, _$response);
}
''';

          final cls = generator.generateClass(operation, 'GetA');
          final method = cls.methods.firstWhere((m) => m.name == 'call');

          final paramNames = method.optionalParameters
              .map((p) => p.name)
              .toList();
          expect(paramNames, ['cancelTokenQuery', 'cancelToken']);

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(expectedMethod),
          );
        },
      );

      test(
        'leaves non-colliding parameter named token unchanged',
        () {
          final queryParam = QueryParameterObject(
            name: 'token',
            rawName: 'token',
            description: null,
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: StringModel(context: context),
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'getA',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/a',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: {queryParam},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final cls = generator.generateClass(operation, 'GetA');
          final method = cls.methods.firstWhere((m) => m.name == 'call');

          final paramNames = method.optionalParameters
              .map((p) => p.name)
              .toList();
          expect(paramNames, ['token', 'cancelToken']);
        },
      );
    });

    group('generateCallableOperation', () {
      test('generates snake_case filename from operation name', () {
        final operation = Operation(
          operationId: 'getUsers',
          context: context,
          summary: 'Get users',
          description: 'Gets a list of users',
          tags: const {},
          isDeprecated: false,
          path: '/users',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final result = generator.generateCallableOperation(operation);
        expect(result.filename, 'get_users.dart');
      });

      test('generates call method with parameters and body', () {
        final requestBody = RequestBodyObject(
          name: 'createUser',
          context: context,
          description: 'User to create',
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: context),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        );

        final pathParam = PathParameterObject(
          name: 'id',
          rawName: 'id',
          description: 'User ID',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: PathParameterEncoding.simple,
          model: StringModel(context: context),
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final queryParam = QueryParameterObject(
          name: 'limit',
          rawName: 'limit',
          description: 'Limit results',
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          model: IntegerModel(context: context),
          context: context,
          allowReserved: false,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'createUser',
          context: context,
          summary: 'Create user',
          description: 'Creates a new user',
          tags: const {},
          isDeprecated: false,
          path: '/users/{id}',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: {queryParam},
          pathParameters: {pathParam},
          cookieParameters: const {},
          responses: const {},
          requestBody: requestBody,
          securitySchemes: const {},
        );

        final result = generator.generateCallableOperation(operation);
        final code = result.code;
        expect(
          code,
          contains(
            ' _i2.Future<_i3.TonikResult<void>> call({\n'
            '    required _i2.String body,\n'
            '    required _i2.String id,\n'
            '    _i2.int? limit,\n'
            '    _i1.CancelToken? cancelToken,\n'
            '  }) async',
          ),
        );
      });

      test('handles parameter aliases correctly', () {
        final pathParam = PathParameterAlias(
          name: 'userId',
          parameter: PathParameterObject(
            name: 'id',
            rawName: 'user_id',
            description: 'User ID',
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            explode: false,
            encoding: PathParameterEncoding.simple,
            model: StringModel(context: context),
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          context: context,
        );

        final queryParam = QueryParameterAlias(
          name: 'pageSize',
          parameter: QueryParameterObject(
            name: 'limit',
            rawName: 'page_size',
            description: 'Page size',
            isRequired: false,
            isDeprecated: false,
            allowEmptyValue: false,
            explode: false,
            encoding: QueryParameterEncoding.form,
            model: IntegerModel(context: context),
            context: context,
            allowReserved: false,
            examples: const [],
            defaultValue: null,
          ),
          context: context,
        );

        final headerParam = RequestHeaderAlias(
          name: 'authTokenAlias',
          header: RequestHeaderObject(
            name: null,
            rawName: 'auth_token',
            description: 'Auth token',
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            explode: false,
            encoding: HeaderParameterEncoding.simple,
            model: StringModel(context: context),
            context: context,
            examples: const [],
            defaultValue: null,
          ),
          context: context,
        );

        final operation = Operation(
          operationId: 'getUser',
          context: context,
          summary: 'Get user',
          description: 'Get user by ID',
          tags: const {},
          isDeprecated: false,
          path: '/users/{user_id}',
          method: HttpMethod.get,
          headers: {headerParam},
          queryParameters: {queryParam},
          pathParameters: {pathParam},
          responses: const {},
          securitySchemes: const {},
          cookieParameters: const {},
        );

        final result = generator.generateCallableOperation(operation);
        final code = result.code;
        expect(
          code,
          contains(
            ' _i2.Future<_i3.TonikResult<void>> call({\n'
            '    required _i2.String userId,\n'
            '    _i2.int? pageSize,\n'
            '    required _i2.String authToken,\n'
            '    _i1.CancelToken? cancelToken,\n'
            '  }) async',
          ),
        );
      });
    });

    group('generateClass', () {
      test(
        'does not generate query parameters method without query parameters',
        () {
          final operation = Operation(
            operationId: 'getPets',
            context: context,
            summary: 'Get pets',
            description: 'Gets a list of pets',
            tags: const {},
            isDeprecated: false,
            path: '/pets',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final result = generator.generateClass(operation, 'GetPets');

          expect(
            result.methods.any((m) => m.name == '_queryParameters'),
            isFalse,
          );
        },
      );

      test('does not generate _parseResponse method for operations with no '
          'responses', () {
        final operation = Operation(
          operationId: 'noResponsesOperation',
          context: context,
          summary: 'Operation with no responses',
          description: 'Should not generate _parseResponse method',
          tags: const {},
          isDeprecated: false,
          path: '/no-responses',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {}, // Empty responses map
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          operation,
          'NoResponsesOperation',
        );
        expect(
          generatedClass.methods.where((m) => m.name == '_parseResponse'),
          isEmpty,
        );
      });

      test('generates _parseResponse method for operations with responses', () {
        final operation = Operation(
          operationId: 'withResponsesOperation',
          context: context,
          summary: 'Operation with responses',
          description: 'Should generate _parseResponse method',
          tags: const {},
          isDeprecated: false,
          path: '/with-responses',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
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
          },
          securitySchemes: const {},
        );

        final generatedClass = generator.generateClass(
          operation,
          'WithResponsesOperation',
        );
        expect(
          generatedClass.methods
              .where((m) => m.name == '_parseResponse')
              .length,
          1,
        );
      });

      test('generates query parameters method when query parameters exist', () {
        final queryParam = QueryParameterObject(
          name: 'filter',
          rawName: 'filter',
          description: 'Filter results',
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          encoding: QueryParameterEncoding.form,
          model: StringModel(context: context),
          context: context,
          allowReserved: false,
          examples: const [],
          defaultValue: null,
        );

        final operation = Operation(
          operationId: 'getPets',
          context: context,
          summary: 'Get pets',
          description: 'Gets a list of pets',
          tags: const {},
          isDeprecated: false,
          path: '/pets',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {queryParam},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final result = generator.generateClass(operation, 'GetPets');

        expect(
          result.methods.any((m) => m.name == '_queryParameters'),
          isTrue,
        );
      });
    });

    group('generateClass — parameter defaults', () {
      test(
        'mixed-location defaults emit static const fields ordered '
        'path → query → header → cookie immediately after _dio',
        () {
          final pathParam = PathParameterObject(
            name: 'id',
            rawName: 'id',
            description: null,
            isRequired: true,
            isDeprecated: false,
            allowEmptyValue: false,
            explode: false,
            model: StringModel(context: context),
            encoding: PathParameterEncoding.simple,
            context: context,
            examples: const [],
            defaultValue: 'x',
          );
          final queryParam = QueryParameterObject(
            name: 'region',
            rawName: 'region',
            description: null,
            isRequired: false,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: StringModel(context: context),
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: 'us',
          );
          final header = RequestHeaderObject(
            name: 'retries',
            rawName: 'X-Retries',
            description: null,
            isRequired: false,
            isDeprecated: false,
            allowEmptyValue: false,
            explode: false,
            model: IntegerModel(context: context),
            encoding: HeaderParameterEncoding.simple,
            context: context,
            examples: const [],
            defaultValue: 5,
          );
          final cookie = CookieParameterObject(
            name: 'tracking',
            rawName: 'tracking',
            description: null,
            isRequired: false,
            isDeprecated: false,
            explode: false,
            model: BooleanModel(context: context),
            encoding: CookieParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: false,
          );

          final operation = Operation(
            operationId: 'listThings',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/things/{id}',
            method: HttpMethod.get,
            headers: {header},
            queryParameters: {queryParam},
            pathParameters: {pathParam},
            cookieParameters: {cookie},
            responses: const {},
            securitySchemes: const {},
          );

          final result = generator.generateClass(operation, 'ListThings');

          final fieldNames = result.fields.map((f) => f.name).toList();
          expect(fieldNames, [
            '_dio',
            'idDefault',
            'regionDefault',
            'retriesDefault',
            'trackingDefault',
          ]);

          final regionField = result.fields.firstWhere(
            (f) => f.name == 'regionDefault',
          );
          expect(regionField.static, isTrue);
          expect(regionField.modifier, FieldModifier.constant);
          expect(regionField.type?.symbol, 'String');

          final callMethod = result.methods.firstWhere((m) => m.name == 'call');
          final regionParam = callMethod.optionalParameters.firstWhere(
            (p) => p.name == 'region',
          );
          expect(regionParam.required, isFalse);
          expect(
            regionParam.defaultTo?.accept(emitter).toString(),
            'regionDefault',
          );
          expect(regionParam.type?.accept(emitter).toString(), 'String');

          final idParam = callMethod.optionalParameters.firstWhere(
            (p) => p.name == 'id',
          );
          expect(idParam.required, isFalse);
          expect(
            idParam.defaultTo?.accept(emitter).toString(),
            'idDefault',
          );
          expect(idParam.type?.accept(emitter).toString(), 'String');

          final retriesParam = callMethod.optionalParameters.firstWhere(
            (p) => p.name == 'retries',
          );
          expect(retriesParam.required, isFalse);
          expect(
            retriesParam.defaultTo?.accept(emitter).toString(),
            'retriesDefault',
          );
          expect(retriesParam.type?.accept(emitter).toString(), 'int');

          final trackingParam = callMethod.optionalParameters.firstWhere(
            (p) => p.name == 'tracking',
          );
          expect(trackingParam.required, isFalse);
          expect(
            trackingParam.defaultTo?.accept(emitter).toString(),
            'trackingDefault',
          );
          expect(trackingParam.type?.accept(emitter).toString(), 'bool');
        },
      );

      test(
        'parameter with no default keeps required+nullable rules and gets '
        'no static const field',
        () {
          final queryParam = QueryParameterObject(
            name: 'filter',
            rawName: 'filter',
            description: null,
            isRequired: false,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: StringModel(context: context),
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'noDefaults',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/pets',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: {queryParam},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final result = generator.generateClass(operation, 'NoDefaults');

          expect(
            result.fields.where((f) => f.name == 'filterDefault'),
            isEmpty,
          );

          final callMethod = result.methods.firstWhere((m) => m.name == 'call');
          final filterParam = callMethod.optionalParameters.firstWhere(
            (p) => p.name == 'filter',
          );
          expect(filterParam.required, isFalse);
          expect(filterParam.defaultTo, isNull);
          expect(filterParam.type?.accept(emitter).toString(), 'String?');
        },
      );

      test(
        'collision: query parameter named regionDefault forces suffix on '
        'region default',
        () {
          final region = QueryParameterObject(
            name: 'region',
            rawName: 'region',
            description: null,
            isRequired: false,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: StringModel(context: context),
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: 'us',
          );
          final preExisting = QueryParameterObject(
            name: 'regionDefault',
            rawName: 'regionDefault',
            description: null,
            isRequired: false,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: StringModel(context: context),
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: null,
          );

          final operation = Operation(
            operationId: 'collide',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/x',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: {region, preExisting},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final result = generator.generateClass(operation, 'Collide');

          final defaultField = result.fields.firstWhere(
            (f) => f.name == 'regionDefault2',
            orElse: () => Field((b) => b..name = 'MISSING'),
          );
          expect(defaultField.name, 'regionDefault2');

          final callMethod = result.methods.firstWhere((m) => m.name == 'call');
          final regionParam = callMethod.optionalParameters.firstWhere(
            (p) => p.name == 'region',
          );
          expect(
            regionParam.defaultTo?.accept(emitter).toString(),
            'regionDefault2',
          );
        },
      );

      test(
        'multipart per-part header with an aliased default does not emit a '
        'static const field on the operation class',
        () {
          final aliasedModel = AliasModel(
            name: 'TraceIdHeader',
            model: StringModel(context: context),
            context: context,
            examples: const [],
            defaultValue: 'static-trace-id',
          );

          final uploadModel = ClassModel(
            name: 'UploadForm',
            properties: [
              Property(
                name: 'file',
                model: BinaryModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            isDeprecated: false,
            examples: const [],
          );

          final requestBody = RequestBodyObject(
            name: 'uploadBody',
            context: context,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: uploadModel,
                contentType: ContentType.multipart,
                rawContentType: 'multipart/form-data',
                multipartEncoding: _multipartEncoding(uploadModel, {
                  'file': PartEncoding(
                    contentType: ContentType.bytes,
                    rawContentType: 'application/octet-stream',
                    style: null,
                    explode: null,
                    allowReserved: null,
                    headers: {
                      'X-Trace-Id': ResponseHeaderObject(
                        name: 'X-Trace-Id',
                        context: context,
                        description: null,
                        explode: false,
                        model: aliasedModel,
                        isRequired: true,
                        isDeprecated: false,
                        encoding: ResponseHeaderEncoding.simple,
                        examples: const [],
                      ),
                    },
                  ),
                }),
                examples: const [],
              ),
            },
          );

          final operation = Operation(
            operationId: 'upload',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/upload',
            method: HttpMethod.post,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            requestBody: requestBody,
            securitySchemes: const {},
          );

          final result = generator.generateClass(operation, 'Upload');

          final fieldNames = result.fields.map((f) => f.name).toList();
          expect(fieldNames, ['_dio']);
        },
      );

      test(
        'call() body delegates to _path/_queryParameters with the parameter '
        'name, not the qualified default reference',
        () {
          final queryParam = QueryParameterObject(
            name: 'region',
            rawName: 'region',
            description: null,
            isRequired: false,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: StringModel(context: context),
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: 'us',
          );

          final operation = Operation(
            operationId: 'listThings',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/things',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: {queryParam},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          const expectedMethod = r'''
Future<TonikResult<void>> call({
  String region = regionDefault,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;
  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
    _$uri = _$baseUri.replace(
      path: _$newPath,
      query: _queryParameters(region: region),
    );
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

  return TonikSuccess(null, _$response);
}
''';

          final cls = generator.generateClass(operation, 'ListThings');
          final method = cls.methods.firstWhere((m) => m.name == 'call');

          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(expectedMethod),
          );
        },
      );

      test(
        'emits exactly one warning when a primitive default value does not '
        'match the expected type',
        () {
          final logs = <LogRecord>[];
          final sub = Logger(
            'OperationParameterDefaults',
          ).onRecord.listen(logs.add);
          addTearDown(sub.cancel);

          final queryParam = QueryParameterObject(
            name: 'enabled',
            rawName: 'enabled',
            description: null,
            isRequired: false,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: BooleanModel(context: context),
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: 'true',
          );

          final operation = Operation(
            operationId: 'listThings',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/things',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: {queryParam},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          generator.generateClass(operation, 'ListThings');

          final warnings = logs.where((r) => r.level == Level.WARNING).toList();
          expect(warnings, hasLength(1));
          expect(warnings.single.message, contains('ListThings'));
          expect(warnings.single.message, contains('enabled'));
        },
      );

      test(
        'enum-typed query parameter with valid default emits static const '
        'and references it from call()',
        () {
          final statusEnum = EnumModel<String>(
            name: 'Status',
            values: {
              const EnumEntry<String>(value: 'active'),
              const EnumEntry<String>(value: 'inactive'),
            },
            isNullable: false,
            context: context,
            isDeprecated: false,
            examples: const [],
          );

          final queryParam = QueryParameterObject(
            name: 'status',
            rawName: 'status',
            description: null,
            isRequired: false,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: statusEnum,
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: 'active',
          );

          final operation = Operation(
            operationId: 'listThings',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/things',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: {queryParam},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final result = generator.generateClass(operation, 'ListThings');

          final defaultField = result.fields.firstWhere(
            (f) => f.name == 'statusDefault',
          );
          expect(defaultField.static, isTrue);
          expect(defaultField.modifier, FieldModifier.constant);
          expect(defaultField.type?.symbol, 'Status');
          expect(
            defaultField.assignment?.accept(emitter).toString(),
            'Status.active',
          );

          final callMethod = result.methods.firstWhere((m) => m.name == 'call');
          final statusParam = callMethod.optionalParameters.firstWhere(
            (p) => p.name == 'status',
          );
          expect(statusParam.required, isFalse);
          expect(
            statusParam.defaultTo?.accept(emitter).toString(),
            'statusDefault',
          );
          expect(statusParam.type?.accept(emitter).toString(), 'Status');

          const expectedCall = r'''
Future<TonikResult<void>> call({
  Status status = statusDefault,
  CancelToken? cancelToken,
}) async {
  late final Uri _$uri;
  late final Object? _$data;
  late final Options _$options;

  try {
    final _$baseUri = Uri.parse(_dio.options.baseUrl);
    final _$pathResult = _path();
    final _$newPath = _$baseUri.path.endsWith('/') ? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' : '${_$baseUri.path}/${_$pathResult.join('/')}';
    _$uri = _$baseUri.replace(
      path: _$newPath,
      query: _queryParameters(status: status),
    );
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

  return TonikSuccess(null, _$response);
}
''';

          final actualCall = format(callMethod.accept(emitter).toString());
          expect(
            collapseWhitespace(actualCall),
            collapseWhitespace(expectedCall),
          );
        },
      );

      test(
        'runtime-default query parameter (DateTime) emits a static getter on '
        'the operation class while the call() parameter stays as-was',
        () {
          final queryParam = QueryParameterObject(
            name: 'since',
            rawName: 'since',
            description: null,
            isRequired: false,
            isDeprecated: false,
            allowEmptyValue: false,
            allowReserved: false,
            explode: false,
            model: DateTimeModel(context: context),
            encoding: QueryParameterEncoding.form,
            context: context,
            examples: const [],
            defaultValue: '2024-01-01T00:00:00Z',
          );

          final operation = Operation(
            operationId: 'listThings',
            context: context,
            tags: const {},
            isDeprecated: false,
            path: '/things',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: {queryParam},
            pathParameters: const {},
            cookieParameters: const {},
            responses: const {},
            securitySchemes: const {},
          );

          final result = generator.generateClass(operation, 'ListThings');

          expect(
            result.fields.where((f) => f.name == 'sinceDefault'),
            isEmpty,
          );

          final getter = result.methods.firstWhere(
            (m) => m.name == 'sinceDefault',
          );
          expect(getter.static, isTrue);
          expect(getter.type, MethodType.getter);
          expect(getter.lambda, isTrue);
          expect(getter.returns?.symbol, 'DateTime');

          final callMethod = result.methods.firstWhere((m) => m.name == 'call');
          final sinceParam = callMethod.optionalParameters.firstWhere(
            (p) => p.name == 'since',
          );
          expect(sinceParam.required, isFalse);
          expect(sinceParam.defaultTo, isNull);
          expect(sinceParam.type?.accept(emitter).toString(), 'DateTime?');
        },
      );
    });
  });
}

Map<Property, PartEncoding> _multipartEncoding(
  ClassModel model,
  Map<String, PartEncoding> byName,
) {
  return {
    for (final entry in byName.entries)
      model.properties.firstWhere((p) => p.name == entry.key): entry.value,
  };
}
