import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';
import 'package:tonik_generate/src/util/operation_parameter_generator.dart';

void main() {
  late NameManager nameManager;
  late NameGenerator nameGenerator;
  late Context context;
  late DartEmitter emitter;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('generateParameters', () {
    test('generates parameters for cookie parameters', () {
      final cookieParam = CookieParameterObject(
        name: 'sessionId',
        rawName: 'session_id',
        description: 'Session identifier',
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
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      expect(parameters.length, 1);
      expect(parameters.first.name, 'sessionId');
      expect(parameters.first.required, isTrue);
      expect(parameters.first.named, isTrue);
      expect(
        parameters.first.type?.accept(emitter).toString(),
        'String',
      );
    });

    test('generates optional parameters for optional cookies', () {
      final cookieParam = CookieParameterObject(
        name: 'trackingId',
        rawName: 'tracking_id',
        description: 'Tracking identifier',
        isRequired: false,
        isDeprecated: false,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      expect(parameters.length, 1);
      expect(parameters.first.name, 'trackingId');
      expect(parameters.first.required, isFalse);
      expect(
        parameters.first.type?.accept(emitter).toString(),
        'String?',
      );
    });

    test('adds deprecation annotation for deprecated cookie parameters', () {
      final cookieParam = CookieParameterObject(
        name: 'oldCookie',
        rawName: 'old_cookie',
        description: 'Old cookie',
        isRequired: true,
        isDeprecated: true,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      expect(parameters.length, 1);
      expect(parameters.first.annotations.length, 1);

      // Use object introspection for annotation.
      final annotation = parameters.first.annotations.first;
      expect(annotation, isA<InvokeExpression>());
      final invoke = annotation as InvokeExpression;
      expect(invoke.target, isA<Reference>());
      final ref = invoke.target as Reference;
      expect(ref.symbol, 'Deprecated');
      expect(ref.url, 'dart:core');
    });

    test('normalizes cookie parameter names', () {
      final cookieParam = CookieParameterObject(
        name: null,
        rawName: 'session_id',
        description: 'Session',
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
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      // Name should be normalized from 'session_id' to 'sessionId'.
      expect(parameters.first.name, 'sessionId');
    });

    test('generates parameters for integer cookie', () {
      final cookieParam = CookieParameterObject(
        name: 'pageNum',
        rawName: 'page_num',
        description: 'Page number',
        isRequired: true,
        isDeprecated: false,
        explode: false,
        model: IntegerModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      expect(parameters.length, 1);
      expect(parameters.first.name, 'pageNum');
      expect(
        parameters.first.type?.accept(emitter).toString(),
        'int',
      );
    });

    test('generates parameters for boolean cookie', () {
      final cookieParam = CookieParameterObject(
        name: 'debugMode',
        rawName: 'debug_mode',
        description: 'Debug mode',
        isRequired: false,
        isDeprecated: false,
        explode: false,
        model: BooleanModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      expect(parameters.length, 1);
      expect(parameters.first.name, 'debugMode');
      expect(
        parameters.first.type?.accept(emitter).toString(),
        'bool?',
      );
    });

    test('adds type suffix when cookie name conflicts with other params', () {
      final pathParam = PathParameterObject(
        name: null,
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
        defaultValue: null,
      );

      final cookieParam = CookieParameterObject(
        name: null,
        rawName: 'id',
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
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      expect(parameters.length, 2);

      final paramNames = parameters.map((p) => p.name).toList();
      expect(paramNames, contains('idPath'));
      expect(paramNames, contains('idCookie'));
    });

    test('includes cookies along with other parameter types', () {
      final pathParam = PathParameterObject(
        name: null,
        rawName: 'userId',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final queryParam = QueryParameterObject(
        name: null,
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

      final headerParam = RequestHeaderObject(
        name: null,
        rawName: 'X-Api-Key',
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

      final cookieParam = CookieParameterObject(
        name: null,
        rawName: 'session_id',
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
        operationId: 'testOp',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/users/{userId}',
        method: HttpMethod.get,
        headers: {headerParam},
        queryParameters: {queryParam},
        pathParameters: {pathParam},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      expect(parameters.length, 4);

      final paramNames = parameters.map((p) => p.name).toList();
      expect(paramNames, contains('userId'));
      expect(paramNames, contains('filter'));
      expect(paramNames, contains('apiKey')); // x- prefix removed.
      expect(paramNames, contains('sessionId'));
    });
  });

  group('multipart per-part header parameters', () {
    test('generates parameter for property with one header', () {
      final requestBody = RequestBodyObject(
        name: 'uploadBody',
        context: context,
        description: null,
        isRequired: true,
        content: {
          RequestContent(
            model: ClassModel(
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
            ),
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'file': MultipartPropertyEncoding(
                contentType: ContentType.bytes,
                rawContentType: 'application/octet-stream',
                headers: {
                  'X-Rate-Limit-Limit': ResponseHeaderObject(
                    name: 'X-Rate-Limit-Limit',
                    context: context,
                    description: 'Rate limit',
                    explode: false,
                    model: IntegerModel(context: context),
                    isRequired: true,
                    isDeprecated: false,
                    encoding: ResponseHeaderEncoding.simple,
                    examples: const [],
                  ),
                },
              ),
            },
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

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      // body + one header param
      expect(parameters.length, 2);
      final headerParam = parameters.firstWhere(
        (p) => p.name == 'fileRateLimitLimit',
      );
      expect(headerParam.named, isTrue);
      expect(headerParam.required, isTrue);
      expect(headerParam.type?.accept(emitter).toString(), 'int');
    });

    test('generates multiple header parameters for multiple headers', () {
      final requestBody = RequestBodyObject(
        name: 'uploadBody',
        context: context,
        description: null,
        isRequired: true,
        content: {
          RequestContent(
            model: ClassModel(
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
            ),
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'file': MultipartPropertyEncoding(
                contentType: ContentType.bytes,
                rawContentType: 'application/octet-stream',
                headers: {
                  'X-Rate-Limit-Limit': ResponseHeaderObject(
                    name: 'X-Rate-Limit-Limit',
                    context: context,
                    description: 'Rate limit',
                    explode: false,
                    model: IntegerModel(context: context),
                    isRequired: true,
                    isDeprecated: false,
                    encoding: ResponseHeaderEncoding.simple,
                    examples: const [],
                  ),
                  'X-Custom-Tag': ResponseHeaderObject(
                    name: 'X-Custom-Tag',
                    context: context,
                    description: 'Custom tag',
                    explode: false,
                    model: StringModel(context: context),
                    isRequired: false,
                    isDeprecated: false,
                    encoding: ResponseHeaderEncoding.simple,
                    examples: const [],
                  ),
                },
              ),
            },
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

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      // body + two header params
      expect(parameters.length, 3);

      final rateLimitParam = parameters.firstWhere(
        (p) => p.name == 'fileRateLimitLimit',
      );
      expect(rateLimitParam.required, isTrue);
      expect(rateLimitParam.type?.accept(emitter).toString(), 'int');

      final customTagParam = parameters.firstWhere(
        (p) => p.name == 'fileCustomTag',
      );
      expect(customTagParam.required, isFalse);
      expect(customTagParam.type?.accept(emitter).toString(), 'String?');
    });

    test(
      'optional property with required header produces optional parameter',
      () {
        final requestBody = RequestBodyObject(
          name: 'uploadBody',
          context: context,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: ClassModel(
                name: 'UploadForm',
                properties: [
                  Property(
                    name: 'avatar',
                    model: BinaryModel(context: context),
                    isRequired: false,
                    isNullable: false,
                    isDeprecated: false,
                    examples: const [],
                    defaultValue: null,
                  ),
                ],
                context: context,
                isDeprecated: false,
                examples: const [],
              ),
              contentType: ContentType.multipart,
              rawContentType: 'multipart/form-data',
              encoding: {
                'avatar': MultipartPropertyEncoding(
                  contentType: ContentType.bytes,
                  rawContentType: 'application/octet-stream',
                  headers: {
                    'X-Custom': ResponseHeaderObject(
                      name: 'X-Custom',
                      context: context,
                      description: null,
                      explode: false,
                      model: StringModel(context: context),
                      isRequired: true,
                      isDeprecated: false,
                      encoding: ResponseHeaderEncoding.simple,
                      examples: const [],
                    ),
                  },
                ),
              },
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

        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
        );

        final headerParam = parameters.firstWhere(
          (p) => p.name == 'avatarCustom',
        );
        // Optional because the property itself is optional.
        expect(headerParam.required, isFalse);
        expect(headerParam.type?.accept(emitter).toString(), 'String?');
      },
    );

    test('does not filter out Content-Type header', () {
      final requestBody = RequestBodyObject(
        name: 'uploadBody',
        context: context,
        description: null,
        isRequired: true,
        content: {
          RequestContent(
            model: ClassModel(
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
            ),
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'file': MultipartPropertyEncoding(
                contentType: ContentType.bytes,
                rawContentType: 'application/octet-stream',
                headers: {
                  'Content-Type': ResponseHeaderObject(
                    name: 'Content-Type',
                    context: context,
                    description: null,
                    explode: false,
                    model: StringModel(context: context),
                    isRequired: false,
                    isDeprecated: false,
                    encoding: ResponseHeaderEncoding.simple,
                    examples: const [],
                  ),
                  'X-Custom': ResponseHeaderObject(
                    name: 'X-Custom',
                    context: context,
                    description: null,
                    explode: false,
                    model: StringModel(context: context),
                    isRequired: false,
                    isDeprecated: false,
                    encoding: ResponseHeaderEncoding.simple,
                    examples: const [],
                  ),
                },
              ),
            },
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

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      // body + Content-Type + X-Custom (Content-Type is not filtered)
      expect(parameters.length, 3);
      final paramNames = parameters.map((p) => p.name).toList();
      expect(paramNames, contains('body'));
      expect(paramNames, contains('fileContentType'));
      expect(paramNames, contains('fileCustom'));
    });

    test('no extra parameters for property without headers', () {
      final requestBody = RequestBodyObject(
        name: 'uploadBody',
        context: context,
        description: null,
        isRequired: true,
        content: {
          RequestContent(
            model: ClassModel(
              name: 'UploadForm',
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
              isDeprecated: false,
              examples: const [],
            ),
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'name': const MultipartPropertyEncoding(
                contentType: ContentType.text,
                rawContentType: 'text/plain',
              ),
            },
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

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      // Only body parameter, no extra header params.
      expect(parameters.length, 1);
      expect(parameters.first.name, 'body');
    });

    test('multipart header parameter name does not collide with query '
        'parameter of same normalized name', () {
      // Query param "file_custom" normalizes to "fileCustom".
      // Multipart header "X-Custom" on property "file" also normalizes to
      // "fileCustom". We need unique names.
      final requestBody = RequestBodyObject(
        name: 'uploadBody',
        context: context,
        description: null,
        isRequired: true,
        content: {
          RequestContent(
            model: ClassModel(
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
            ),
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'file': MultipartPropertyEncoding(
                contentType: ContentType.bytes,
                rawContentType: 'application/octet-stream',
                headers: {
                  'X-Custom': ResponseHeaderObject(
                    name: 'X-Custom',
                    context: context,
                    description: null,
                    explode: false,
                    model: StringModel(context: context),
                    isRequired: true,
                    isDeprecated: false,
                    encoding: ResponseHeaderEncoding.simple,
                    examples: const [],
                  ),
                },
              ),
            },
            examples: const [],
          ),
        },
      );

      final queryParam = QueryParameterObject(
        name: null,
        rawName: 'file_custom',
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
        operationId: 'upload',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/upload',
        method: HttpMethod.post,
        headers: const {},
        queryParameters: {queryParam},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        requestBody: requestBody,
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      // body + query param + multipart header param = 3 parameters.
      expect(parameters.length, 3);

      final paramNames = parameters.map((p) => p.name).toList();
      // All names must be unique.
      expect(
        paramNames.toSet().length,
        paramNames.length,
        reason: 'Parameter names must be unique: $paramNames',
      );
    });

    test('generates deprecated annotation for deprecated multipart header', () {
      final requestBody = RequestBodyObject(
        name: 'uploadBody',
        context: context,
        description: null,
        isRequired: true,
        content: {
          RequestContent(
            model: ClassModel(
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
            ),
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'file': MultipartPropertyEncoding(
                contentType: ContentType.bytes,
                rawContentType: 'application/octet-stream',
                headers: {
                  'X-Legacy': ResponseHeaderObject(
                    name: 'X-Legacy',
                    context: context,
                    description: null,
                    explode: false,
                    model: StringModel(context: context),
                    isRequired: false,
                    isDeprecated: true,
                    encoding: ResponseHeaderEncoding.simple,
                    examples: const [],
                  ),
                },
              ),
            },
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

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      final headerParam = parameters.firstWhere((p) => p.name != 'body');
      expect(headerParam.annotations, hasLength(1));
      expect(
        headerParam.annotations.first.accept(emitter).toString(),
        contains('Deprecated'),
      );
    });

    test('resolves ResponseHeaderAlias to underlying header object', () {
      final underlyingHeader = ResponseHeaderObject(
        name: 'X-Trace-Id',
        context: context,
        description: 'Trace identifier',
        explode: false,
        model: StringModel(context: context),
        isRequired: true,
        isDeprecated: false,
        encoding: ResponseHeaderEncoding.simple,
        examples: const [],
      );

      final bodyModel = ClassModel(
        name: 'UploadForm',
        isDeprecated: false,
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
        examples: const [],
      );

      final requestBody = RequestBodyObject(
        name: 'uploadBody',
        context: context,
        description: 'Upload',
        isRequired: true,
        content: {
          RequestContent(
            model: bodyModel,
            contentType: ContentType.multipart,
            rawContentType: 'multipart/form-data',
            encoding: {
              'file': MultipartPropertyEncoding(
                contentType: ContentType.bytes,
                rawContentType: 'application/octet-stream',
                headers: {
                  'X-Trace-Id': ResponseHeaderAlias(
                    name: 'X-Trace-Id',
                    context: context,
                    header: underlyingHeader,
                  ),
                },
              ),
            },
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

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      // body + 1 resolved header = 2 parameters.
      expect(parameters.length, 2);

      final headerParam = parameters.firstWhere(
        (p) => p.name != 'body',
      );
      expect(headerParam.name, 'fileTraceId');
      expect(headerParam.required, isTrue);
      // The type should come from the resolved underlying header (String).
      final typeCode = headerParam.type?.accept(emitter).toString();
      expect(typeCode, contains('String'));
    });

    test(
      'per-part header backed by an alias with a default does not receive a '
      'defaultTo or static const field (defaults pipeline is operation '
      'parameters only)',
      () {
        final aliasedModel = AliasModel(
          name: 'TraceIdHeader',
          model: StringModel(context: context),
          context: context,
          examples: const [],
          defaultValue: 'static-trace-id',
        );

        final requestBody = RequestBodyObject(
          name: 'uploadBody',
          context: context,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: ClassModel(
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
              ),
              contentType: ContentType.multipart,
              rawContentType: 'multipart/form-data',
              encoding: {
                'file': MultipartPropertyEncoding(
                  contentType: ContentType.bytes,
                  rawContentType: 'application/octet-stream',
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
              },
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

        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
        );

        final headerParam = parameters.firstWhere(
          (p) => p.name == 'fileTraceId',
        );
        expect(headerParam.defaultTo, isNull);
        expect(headerParam.required, isTrue);
      },
    );
  });

  group('body parameter name collision', () {
    test(
      'adds Query suffix to query parameter named body when '
      'request body is present',
      () {
        final queryParam = QueryParameterObject(
          name: null,
          rawName: 'body',
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

        final requestBody = RequestBodyObject(
          name: 'payload',
          context: context,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: ClassModel(
                name: 'Payload',
                properties: const [],
                context: context,
                isDeprecated: false,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        );

        final operation = Operation(
          operationId: 'createWithBodyQuery',
          context: context,
          tags: const {},
          isDeprecated: false,
          path: '/test',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: {queryParam},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          requestBody: requestBody,
          securitySchemes: const {},
        );

        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
        );

        final paramNames = parameters.map((p) => p.name).toList();
        expect(paramNames, contains('body'));
        expect(paramNames, contains('bodyQuery'));
        expect(
          paramNames.toSet().length,
          paramNames.length,
          reason: 'Parameter names must be unique: $paramNames',
        );
      },
    );

    test(
      'adds Header suffix to header parameter named body when '
      'request body is present',
      () {
        final headerParam = RequestHeaderObject(
          name: null,
          rawName: 'body',
          description: null,
          isRequired: false,
          isDeprecated: false,
          allowEmptyValue: false,
          explode: false,
          model: StringModel(context: context),
          encoding: HeaderParameterEncoding.simple,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final requestBody = RequestBodyObject(
          name: 'payload',
          context: context,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: ClassModel(
                name: 'Payload',
                properties: const [],
                context: context,
                isDeprecated: false,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        );

        final operation = Operation(
          operationId: 'createWithBodyHeader',
          context: context,
          tags: const {},
          isDeprecated: false,
          path: '/test',
          method: HttpMethod.post,
          headers: {headerParam},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          requestBody: requestBody,
          securitySchemes: const {},
        );

        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
        );

        final paramNames = parameters.map((p) => p.name).toList();
        expect(paramNames, contains('body'));
        expect(paramNames, contains('bodyHeader'));
        expect(
          paramNames.toSet().length,
          paramNames.length,
          reason: 'Parameter names must be unique: $paramNames',
        );
      },
    );

    test(
      'adds Cookie suffix to cookie parameter named body when '
      'request body is present',
      () {
        final cookieParam = CookieParameterObject(
          name: null,
          rawName: 'body',
          description: null,
          isRequired: false,
          isDeprecated: false,
          explode: false,
          model: StringModel(context: context),
          encoding: CookieParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: null,
        );

        final requestBody = RequestBodyObject(
          name: 'payload',
          context: context,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: ClassModel(
                name: 'Payload',
                properties: const [],
                context: context,
                isDeprecated: false,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        );

        final operation = Operation(
          operationId: 'createWithBodyCookie',
          context: context,
          tags: const {},
          isDeprecated: false,
          path: '/test',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: {cookieParam},
          responses: const {},
          requestBody: requestBody,
          securitySchemes: const {},
        );

        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
        );

        final paramNames = parameters.map((p) => p.name).toList();
        expect(paramNames, contains('body'));
        expect(paramNames, contains('bodyCookie'));
        expect(
          paramNames.toSet().length,
          paramNames.length,
          reason: 'Parameter names must be unique: $paramNames',
        );
      },
    );

    test(
      'does not add suffix when parameter named body has no request body',
      () {
        final queryParam = QueryParameterObject(
          name: null,
          rawName: 'body',
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
          operationId: 'getWithBody',
          context: context,
          tags: const {},
          isDeprecated: false,
          path: '/test',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {queryParam},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
        );

        expect(parameters.length, 1);
        expect(parameters.first.name, 'body');
      },
    );
  });

  group('cancelToken parameter name collision', () {
    test('adds Query suffix to query parameter named cancelToken', () {
      final queryParam = QueryParameterObject(
        name: null,
        rawName: 'cancelToken',
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
        operationId: 'getWithCancelTokenQuery',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: {queryParam},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      final paramNames = parameters.map((p) => p.name).toList();
      expect(paramNames, contains('cancelTokenQuery'));
      expect(paramNames, isNot(contains('cancelToken')));
      expect(
        paramNames.toSet().length,
        paramNames.length,
        reason: 'Parameter names must be unique: $paramNames',
      );
    });

    test('adds Path suffix to path parameter named cancelToken', () {
      final pathParam = PathParameterObject(
        name: null,
        rawName: 'cancelToken',
        description: null,
        isRequired: true,
        isDeprecated: false,
        allowEmptyValue: false,
        explode: false,
        model: StringModel(context: context),
        encoding: PathParameterEncoding.simple,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'getWithCancelTokenPath',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test/{cancelToken}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: {pathParam},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      final paramNames = parameters.map((p) => p.name).toList();
      expect(paramNames, contains('cancelTokenPath'));
      expect(paramNames, isNot(contains('cancelToken')));
      expect(
        paramNames.toSet().length,
        paramNames.length,
        reason: 'Parameter names must be unique: $paramNames',
      );
    });

    test('adds Header suffix to header parameter named cancelToken', () {
      final headerParam = RequestHeaderObject(
        name: null,
        rawName: 'cancelToken',
        description: null,
        isRequired: false,
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
        operationId: 'getWithCancelTokenHeader',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: {headerParam},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: const {},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      final paramNames = parameters.map((p) => p.name).toList();
      expect(paramNames, contains('cancelTokenHeader'));
      expect(paramNames, isNot(contains('cancelToken')));
      expect(
        paramNames.toSet().length,
        paramNames.length,
        reason: 'Parameter names must be unique: $paramNames',
      );
    });

    test('adds Cookie suffix to cookie parameter named cancelToken', () {
      final cookieParam = CookieParameterObject(
        name: null,
        rawName: 'cancelToken',
        description: null,
        isRequired: false,
        isDeprecated: false,
        explode: false,
        model: StringModel(context: context),
        encoding: CookieParameterEncoding.form,
        context: context,
        examples: const [],
        defaultValue: null,
      );

      final operation = Operation(
        operationId: 'getWithCancelTokenCookie',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/test',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        cookieParameters: {cookieParam},
        responses: const {},
        securitySchemes: const {},
      );

      final parameters = generateParameters(
        operation: operation,
        nameManager: nameManager,
        package: 'api',
      );

      final paramNames = parameters.map((p) => p.name).toList();
      expect(paramNames, contains('cancelTokenCookie'));
      expect(paramNames, isNot(contains('cancelToken')));
      expect(
        paramNames.toSet().length,
        paramNames.length,
        reason: 'Parameter names must be unique: $paramNames',
      );
    });

    test(
      'renames query parameter named cancelToken even when '
      'request body is present',
      () {
        final queryParam = QueryParameterObject(
          name: null,
          rawName: 'cancelToken',
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

        final requestBody = RequestBodyObject(
          name: 'payload',
          context: context,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: ClassModel(
                name: 'Payload',
                properties: const [],
                context: context,
                isDeprecated: false,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        );

        final operation = Operation(
          operationId: 'createWithCancelTokenQuery',
          context: context,
          tags: const {},
          isDeprecated: false,
          path: '/test',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: {queryParam},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          requestBody: requestBody,
          securitySchemes: const {},
        );

        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
        );

        final paramNames = parameters.map((p) => p.name).toList();
        expect(paramNames, contains('body'));
        expect(paramNames, contains('cancelTokenQuery'));
        expect(paramNames, isNot(contains('cancelToken')));
        expect(
          paramNames.toSet().length,
          paramNames.length,
          reason: 'Parameter names must be unique: $paramNames',
        );
      },
    );

    test(
      'does not rename query parameter named token (no collision with '
      'cancelToken)',
      () {
        final queryParam = QueryParameterObject(
          name: null,
          rawName: 'token',
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
          operationId: 'getWithToken',
          context: context,
          tags: const {},
          isDeprecated: false,
          path: '/test',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: {queryParam},
          pathParameters: const {},
          cookieParameters: const {},
          responses: const {},
          securitySchemes: const {},
        );

        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
        );

        expect(parameters.length, 1);
        expect(parameters.first.name, 'token');
      },
    );
  });

  group('generateParameters — defaultsByName', () {
    Operation operationWith({
      Set<QueryParameterObject> queryParameters = const {},
      Set<PathParameterObject> pathParameters = const {},
      Set<RequestHeaderObject> headers = const {},
      Set<CookieParameterObject> cookieParameters = const {},
      String path = '/things',
    }) => Operation(
      operationId: 'op',
      context: context,
      tags: const {},
      isDeprecated: false,
      path: path,
      method: HttpMethod.get,
      headers: headers,
      queryParameters: queryParameters,
      pathParameters: pathParameters,
      cookieParameters: cookieParameters,
      responses: const {},
      securitySchemes: const {},
    );

    test(
      'optional query string with materialised default becomes non-required '
      'with defaultTo and non-nullable type',
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

        final operation = operationWith(queryParameters: {region});
        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
          defaultsByName: {
            'region': OperationParameterDefault.local(
              memberName: 'regionDefault',
              value: const CodeExpression(Code("r'us'")),
              type: _dummyType,
            ),
          },
        );

        expect(parameters.length, 1);
        final param = parameters.single;
        expect(param.name, 'region');
        expect(param.required, isFalse);
        expect(param.named, isTrue);
        expect(param.defaultTo?.accept(emitter).toString(), 'regionDefault');
        expect(param.type?.accept(emitter).toString(), 'String');
      },
    );

    test(
      'required query int with materialised default becomes non-required '
      'with defaultTo',
      () {
        final page = QueryParameterObject(
          name: 'page',
          rawName: 'page',
          description: null,
          isRequired: true,
          isDeprecated: false,
          allowEmptyValue: false,
          allowReserved: false,
          explode: false,
          model: IntegerModel(context: context),
          encoding: QueryParameterEncoding.form,
          context: context,
          examples: const [],
          defaultValue: 1,
        );

        final operation = operationWith(queryParameters: {page});
        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
          defaultsByName: {
            'page': OperationParameterDefault.local(
              memberName: 'pageDefault',
              value: const CodeExpression(Code('1')),
              type: _dummyType,
            ),
          },
        );

        final param = parameters.single;
        expect(param.required, isFalse);
        expect(param.defaultTo?.accept(emitter).toString(), 'pageDefault');
        expect(param.type?.accept(emitter).toString(), 'int');
      },
    );

    test(
      'header integer with materialised default exposes defaultTo + '
      'non-nullable int type',
      () {
        final retries = RequestHeaderObject(
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

        final operation = operationWith(headers: {retries});
        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
          defaultsByName: {
            'retries': OperationParameterDefault.local(
              memberName: 'retriesDefault',
              value: const CodeExpression(Code('5')),
              type: _dummyType,
            ),
          },
        );

        final param = parameters.single;
        expect(param.name, 'retries');
        expect(param.required, isFalse);
        expect(param.defaultTo?.accept(emitter).toString(), 'retriesDefault');
        expect(param.type?.accept(emitter).toString(), 'int');
      },
    );

    test(
      'cookie boolean with materialised default exposes defaultTo + '
      'non-nullable bool type',
      () {
        final tracking = CookieParameterObject(
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

        final operation = operationWith(cookieParameters: {tracking});
        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
          defaultsByName: {
            'tracking': OperationParameterDefault.local(
              memberName: 'trackingDefault',
              value: const CodeExpression(Code('false')),
              type: _dummyType,
            ),
          },
        );

        final param = parameters.single;
        expect(param.name, 'tracking');
        expect(param.required, isFalse);
        expect(
          param.defaultTo?.accept(emitter).toString(),
          'trackingDefault',
        );
        expect(param.type?.accept(emitter).toString(), 'bool');
      },
    );

    test(
      'path string with materialised default becomes non-required + '
      'defaultTo, no warning',
      () {
        final id = PathParameterObject(
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

        final operation = operationWith(
          pathParameters: {id},
          path: '/things/{id}',
        );
        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
          defaultsByName: {
            'id': OperationParameterDefault.local(
              memberName: 'idDefault',
              value: const CodeExpression(Code("r'x'")),
              type: _dummyType,
            ),
          },
        );

        final param = parameters.single;
        expect(param.required, isFalse);
        expect(param.defaultTo?.accept(emitter).toString(), 'idDefault');
        expect(param.type?.accept(emitter).toString(), 'String');
      },
    );

    test(
      'parameter without a defaults entry retains normal required/optional '
      'rules — defaultTo stays null',
      () {
        final region = QueryParameterObject(
          name: 'region',
          rawName: 'region',
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

        final operation = operationWith(queryParameters: {region});
        final parameters = generateParameters(
          operation: operation,
          nameManager: nameManager,
          package: 'api',
        );

        final param = parameters.single;
        expect(param.required, isTrue);
        expect(param.defaultTo, isNull);
        expect(param.type?.accept(emitter).toString(), 'String');
      },
    );
  });
}

final _dummyType = TypeReference(
  (b) => b
    ..symbol = 'String'
    ..url = 'dart:core',
);
