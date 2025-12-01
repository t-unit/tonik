import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/response/response_generator.dart';

void main() {
  late DartEmitter emitter;
  late NameManager nameManager;
  late ResponseGenerator generator;
  late Context testContext;

  setUp(() {
    emitter = DartEmitter(orderDirectives: true, useNullSafetySyntax: true);
    nameManager = NameManager(generator: NameGenerator());
    generator = ResponseGenerator(
      nameManager: nameManager,
      package: 'test_package',
    );
    testContext = Context.initial();
  });

  group('ResponseGenerator', () {
    test('throws when response has no headers and no bodies', () {
      final response = ResponseObject(
        name: 'EmptyResponse',
        context: testContext,
        description: 'Empty response',
        headers: const {},
        bodies: const {},
      );

      expect(() => generator.generate(response), throwsArgumentError);
    });

    test('throws when response has no headers and single body', () {
      final response = ResponseObject(
        name: 'SingleBodyResponse',
        context: testContext,
        description: 'Single body response',
        headers: const {},
        bodies: {
          ResponseBody(
            model: StringModel(context: testContext),
            rawContentType: 'application/json',
            contentType: ContentType.json,
          ),
        },
      );

      expect(() => generator.generate(response), throwsArgumentError);
    });

    group('generate method', () {
      test('generates typedef for ResponseAlias', () {
        final aliasResponse = ResponseAlias(
          name: 'AliasResponse',
          context: testContext,
          response: ResponseObject(
            name: 'OriginalResponse',
            context: testContext,
            description: 'Original response',
            headers: {
              'X-Test': ResponseHeaderObject(
                name: 'X-Test',
                context: testContext,
                description: 'Test header',
                model: StringModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                explode: false,
                encoding: ResponseHeaderEncoding.simple,
              ),
            },
            bodies: {
              ResponseBody(
                model: StringModel(context: testContext),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
            },
          ),
        );

        final result = generator.generate(aliasResponse);
        expect(result.filename, 'alias_response.dart');
        expect(result.code, contains('typedef AliasResponse ='));
      });

      test('generates class for ResponseObject with single body', () {
        final response = ResponseObject(
          name: 'SingleBodyResponse',
          context: testContext,
          description: 'Response with single body',
          headers: {
            'X-Test': ResponseHeaderObject(
              name: 'X-Test',
              context: testContext,
              description: 'Test header',
              model: StringModel(context: testContext),
              isRequired: true,
              isDeprecated: false,
              explode: false,
              encoding: ResponseHeaderEncoding.simple,
            ),
          },
          bodies: {
            ResponseBody(
              model: StringModel(context: testContext),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        );

        final result = generator.generate(response);
        expect(result.filename, 'single_body_response.dart');

        final singleBodyClass = generator.generateResponseClass(response);
        expect(singleBodyClass.name, 'SingleBodyResponse');
      });

      test(
        'generates non-sealed class for ResponseObject with headers only',
        () {
          final response = ResponseObject(
            name: 'HeadersOnlyResponse',
            context: testContext,
            description: 'Response with headers but no body',
            headers: {
              'X-User-Id': ResponseHeaderObject(
                name: 'X-User-Id',
                context: testContext,
                description: 'User ID header',
                model: IntegerModel(context: testContext),
                isRequired: false,
                isDeprecated: false,
                explode: false,
                encoding: ResponseHeaderEncoding.simple,
              ),
            },
            bodies: const {},
          );

          final result = generator.generate(response);
          expect(result.filename, 'headers_only_response.dart');

          final generatedClass = generator.generateResponseClass(response);
          expect(generatedClass.name, 'HeadersOnlyResponse');
          expect(generatedClass.sealed, isFalse);
        },
      );

      test(
        'generates multiple classes for ResponseObject with multiple bodies',
        () {
          final response = ResponseObject(
            name: 'MultiBodyResponse',
            context: testContext,
            description: 'Response with multiple bodies',
            headers: {
              'X-Test': ResponseHeaderObject(
                name: 'X-Test',
                context: testContext,
                description: 'Test header',
                model: StringModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                explode: false,
                encoding: ResponseHeaderEncoding.simple,
              ),
            },
            bodies: {
              ResponseBody(
                model: StringModel(context: testContext),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
              ResponseBody(
                model: IntegerModel(context: testContext),
                rawContentType: 'application/xml',
                contentType: ContentType.json,
              ),
            },
          );

          final result = generator.generate(response);
          expect(result.filename, 'multi_body_response.dart');

          expect(result.code, contains('sealed class MultiBodyResponse'));
          expect(
            result.code,
            contains('class MultiBodyResponseJson extends MultiBodyResponse'),
          );
          expect(
            result.code,
            contains('class MultiBodyResponseXml extends MultiBodyResponse'),
          );
        },
      );
    });

    group('typedef generation', () {
      test('generates typedef with correct name and definition', () {
        final aliasResponse = ResponseAlias(
          name: 'AliasResponse',
          context: testContext,
          response: ResponseObject(
            name: 'OriginalResponse',
            context: testContext,
            description: 'Original response',
            headers: const {},
            bodies: {
              ResponseBody(
                model: StringModel(context: testContext),
                rawContentType: 'application/json',
                contentType: ContentType.json,
              ),
              ResponseBody(
                model: StringModel(context: testContext),
                rawContentType: 'application/xml',
                contentType: ContentType.json,
              ),
            },
          ),
        );

        final name = nameManager.responseNames(aliasResponse).baseName;
        final typedef = generator.generateTypedef(aliasResponse, name);
        expect(typedef.name, name);
        expect(
          typedef.definition.accept(emitter).toString(),
          'OriginalResponse',
        );
      });
    });

    group('generateResponseClass for headers-only responses', () {
      test('generates non-sealed class with constructor and fields', () {
        final response = ResponseObject(
          name: 'HeadersOnlyResponse',
          context: testContext,
          description: 'Response with headers but no body',
          headers: {
            'X-User-Id': ResponseHeaderObject(
              name: 'X-User-Id',
              context: testContext,
              description: 'User ID header',
              model: IntegerModel(context: testContext),
              isRequired: false,
              isDeprecated: false,
              explode: false,
              encoding: ResponseHeaderEncoding.simple,
            ),
            'X-User-Name': ResponseHeaderObject(
              name: 'X-User-Name',
              context: testContext,
              description: 'User name header',
              model: StringModel(context: testContext),
              isRequired: false,
              isDeprecated: false,
              explode: false,
              encoding: ResponseHeaderEncoding.simple,
            ),
          },
          bodies: const {},
        );

        final generatedClass = generator.generateResponseClass(response);

        expect(generatedClass.name, 'HeadersOnlyResponse');
        expect(generatedClass.sealed, isFalse);

        expect(generatedClass.constructors, hasLength(1));
        final constructor = generatedClass.constructors.first;
        expect(constructor.constant, isTrue);

        final fieldNames = generatedClass.fields.map((f) => f.name).toList();
        expect(fieldNames, containsAll(['xUserId', 'xUserName']));

        final methodNames = generatedClass.methods.map((m) => m.name).toList();
        expect(
          methodNames,
          containsAll(['operator ==', 'hashCode', 'copyWith']),
        );
      });

      test(
        'generates class with required headers marked as required params',
        () {
          final response = ResponseObject(
            name: 'RequiredHeaderResponse',
            context: testContext,
            description: 'Response with required headers',
            headers: {
              'X-Required': ResponseHeaderObject(
                name: 'X-Required',
                context: testContext,
                description: 'Required header',
                model: StringModel(context: testContext),
                isRequired: true,
                isDeprecated: false,
                explode: false,
                encoding: ResponseHeaderEncoding.simple,
              ),
              'X-Optional': ResponseHeaderObject(
                name: 'X-Optional',
                context: testContext,
                description: 'Optional header',
                model: StringModel(context: testContext),
                isRequired: false,
                isDeprecated: false,
                explode: false,
                encoding: ResponseHeaderEncoding.simple,
              ),
            },
            bodies: const {},
          );

          final generatedClass = generator.generateResponseClass(response);
          final constructor = generatedClass.constructors.first;

          final requiredParam = constructor.optionalParameters.firstWhere(
            (p) => p.name == 'xRequired',
          );
          final optionalParam = constructor.optionalParameters.firstWhere(
            (p) => p.name == 'xOptional',
          );

          expect(requiredParam.required, isTrue);
          expect(optionalParam.required, isFalse);
        },
      );
    });
  });
}
