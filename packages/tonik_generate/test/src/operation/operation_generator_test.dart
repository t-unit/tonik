import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/operation/operation_generator.dart';

void main() {
  group('OperationGenerator', () {
    late OperationGenerator generator;
    late Context context;
    late DartEmitter emitter;
    late NameManager nameManager;
    late NameGenerator nameGenerator;

    final format =
        DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;

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
          responses: const {},
          requestBody: null,
        );

        const expectedMethod = r'''
          Future<TonikResult<void>> call() async {
            final Uri _$uri;
            final Object? _$data;
            final Options _$options;

            try {
              _$uri = Uri.parse(_dio.options.baseUrl).resolveUri(Uri(path: _path()));
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

            final Response<dynamic> _$response;
            try {
              _$response = await _dio.requestUri<dynamic>(
                _$uri,
                data: _$data,
                options: _$options,
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
        expect(method.optionalParameters, isEmpty);

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
          responses: const {},
          requestBody: null,
        );

        const expectedMethod = r'''
          Future<TonikResult<void>> call({required String myHeader}) async {
            final Uri _$uri;
            final Object? _$data;
            final Options _$options;

            try {
              _$uri = Uri.parse(_dio.options.baseUrl).resolveUri(Uri(path: _path()));
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

            final Response<dynamic> _$response;
            try {
              _$response = await _dio.requestUri<dynamic>(
                _$uri,
                data: _$data,
                options: _$options,
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

        expect(method.optionalParameters, hasLength(1));
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
            ),
          },
          responses: const {},
          requestBody: null,
        );

        const expectedMethod = r'''
          Future<TonikResult<void>> call({required int petId}) async {
            final Uri _$uri;
            final Object? _$data;
            final Options _$options;

            try {
              _$uri = Uri.parse(
                _dio.options.baseUrl,
              ).resolveUri(Uri(path: _path(petId: petId)));
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

            final Response<dynamic> _$response;
            try {
              _$response = await _dio.requestUri<dynamic>(
                _$uri,
                data: _$data,
                options: _$options,
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
              ),
            ),
          ],
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

        // Check parameters
        expect(method.optionalParameters, hasLength(1));
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
          responses: const {},
          requestBody: null,
        );

        const expectedMethod = r'''
          Future<TonikResult<void>> call() async {
            final Uri _$uri;
            final Object? _$data;
            final Options _$options;

            try {
              _$uri = Uri.parse(_dio.options.baseUrl).resolveUri(Uri(path: _path()));
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

            final Response<dynamic> _$response;
            try {
              _$response = await _dio.requestUri<dynamic>(
                _$uri,
                data: _$data,
                options: _$options,
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
        expect(method.optionalParameters, isEmpty);

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
          responses: const {},
          requestBody: null,
        );

        const expectedMethod = r'''
          Future<TonikResult<void>> call({required String filter, String? sort}) async {
            final Uri _$uri;
            final Object? _$data;
            final Options _$options;

            try {
              _$uri = Uri.parse(_dio.options.baseUrl).resolveUri(
                Uri(path: _path(), query: _queryParameters(filter: filter, sort: sort)),
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

            final Response<dynamic> _$response;
            try {
              _$response = await _dio.requestUri<dynamic>(
                _$uri,
                data: _$data,
                options: _$options,
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

        // Check parameters
        expect(method.optionalParameters, hasLength(2));
        final param1 = method.optionalParameters.first;
        final param2 = method.optionalParameters.last;
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
            responses: const {},
            requestBody: null,
          );

          const normalizedParams = NormalizedRequestParameters(
            pathParameters: [],
            queryParameters: [],
            headers: [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          expect(method.optionalParameters, isEmpty);
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
            responses: const {},
            requestBody: requestBody,
          );

          const normalizedParams = NormalizedRequestParameters(
            pathParameters: [],
            queryParameters: [],
            headers: [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          expect(method.optionalParameters, hasLength(1));
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
              ),
              RequestContent(
                model: IntegerModel(context: context),
                contentType: ContentType.json,
                rawContentType: 'application/xml',
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
            responses: const {},
            requestBody: requestBody,
          );

          const normalizedParams = NormalizedRequestParameters(
            pathParameters: [],
            queryParameters: [],
            headers: [],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          expect(method.optionalParameters, hasLength(1));
          final param = method.optionalParameters.first;
          expect(param.type?.accept(emitter).toString(), 'MultiBody');
          expect(param.required, isTrue);
          expect(param.name, 'body');
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
          );

          final normalizedParams = NormalizedRequestParameters(
            pathParameters: [(normalizedName: 'body', parameter: pathParam)],
            queryParameters: [(normalizedName: 'body', parameter: queryParam)],
            headers: [(normalizedName: 'body', parameter: headerParam)],
          );

          final method = generator.generateCallMethod(
            operation,
            normalizedParams,
          );

          // Verify request body parameter is named 'body'
          final bodyParam = method.optionalParameters.firstWhere(
            (p) => p.type?.accept(emitter).toString() == 'String',
          );
          expect(bodyParam.name, 'body');
          expect(bodyParam.required, isTrue);

          // Verify other parameters have appropriate suffixes
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
          requestBody: null,
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
                ),
              },
            ),
          },
        );
        const normalizedParams = NormalizedRequestParameters(
          pathParameters: [],
          queryParameters: [],
          headers: [],
        );
        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );
        const expectedMethod = r'''
          Future<TonikResult<String>> call() async {
            final Uri _$uri;
            final Object? _$data;
            final Options _$options;

            try {
              _$uri = Uri.parse(_dio.options.baseUrl).resolveUri(Uri(path: _path()));
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

            final Response<dynamic> _$response;
            try {
              _$response = await _dio.requestUri<dynamic>(
                _$uri,
                data: _$data,
                options: _$options,
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

      test('generates call method without parsing for void return', () {
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
          requestBody: null,
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
        );
        final method = generator.generateCallMethod(
          operation,
          normalizedParams,
        );
        const expectedMethod = r'''
          Future<TonikResult<void>> call() async {
            final Uri _$uri;
            final Object? _$data;
            final Options _$options;

            try {
              _$uri = Uri.parse(_dio.options.baseUrl).resolveUri(Uri(path: _path()));
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

            final Response<dynamic> _$response;
            try {
              _$response = await _dio.requestUri<dynamic>(
                _$uri,
                data: _$data,
                options: _$options,
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
          responses: const {},
          requestBody: null,
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
          responses: const {},
          requestBody: requestBody,
        );

        final result = generator.generateCallableOperation(operation);
        final code = result.code;

        // Verify the generated code contains the expected method signature
        expect(
          code,
          contains(
            ' _i2.Future<_i3.TonikResult<void>> call({\n'
            '    required _i2.String body,\n'
            '    required _i2.String id,\n'
            '    _i2.int? limit,\n'
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
          requestBody: null,
        );

        final result = generator.generateCallableOperation(operation);
        final code = result.code;

        // Verify the generated code uses the raw names
        expect(
          code,
          contains(
            ' _i2.Future<_i3.TonikResult<void>> call({\n'
            '    required _i2.String userId,\n'
            '    _i2.int? pageSize,\n'
            '    required _i2.String authToken,\n'
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
            responses: const {},
            requestBody: null,
          );

          final generatedClass = generator.generateClass(operation, 'GetUsers');

          // Verify that _queryParameters method is not generated
          expect(
            generatedClass.methods.where((m) => m.name == '_queryParameters'),
            isEmpty,
          );

          // Verify that call method doesn't include query parameter
          final callMethod = generatedClass.methods.firstWhere(
            (m) => m.name == 'call',
          );
          final methodString = callMethod.accept(emitter).toString();
          expect(methodString.contains('query:'), isFalse);
          expect(methodString.contains('Uri(path: _path())'), isTrue);
        },
      );

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
        );

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
          queryParameters: {queryParam},
          pathParameters: const {},
          responses: const {},
          requestBody: null,
        );

        final generatedClass = generator.generateClass(operation, 'GetUsers');

        // Verify that _queryParameters method is generated
        expect(
          generatedClass.methods.where((m) => m.name == '_queryParameters'),
          isNotEmpty,
        );

        // Verify that call method includes query parameter
        final callMethod = generatedClass.methods.firstWhere(
          (m) => m.name == 'call',
        );
        final methodString = callMethod.accept(emitter).toString();
        expect(methodString.contains('query: _queryParameters('), isTrue);
        expect(methodString.contains('filter: filter'), isTrue);
      });
    });
  });
}
