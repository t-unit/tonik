import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';
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
      nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );
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
        cookieParameters: const {},
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
                examples: const [],
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
String _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
        examples: const [],
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
        cookieParameters: const {},
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
                examples: const [],
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        AnonymousModel _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = AnonymousModel.fromJson(_$json);
              return _$body;
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
        cookieParameters: const {},
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
                examples: const [],
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        User _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return _$body;
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
        cookieParameters: const {},
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
                  examples: const [],
                ),
                rawContentType: 'application/json',
                contentType: ContentType.json,
                examples: const [],
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        List<int> _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonList<int>();
              return _$body;
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
        cookieParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): ResponseObject(
            name: null,
            context: context,
            headers: const {},
            description: '',
            bodies: {
              ResponseBody(
                model: ListModel(
                  content: classModel,
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
        securitySchemes: const {},
      );

      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        List<User> _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonList<Object?>()
                .map(User.fromJson)
                .toList();
              return _$body;
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
              examples: const [],
            ),
          ),
          (
            discriminatorValue: 'dog',
            model: ClassModel(
              isDeprecated: false,
              name: 'Dog',
              properties: const [],
              context: context,
              examples: const [],
            ),
          ),
        },
        discriminator: 'type',
        context: context,
        examples: const [],
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
        cookieParameters: const {},
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
                examples: const [],
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        Pet _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = Pet.fromJson(_$json);
              return _$body;
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
        cookieParameters: const {},
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
                examples: const [],
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        String _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (var status, r'application/json') when status != null && status >= 200 && status <= 299:
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonString();
              return _$body;
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
        cookieParameters: const {},
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
                examples: const [],
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        String _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (_, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonString();
              return _$body;
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
        cookieParameters: const {},
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
                examples: const [],
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
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return MultiStatusOpResponse200(body: _$body);
            case (400, _):
              return MultiStatusOpResponse400();
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
          examples: const [],
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
          examples: const [],
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
        cookieParameters: const {},
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
                examples: const [],
              ),
            },
          ),
        },
        securitySchemes: const {},
      );
      final method = generator.generateParseResponseMethod(operation);
      const expectedMethod = r'''
        AnonymousResponse _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
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
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
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
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
        examples: const [],
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
        cookieParameters: const {},
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
                examples: const [],
              ),
            },
            description: '',
            bodies: {
              ResponseBody(
                model: classModel,
                rawContentType: 'application/json',
                contentType: ContentType.json,
                examples: const [],
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
                examples: const [],
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
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
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
            case (var status, r'application/json') when status != null && status >= 400 && status <= 499:
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

    test(
      'emits explicit status arm before range arm declared earlier in spec',
      () {
        final okModel = ClassModel(
          isDeprecated: false,
          name: 'Ok',
          properties: [
            Property(
              name: 'value',
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
        final genericModel = ClassModel(
          isDeprecated: false,
          name: 'Generic',
          properties: [
            Property(
              name: 'message',
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
        final operation = Operation(
          operationId: 'getThing',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/thing',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const RangeResponseStatus(min: 200, max: 299): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: genericModel,
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: okModel,
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
          GetThingResponse _parseResponse(Response<List<int>> response) {
            final _$mediaType = extractMediaType(response.headers.value('content-type'));
            switch ((response.statusCode, _$mediaType)) {
              case (200, r'application/json'):
                final _$json = decodeResponseJson<Object?>(response.data);
                final _$body = Ok.fromJson(_$json);
                return GetThingResponse200(body: _$body);
              case (var status, r'application/json') when status != null && status >= 200 && status <= 299:
                final _$json = decodeResponseJson<Object?>(response.data);
                final _$body = Generic.fromJson(_$json);
                return GetThingResponse2XX(body: _$body);
              default:
                final _$content = response.headers.value('content-type') ?? 'not specified';
                final _$matched = _$mediaType ?? 'none';
                final _$status = response.statusCode;
                throw ResponseDecodingException(
                  'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
                );
            }
          }
        ''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'emits explicit, then range, then default arms when declared in reverse '
      'specificity order',
      () {
        final okModel = ClassModel(
          isDeprecated: false,
          name: 'Ok',
          properties: [
            Property(
              name: 'value',
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
        final genericModel = ClassModel(
          isDeprecated: false,
          name: 'Generic',
          properties: [
            Property(
              name: 'message',
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
        final operation = Operation(
          operationId: 'getThing',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/thing',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const DefaultResponseStatus(): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: const {},
            ),
            const RangeResponseStatus(min: 200, max: 299): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: genericModel,
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: okModel,
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
          GetThingResponse _parseResponse(Response<List<int>> response) {
            final _$mediaType = extractMediaType(response.headers.value('content-type'));
            switch ((response.statusCode, _$mediaType)) {
              case (200, r'application/json'):
                final _$json = decodeResponseJson<Object?>(response.data);
                final _$body = Ok.fromJson(_$json);
                return GetThingResponse200(body: _$body);
              case (var status, r'application/json') when status != null && status >= 200 && status <= 299:
                final _$json = decodeResponseJson<Object?>(response.data);
                final _$body = Generic.fromJson(_$json);
                return GetThingResponse2XX(body: _$body);
              case (_, _):
                return GetThingResponseDefault();
            }
          }
        ''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'orders two same-specificity explicit arms by status code regardless of '
      'declaration order',
      () {
        final okModel = ClassModel(
          isDeprecated: false,
          name: 'Ok',
          properties: [
            Property(
              name: 'value',
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
        final createdModel = ClassModel(
          isDeprecated: false,
          name: 'Created',
          properties: [
            Property(
              name: 'id',
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
        final operation = Operation(
          operationId: 'getThing',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/thing',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 201): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: createdModel,
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: okModel,
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
          GetThingResponse _parseResponse(Response<List<int>> response) {
            final _$mediaType = extractMediaType(response.headers.value('content-type'));
            switch ((response.statusCode, _$mediaType)) {
              case (200, r'application/json'):
                final _$json = decodeResponseJson<Object?>(response.data);
                final _$body = Ok.fromJson(_$json);
                return GetThingResponse200(body: _$body);
              case (201, r'application/json'):
                final _$json = decodeResponseJson<Object?>(response.data);
                final _$body = Created.fromJson(_$json);
                return GetThingResponse201(body: _$body);
              default:
                final _$content = response.headers.value('content-type') ?? 'not specified';
                final _$matched = _$mediaType ?? 'none';
                final _$status = response.statusCode;
                throw ResponseDecodingException(
                  'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
                );
            }
          }
        ''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

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
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
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
            examples: const [],
          ),
        },
        bodies: {
          ResponseBody(
            model: classModel,
            rawContentType: 'application/json',
            contentType: ContentType.json,
            examples: const [],
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
        cookieParameters: const {},
        securitySchemes: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): aliasedResponse,
        },
      );

      final method = generator.generateParseResponseMethod(operation);

      const expectedMethod = r'''
        BaseResponse _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return BaseResponse(
                body: _$body,
                xUserId: response.headers
                    .value(r'x-user-id')
                    .decodeSimpleString(context: r'x-user-id'),
              );
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
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
        examples: const [],
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
        examples: const [],
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
            examples: const [],
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
        cookieParameters: const {},
        securitySchemes: const {},
        responses: {const ExplicitResponseStatus(statusCode: 200): response},
      );

      final method = generator.generateParseResponseMethod(operation);

      const expectedMethod = r'''
        HeaderAliasResponse _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return HeaderAliasResponse(
                body: _$body,
                xUserId: response.headers
                    .value(r'x-user-id')
                    .decodeSimpleString(context: r'x-user-id'),
              );
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
              );
          }
        }
      ''';

      expect(
        collapseWhitespace(format(method.accept(emitter).toString())),
        collapseWhitespace(expectedMethod),
      );
    });

    test('generates for response with header that normalizes to body', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: context,
        examples: const [],
      );

      final response = ResponseObject(
        name: 'BodyHeaderResponse',
        context: context,
        description: 'Response with header that normalizes to body',
        headers: {
          'body_': ResponseHeaderObject(
            name: 'body_',
            context: context,
            description: 'Body header',
            model: StringModel(context: context),
            isRequired: true,
            isDeprecated: false,
            explode: false,
            encoding: ResponseHeaderEncoding.simple,
            examples: const [],
          ),
        },
        bodies: {
          ResponseBody(
            model: classModel,
            rawContentType: 'application/json',
            contentType: ContentType.json,
            examples: const [],
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
        cookieParameters: const {},
        securitySchemes: const {},
        responses: {const ExplicitResponseStatus(statusCode: 200): response},
      );

      final method = generator.generateParseResponseMethod(operation);

      const expectedMethod = r'''
        BodyHeaderResponse _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return BodyHeaderResponse(
                body: _$body,
                bodyHeader: response.headers
                    .value(r'body_')
                    .decodeSimpleString(context: r'body_'),
              );
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
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
      'keeps decoded body when a multi-response header normalizes to body',
      () {
        final classModel = ClassModel(
          isDeprecated: false,
          name: 'User',
          properties: const [],
          context: context,
          examples: const [],
        );
        final response = ResponseObject(
          name: 'BodyHeaderResponse',
          context: context,
          description: 'Response with header that normalizes to body',
          headers: {
            'body_': ResponseHeaderObject(
              name: 'body_',
              context: context,
              description: 'Body header',
              model: StringModel(context: context),
              isRequired: true,
              isDeprecated: false,
              explode: false,
              encoding: ResponseHeaderEncoding.simple,
              examples: const [],
            ),
          },
          bodies: {
            ResponseBody(
              model: classModel,
              rawContentType: 'application/json',
              contentType: ContentType.json,
              examples: const [],
            ),
          },
        );
        final errorResponse = ResponseObject(
          name: 'ErrorResponse',
          context: context,
          description: 'Empty error response',
          headers: const {},
          bodies: const {},
        );
        final operation = Operation(
          operationId: 'multiBodyHeaderOp',
          context: context,
          tags: const {},
          isDeprecated: false,
          path: '/users/{id}',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          securitySchemes: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): response,
            const ExplicitResponseStatus(statusCode: 400): errorResponse,
          },
        );

        final method = generator.generateParseResponseMethod(operation);
        final generated = collapseWhitespace(
          format(method.accept(emitter).toString()),
        );

        expect(
          generated,
          contains(
            collapseWhitespace(r'''
              body: _$body,
              bodyHeader: response.headers
                  .value(r'body_')
                  .decodeSimpleString(context: r'body_'),
            '''),
          ),
        );
        expect(generated, isNot(contains('body2:')));
      },
    );

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
              examples: const [],
            ),
            ResponseBody(
              model: IntegerModel(context: context),
              rawContentType: 'application/xml',
              contentType: ContentType.json,
              examples: const [],
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
          cookieParameters: const {},
          responses: {const ExplicitResponseStatus(statusCode: 200): response},
          securitySchemes: const {},
        );

        final method = generator.generateParseResponseMethod(operation);

        const expectedMethod = r'''
        UserResponse _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonString();
              return UserResponseJson(body: _$body);
            case (200, r'application/xml'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonInt();
              return UserResponseXml(body: _$body);
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
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
            examples: const [],
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
            examples: const [],
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
        cookieParameters: const {},
        responses: {
          const ExplicitResponseStatus(statusCode: 200): successResponse,
          const ExplicitResponseStatus(statusCode: 400): errorResponse,
        },
        securitySchemes: const {},
      );

      final method = generator.generateParseResponseMethod(operation);

      const expectedMethod = r'''
        GetUserResponse _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonString();
              return GetUserResponse200(body: _$body);
            case (400, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonInt();
              return GetUserResponse400(body: _$body);
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
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
        cookieParameters: const {},
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
      const expectedMethod = r'''
        void _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
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
          cookieParameters: const {},
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
                  examples: const [],
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
          cookieParameters: const {},
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
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
String _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'text/plain'):
      final _$body = decodeResponseText(response.data);
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: BinaryModel(context: context),
                  rawContentType: 'application/octet-stream',
                  contentType: ContentType.bytes,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
TonikFile _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/octet-stream'):
      final _$body = TonikFileBytes(decodeResponseBytes(response.data));
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('generates guarded case for type wildcard response media range', () {
        final operation = Operation(
          operationId: 'applicationWildcardOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/application-wildcard',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: BinaryModel(context: context),
                  rawContentType: 'application/*',
                  contentType: ContentType.bytes,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
TonikFile _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
  switch ((response.statusCode, _$mediaType)) {
    case (200, _) when matchesMediaTypeRange(_$mediaType, r'application/*'):
      final _$body = TonikFileBytes(decodeResponseBytes(response.data));
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test(
        'generates guarded case for catch-all media range and status range',
        () {
          final operation = Operation(
            operationId: 'catchAllRangeOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/catch-all-range',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const RangeResponseStatus(min: 200, max: 299): ResponseObject(
                name: null,
                context: context,
                headers: const {},
                description: '',
                bodies: {
                  ResponseBody(
                    model: BinaryModel(context: context),
                    rawContentType: '*/*',
                    contentType: ContentType.bytes,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
TonikFile _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
  switch ((response.statusCode, _$mediaType)) {
    case (var status, _) when status != null && status >= 200 && status <= 299 && matchesMediaTypeRange(_$mediaType, r'*/*'):
      final _$body = TonikFileBytes(decodeResponseBytes(response.data));
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test('orders exact media type before type wildcard before catch-all', () {
        final operation = Operation(
          operationId: 'wildcardPrecedenceOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/wildcard-precedence',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: BinaryModel(context: context),
                  rawContentType: '*/*',
                  contentType: ContentType.bytes,
                  examples: const [],
                ),
                ResponseBody(
                  model: BinaryModel(context: context),
                  rawContentType: 'application/*',
                  contentType: ContentType.bytes,
                  examples: const [],
                ),
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

        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
AnonymousResponse _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
  switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return AnonymousResponseJson(body: _$body);
    case (200, _) when matchesMediaTypeRange(_$mediaType, r'application/*'):
      final _$body = TonikFileBytes(decodeResponseBytes(response.data));
      return AnonymousResponseModel2(body: _$body);
    case (200, _) when matchesMediaTypeRange(_$mediaType, r'*/*'):
      final _$body = TonikFileBytes(decodeResponseBytes(response.data));
      return AnonymousResponseModel(body: _$body);
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: BinaryModel(context: context),
                  rawContentType: 'image/png',
                  contentType: ContentType.bytes,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
TonikFile _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'image/png'):
      final _$body = TonikFileBytes(decodeResponseBytes(response.data));
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
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
          cookieParameters: const {},
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
                  examples: const [],
                ),
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'text/plain',
                  contentType: ContentType.text,
                  examples: const [],
                ),
                ResponseBody(
                  model: BinaryModel(context: context),
                  rawContentType: 'application/octet-stream',
                  contentType: ContentType.bytes,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
AnonymousResponse _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return AnonymousResponseJson(body: _$body);
    case (200, r'text/plain'):
      final _$body = decodeResponseText(response.data);
      return AnonymousResponsePlain(body: _$body);
    case (200, r'application/octet-stream'):
      final _$body = TonikFileBytes(decodeResponseBytes(response.data));
      return AnonymousResponseOctetStream(body: _$body);
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });
    });

    group('form-urlencoded response bodies', () {
      test('generates for primitive form response', () {
        final operation = Operation(
          operationId: 'formPrimitiveOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/form-primitive',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'application/x-www-form-urlencoded',
                  contentType: ContentType.form,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
String _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/x-www-form-urlencoded'):
      final _$formString = decodeResponseText(response.data);
      final _$body = _$formString.decodeFormString();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('generates for class model form response', () {
        final classModel = ClassModel(
          isDeprecated: false,
          name: 'FormData',
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
            Property(
              name: 'age',
              model: IntegerModel(context: context),
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

        final operation = Operation(
          operationId: 'formClassOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/form-class',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: classModel,
                  rawContentType: 'application/x-www-form-urlencoded',
                  contentType: ContentType.form,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
FormData _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/x-www-form-urlencoded'):
      final _$formString = decodeResponseText(response.data);
      final _$body = FormData.fromForm(_$formString, explode: true);
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('generates for integer form response', () {
        final operation = Operation(
          operationId: 'formIntegerOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/form-integer',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: IntegerModel(context: context),
                  rawContentType: 'application/x-www-form-urlencoded',
                  contentType: ContentType.form,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
int _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/x-www-form-urlencoded'):
      final _$formString = decodeResponseText(response.data);
      final _$body = _$formString.decodeFormInt();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('generates for DateTime form response', () {
        final operation = Operation(
          operationId: 'formDateTimeOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/form-datetime',
          method: HttpMethod.post,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: DateTimeModel(context: context),
                  rawContentType: 'application/x-www-form-urlencoded',
                  contentType: ContentType.form,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
DateTime _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/x-www-form-urlencoded'):
      final _$formString = decodeResponseText(response.data);
      final _$body = _$formString.decodeFormDateTime();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });
    });

    group('NeverModel response headers', () {
      test('generates runtime check for NeverModel header', () {
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
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );
        final responseHeaders = {
          'X-Any-Header': ResponseHeaderObject(
            name: 'X-Any-Header',
            context: context,
            description: '',
            isRequired: false,
            isDeprecated: false,
            model: AnyModel(context: context),
            explode: false,
            encoding: ResponseHeaderEncoding.simple,
            examples: const [],
          ),
          'X-Never-Header': ResponseHeaderObject(
            name: 'X-Never-Header',
            context: context,
            description: '',
            isRequired: false,
            isDeprecated: false,
            model: NeverModel(context: context),
            explode: false,
            encoding: ResponseHeaderEncoding.simple,
            examples: const [],
          ),
        };
        final operation = Operation(
          operationId: 'neverHeaderOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/never-header',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
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
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);

        // NeverModel headers should generate a runtime check that throws
        // only if the server sends a value.
        const expectedMethod = r'''
        AnonymousResponse _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              if (response.headers.value(r'X-Never-Header') != null) {
                throw SimpleDecodingException(
                  r'NeverModel does not permit any value at X-Never-Header',
                );
              }
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return AnonymousResponse(
                  body: _$body,
                  xAnyHeader: response.headers.value(r'X-Any-Header'),
              );
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
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
        'generates runtime check for NeverModel header in multi-response',
        () {
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
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          );
          final responseHeaders = {
            'X-Never-Header': ResponseHeaderObject(
              name: 'X-Never-Header',
              context: context,
              description: '',
              isRequired: false,
              isDeprecated: false,
              model: NeverModel(context: context),
              explode: false,
              encoding: ResponseHeaderEncoding.simple,
              examples: const [],
            ),
          };
          final operation = Operation(
            operationId: 'multiNeverOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/multi-never',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
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
                    examples: const [],
                  ),
                },
              ),
              const ExplicitResponseStatus(statusCode: 404): ResponseObject(
                name: null,
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
          final method = generator.generateParseResponseMethod(operation);

          // Multi-response should also generate runtime check for NeverModel.
          const expectedMethod = r'''
        MultiNeverOpResponse _parseResponse(Response<List<int>> response) {
          final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
            case (200, r'application/json'):
              if (response.headers.value(r'X-Never-Header') != null) {
                throw SimpleDecodingException(
                  r'NeverModel does not permit any value at X-Never-Header',
                );
              }
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = User.fromJson(_$json);
              return MultiNeverOpResponse200(body: AnonymousResponse(body: _$body));
            case (404, r'application/json'):
              final _$json = decodeResponseJson<Object?>(response.data);
              final _$body = _$json.decodeJsonString();
              return MultiNeverOpResponse404(body: _$body);
            default:
              final _$content = response.headers.value('content-type') ?? 'not specified';
              final _$matched = _$mediaType ?? 'none';
              final _$status = response.statusCode;
              throw ResponseDecodingException(
                'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
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
    });

    group('NeverModel response bodies', () {
      test(
        'decodes ListModel<NeverModel> JSON body before rejecting items',
        () {
          final operation = Operation(
            operationId: 'listNeverOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/list-never',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: const {},
                description: '',
                bodies: {
                  ResponseBody(
                    model: ListModel(
                      content: NeverModel(context: context),
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
            securitySchemes: const {},
          );
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
List<Never> _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json
          .decodeJsonList<Object?>()
          .map(
            (e) => throw JsonDecodingException(
              'Cannot decode List<NeverModel> - this type does not permit any value.',
            ),
          )
          .toList();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test('generates pure throw for non-nullable NeverModel JSON body', () {
        final operation = Operation(
          operationId: 'pureNeverOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/pure-never',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
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
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
Never _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      throw JsonDecodingException(
        'Cannot decode NeverModel - this type does not permit any value.',
      );
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test(
        'generates pure throw for AliasModel resolving to NeverModel JSON body',
        () {
          final operation = Operation(
            operationId: 'aliasNeverOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/alias-never',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: const {},
                description: '',
                bodies: {
                  ResponseBody(
                    model: AliasModel(
                      name: 'NeverAlias',
                      model: NeverModel(context: context),
                      context: context,
                      examples: const [],
                      defaultValue: null,
                    ),
                    rawContentType: 'application/json',
                    contentType: ContentType.json,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
NeverAlias _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      throw JsonDecodingException(
        'Cannot decode NeverModel - this type does not permit any value.',
      );
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'multi-status response keeps non-Never case unchanged and emits pure '
        'throw for Never case',
        () {
          final operation = Operation(
            operationId: 'multiNeverBodyOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/multi-never-body',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
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
                    examples: const [],
                  ),
                },
              ),
              const ExplicitResponseStatus(statusCode: 404): ResponseObject(
                name: null,
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
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
MultiNeverBodyOpResponse _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      throw JsonDecodingException(
        'Cannot decode NeverModel - this type does not permit any value.',
      );
    case (404, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return MultiNeverBodyOpResponse404(body: _$body);
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException(
        'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
      );
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'emits never-header check before pure throw without wrapper',
        () {
          final responseHeaders = {
            'X-Never-Header': ResponseHeaderObject(
              name: 'X-Never-Header',
              context: context,
              description: '',
              isRequired: false,
              isDeprecated: false,
              model: NeverModel(context: context),
              explode: false,
              encoding: ResponseHeaderEncoding.simple,
              examples: const [],
            ),
          };
          final operation = Operation(
            operationId: 'neverBodyAndHeaderOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/never-body-and-header',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: responseHeaders,
                description: '',
                bodies: {
                  ResponseBody(
                    model: NeverModel(context: context),
                    rawContentType: 'application/json',
                    contentType: ContentType.json,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
AnonymousResponse _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      if (response.headers.value(r'X-Never-Header') != null) {
        throw SimpleDecodingException(
          r'NeverModel does not permit any value at X-Never-Header',
        );
      }
      throw JsonDecodingException(
        'Cannot decode NeverModel - this type does not permit any value.',
      );
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException(
        'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
      );
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'multi-status response emits pure throw with never-header check '
        'without wrapper construction for Never body case',
        () {
          final responseHeaders = {
            'X-Never-Header': ResponseHeaderObject(
              name: 'X-Never-Header',
              context: context,
              description: '',
              isRequired: false,
              isDeprecated: false,
              model: NeverModel(context: context),
              explode: false,
              encoding: ResponseHeaderEncoding.simple,
              examples: const [],
            ),
          };
          final operation = Operation(
            operationId: 'multiNeverBodyHeaderOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/multi-never-body-header',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: responseHeaders,
                description: '',
                bodies: {
                  ResponseBody(
                    model: NeverModel(context: context),
                    rawContentType: 'application/json',
                    contentType: ContentType.json,
                    examples: const [],
                  ),
                },
              ),
              const ExplicitResponseStatus(statusCode: 404): ResponseObject(
                name: null,
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
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
MultiNeverBodyHeaderOpResponse _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      if (response.headers.value(r'X-Never-Header') != null) {
        throw SimpleDecodingException(
          r'NeverModel does not permit any value at X-Never-Header',
        );
      }
      throw JsonDecodingException(
        'Cannot decode NeverModel - this type does not permit any value.',
      );
    case (404, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return MultiNeverBodyHeaderOpResponse404(body: _$body);
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException(
        'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
      );
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates pure throw for AliasModel resolving to NeverModel '
        'form-urlencoded body',
        () {
          final operation = Operation(
            operationId: 'formAliasNeverOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/form-alias-never',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: const {},
                description: '',
                bodies: {
                  ResponseBody(
                    model: AliasModel(
                      name: 'NeverFormAlias',
                      model: NeverModel(context: context),
                      context: context,
                      examples: const [],
                      defaultValue: null,
                    ),
                    rawContentType: 'application/x-www-form-urlencoded',
                    contentType: ContentType.form,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
NeverFormAlias _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/x-www-form-urlencoded'):
      throw FormDecodingException(
        'Cannot decode NeverModel - this type does not permit any value.',
      );
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException(
        'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
      );
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates pure throw for required NeverModel form-urlencoded body',
        () {
          final operation = Operation(
            operationId: 'formNeverBodyOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/form-never-body',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: const {},
                description: '',
                bodies: {
                  ResponseBody(
                    model: NeverModel(context: context),
                    rawContentType: 'application/x-www-form-urlencoded',
                    contentType: ContentType.form,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
Never _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/x-www-form-urlencoded'):
      throw FormDecodingException(
        'Cannot decode NeverModel - this type does not permit any value.',
      );
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException(
        'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
      );
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'decodes required ListModel<NeverModel> '
        'form-urlencoded body',
        () {
          final operation = Operation(
            operationId: 'formListNeverBodyOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/form-list-never-body',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: const {},
                description: '',
                bodies: {
                  ResponseBody(
                    model: ListModel(
                      content: NeverModel(context: context),
                      context: context,
                      examples: const [],
                    ),
                    rawContentType: 'application/x-www-form-urlencoded',
                    contentType: ContentType.form,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
List<Never> _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/x-www-form-urlencoded'):
      final _$formString = decodeResponseText(response.data);
      final _$body = _$formString
          .decodeFormStringList()
          .map(
            (e) => throw FormDecodingException(
              'Cannot decode List<NeverModel> - this type does not permit any value.',
            ),
          )
          .toList();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException(
        'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
      );
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'decodes nullable ListModel<NeverModel> form body before rejecting '
        'items',
        () {
          final operation = Operation(
            operationId: 'formNullableListNeverBodyOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/form-nullable-list-never-body',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: const {},
                description: '',
                bodies: {
                  ResponseBody(
                    model: ListModel(
                      content: NeverModel(context: context),
                      isNullable: true,
                      context: context,
                      examples: const [],
                    ),
                    rawContentType: 'application/x-www-form-urlencoded',
                    contentType: ContentType.form,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
List<Never>? _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/x-www-form-urlencoded'):
      final _$formString = decodeResponseText(response.data);
      final _$body = _$formString
          .decodeFormStringList()
          .map(
            (e) => throw FormDecodingException(
              'Cannot decode List<NeverModel> - this type does not permit any value.',
            ),
          )
          .toList();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException(
        'Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}',
      );
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );
    });

    group('multipart response', () {
      test(
        'generates code that throws ResponseDecodingException '
        'instead of crashing the generator',
        () {
          final operation = Operation(
            operationId: 'multipartOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/multipart',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: const {},
                description: '',
                bodies: {
                  ResponseBody(
                    model: StringModel(context: context),
                    rawContentType: 'multipart/form-data',
                    contentType: ContentType.multipart,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );

          // Should not throw at generation time.
          final method = generator.generateParseResponseMethod(operation);
          final actual = format(method.accept(emitter).toString());

          // Generated code should contain a throw of
          // ResponseDecodingException with the correct message.
          expect(
            collapseWhitespace(actual),
            contains(
              collapseWhitespace(
                'throw ResponseDecodingException(\n'
                "'Multipart response body decoding is not supported.',\n"
                ');',
              ),
            ),
          );
        },
      );

      test(
        'generated multipart response method is well-formed '
        'and matches expected output',
        () {
          final operation = Operation(
            operationId: 'multipartOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/multipart',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: const {},
                description: '',
                bodies: {
                  ResponseBody(
                    model: StringModel(context: context),
                    rawContentType: 'multipart/form-data',
                    contentType: ContentType.multipart,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );

          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
String _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'multipart/form-data'):
      throw ResponseDecodingException(
        'Multipart response body decoding is not supported.',
      );
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates multipart response in multi-response operation',
        () {
          final operation = Operation(
            operationId: 'multipartMultiOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/multipart-multi',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: const {},
                description: '',
                bodies: {
                  ResponseBody(
                    model: StringModel(context: context),
                    rawContentType: 'multipart/form-data',
                    contentType: ContentType.multipart,
                    examples: const [],
                  ),
                },
              ),
              const ExplicitResponseStatus(statusCode: 404): ResponseObject(
                name: null,
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

          // Should not throw at generation time.
          final method = generator.generateParseResponseMethod(operation);
          final actual = format(method.accept(emitter).toString());

          // The multipart case should throw ResponseDecodingException.
          expect(
            collapseWhitespace(actual),
            contains(
              collapseWhitespace(
                'throw ResponseDecodingException(\n'
                "'Multipart response body decoding is not supported.',\n"
                ');',
              ),
            ),
          );
        },
      );
    });

    group('special characters in content type', () {
      test(
        'generates valid code when content type contains single quote',
        () {
          final operation = Operation(
            operationId: 'specialContentTypeOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/test',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
            responses: {
              const ExplicitResponseStatus(statusCode: 200): ResponseObject(
                name: null,
                context: context,
                headers: const {},
                description: '',
                bodies: {
                  ResponseBody(
                    model: StringModel(context: context),
                    rawContentType: "application/vnd.it's+json",
                    contentType: ContentType.json,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );

          final method = generator.generateParseResponseMethod(operation);

          const expectedMethod = r'''
String _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r"application/vnd.it's+json"):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
          expect(
            collapseWhitespace(
              format(method.accept(emitter).toString()),
            ),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );
    });

    group('spec content type normalization', () {
      test('lowercases mixed-case spec key in case pattern', () {
        final operation = Operation(
          operationId: 'mixedCaseContentTypeOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/mixed-case',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'Application/JSON',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
String _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
  switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('strips parameters from spec key in case pattern', () {
        final operation = Operation(
          operationId: 'paramContentTypeOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/param-content',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'application/json; charset=utf-8',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
String _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
  switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('normalizes spec key for range response status', () {
        final operation = Operation(
          operationId: 'rangeNormalizedOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/range-normalized',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const RangeResponseStatus(min: 200, max: 299): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'Application/Problem+JSON',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
String _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
  switch ((response.statusCode, _$mediaType)) {
    case (var status, r'application/problem+json') when status != null && status >= 200 && status <= 299:
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('normalizes spec key for default response status', () {
        final operation = Operation(
          operationId: 'defaultNormalizedOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/default-normalized',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const DefaultResponseStatus(): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'application/vnd.foo+json; version=1',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
String _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
  switch ((response.statusCode, _$mediaType)) {
    case (_, r'application/vnd.foo+json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('emits no warnings when normalizing a non-colliding spec key', () {
        final previousRootLevel = Logger.root.level;
        Logger.root.level = Level.ALL;
        addTearDown(() => Logger.root.level = previousRootLevel);

        final logs = <LogRecord>[];
        final sub = Logger('ParseGenerator').onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final operation = Operation(
          operationId: 'silentNormalizationOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/silent-normalization',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: StringModel(context: context),
                  rawContentType: 'application/json; charset=utf-8',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        generator.generateParseResponseMethod(operation);

        final warnings = logs
            .where((r) => r.level == Level.WARNING)
            .map((r) => r.message)
            .toList();
        expect(warnings, isEmpty);
      });

      test(
        'dedupes spec keys that normalize to the same media type, keeps first '
        'raw entry, and names distinct dropped model types in the warning',
        () {
          final previousRootLevel = Logger.root.level;
          Logger.root.level = Level.ALL;
          addTearDown(() => Logger.root.level = previousRootLevel);

          final logs = <LogRecord>[];
          final sub = Logger('ParseGenerator').onRecord.listen(logs.add);
          addTearDown(sub.cancel);

          final operation = Operation(
            operationId: 'dedupeContentTypeOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/dedupe-content',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
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
                    examples: const [],
                  ),
                  ResponseBody(
                    model: IntegerModel(context: context),
                    rawContentType: 'application/json; charset=utf-8',
                    contentType: ContentType.json,
                    examples: const [],
                  ),
                  ResponseBody(
                    model: IntegerModel(context: context),
                    rawContentType: 'Application/JSON',
                    contentType: ContentType.json,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
AnonymousResponse _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
  switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return AnonymousResponseJson(body: _$body);
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );

          final warnings = logs
              .where((r) => r.level == Level.WARNING)
              .map((r) => r.message)
              .toList();
          expect(warnings, hasLength(1));
          expect(warnings.single, contains('application/json; charset=utf-8'));
          expect(warnings.single, contains('Application/JSON'));
          expect(warnings.single, contains('kept model: StringModel'));
          expect(warnings.single, contains('dropped models:'));
          expect(warnings.single, contains('IntegerModel'));
        },
      );

      test(
        'dedupes two independent collision groups and emits one warning per '
        'group',
        () {
          final previousRootLevel = Logger.root.level;
          Logger.root.level = Level.ALL;
          addTearDown(() => Logger.root.level = previousRootLevel);

          final logs = <LogRecord>[];
          final sub = Logger('ParseGenerator').onRecord.listen(logs.add);
          addTearDown(sub.cancel);

          final operation = Operation(
            operationId: 'multiGroupDedupeOp',
            context: context,
            summary: '',
            description: '',
            tags: const {},
            isDeprecated: false,
            path: '/multi-group-dedupe',
            method: HttpMethod.get,
            headers: const {},
            queryParameters: const {},
            pathParameters: const {},
            cookieParameters: const {},
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
                    examples: const [],
                  ),
                  ResponseBody(
                    model: StringModel(context: context),
                    rawContentType: 'application/json; charset=utf-8',
                    contentType: ContentType.json,
                    examples: const [],
                  ),
                  ResponseBody(
                    model: StringModel(context: context),
                    rawContentType: 'application/xml',
                    contentType: ContentType.json,
                    examples: const [],
                  ),
                  ResponseBody(
                    model: StringModel(context: context),
                    rawContentType: 'application/xml; charset=utf-8',
                    contentType: ContentType.json,
                    examples: const [],
                  ),
                },
              ),
            },
            securitySchemes: const {},
          );
          final method = generator.generateParseResponseMethod(operation);
          const expectedMethod = r'''
AnonymousResponse _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
  switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return AnonymousResponseJson(body: _$body);
    case (200, r'application/xml'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = _$json.decodeJsonString();
      return AnonymousResponseXml(body: _$body);
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
          expect(
            collapseWhitespace(format(method.accept(emitter).toString())),
            collapseWhitespace(format(expectedMethod)),
          );

          final warnings = logs
              .where((r) => r.level == Level.WARNING)
              .map((r) => r.message)
              .toList();
          expect(warnings, hasLength(2));
          final jsonWarning = warnings.firstWhere(
            (w) => w.contains('"application/json"'),
          );
          expect(
            jsonWarning,
            contains('application/json; charset=utf-8'),
          );
          expect(jsonWarning, isNot(contains('kept model:')));
          expect(jsonWarning, isNot(contains('dropped models:')));
          final xmlWarning = warnings.firstWhere(
            (w) => w.contains('"application/xml"'),
          );
          expect(
            xmlWarning,
            contains('application/xml; charset=utf-8'),
          );
          expect(xmlWarning, isNot(contains('kept model:')));
          expect(xmlWarning, isNot(contains('dropped models:')));
        },
      );
    });

    test(
      'generates runtime throw for multipart response body',
      () {
        final operation = Operation(
          operationId: 'multipartResponseOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/multipart-response',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: ClassModel(
                    name: 'TestModel',
                    properties: const [],
                    context: context,
                    isDeprecated: false,
                    examples: const [],
                  ),
                  rawContentType: 'multipart/form-data',
                  contentType: ContentType.multipart,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        final generated = format(method.accept(emitter).toString());

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace(
              '''throw ResponseDecodingException( 'Multipart response body decoding is not supported.', );''',
            ),
          ),
        );
      },
    );

    group('immutable collections', () {
      late ParseGenerator immutableGenerator;

      setUp(() {
        immutableGenerator = ParseGenerator(
          nameManager: nameManager,
          package: package,
          useImmutableCollections: true,
        );
      });

      test('generates IList return type for direct list response body', () {
        final operation = Operation(
          operationId: 'listStringsOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/strings',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: ListModel(
                    content: StringModel(context: context),
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
          securitySchemes: const {},
        );
        final method = immutableGenerator.generateParseResponseMethod(
          operation,
        );
        const expectedMethod = r'''
IList<String> _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = IList(_$json.decodeJsonList<String>());
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('generates IMap return type for direct map response body', () {
        final operation = Operation(
          operationId: 'getCountsOp',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/counts',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: MapModel(
                    valueModel: IntegerModel(context: context),
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
          securitySchemes: const {},
        );
        final method = immutableGenerator.generateParseResponseMethod(
          operation,
        );
        const expectedMethod = r'''
IMap<String, int> _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      final _$body = IMap(_$json.decodeJsonMap((v) => v.decodeJsonInt()));
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      });
    });

    test(
      r'splices _$decodeTree helper into _parseResponse for self-referential '
      'MapModel response body',
      () {
        final tree = MapModel(
          name: 'Tree',
          valueModel: AnyModel(context: context),
          context: context,
          examples: const [],
        );
        tree.valueModel = tree;

        final operation = Operation(
          operationId: 'getTree',
          context: context,
          summary: '',
          description: '',
          tags: const {},
          isDeprecated: false,
          path: '/tree',
          method: HttpMethod.get,
          headers: const {},
          queryParameters: const {},
          pathParameters: const {},
          cookieParameters: const {},
          responses: {
            const ExplicitResponseStatus(statusCode: 200): ResponseObject(
              name: null,
              context: context,
              headers: const {},
              description: '',
              bodies: {
                ResponseBody(
                  model: tree,
                  rawContentType: 'application/json',
                  contentType: ContentType.json,
                  examples: const [],
                ),
              },
            ),
          },
          securitySchemes: const {},
        );
        final method = generator.generateParseResponseMethod(operation);
        const expectedMethod = r'''
Tree _parseResponse(Response<List<int>> response) {
  final _$mediaType = extractMediaType(response.headers.value('content-type'));
          switch ((response.statusCode, _$mediaType)) {
    case (200, r'application/json'):
      final _$json = decodeResponseJson<Object?>(response.data);
      late final Tree Function(Object?) _$decodeTree;
      _$decodeTree = (Object? v) => v.decodeJsonMap((v) => _$decodeTree(v), context: r'Tree');
      final _$body = _$decodeTree(_$json);
      return _$body;
    default:
      final _$content = response.headers.value('content-type') ?? 'not specified';
      final _$matched = _$mediaType ?? 'none';
      final _$status = response.statusCode;
      throw ResponseDecodingException('Unexpected content type: ${_$content} (matched as: ${_$matched}) for status code: ${_$status}');
  }
}
''';
        expect(
          collapseWhitespace(format(method.accept(emitter).toString())),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );
  });
}
