import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/data_generator.dart';

void main() {
  late DataGenerator generator;
  late NameManager nameManager;
  late Context testContext;
  late DartEmitter emitter;
  late String Function(String, {Object? uri}) format;

  setUp(() {
    nameManager = NameManager(
      generator: NameGenerator(),
      stableModelSorter: StableModelSorter(),
    );
    generator = DataGenerator(
      nameManager: nameManager,
      package: 'test_package',
    );
    testContext = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
    format = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format;
  });

  group('generateDataMethod', () {
    test('returns null when no request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        securitySchemes: const {},
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
      );

      const expectedMethod = '''
        Object? _data() {
          return null;
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles single content type request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: false,
          content: {
            RequestContent(
              model: ClassModel(
                isDeprecated: false,
                name: 'TestModel',
                properties: const [],
                context: testContext,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        ),
        responses: const <ResponseStatus, Response>{},
        pathParameters: const <PathParameter>{},
        queryParameters: const <QueryParameter>{},
        headers: const <RequestHeader>{},
        cookieParameters: const <CookieParameter>{},
        context: testContext,
        tags: const <Tag>{},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({TestModel? body}) {
          return body?.toJson();
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles multiple content types in request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: false,
          content: {
            RequestContent(
              model: ClassModel(
                isDeprecated: false,
                name: 'JsonModel',
                properties: const [],
                context: testContext,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
            RequestContent(
              model: ClassModel(
                isDeprecated: false,
                name: 'FormModel',
                properties: const [],
                context: testContext,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json+problem',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({Test? body}) {
          if (body == null) return null;
          return switch (body) {
            final TestJson value => value.value.toJson(),
            final TestJsonProblem value => value.value.toJson(),
          };
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('JSON encodes string scalar in multi-content request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({required Test body}) {
          return switch (body) {
            final TestJson value => jsonEncode(value.value),
            final TestPlain value => value.value,
          };
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test(
      'handles single-content JSON with a recursive named MapModel body',
      () {
        final tree = MapModel(
          name: 'Tree',
          valueModel: AnyModel(context: testContext),
          context: testContext,
          examples: const [],
        );
        tree.valueModel = tree;

        final operation = Operation(
          operationId: 'postTree',
          path: '/tree',
          method: HttpMethod.post,
          requestBody: RequestBodyObject(
            name: 'treeBody',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: tree,
                contentType: ContentType.json,
                rawContentType: 'application/json',
                examples: const [],
              ),
            },
          ),
          responses: const {},
          pathParameters: const {},
          cookieParameters: const {},
          queryParameters: const {},
          headers: const {},
          context: testContext,
          tags: const {},
          isDeprecated: false,
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          Object? _data({required Tree body}) {
            late final Object? Function(Object?) _$encodeTree;
            _$encodeTree = (Object? raw) {
              if (raw is! Tree) {
                throw EncodingException(
                  'Cannot encode value as Tree (at \'postTree.body\'); got: '
                  '${raw.runtimeType}',
                );
              }
              final v = raw;
              return v.map((k, v) => MapEntry(k, _$encodeTree(v)));
            };
            return _$encodeTree(body);
          }
        ''';

        final method = generator.generateDataMethod(operation);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'handles multi-content JSON with a recursive named MapModel variant',
      () {
        final tree = MapModel(
          name: 'Tree',
          valueModel: AnyModel(context: testContext),
          context: testContext,
          examples: const [],
        );
        tree.valueModel = tree;

        final operation = Operation(
          operationId: 'testOp',
          path: '/test',
          method: HttpMethod.post,
          requestBody: RequestBodyObject(
            name: 'recursiveBody',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: tree,
                contentType: ContentType.json,
                rawContentType: 'application/json',
                examples: const [],
              ),
              RequestContent(
                model: ClassModel(
                  isDeprecated: false,
                  name: 'Plain',
                  properties: const [],
                  context: testContext,
                  examples: const [],
                ),
                contentType: ContentType.json,
                rawContentType: 'application/json+problem',
                examples: const [],
              ),
            },
          ),
          responses: const {},
          pathParameters: const {},
          cookieParameters: const {},
          queryParameters: const {},
          headers: const {},
          context: testContext,
          tags: const {},
          isDeprecated: false,
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          Object? _data({required RecursiveBody body}) {
            late final Object? Function(Object?) _$encodeTree;
            _$encodeTree = (Object? raw) {
              if (raw is! Tree) {
                throw EncodingException(
                  'Cannot encode value as Tree (at \'testOp.body\'); got: '
                  '${raw.runtimeType}',
                );
              }
              final v = raw;
              return v.map((k, v) => MapEntry(k, _$encodeTree(v)));
            };
            return switch (body) {
              final RecursiveBodyJson value => _$encodeTree(value.value),
              final RecursiveBodyJsonProblem value => value.value.toJson(),
            };
          }
        ''';

        final method = generator.generateDataMethod(operation);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test('JSON encodes primitive string model in request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({required String body}) {
          return jsonEncode(body);
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('JSON encodes optional primitive string request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: false,
          content: {
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({String? body}) {
          if (body == null) return null;
          return jsonEncode(body);
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('JSON encodes string alias model in request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: AliasModel(
                name: 'UserId',
                model: StringModel(context: testContext),
                context: testContext,
                examples: const [],
                defaultValue: null,
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({required UserId body}) {
          return jsonEncode(body);
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('JSON encodes string enum model in request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: EnumModel<String>(
                name: 'Status',
                values: {
                  const EnumEntry(value: 'active'),
                  const EnumEntry(value: 'inactive'),
                },
                isNullable: false,
                isDeprecated: false,
                context: testContext,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({required Status body}) {
          return jsonEncode(body.toJson());
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles date model in request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: false,
          content: {
            RequestContent(
              model: DateModel(context: testContext),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({Date? body}) {
          if (body == null) return null;
          return jsonEncode(body.toJson());
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles decimal model in request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: false,
          content: {
            RequestContent(
              model: DecimalModel(context: testContext),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({BigDecimal? body}) {
          if (body == null) return null;
          return jsonEncode(body.toString());
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles mixed primitive and enum content types in request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: IntegerModel(context: testContext),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
            RequestContent(
              model: EnumModel(
                isDeprecated: false,
                name: 'TestEnum',
                values: {
                  const EnumEntry(value: 'value1'),
                  const EnumEntry(value: 'value2'),
                },
                context: testContext,
                isNullable: false,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json+problem',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({required Test body}) {
          return switch (body) {
            final TestJson value => value.value,
            final TestJsonProblem value => jsonEncode(value.value.toJson()),
          };
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles nullable parameter type for optional request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: false,
          content: {
            RequestContent(
              model: ClassModel(
                isDeprecated: false,
                name: 'TestModel',
                properties: const [],
                context: testContext,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({TestModel? body}) {
          return body?.toJson();
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles text/plain request body without JSON encoding', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({required String body}) {
          return body;
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test(
      'handles application/octet-stream request body without JSON encoding',
      () {
        final operation = Operation(
          operationId: 'testOp',
          path: '/test',
          method: HttpMethod.post,
          requestBody: RequestBodyObject(
            name: 'test',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: StringModel(context: testContext),
                contentType: ContentType.bytes,
                rawContentType: 'application/octet-stream',
                examples: const [],
              ),
            },
          ),
          responses: const {},
          pathParameters: const {},
          cookieParameters: const {},
          queryParameters: const {},
          headers: const {},
          context: testContext,
          tags: const {},
          isDeprecated: false,
          securitySchemes: const {},
        );

        // Note: For binary, the model is StringModel but at runtime
        // the user passes List<int> which is passed through directly
        const expectedMethod = '''
        Object? _data({required String body}) {
          return body;
        }
      ''';

        final method = generator.generateDataMethod(operation);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'handles application/octet-stream request body with BinaryModel',
      () {
        final operation = Operation(
          operationId: 'testOp',
          path: '/test',
          method: HttpMethod.post,
          requestBody: RequestBodyObject(
            name: 'test',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: BinaryModel(context: testContext),
                contentType: ContentType.bytes,
                rawContentType: 'application/octet-stream',
                examples: const [],
              ),
            },
          ),
          responses: const {},
          pathParameters: const {},
          cookieParameters: const {},
          queryParameters: const {},
          headers: const {},
          context: testContext,
          tags: const {},
          isDeprecated: false,
          securitySchemes: const {},
        );

        const expectedMethod = '''
        Object? _data({required TonikFile body}) {
          return body.toBytes();
        }
      ''';

        final method = generator.generateDataMethod(operation);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'handles optional application/octet-stream request body with BinaryModel',
      () {
        final operation = Operation(
          operationId: 'testOp',
          path: '/test',
          method: HttpMethod.post,
          requestBody: RequestBodyObject(
            name: 'test',
            context: testContext,
            description: null,
            isRequired: false,
            content: {
              RequestContent(
                model: BinaryModel(context: testContext),
                contentType: ContentType.bytes,
                rawContentType: 'application/octet-stream',
                examples: const [],
              ),
            },
          ),
          responses: const {},
          pathParameters: const {},
          cookieParameters: const {},
          queryParameters: const {},
          headers: const {},
          context: testContext,
          tags: const {},
          isDeprecated: false,
          securitySchemes: const {},
        );

        const expectedMethod = '''
        Object? _data({TonikFile? body}) {
          return body?.toBytes();
        }
      ''';

        final method = generator.generateDataMethod(operation);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test('handles multiple content types with text variant', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: ClassModel(
                isDeprecated: false,
                name: 'JsonModel',
                properties: const [],
                context: testContext,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({required Test body}) {
          return switch (body) {
            final TestJson value => value.value.toJson(),
            final TestPlain value => value.value,
          };
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles multiple content types with bytes variant', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: ClassModel(
                isDeprecated: false,
                name: 'JsonModel',
                properties: const [],
                context: testContext,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.bytes,
              rawContentType: 'application/octet-stream',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({required Test body}) {
          return switch (body) {
            final TestJson value => value.value.toJson(),
            final TestOctetStream value => value.value,
          };
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles multiple content types with BinaryModel bytes variant', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: ClassModel(
                isDeprecated: false,
                name: 'JsonModel',
                properties: const [],
                context: testContext,
                examples: const [],
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
              examples: const [],
            ),
            RequestContent(
              model: BinaryModel(context: testContext),
              contentType: ContentType.bytes,
              rawContentType: 'application/octet-stream',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({required Test body}) {
          return switch (body) {
            final TestJson value => value.value.toJson(),
            final TestOctetStream value => value.value.toBytes(),
          };
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('handles optional text/plain request body', () {
      final operation = Operation(
        operationId: 'testOp',
        path: '/test',
        method: HttpMethod.post,
        requestBody: RequestBodyObject(
          name: 'test',
          context: testContext,
          description: null,
          isRequired: false,
          content: {
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.text,
              rawContentType: 'text/plain',
              examples: const [],
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        cookieParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        tags: const {},
        isDeprecated: false,
        securitySchemes: const {},
      );

      const expectedMethod = '''
        Object? _data({String? body}) {
          return body;
        }
      ''';

      final method = generator.generateDataMethod(operation);
      final methodString = format(method.accept(emitter).toString());
      expect(
        collapseWhitespace(methodString),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    group('form-urlencoded request bodies', () {
      test('generates _data method for ClassModel request body', () {
        final petModel = ClassModel(
          name: 'Pet',
          isDeprecated: false,
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'age',
              model: IntegerModel(context: testContext),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final operation = Operation(
          operationId: 'createPet',
          path: '/pets',
          method: HttpMethod.post,
          requestBody: RequestBodyObject(
            name: 'pet',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: petModel,
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                examples: const [],
              ),
            },
          ),
          responses: const {},
          pathParameters: const {},
          cookieParameters: const {},
          queryParameters: const {},
          headers: const {},
          context: testContext,
          tags: const {},
          isDeprecated: false,
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          Object? _data({required Pet body}) {
            return body
                .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
                .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                .join('&');
          }
        ''';

        final method = generator.generateDataMethod(operation);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test('generates _data method for optional form request body', () {
        final petModel = ClassModel(
          name: 'Pet',
          isDeprecated: false,
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final operation = Operation(
          operationId: 'updatePet',
          path: '/pets',
          method: HttpMethod.post,
          requestBody: RequestBodyObject(
            name: 'pet',
            context: testContext,
            description: null,
            isRequired: false,
            content: {
              RequestContent(
                model: petModel,
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                examples: const [],
              ),
            },
          ),
          responses: const {},
          pathParameters: const {},
          cookieParameters: const {},
          queryParameters: const {},
          headers: const {},
          context: testContext,
          tags: const {},
          isDeprecated: false,
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          Object? _data({Pet? body}) {
            if (body == null) return null;
            return body
                .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
                .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                .join('&');
          }
        ''';

        final method = generator.generateDataMethod(operation);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test(
        'applies per-property allowReserved to a flagged property while '
        'leaving siblings fully percent-encoded',
        () {
          final formModel = ClassModel(
            name: 'ReservedForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'reserved',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'notReserved',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'optional',
                model: StringModel(context: testContext),
                isRequired: false,
                isNullable: true,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = Operation(
            operationId: 'postReserved',
            path: '/reserved',
            method: HttpMethod.post,
            requestBody: RequestBodyObject(
              name: 'reserved',
              context: testContext,
              description: null,
              isRequired: true,
              content: {
                RequestContent(
                  model: formModel,
                  contentType: ContentType.form,
                  rawContentType: 'application/x-www-form-urlencoded',
                  examples: const [],
                  formEncoding: _formEncodingByName(formModel, {
                    'reserved': _reserved(true),
                    'notReserved': _reserved(false),
                  }),
                ),
              },
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          const expectedMethod = r'''
            Object? _data({required ReservedForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'reserved': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'threads fieldEncodings through the object path for an optional form '
        'body',
        () {
          final formModel = ClassModel(
            name: 'OptionalReservedForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'reserved',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = Operation(
            operationId: 'postOptionalReserved',
            path: '/optional-reserved',
            method: HttpMethod.post,
            requestBody: RequestBodyObject(
              name: 'optionalReserved',
              context: testContext,
              description: null,
              isRequired: false,
              content: {
                RequestContent(
                  model: formModel,
                  contentType: ContentType.form,
                  rawContentType: 'application/x-www-form-urlencoded',
                  examples: const [],
                  formEncoding: _formEncodingByName(formModel, {
                    'reserved': _reserved(true),
                  }),
                ),
              },
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          const expectedMethod = r'''
            Object? _data({OptionalReservedForm? body}) {
              if (body == null) return null;
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'reserved': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'keeps object-level toForm when no property opts into allowReserved',
        () {
          final formModel = ClassModel(
            name: 'PlainForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = Operation(
            operationId: 'postPlain',
            path: '/plain',
            method: HttpMethod.post,
            requestBody: RequestBodyObject(
              name: 'plain',
              context: testContext,
              description: null,
              isRequired: true,
              content: {
                RequestContent(
                  model: formModel,
                  contentType: ContentType.form,
                  rawContentType: 'application/x-www-form-urlencoded',
                  examples: const [],
                  formEncoding: _formEncodingByName(formModel, {
                    'name': _reserved(false),
                  }),
                ),
              },
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          const expectedMethod = r'''
            Object? _data({required PlainForm body}) {
              return body
                  .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'routes a write-only sibling through the object path beside a flagged '
        'property',
        () {
          final formModel = ClassModel(
            name: 'SecretForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'reserved',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'secret',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isWriteOnly: true,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postSecret',
            model: formModel,
            encoding: {
              'reserved': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required SecretForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'reserved': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'routes a free-form sibling through the object path beside a flagged '
        'scalar',
        () {
          final formModel = ClassModel(
            name: 'MetaForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'reserved',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'metadata',
                model: AnyModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postMeta',
            model: formModel,
            encoding: {
              'reserved': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required MetaForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'reserved': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'routes a complex-list sibling through the object path, deferring its '
        'rejection to the class parameterProperties',
        () {
          final formModel = ClassModel(
            name: 'BadForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'reserved',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'items',
                model: ListModel(
                  content: ClassModel(
                    name: 'Item',
                    isDeprecated: false,
                    properties: const [],
                    context: testContext,
                    examples: const [],
                  ),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postBad',
            model: formModel,
            encoding: {
              'reserved': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required BadForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'reserved': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'threads allowReserved through enum and composition properties '
        'alongside the flagged scalar',
        () {
          final formModel = ClassModel(
            name: 'ComboForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'reserved',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'status',
                model: EnumModel<String>(
                  name: 'Status',
                  values: {
                    const EnumEntry(value: 'active'),
                    const EnumEntry(value: 'inactive'),
                  },
                  isNullable: false,
                  isDeprecated: false,
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'choice',
                model: OneOfModel(
                  name: 'Choice',
                  models: {
                    (
                      discriminatorValue: null,
                      model: StringModel(context: testContext),
                    ),
                    (
                      discriminatorValue: null,
                      model: IntegerModel(context: testContext),
                    ),
                  },
                  isDeprecated: false,
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postCombo',
            model: formModel,
            encoding: {
              'reserved': _reserved(true),
              'status': _reserved(true),
              'choice': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required ComboForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'reserved': const FormFieldEncoding(allowReserved: true),
                      r'status': const FormFieldEncoding(allowReserved: true),
                      r'choice': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'threads a sole flagged enum through the object-path fieldEncodings',
        () {
          final formModel = ClassModel(
            name: 'EnumOnlyForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'status',
                model: EnumModel<String>(
                  name: 'Status',
                  values: {
                    const EnumEntry(value: 'active'),
                    const EnumEntry(value: 'inactive'),
                  },
                  isNullable: false,
                  isDeprecated: false,
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postEnumOnly',
            model: formModel,
            encoding: {
              'status': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required EnumOnlyForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'status': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'threads a sole flagged composition through the object-path '
        'fieldEncodings',
        () {
          final formModel = ClassModel(
            name: 'CompositionOnlyForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'choice',
                model: OneOfModel(
                  name: 'Choice',
                  models: {
                    (
                      discriminatorValue: null,
                      model: StringModel(context: testContext),
                    ),
                    (
                      discriminatorValue: null,
                      model: IntegerModel(context: testContext),
                    ),
                  },
                  isDeprecated: false,
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postCompositionOnly',
            model: formModel,
            encoding: {
              'choice': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required CompositionOnlyForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'choice': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'routes a special-character property name through the object path',
        () {
          final formModel = ClassModel(
            name: 'SpacedForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'reserved',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'a b',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postSpaced',
            model: formModel,
            encoding: {
              'reserved': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required SpacedForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'reserved': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'routes a list-property sibling through the object path beside a '
        'flagged scalar',
        () {
          final formModel = ClassModel(
            name: 'ListForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'reserved',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'tags',
                model: ListModel(
                  content: StringModel(context: testContext),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postList',
            model: formModel,
            encoding: {
              'reserved': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required ListForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'reserved': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'routes a map-property sibling through the object path, deferring its '
        'rejection to the class parameterProperties',
        () {
          final formModel = ClassModel(
            name: 'MapForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'reserved',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'meta',
                model: MapModel(
                  valueModel: StringModel(context: testContext),
                  context: testContext,
                  examples: const [],
                ),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postMap',
            model: formModel,
            encoding: {
              'reserved': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required MapForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'reserved': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'threads a sole flagged free-form property through fieldEncodings even '
        'though the object path ignores its allowReserved',
        () {
          final formModel = ClassModel(
            name: 'AnyOnlyForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'metadata',
                model: AnyModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postAnyOnly',
            model: formModel,
            encoding: {
              'metadata': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required AnyOnlyForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'metadata': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'stays on the object path when only a read-only property carries '
        'allowReserved',
        () {
          final formModel = ClassModel(
            name: 'ReadOnlyForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'visible',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'hidden',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isReadOnly: true,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postReadOnly',
            model: formModel,
            encoding: {
              'hidden': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required ReadOnlyForm body}) {
              return body
                  .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'keys fieldEncodings by raw spec name for a write property colliding '
        'with a read-only sibling',
        () {
          final formModel = ClassModel(
            name: 'CollisionForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'user-name',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isReadOnly: true,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'user_name',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = _formOperation(
            operationId: 'postCollision',
            model: formModel,
            encoding: {
              'user_name': _reserved(true),
            },
            context: testContext,
          );

          const expectedMethod = r'''
            Object? _data({required CollisionForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'user_name': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'threads fieldEncodings through the object path for an allOf form body',
        () {
          final memberProperty = Property(
            name: 'reserved',
            model: StringModel(context: testContext),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          );
          final formModel = AllOfModel(
            name: 'CompositeForm',
            isDeprecated: false,
            models: {
              ClassModel(
                name: 'Member',
                isDeprecated: false,
                properties: [memberProperty],
                context: testContext,
                examples: const [],
              ),
            },
            context: testContext,
            examples: const [],
          );

          final operation = Operation(
            operationId: 'postComposite',
            path: '/composite',
            method: HttpMethod.post,
            requestBody: RequestBodyObject(
              name: 'composite',
              context: testContext,
              description: null,
              isRequired: true,
              content: {
                RequestContent(
                  model: formModel,
                  contentType: ContentType.form,
                  rawContentType: 'application/x-www-form-urlencoded',
                  examples: const [],
                  formEncoding: {
                    memberProperty: _reserved(true),
                  },
                ),
              },
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          const expectedMethod = r'''
            Object? _data({required CompositeForm body}) {
              return body
                  .toForm(
                    '',
                    explode: true,
                    allowEmpty: true,
                    useQueryComponent: true,
                    fieldEncodings: <String, FormFieldEncoding>{
                      r'reserved': const FormFieldEncoding(allowReserved: true),
                    },
                  )
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&');
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );
    });

    group('multipart request bodies', () {
      test('generates _data method for single-content multipart with string '
          'properties', () {
        final userModel = ClassModel(
          name: 'CreateUserForm',
          isDeprecated: false,
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
            Property(
              name: 'nickname',
              model: StringModel(context: testContext),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final operation = Operation(
          operationId: 'createUser',
          path: '/users',
          method: HttpMethod.post,
          requestBody: RequestBodyObject(
            name: 'createUser',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: userModel,
                contentType: ContentType.multipart,
                rawContentType: 'multipart/form-data',
                multipartEncoding: _multipartEncodingByName(userModel, {
                  'name': const PartEncoding(
                    contentType: ContentType.text,
                    rawContentType: 'text/plain',
                    headers: null,
                    style: EncodingStyle.form,
                    explode: true,
                    allowReserved: false,
                  ),
                  'nickname': const PartEncoding(
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
          ),
          responses: const {},
          pathParameters: const {},
          cookieParameters: const {},
          queryParameters: const {},
          headers: const {},
          context: testContext,
          tags: const {},
          isDeprecated: false,
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          Future<Object?> _data({required CreateUserForm body}) async {
            final _$formData = FormData();
            _$formData.files.add(MapEntry(r'name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse(r'text/plain'))));
            if (body.nickname != null) {
              _$formData.files.add(MapEntry(r'nickname', MultipartFile.fromString(body.nickname!, contentType: DioMediaType.parse(r'text/plain'))));
            }
            return _$formData;
          }
        ''';

        final method = generator.generateDataMethod(operation);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test(
        'generates _data method with multipart header params in signature',
        () {
          final uploadModel = ClassModel(
            name: 'UploadForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'file',
                model: BinaryModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = Operation(
            operationId: 'uploadFile',
            path: '/uploads',
            method: HttpMethod.post,
            requestBody: RequestBodyObject(
              name: 'uploadFile',
              context: testContext,
              description: null,
              isRequired: true,
              content: {
                RequestContent(
                  model: uploadModel,
                  contentType: ContentType.multipart,
                  rawContentType: 'multipart/form-data',
                  multipartEncoding: _multipartEncodingByName(uploadModel, {
                    'file': PartEncoding(
                      contentType: ContentType.bytes,
                      rawContentType: 'application/octet-stream',
                      style: null,
                      explode: null,
                      allowReserved: null,
                      headers: {
                        'X-Rate-Limit': ResponseHeaderObject(
                          name: 'X-Rate-Limit',
                          context: testContext,
                          description: null,
                          explode: false,
                          model: IntegerModel(context: testContext),
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
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          final method = generator.generateDataMethod(operation);

          // _data() must include multipart header params so they're in scope.
          expect(method.optionalParameters, hasLength(2));

          final bodyParam = method.optionalParameters.first;
          expect(bodyParam.name, 'body');

          final headerParam = method.optionalParameters[1];
          expect(headerParam.name, 'fileRateLimit');
          expect(headerParam.named, isTrue);
          expect(headerParam.required, isTrue);
        },
      );

      test('generates _data method for multi-content including multipart', () {
        final jsonModel = ClassModel(
          name: 'JsonPayload',
          isDeprecated: false,
          properties: [
            Property(
              name: 'value',
              model: StringModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final formModel = ClassModel(
          name: 'FormPayload',
          isDeprecated: false,
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final operation = Operation(
          operationId: 'createItem',
          path: '/items',
          method: HttpMethod.post,
          requestBody: RequestBodyObject(
            name: 'createItem',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: jsonModel,
                contentType: ContentType.json,
                rawContentType: 'application/json',
                examples: const [],
              ),
              RequestContent(
                model: formModel,
                contentType: ContentType.multipart,
                rawContentType: 'multipart/form-data',
                multipartEncoding: _multipartEncodingByName(formModel, {
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
          ),
          responses: const {},
          pathParameters: const {},
          cookieParameters: const {},
          queryParameters: const {},
          headers: const {},
          context: testContext,
          tags: const {},
          isDeprecated: false,
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          Future<Object?> _data({required CreateItem body}) async {
            return switch (body) {
              final CreateItemJson value => value.value.toJson(),
              final CreateItemFormData value => await () async {
                final _$formData = FormData();
                _$formData.files.add(MapEntry(r'name', MultipartFile.fromString(value.value.name, contentType: DioMediaType.parse(r'text/plain'))));
                return _$formData;
              }(),
            };
          }
        ''';

        final method = generator.generateDataMethod(operation);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });
      test('generates _data method for multi-content with form variant', () {
        final jsonModel = ClassModel(
          name: 'JsonPayload',
          isDeprecated: false,
          properties: const [],
          context: testContext,
          examples: const [],
        );

        final formModel = ClassModel(
          name: 'FormPayload',
          isDeprecated: false,
          properties: [
            Property(
              name: 'email',
              model: StringModel(context: testContext),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: testContext,
          examples: const [],
        );

        final operation = Operation(
          operationId: 'createUser',
          path: '/users',
          method: HttpMethod.post,
          requestBody: RequestBodyObject(
            name: 'createUser',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: jsonModel,
                contentType: ContentType.json,
                rawContentType: 'application/json',
                examples: const [],
              ),
              RequestContent(
                model: formModel,
                contentType: ContentType.form,
                rawContentType: 'application/x-www-form-urlencoded',
                examples: const [],
              ),
            },
          ),
          responses: const {},
          pathParameters: const {},
          cookieParameters: const {},
          queryParameters: const {},
          headers: const {},
          context: testContext,
          tags: const {},
          isDeprecated: false,
          securitySchemes: const {},
        );

        const expectedMethod = r'''
          Object? _data({required CreateUser body}) {
            return switch (body) {
              final CreateUserJson value => value.value.toJson(),
              final CreateUserXWwwFormUrlencoded value => value.value
                  .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
                  .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                  .join('&'),
            };
          }
        ''';

        final method = generator.generateDataMethod(operation);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });

      test(
        'generates _data method for optional multi-content with null check',
        () {
          final jsonModel = ClassModel(
            name: 'JsonPayload',
            isDeprecated: false,
            properties: const [],
            context: testContext,
            examples: const [],
          );

          final formModel = ClassModel(
            name: 'FormPayload',
            isDeprecated: false,
            properties: const [],
            context: testContext,
            examples: const [],
          );

          final operation = Operation(
            operationId: 'updateItem',
            path: '/items',
            method: HttpMethod.put,
            requestBody: RequestBodyObject(
              name: 'updateItem',
              context: testContext,
              description: null,
              isRequired: false,
              content: {
                RequestContent(
                  model: jsonModel,
                  contentType: ContentType.json,
                  rawContentType: 'application/json',
                  examples: const [],
                ),
                RequestContent(
                  model: formModel,
                  contentType: ContentType.form,
                  rawContentType: 'application/x-www-form-urlencoded',
                  examples: const [],
                ),
              },
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          const expectedMethod = r'''
            Object? _data({UpdateItem? body}) {
              if (body == null) return null;
              return switch (body) {
                final UpdateItemJson value => value.value.toJson(),
                final UpdateItemXWwwFormUrlencoded value => value.value
                    .toForm('', explode: true, allowEmpty: true, useQueryComponent: true)
                    .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                    .join('&'),
              };
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'applies per-property allowReserved in the form arm of a '
        'multi-content body',
        () {
          final jsonModel = ClassModel(
            name: 'JsonPayload',
            isDeprecated: false,
            properties: const [],
            context: testContext,
            examples: const [],
          );

          final formModel = ClassModel(
            name: 'FormPayload',
            isDeprecated: false,
            properties: [
              Property(
                name: 'reserved',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
              Property(
                name: 'plain',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = Operation(
            operationId: 'createUser',
            path: '/users',
            method: HttpMethod.post,
            requestBody: RequestBodyObject(
              name: 'createUser',
              context: testContext,
              description: null,
              isRequired: true,
              content: {
                RequestContent(
                  model: jsonModel,
                  contentType: ContentType.json,
                  rawContentType: 'application/json',
                  examples: const [],
                ),
                RequestContent(
                  model: formModel,
                  contentType: ContentType.form,
                  rawContentType: 'application/x-www-form-urlencoded',
                  examples: const [],
                  formEncoding: _formEncodingByName(formModel, {
                    'reserved': _reserved(true),
                    'plain': _reserved(false),
                  }),
                ),
              },
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          const expectedMethod = r'''
            Object? _data({required CreateUser body}) {
              return switch (body) {
                final CreateUserJson value => value.value.toJson(),
                final CreateUserXWwwFormUrlencoded value => value.value
                    .toForm(
                      '',
                      explode: true,
                      allowEmpty: true,
                      useQueryComponent: true,
                      fieldEncodings: <String, FormFieldEncoding>{
                        r'reserved': const FormFieldEncoding(allowReserved: true),
                      },
                    )
                    .map((e) => e.name.isEmpty ? e.value : '${e.name}=${e.value}')
                    .join('&'),
              };
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates _data method for optional single-content multipart body',
        () {
          final userModel = ClassModel(
            name: 'CreateUserForm',
            isDeprecated: false,
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = Operation(
            operationId: 'createUser',
            path: '/users',
            method: HttpMethod.post,
            requestBody: RequestBodyObject(
              name: 'createUser',
              context: testContext,
              description: null,
              isRequired: false,
              content: {
                RequestContent(
                  model: userModel,
                  contentType: ContentType.multipart,
                  rawContentType: 'multipart/form-data',
                  multipartEncoding: _multipartEncodingByName(userModel, {
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
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          const expectedMethod = r'''
            Future<Object?> _data({CreateUserForm? body}) async {
              if (body == null) return null;
              final _$formData = FormData();
              _$formData.files.add(MapEntry(r'name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse(r'text/plain'))));
              return _$formData;
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );

      test(
        'generates _data method for multi-content multipart with header params',
        () {
          final jsonModel = ClassModel(
            name: 'JsonPayload',
            isDeprecated: false,
            properties: const [],
            context: testContext,
            examples: const [],
          );

          final uploadModel = ClassModel(
            name: 'UploadPayload',
            isDeprecated: false,
            properties: [
              Property(
                name: 'file',
                model: BinaryModel(context: testContext),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: testContext,
            examples: const [],
          );

          final operation = Operation(
            operationId: 'uploadItem',
            path: '/items/upload',
            method: HttpMethod.post,
            requestBody: RequestBodyObject(
              name: 'uploadItem',
              context: testContext,
              description: null,
              isRequired: true,
              content: {
                RequestContent(
                  model: jsonModel,
                  contentType: ContentType.json,
                  rawContentType: 'application/json',
                  examples: const [],
                ),
                RequestContent(
                  model: uploadModel,
                  contentType: ContentType.multipart,
                  rawContentType: 'multipart/form-data',
                  multipartEncoding: _multipartEncodingByName(uploadModel, {
                    'file': PartEncoding(
                      contentType: ContentType.bytes,
                      rawContentType: 'application/octet-stream',
                      style: null,
                      explode: null,
                      allowReserved: null,
                      headers: {
                        'X-Checksum': ResponseHeaderObject(
                          name: 'X-Checksum',
                          context: testContext,
                          description: null,
                          explode: false,
                          model: StringModel(context: testContext),
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
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          final method = generator.generateDataMethod(operation);

          // Verify the multipart header params are included in the method
          // signature alongside the body parameter.
          expect(method.optionalParameters, hasLength(2));

          final bodyParam = method.optionalParameters.first;
          expect(bodyParam.name, 'body');

          final headerParam = method.optionalParameters[1];
          expect(headerParam.name, 'fileChecksum');
          expect(headerParam.named, isTrue);
          expect(headerParam.required, isTrue);

          // Must be async because of multipart
          expect(method.modifier, MethodModifier.async);
        },
      );

      test(
        'generates _data method for non-ClassModel multipart body '
        'without unreachable return',
        () {
          final mapModel = MapModel(
            name: 'AssetMap',
            valueModel: StringModel(context: testContext),
            context: testContext,
            examples: const [],
          );

          final operation = Operation(
            operationId: 'uploadAssets',
            path: '/assets',
            method: HttpMethod.post,
            requestBody: RequestBodyObject(
              name: 'uploadAssets',
              context: testContext,
              description: null,
              isRequired: true,
              content: {
                RequestContent(
                  model: mapModel,
                  contentType: ContentType.multipart,
                  rawContentType: 'multipart/form-data',
                  examples: const [],
                ),
              },
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          const expectedMethod = '''
            Future<Object?> _data({
              required AssetMap body,
            }) async {
              throw UnsupportedError(
                'Multipart request bodies require an object schema (ClassModel). Got: MapModel.',
              );
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );
    });

    group('unsupported bytes content type generates runtime throws', () {
      test(
        'generates runtime throw for EnumModel with bytes content type',
        () {
          final operation = Operation(
            operationId: 'testOp',
            path: '/test',
            method: HttpMethod.post,
            requestBody: RequestBodyObject(
              name: 'test',
              context: testContext,
              description: null,
              isRequired: true,
              content: {
                RequestContent(
                  model: EnumModel<String>(
                    name: 'Status',
                    values: const {},
                    context: testContext,
                    isNullable: false,
                    isDeprecated: false,
                    examples: const [],
                  ),
                  contentType: ContentType.bytes,
                  rawContentType: 'application/octet-stream',
                  examples: const [],
                ),
              },
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            contains('EncodingException'),
          );
        },
      );

      test(
        'generates runtime throw for EnumModel with bytes in '
        'multi-content request body using wildcard pattern',
        () {
          final operation = Operation(
            operationId: 'testOp',
            path: '/test',
            method: HttpMethod.post,
            requestBody: RequestBodyObject(
              name: 'test',
              context: testContext,
              description: null,
              isRequired: true,
              content: {
                RequestContent(
                  model: ClassModel(
                    isDeprecated: false,
                    name: 'JsonModel',
                    properties: const [],
                    context: testContext,
                    examples: const [],
                  ),
                  contentType: ContentType.json,
                  rawContentType: 'application/json',
                  examples: const [],
                ),
                RequestContent(
                  model: EnumModel<String>(
                    name: 'Status',
                    values: const {},
                    context: testContext,
                    isNullable: false,
                    isDeprecated: false,
                    examples: const [],
                  ),
                  contentType: ContentType.bytes,
                  rawContentType: 'application/octet-stream',
                  examples: const [],
                ),
              },
            ),
            responses: const {},
            pathParameters: const {},
            cookieParameters: const {},
            queryParameters: const {},
            headers: const {},
            context: testContext,
            tags: const {},
            isDeprecated: false,
            securitySchemes: const {},
          );

          const expectedMethod = '''
            Object? _data({required Test body}) {
              return switch (body) {
                final TestJson value => value.value.toJson(),
                final TestOctetStream _ => throw EncodingException('Unsupported model for bytes content type.'),
              };
            }
          ''';

          final method = generator.generateDataMethod(operation);
          final methodString = format(method.accept(emitter).toString());
          expect(
            collapseWhitespace(methodString),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );
    });

    group(
      'non-ClassModel multipart in multi-content uses wildcard pattern',
      () {
        test(
          'generates throw with wildcard pattern for MapModel multipart in '
          'multi-content request body',
          () {
            final jsonModel = ClassModel(
              name: 'JsonPayload',
              isDeprecated: false,
              properties: const [],
              context: testContext,
              examples: const [],
            );

            final mapModel = MapModel(
              name: 'AssetMap',
              valueModel: StringModel(context: testContext),
              context: testContext,
              examples: const [],
            );

            final operation = Operation(
              operationId: 'createItem',
              path: '/items',
              method: HttpMethod.post,
              requestBody: RequestBodyObject(
                name: 'createItem',
                context: testContext,
                description: null,
                isRequired: true,
                content: {
                  RequestContent(
                    model: jsonModel,
                    contentType: ContentType.json,
                    rawContentType: 'application/json',
                    examples: const [],
                  ),
                  RequestContent(
                    model: mapModel,
                    contentType: ContentType.multipart,
                    rawContentType: 'multipart/form-data',
                    examples: const [],
                  ),
                },
              ),
              responses: const {},
              pathParameters: const {},
              cookieParameters: const {},
              queryParameters: const {},
              headers: const {},
              context: testContext,
              tags: const {},
              isDeprecated: false,
              securitySchemes: const {},
            );

            const expectedMethod = '''
              Future<Object?> _data({required CreateItem body}) async {
                return switch (body) {
                  final CreateItemJson value => value.value.toJson(),
                  final CreateItemFormData _ => await () async {
                    throw UnsupportedError(
                      'Multipart request bodies require an object schema (ClassModel). Got: MapModel.',
                    );
                  }(),
                };
              }
            ''';

            final method = generator.generateDataMethod(operation);
            final methodString = format(method.accept(emitter).toString());
            expect(
              collapseWhitespace(methodString),
              collapseWhitespace(format(expectedMethod)),
            );
          },
        );
      },
    );
  });
}

FieldEncoding _reserved(bool allowReserved) =>
    FieldEncoding(allowReserved: allowReserved, style: null, explode: null);

Map<Property, FieldEncoding> _formEncodingByName(
  ClassModel model,
  Map<String, FieldEncoding> byName,
) {
  return {
    for (final entry in byName.entries)
      model.properties.firstWhere((p) => p.name == entry.key): entry.value,
  };
}

Map<Property, PartEncoding> _multipartEncodingByName(
  ClassModel model,
  Map<String, PartEncoding> byName,
) {
  return {
    for (final entry in byName.entries)
      model.properties.firstWhere((p) => p.name == entry.key): entry.value,
  };
}

Operation _formOperation({
  required String operationId,
  required ClassModel model,
  required Map<String, FieldEncoding> encoding,
  required Context context,
}) {
  return Operation(
    operationId: operationId,
    path: '/$operationId',
    method: HttpMethod.post,
    requestBody: RequestBodyObject(
      name: operationId,
      context: context,
      description: null,
      isRequired: true,
      content: {
        RequestContent(
          model: model,
          contentType: ContentType.form,
          rawContentType: 'application/x-www-form-urlencoded',
          examples: const [],
          formEncoding: _formEncodingByName(model, encoding),
        ),
      },
    ),
    responses: const {},
    pathParameters: const {},
    cookieParameters: const {},
    queryParameters: const {},
    headers: const {},
    context: context,
    tags: const {},
    isDeprecated: false,
    securitySchemes: const {},
  );
}
