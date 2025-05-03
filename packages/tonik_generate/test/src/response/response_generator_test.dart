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
        expect(result.filename, equals('alias_response.dart'));
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
        expect(result.filename, equals('single_body_response.dart'));
        expect(result.code, contains('class SingleBodyResponse'));
      });

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

        final name = nameManager.responseName(aliasResponse);
        final typedef = generator.generateTypedef(aliasResponse, name);
        expect(typedef.name, name);
        expect(
          typedef.definition.accept(emitter).toString(),
          'OriginalResponse',
        );
      });
    });
  });
}
