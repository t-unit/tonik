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
        requestBody: null,
        responses: const {},
        pathParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        summary: null,
        description: null,
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
                name: 'TestModel',
                properties: const <Property>{},
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
        context: testContext,
        summary: null,
        description: null,
        tags: const <Tag>{},
        isDeprecated: false,
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
                name: 'JsonModel',
                properties: const <Property>{},
                context: testContext,
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
            RequestContent(
              model: ClassModel(
                name: 'FormModel',
                properties: const <Property>{},
                context: testContext,
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json+problem',
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
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
        queryParameters: const {},
        headers: const {},
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
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
        queryParameters: const {},
        headers: const {},
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
      );

      const expectedMethod = '''
        Object? _data({required DateTime? body}) {
          return body?.toIso8601String();
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
        queryParameters: const {},
        headers: const {},
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
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
                name: 'TestEnum',
                values: const {'value1', 'value2'},
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
        queryParameters: const {},
        headers: const {},
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
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
                name: 'TestModel',
                properties: const <Property>{},
                context: testContext,
              ),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
          },
        ),
        responses: const {},
        pathParameters: const {},
        queryParameters: const {},
        headers: const {},
        context: testContext,
        summary: null,
        description: null,
        tags: const {},
        isDeprecated: false,
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
  });
}
