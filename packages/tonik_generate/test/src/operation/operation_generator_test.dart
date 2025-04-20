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

        const expectedMethod = '''
          Future<TonikResult<void>> call() async {
            final Uri uri;
            final Object? data;
            final Options options;

            try {
              uri = Uri.parse(_dio.options.baseUrl).resolveUri(Uri(path: _path()));
              data = _data();
              options = _options();
            } on Exception catch (exception, stackTrace) {
              return TonikError(
                exception,
                stackTrace: stackTrace,
                type: TonikErrorType.encoding,
                response: null,
              );
            }

            final Response<dynamic> response;

            try {
              response = await _dio.requestUri<dynamic>(
                uri,
                data: data,
                options: options,
              );
            } on Exception catch (exception, stackTrace) {
              return TonikError(
                exception,
                stackTrace: stackTrace,
                type: TonikErrorType.network,
                response: null,
              );
            }

            return TonikSuccess(null, response);
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

        const expectedMethod = '''
          Future<TonikResult<void>> call({required String xMyHeader}) async {
            final Uri uri;
            final Object? data;
            final Options options;

            try {
              uri = Uri.parse(_dio.options.baseUrl).resolveUri(Uri(path: _path()));
              data = _data();
              options = _options(xMyHeader: xMyHeader);
            } on Exception catch (exception, stackTrace) {
              return TonikError(
                exception,
                stackTrace: stackTrace,
                type: TonikErrorType.encoding,
                response: null,
              );
            }

            final Response<dynamic> response;

            try {
              response = await _dio.requestUri<dynamic>(
                uri,
                data: data,
                options: options,
              );
            } on Exception catch (exception, stackTrace) {
              return TonikError(
                exception,
                stackTrace: stackTrace,
                type: TonikErrorType.network,
                response: null,
              );
            }

            return TonikSuccess(null, response);
          }
        ''';

        final normalizedParams = NormalizedRequestParameters(
          pathParameters: const [],
          queryParameters: const [],
          headers: [(normalizedName: 'xMyHeader', parameter: requestHeader)],
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
        expect(param.name, 'xMyHeader');
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
          pathParameters: const {},
          responses: const {},
          requestBody: null,
        );

        const expectedMethod = '''
          Future<TonikResult<void>> call({required int petId}) async {
            final Uri uri;
            final Object? data;
            final Options options;

            try {
              uri = Uri.parse(
                _dio.options.baseUrl,
              ).resolveUri(Uri(path: _path(petId: petId)));
              data = _data();
              options = _options();
            } on Exception catch (exception, stackTrace) {
              return TonikError(
                exception,
                stackTrace: stackTrace,
                type: TonikErrorType.encoding,
                response: null,
              );
            }

            final Response<dynamic> response;

            try {
              response = await _dio.requestUri<dynamic>(
                uri,
                data: data,
                options: options,
              );
            } on Exception catch (exception, stackTrace) {
              return TonikError(
                exception,
                stackTrace: stackTrace,
                type: TonikErrorType.network,
                response: null,
              );
            }

            return TonikSuccess(null, response);
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

        const expectedMethod = '''
          Future<TonikResult<void>> call() async {
            final Uri uri;
            final Object? data;
            final Options options;

            try {
              uri = Uri.parse(_dio.options.baseUrl).resolveUri(Uri(path: _path()));
              data = _data();
              options = _options();
            } on Exception catch (exception, stackTrace) {
              return TonikError(
                exception,
                stackTrace: stackTrace,
                type: TonikErrorType.encoding,
                response: null,
              );
            }

            final Response<dynamic> response;

            try {
              response = await _dio.requestUri<dynamic>(
                uri,
                data: data,
                options: options,
              );
            } on Exception catch (exception, stackTrace) {
              return TonikError(
                exception,
                stackTrace: stackTrace,
                type: TonikErrorType.network,
                response: null,
              );
            }

            return TonikSuccess(null, response);
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

        const expectedMethod = '''
          Future<TonikResult<void>> call({required String filter, String? sort}) async {
            final Uri uri;
            final Object? data;
            final Options options;

            try {
              uri = Uri.parse(_dio.options.baseUrl).resolveUri(
                Uri(path: _path(), query: _queryParameters(filter: filter, sort: sort)),
              );
              data = _data();
              options = _options();
            } on Exception catch (exception, stackTrace) {
              return TonikError(
                exception,
                stackTrace: stackTrace,
                type: TonikErrorType.encoding,
                response: null,
              );
            }

            final Response<dynamic> response;

            try {
              response = await _dio.requestUri<dynamic>(
                uri,
                data: data,
                options: options,
              );
            } on Exception catch (exception, stackTrace) {
              return TonikError(
                exception,
                stackTrace: stackTrace,
                type: TonikErrorType.network,
                response: null,
              );
            }

            return TonikSuccess(null, response);
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

      test(
        'generates query parameters method when query parameters exist',
        () {
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
        },
      );
    });
  });
}
