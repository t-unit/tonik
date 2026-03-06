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
    nameManager = NameManager(generator: NameGenerator());
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
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
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
        Object? _data({required TestModel? body}) { 
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
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
            RequestContent(
              model: ClassModel(
                isDeprecated: false,
                name: 'FormModel',
                properties: const [],
                context: testContext,
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json+problem',
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

    test('handles primitive model in request body', () {
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
        Object? _data({required Date? body}) {
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
        Object? _data({required BigDecimal? body}) {
          return body?.toString();
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
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json+problem',
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
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
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
        Object? _data({required TestModel? body}) {
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
        Object? _data({required TonikFile? body}) {
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
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.text,
              rawContentType: 'text/plain',
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
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.bytes,
              rawContentType: 'application/octet-stream',
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
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
            RequestContent(
              model: BinaryModel(context: testContext),
              contentType: ContentType.bytes,
              rawContentType: 'application/octet-stream',
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
        Object? _data({required String? body}) {
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
            ),
            Property(
              name: 'age',
              model: IntegerModel(context: testContext),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: testContext,
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
          Object? _data({required Pet body}) {
            return body.toForm(explode: true, allowEmpty: true, useQueryComponent: true);
          }
        ''';

        final method = generator.generateDataMethod(operation);
        final methodString = format(method.accept(emitter).toString());
        expect(
          collapseWhitespace(methodString),
          collapseWhitespace(format(expectedMethod)),
        );
      });
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
            ),
            Property(
              name: 'nickname',
              model: StringModel(context: testContext),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: testContext,
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
                encoding: {
                  'name': const MultipartPropertyEncoding(
                    contentType: ContentType.text,
                    rawContentType: 'text/plain',
                    style: MultipartEncodingStyle.form,
                    explode: true,
                    allowReserved: false,
                  ),
                  'nickname': const MultipartPropertyEncoding(
                    contentType: ContentType.text,
                    rawContentType: 'text/plain',
                    style: MultipartEncodingStyle.form,
                    explode: true,
                    allowReserved: false,
                  ),
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

        const expectedMethod = '''
          Future<Object?> _data({required CreateUserForm body}) async {
            final formData = FormData();
            formData.files.add(MapEntry('name', MultipartFile.fromString(body.name, contentType: DioMediaType.parse('text/plain'))));
            if (body.nickname != null) {
              formData.files.add(MapEntry('nickname', MultipartFile.fromString(body.nickname!, contentType: DioMediaType.parse('text/plain'))));
            }
            return formData;
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
              ),
            ],
            context: testContext,
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
                  encoding: {
                    'file': MultipartPropertyEncoding(
                      contentType: ContentType.bytes,
                      rawContentType: 'application/octet-stream',
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
                        ),
                      },
                    ),
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
            ),
          ],
          context: testContext,
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
            ),
          ],
          context: testContext,
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
              ),
              RequestContent(
                model: formModel,
                contentType: ContentType.multipart,
                rawContentType: 'multipart/form-data',
                encoding: {
                  'name': const MultipartPropertyEncoding(
                    contentType: ContentType.text,
                    rawContentType: 'text/plain',
                    style: MultipartEncodingStyle.form,
                    explode: true,
                    allowReserved: false,
                  ),
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

        const expectedMethod = '''
          Future<Object?> _data({required CreateItem body}) async {
            return switch (body) {
              final CreateItemJson value => value.value.toJson(),
              final CreateItemFormData value => await () async {
                final formData = FormData();
                formData.files.add(MapEntry('name', MultipartFile.fromString(value.value.name, contentType: DioMediaType.parse('text/plain'))));
                return formData;
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
    });
  });
}
