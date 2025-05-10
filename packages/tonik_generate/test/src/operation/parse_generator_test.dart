import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/parse_generator.dart';

void main() {
  group('ParseGenerator', () {
    const package = 'package:package_name/package_name.dart';

    late ParseGenerator generator;
    late NameManager nameManager;
    late NameGenerator nameGenerator;
    late Context context;
    late DartEmitter emitter;

    final format =
        DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = ParseGenerator(
        nameManager: nameManager,
        package: package,
      );

      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
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
        requestBody: null,
      );
      final responseType = refer('String');
      final method = generator.generateParseResponseMethod(
        operation,
        responseType,
      );
      const expectedMethod = r'''
String _parseResponse(Response<Object?> response) {
  switch ((response.statusCode, response.headers.value('content-type'))) {
    case (200, 'application/json'):
      return response.data.decodeJsonString();
    default:
      final content = response.headers.value('content-type') ?? 'not specified';
      final status = response.statusCode;
      throw DecodingException('Unexpected content type: $content for status code: $status');
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
        context: context,
        values: const {'A', 'B', 'C'},
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
        requestBody: null,
      );
      final responseType = refer('Anonymous');
      final method = generator.generateParseResponseMethod(
        operation,
        responseType,
      );
      const expectedMethod = r'''
        Anonymous _parseResponse(Response<Object?> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              return Anonymous.fromJson(response.data);
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw DecodingException('Unexpected content type: $content for status code: $status');
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
        requestBody: null,
      );
      final responseType = refer('User');
      final method = generator.generateParseResponseMethod(
        operation,
        responseType,
      );
      const expectedMethod = r'''
        User _parseResponse(Response<Object?> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              return User.fromJson(response.data);
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw DecodingException('Unexpected content type: $content for status code: $status');
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
        requestBody: null,
      );
      final responseType = TypeReference(
        (b) =>
            b
              ..symbol = 'List'
              ..types.add(refer('int')),
      );
      final method = generator.generateParseResponseMethod(
        operation,
        responseType,
      );
      const expectedMethod = r'''
        List<int> _parseResponse(Response<Object?> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              return response.data.decodeJsonList<int>();
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw DecodingException('Unexpected content type: $content for status code: $status');
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
        requestBody: null,
      );
      final responseType = TypeReference(
        (b) =>
            b
              ..symbol = 'List'
              ..types.add(refer('User')),
      );
      final method = generator.generateParseResponseMethod(
        operation,
        responseType,
      );
      const expectedMethod = r'''
        List<User> _parseResponse(Response<Object?> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              return response.data.decodeJsonList<Object?>()
                .map((e) => User.fromJson(e))
                .toList();
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw DecodingException('Unexpected content type: $content for status code: $status');
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
        name: 'Pet',
        models: {
          (
            discriminatorValue: 'cat',
            model: ClassModel(
              name: 'Cat',
              properties: const [],
              context: context,
            ),
          ),
          (
            discriminatorValue: 'dog',
            model: ClassModel(
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
        requestBody: null,
      );
      final responseType = refer('Pet');
      final method = generator.generateParseResponseMethod(
        operation,
        responseType,
      );
      const expectedMethod = r'''
        Pet _parseResponse(Response<Object?> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              return Pet.fromJson(response.data);
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw DecodingException('Unexpected content type: $content for status code: $status');
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
        requestBody: null,
      );
      final responseType = refer('String');
      final method = generator.generateParseResponseMethod(
        operation,
        responseType,
      );
      const expectedMethod = r'''
        String _parseResponse(Response<Object?> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (var status, 'application/json') when status >= 200 && status <= 299:
              return response.data.decodeJsonString();
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw DecodingException('Unexpected content type: $content for status code: $status');
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
        requestBody: null,
      );
      final responseType = refer('String');
      final method = generator.generateParseResponseMethod(
        operation,
        responseType,
      );
      const expectedMethod = r'''
        String _parseResponse(Response<Object?> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (_, 'application/json'):
              return response.data.decodeJsonString();
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw DecodingException('Unexpected content type: $content for status code: $status');
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('generates for multiple response status codes', () {
      const wrapperClass = 'MyResponseWrapper';
      final classModel = ClassModel(
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
        requestBody: null,
      );
      final responseType = refer(wrapperClass);
      final method = generator.generateParseResponseMethod(
        operation,
        responseType,
      );
      const expectedMethod = r'''
        MyResponseWrapper _parseResponse(Response<Object?> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              return MultiStatusOpResponse200(body: User.fromJson(response.data));
            case (400, _):
              return const MultiStatusOpResponse400();
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw DecodingException('Unexpected content type: $content for status code: $status');
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('generates for response with headers', () {
      const wrapperClass = 'MyResponseWrapper';
      final classModel = ClassModel(
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
        requestBody: null,
      );
      final responseType = refer(wrapperClass);
      final method = generator.generateParseResponseMethod(
        operation,
        responseType,
      );
      const expectedMethod = r'''
        MyResponseWrapper _parseResponse(Response<Object?> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              return Anonymous(
                  body: User.fromJson(response.data),
                  xRateLimit: response.headers.value(r'x-rate-limit').decodeSimpleNullableInt(),
                  xExpiresAfter: response.headers.value(r'x-expires-after').decodeSimpleNullableDateTime(),
              );
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw DecodingException('Unexpected content type: $content for status code: $status');
          }
        }
      ''';
      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('combines headers, default, range, and explicit cases', () {
      const wrapperClass = 'CombinedOpResponseWrapper';
      final classModel = ClassModel(
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
        context: context,
        values: const {'A', 'B', 'C'},
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
        requestBody: null,
      );
      final responseType = refer(wrapperClass);
      final method = generator.generateParseResponseMethod(
        operation,
        responseType,
      );
      const expectedMethod = r'''
        CombinedOpResponseWrapper _parseResponse(Response<Object?> response) {
          switch ((response.statusCode, response.headers.value('content-type'))) {
            case (200, 'application/json'):
              return CombinedOpResponse200(
                body: Anonymous(
                  body: User.fromJson(response.data),
                  xRateLimit: response.headers.value(r'x-rate-limit').decodeSimpleNullableInt(),
                ),
              );
            case (var status, 'application/json') when status >= 400 && status <= 499:
              return CombinedOpResponse4XX(
                body: AnonymousModel.fromJson(response.data),
              );
            case (_, _):
              return const CombinedOpResponseDefault();
            default:
              final content = response.headers.value('content-type') ?? 'not specified';
              final status = response.statusCode;
              throw DecodingException(
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
  });
}
