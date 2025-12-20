import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/parse_generator.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';

void main() {
  group('ParseGenerator', () {
    const package = 'package:package_name/package_name.dart';

    late ParseGenerator generator;
    late NameManager nameManager;
    late NameGenerator nameGenerator;
    late Context context;
    late DartEmitter emitter;
    late CorePrefixedAllocator scopedAllocator;
    late DartEmitter scopedEmitter;

    final format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = ParseGenerator(nameManager: nameManager, package: package);

      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
      scopedAllocator = CorePrefixedAllocator();
      scopedEmitter = DartEmitter(
        useNullSafetySyntax: true,
        allocator: scopedAllocator,
      );
    });

    test('generates for primitive response', () {
      final operation = Operation(
        operationId: 'primitiveOp',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/primitive',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
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
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
String _parseResponse(Response<List<int>> response) {
  switch ((response.statusCode, response.headers.value('content-type'))) {
    case (200, 'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return _$body;
    default:
      final content = response.headers.value('content-type') ?? 'not specified';
      final status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
  }
}
''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('generates for enum response', () {
      final enumModel = EnumModel(
        isDeprecated: false,
        context: context,
        values: {
          const EnumEntry(value: 'A'),
          const EnumEntry(value: 'B'),
          const EnumEntry(value: 'C'),
        },
        isNullable: false,
      );
      final operation = Operation(
        operationId: 'enumOp',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/enum',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: '',
            bodies: {
              ResponseBody(
                model: enumModel,
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        AnonymousModel _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = AnonymousModel.fromJson(_$json);
              return _$body;
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('generates for class response', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final operation = Operation(
        operationId: 'classOp',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/class',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: '',
            bodies: {
              ResponseBody(
                model: classModel,
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        User _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return _$body;
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('generates for list of primitives', () {
      final operation = Operation(
        operationId: 'listPrimitiveOp',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/list-primitive',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: '',
            bodies: {
              ResponseBody(
                model: ListModel(
                  content: IntegerModel(context: context),
                  context: context,
                ),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        List<int> _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonList<int>();
              return _$body;
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('generates for list of classes', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final operation = Operation(
        operationId: 'listClassOp',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/list-class',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: '',
            bodies: {
              ResponseBody(
                model: ListModel(content: classModel, context: context),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        },
        securitySchemes: const {},
      );

      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        List<User> _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonList<Object?>()
                .map(User.fromJson)
                .toList();
              return _$body;
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('generates for oneOf/allOf polymorphic response', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'Pet',
        models: {
          (
            discriminatorValue: 'cat',
            model: ClassModel(
              isDeprecated: false,
              name: 'Cat',
              properties: const [],
              context: context,
            ),
          ),
          (
            discriminatorValue: 'dog',
            model: ClassModel(
              isDeprecated: false,
              name: 'Dog',
              properties: const [],
              context: context,
            ),
          ),
        },
        discriminator: 'type',
        context: context,
      );
      final operation = Operation(
        operationId: 'oneOfOp',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/oneof',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: '',
            bodies: {
              ResponseBody(
                model: oneOfModel,
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        Pet _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = Pet.fromJson(_$json);
              return _$body;
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('generates for range response status', () {
      final operation = Operation(
        operationId: 'rangeStatusOp',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/range-status',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const RangeResponseStatus(min: 200, max: 299): ResponseObject(
            name: null,
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
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        String _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (var status, 'application/json') when status != null && status >= 200 && status <= 299:
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonString();
              return _$body;
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('generates for default response status', () {
      final operation = Operation(
        operationId: 'defaultStatusOp',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/default-status',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const DefaultResponseStatus(): ResponseObject(
            name: null,
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
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        String _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (_, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonString();
              return _$body;
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('generates for multiple response status codes', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final operation = Operation(
        operationId: 'multiStatusOp',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/multi-status',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: '',
            bodies: {
              ResponseBody(
                model: classModel,
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
          const ExplicitResponseStatus(statusCode: 400): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: '',
            bodies: const {},
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        MultiStatusOpResponse _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return MultiStatusOpResponse200(body: _$body);
            case (400, _):
              return MultiStatusOpResponse400();
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('generates for response with headers', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final responseHeaders = {
        'x-rate-limit': ResponseHeaderObject(
          name: 'x-rate-limit',
          context: context,
          description: '',
          isRequired: false,
          isDeprecated: false,
          model: IntegerModel(context: context),
          explode: false,
          encoding: ResponseHeaderEncoding.simple,
        ),
        'x-expires-after': ResponseHeaderObject(
          name: 'x-expires-after',
          context: context,
          description: '',
          isRequired: false,
          isDeprecated: false,
          model: DateTimeModel(context: context),
          explode: false,
          encoding: ResponseHeaderEncoding.simple,
        ),
      };
      final operation = Operation(
        operationId: 'headerStatusOp',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/header-status',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: responseHeaders,
            description: '',
            bodies: {
              ResponseBody(
                model: classModel,
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        AnonymousResponse _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return AnonymousResponse(
                  body: _$body,
                  xRateLimit: response.headers
                    .value(r'x-rate-limit')
                    .decodeSimpleNullableInt(context: r'x-rate-limit'),
                  xExpiresAfter: response.headers
                    .value(r'x-expires-after')
                    .decodeSimpleNullableDateTime(context: r'x-expires-after'),
              );
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: $content for status code: $status',
              );
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('combines headers, default, range, and explicit cases', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final enumModel = EnumModel(
        isDeprecated: false,
        context: context,
        values: {
          const EnumEntry(value: 'A'),
          const EnumEntry(value: 'B'),
          const EnumEntry(value: 'C'),
        },
        isNullable: false,
      );
      final operation = Operation(
        operationId: 'combinedOp',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/combined',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: {
              'x-rate-limit': ResponseHeaderObject(
                name: 'x-rate-limit',
                context: context,
                description: null,
                explode: false,
                model: IntegerModel(context: context),
                isRequired: false,
                isDeprecated: false,
                encoding: ResponseHeaderEncoding.simple,
              ),
            },
            description: '',
            bodies: {
              ResponseBody(
                model: classModel,
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
          const RangeResponseStatus(min: 400, max: 499): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: '',
            bodies: {
              ResponseBody(
                model: enumModel,
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
          const DefaultResponseStatus(): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: '',
            bodies: const {},
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        CombinedOpResponse _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return CombinedOpResponse200(
                body: AnonymousResponse(
                  body: _$body,
                  xRateLimit: response.headers
                    .value(r'x-rate-limit')
                    .decodeSimpleNullableInt(context: r'x-rate-limit'),
                ),
              );
            case (var status, 'application/json') when status != null && status >= 400 && status <= 499:
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = AnonymousModel.fromJson(_$json);
              return CombinedOpResponse4XX(body: _$body);
            case (_, _):
              return CombinedOpResponseDefault();
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('generates for response with alias', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      // Create the base response object
      final baseResponse = ResponseObject(
        name: 'BaseResponse',
        context: context,
        description: 'Base response with headers',
        headers: {
          'x-user-id': ResponseHeaderObject(
            name: 'x-user-id',
            context: context,
            description: 'User ID header',
            model: StringModel(context: context),
            isRequired: true,
            isDeprecated: false,
            explode: false,
            encoding: ResponseHeaderEncoding.simple,
          ),
        },
        bodies: {
          ResponseBody(
            model: classModel,
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
      );

      // Create an alias for the base response
      final aliasedResponse = ResponseAlias(
        name: 'AliasedResponse',
        context: context,
        response: baseResponse,
      );

      final operation = Operation(
        operationId: 'aliasOp',
        context: context,
        summary: 'Get user with alias',
        description: 'Get user by ID using aliased response',
        tags: {Tag(name: 'users')},
        isDeprecated: false,
        path: '/users/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        securitySchemes: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): aliasedResponse,
        },
      );

      final method = generator.generateParseResponseMethod(operation);

      const expectedMethod = r'''
        BaseResponse _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return BaseResponse(
                body: _$body,
                xUserId: response.headers
                    .value(r'x-user-id')
                    .decodeSimpleString(context: r'x-user-id'),
              );
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: $content for status code: $status',
              );
          }
        }
      ''';

      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('generates for response with header alias', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
      );

      // The actual header object
      final headerObject = ResponseHeaderObject(
        name: 'x-user-id',
        context: context,
        description: 'User ID header',
        model: StringModel(context: context),
        isRequired: true,
        isDeprecated: false,
        explode: false,
        encoding: ResponseHeaderEncoding.simple,
      );

      // The alias header
      final headerAlias = ResponseHeaderAlias(
        name: 'x-user-id-alias',
        context: context,
        header: headerObject,
      );

      final response = ResponseObject(
        name: 'HeaderAliasResponse',
        context: context,
        description: 'Response with header alias',
        headers: {'x-user-id': headerAlias},
        bodies: {
          ResponseBody(
            model: classModel,
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
      );

      final operation = Operation(
        operationId: 'headerAliasOp',
        context: context,
        summary: 'Get user with header alias',
        description: 'Get user by ID using header alias',
        tags: {Tag(name: 'users')},
        isDeprecated: false,
        path: '/users/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        securitySchemes: const {},
        responses: {const ExplicitResponseStatus(statusCode: 200): response},
      );

      final method = generator.generateParseResponseMethod(operation);

      const expectedMethod = r'''
        HeaderAliasResponse _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return HeaderAliasResponse(
                body: _$body,
                xUserId: response.headers
                    .value(r'x-user-id')
                    .decodeSimpleString(context: r'x-user-id'),
              );
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: $content for status code: $status',
              );
          }
        }
      ''';

      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('generates for response with header named body', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
      );

      final response = ResponseObject(
        name: 'BodyHeaderResponse',
        context: context,
        description: 'Response with header named body',
        headers: {
          'body': ResponseHeaderObject(
            name: 'body',
            context: context,
            description: 'Body header',
            model: StringModel(context: context),
            isRequired: true,
            isDeprecated: false,
            explode: false,
            encoding: ResponseHeaderEncoding.simple,
          ),
        },
        bodies: {
          ResponseBody(
            model: classModel,
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
      );

      final operation = Operation(
        operationId: 'bodyHeaderOp',
        context: context,
        summary: 'Get user with body header',
        description: 'Get user by ID with body header',
        tags: {Tag(name: 'users')},
        isDeprecated: false,
        path: '/users/{id}',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        securitySchemes: const {},
        responses: {const ExplicitResponseStatus(statusCode: 200): response},
      );

      final method = generator.generateParseResponseMethod(operation);

      const expectedMethod = r'''
        BodyHeaderResponse _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return BodyHeaderResponse(
                body: _$body,
                bodyHeader: response.headers
                    .value(r'body')
                    .decodeSimpleString(context: r'body'),
              );
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: $content for status code: $status',
              );
          }
        }
      ''';

      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test(
      'selects correct body model based on status code and content type',
      () {
        final response = ResponseObject(
          name: 'UserResponse',
          context: context,
          description: 'A user response',
          headers: const {},
          bodies: {
            ResponseBody(
              model: StringModel(context: context),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
            ResponseBody(
              model: IntegerModel(context: context),
              rawContentType: 'application/xml',
              contentType: ContentType.json,
            ),
          },
        );

        final operation = Operation(
          operationId: 'getUser',
          context: context,
          tags: const {},
          isDeprecated: false,
          path: '/user',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: {const ExplicitResponseStatus(statusCode: 200): response},
          securitySchemes: const {},
        );

        final method = generator.generateParseResponseMethod(operation);

        const expectedMethod = r'''
        UserResponse _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonString();
              return UserResponseJson(body: _$body);
            case (200, 'application/xml'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonInt();
              return UserResponseXml(body: _$body);
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: $content for status code: $status',
              );
          }
        }
      ''';

        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(expectedMethod),
        );
      },
    );

    test('handles multiple status codes with different content types', () {
      final successResponse = ResponseObject(
        name: 'SuccessResponse',
        context: context,
        description: 'Success response',
        headers: const {},
        bodies: {
          ResponseBody(
            model: StringModel(context: context),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
      );

      final errorResponse = ResponseObject(
        name: 'ErrorResponse',
        context: context,
        description: 'Error response',
        headers: const {},
        bodies: {
          ResponseBody(
            model: IntegerModel(context: context),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
      );

      final operation = Operation(
        operationId: 'getUser',
        context: context,
        tags: const {},
        isDeprecated: false,
        path: '/user',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): successResponse,
          const ExplicitResponseStatus(statusCode: 400): errorResponse,
        },
        securitySchemes: const {},
      );

      final method = generator.generateParseResponseMethod(operation);

      const expectedMethod = r'''
        GetUserResponse _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonString();
              return GetUserResponse200(body: _$body);
            case (400, 'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonInt();
              return GetUserResponse400(body: _$body);
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: $content for status code: $status',
              );
          }
        }
      ''';

      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('generates without default case when DefaultResponseStatus with null '
        'content type exists', () {
      final operation = Operation(
        operationId: 'defaultNullContentType',
        context: context,
        summary: '',
        description: '',
        tags: const {},
        isDeprecated: false,
        path: '/default-null-content',
        method: HttpMethod.get,
        headers: const {},
        queryParameters: const {},
        pathParameters: const {},
        responses: {
          const DefaultResponseStatus(): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: '',
            bodies: const {}, // Empty bodies will result in null content type
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = '''
        void _parseResponse(Response<List<int>> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (_, _):
              return;
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    group('Scoped Emitters', () {
      test('generates scoped response with headers', () {
        final operation = Operation(
          context: context,
          operationId: 'getUser',
          summary: 'Get user',
          description: 'Get user by ID',
          tags: {Tag(name: 'users')},
          isDeprecated: false,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          securitySchemes: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              context: context,
              name: 'GetUserResponse',
              description: 'Response for GetUser',
              bodies: const <ResponseBody>{},
              headers: {
                'x-user-id': ResponseHeaderObject(
                  context: context,
                  name: 'x-user-id',
                  description: 'User ID header',
                  model: StringModel(context: context),
                  isRequired: true,
                  isDeprecated: false,
                  explode: false,
                  encoding: ResponseHeaderEncoding.simple,
                ),
              },
            ),
          },
        );

        final method = generator.generateParseResponseMethod(operation);

        final generated = method.accept(scopedEmitter).toString();
        expect(generated, contains('_i2.Response'));
        expect(generated, contains('_i1.GetUserResponse('));
      });
    });

    group('text/plain responses', () {
      test('generates text decoder for text/plain response', () {
        final operation = Operation(
          operationId: 'textOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/text',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'text/plain',
                  contentType: ContentType.text,
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
String _parseResponse(Response<List<int>> response) {
  switch ((response.statusCode, response.headers.value('content-type'))) {
    case (200, 'text/plain'):
      final _$body = decodeResponseText(response.data);
      return _$body;
    default:
      final content = response.headers.value('content-type') ?? 'not specified';
      final status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });
    });

    group('binary responses', () {
      test('generates bytes decoder for application/octet-stream response', () {
        final operation = Operation(
          operationId: 'binaryOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/binary',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: ListModel(
                    content: IntegerModel(context: context),
                    context: context,
                  ),
                  rawContentType: 'application/octet-stream',
                  contentType: ContentType.bytes,
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
List<int> _parseResponse(Response<List<int>> response) {
  switch ((response.statusCode, response.headers.value('content-type'))) {
    case (200, 'application/octet-stream'):
      final _$body = decodeResponseBytes(response.data);
      return _$body;
    default:
      final content = response.headers.value('content-type') ?? 'not specified';
      final status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('generates bytes decoder for image/png response', () {
        final operation = Operation(
          operationId: 'imageOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/image',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: ListModel(
                    content: IntegerModel(context: context),
                    context: context,
                  ),
                  rawContentType: 'image/png',
                  contentType: ContentType.bytes,
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
List<int> _parseResponse(Response<List<int>> response) {
  switch ((response.statusCode, response.headers.value('content-type'))) {
    case (200, 'image/png'):
      final _$body = decodeResponseBytes(response.data);
      return _$body;
    default:
      final content = response.headers.value('content-type') ?? 'not specified';
      final status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });
    });

    group('mixed content types in one response', () {
      test('generates correct decoders for json, text, and binary', () {
        final operation = Operation(
          operationId: 'mixedOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/mixed',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                ),
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'text/plain',
                  contentType: ContentType.text,
                ),
                ResponseBody(
                  model: ListModel(
                    content: IntegerModel(context: context),
                    context: context,
                  ),
                  rawContentType: 'application/octet-stream',
                  contentType: ContentType.bytes,
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
AnonymousResponse _parseResponse(Response<List<int>> response) {
  switch ((response.statusCode, response.headers.value('content-type'))) {
    case (200, 'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return AnonymousResponseJson(body: _$body);
    case (200, 'text/plain'):
      final _$body = decodeResponseText(response.data);
      return AnonymousResponsePlain(body: _$body);
    case (200, 'application/octet-stream'):
      final _$body = decodeResponseBytes(response.data);
      return AnonymousResponseOctetStream(body: _$body);
    default:
      final content = response.headers.value('content-type') ?? 'not specified';
      final status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: $content for status code: $status');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });
    });
  });
}
