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

  group('ResponseGenerator header field deprecation', () {
    test(
      'adds @Deprecated annotation to field when response header is deprecated',
      () {
        final response = ResponseObject(
          name: 'TestResponse',
          context: testContext,
          description: 'Test response',
          headers: {
            'X-Legacy-Header': ResponseHeaderObject(
              name: 'X-Legacy-Header',
              context: testContext,
              description: 'A deprecated header',
              model: StringModel(context: testContext),
              isRequired: true,
              isDeprecated: true,
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

        final result = generator.generateResponseClass(response);

        // Find the deprecated header field
        final deprecatedField = result.fields.firstWhere(
          (f) => f.name == 'xLegacyHeader',
          orElse: () => throw StateError('No xLegacyHeader field found'),
        );
        final hasDeprecatedAnnotation = deprecatedField.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isTrue);
      },
    );

    test(
      'does not add @Deprecated annotation to field when response '
      'header is not deprecated',
      () {
        final response = ResponseObject(
          name: 'TestResponse',
          context: testContext,
          description: 'Test response',
          headers: {
            'X-Current-Header': ResponseHeaderObject(
              name: 'X-Current-Header',
              context: testContext,
              description: 'A current header',
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

        final result = generator.generateResponseClass(response);

        final field = result.fields.firstWhere(
          (f) => f.name == 'xCurrentHeader',
          orElse: () => throw StateError('No xCurrentHeader field found'),
        );
        final hasDeprecatedAnnotation = field.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isFalse);
      },
    );

    test(
      'adds @Deprecated annotation only to deprecated header field '
      'in multi-header response',
      () {
        final response = ResponseObject(
          name: 'MultiHeaderResponse',
          context: testContext,
          description: 'Response with multiple headers',
          headers: {
            'X-Legacy': ResponseHeaderObject(
              name: 'X-Legacy',
              context: testContext,
              description: 'A deprecated header',
              model: StringModel(context: testContext),
              isRequired: true,
              isDeprecated: true,
              explode: false,
              encoding: ResponseHeaderEncoding.simple,
            ),
            'X-Current': ResponseHeaderObject(
              name: 'X-Current',
              context: testContext,
              description: 'A current header',
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

        final result = generator.generateResponseClass(response);

        // Check deprecated field has annotation
        final legacyField = result.fields.firstWhere(
          (f) => f.name == 'xLegacy',
          orElse: () => throw StateError('No xLegacy field found'),
        );
        final legacyHasDeprecated = legacyField.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );
        expect(legacyHasDeprecated, isTrue);

        // Check current field does not have annotation
        final currentField = result.fields.firstWhere(
          (f) => f.name == 'xCurrent',
          orElse: () => throw StateError('No xCurrent field found'),
        );
        final currentHasDeprecated = currentField.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );
        expect(currentHasDeprecated, isFalse);
      },
    );
  });

  group('ResponseGenerator multi-body response header deprecation', () {
    test(
      'adds @Deprecated annotation to header field in multi-body '
      'response base class',
      () {
        final response = ResponseObject(
          name: 'MultiBodyResponse',
          context: testContext,
          description: 'Response with multiple bodies',
          headers: {
            'X-Deprecated-Header': ResponseHeaderObject(
              name: 'X-Deprecated-Header',
              context: testContext,
              description: 'A deprecated header',
              model: StringModel(context: testContext),
              isRequired: true,
              isDeprecated: true,
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
              rawContentType: 'text/plain',
              contentType: ContentType.json,
            ),
          },
        );

        final results = generator.generateMultiBodyResponseClasses(response);

        // Check the base sealed class has deprecated header field
        final baseClass = results.firstWhere(
          (c) => c.name == 'MultiBodyResponse',
          orElse: () => throw StateError('No base class found'),
        );

        final deprecatedField = baseClass.fields.firstWhere(
          (f) => f.name == 'xDeprecatedHeader',
          orElse: () => throw StateError('No xDeprecatedHeader field found'),
        );
        final hasDeprecatedAnnotation = deprecatedField.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isTrue);
      },
    );

    test(
      'does not add @Deprecated annotation to non-deprecated header '
      'in multi-body response',
      () {
        final response = ResponseObject(
          name: 'MultiBodyResponse',
          context: testContext,
          description: 'Response with multiple bodies',
          headers: {
            'X-Current-Header': ResponseHeaderObject(
              name: 'X-Current-Header',
              context: testContext,
              description: 'A current header',
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
              rawContentType: 'text/plain',
              contentType: ContentType.json,
            ),
          },
        );

        final results = generator.generateMultiBodyResponseClasses(response);

        final baseClass = results.firstWhere(
          (c) => c.name == 'MultiBodyResponse',
          orElse: () => throw StateError('No base class found'),
        );

        final field = baseClass.fields.firstWhere(
          (f) => f.name == 'xCurrentHeader',
          orElse: () => throw StateError('No xCurrentHeader field found'),
        );
        final hasDeprecatedAnnotation = field.annotations.any(
          (a) => a.accept(emitter).toString().contains('Deprecated'),
        );

        expect(hasDeprecatedAnnotation, isFalse);
      },
    );
  });
}
