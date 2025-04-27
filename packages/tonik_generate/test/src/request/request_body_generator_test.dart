import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/request/request_body_generator.dart';

void main() {
  late RequestBodyGenerator generator;
  late NameManager nameManager;
  late Context testContext;
  late DartEmitter emitter;

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameManager = NameManager(generator: NameGenerator());
    generator = RequestBodyGenerator(
      nameManager: nameManager,
      package: 'test_package',
    );
    testContext = Context.initial().push('test');
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('RequestBodyGenerator', () {
    test('throws when request body has no content', () {
      final requestBody = RequestBodyObject(
        name: 'EmptyBody',
        context: testContext,
        description: null,
        isRequired: true,
        content: const {},
      );

      expect(
        () => generator.generate(requestBody),
        throwsArgumentError,
      );
    });

    test('throws when request body has only one content', () {
      final requestBody = RequestBodyObject(
        name: 'SingleBody',
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
      );

      expect(
        () => generator.generate(requestBody),
        throwsArgumentError,
      );
    });

    group('typedef generation', () {
      test('generates typedef with correct name and definition', () {
        final aliasBody = RequestBodyAlias(
          name: 'AliasBody',
          context: testContext,
          requestBody: RequestBodyObject(
            name: 'OriginalBody',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: StringModel(context: testContext),
                contentType: ContentType.json,
                rawContentType: 'application/json',
              ),
              RequestContent(
                model: StringModel(context: testContext),
                contentType: ContentType.json,
                rawContentType: 'application/json',
              ),
            },
          ),
        );

        final (name, _) = nameManager.requestBodyNames(aliasBody);
        final typedef = generator.generateTypedef(aliasBody, name);
        expect(typedef.name, name);
        expect(
          typedef.definition.accept(emitter).toString(),
          'OriginalBody',
        );
      });
    });

    group('sealed class generation', () {
      test('generates base class with correct name and annotations', () {
        final requestBody = RequestBodyObject(
          name: 'MultiBody',
          context: testContext,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
          },
        );

        final (name, _) = nameManager.requestBodyNames(requestBody);
        final classes = generator.generateClasses(requestBody, name);
        final baseClass = classes.first;

        expect(baseClass.name, 'MultiBody');
        expect(baseClass.sealed, isTrue);
        expect(baseClass.annotations.length, 1);
        expect(
          baseClass.annotations.first.accept(emitter).toString(),
          'immutable',
        );
      });

      test('generates subclass with correct name, fields, and methods', () {
        final requestBody = RequestBodyObject(
          name: 'MultiBody',
          context: testContext,
          description: null,
          isRequired: true,
          content: {
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.json,
              rawContentType: 'application/json',
            ),
            RequestContent(
              model: StringModel(context: testContext),
              contentType: ContentType.json,
              rawContentType: 'application/json+problem',
            ),
          },
        );

        final (name, _) = nameManager.requestBodyNames(requestBody);
        final classes = generator.generateClasses(requestBody, name);
        final subClass = classes[1];

        expect(subClass.name, 'MultiBodyJson');
        expect(
          subClass.extend?.accept(emitter).toString(),
          'MultiBody',
        );

        // Test field
        final field = subClass.fields.first;
        expect(field.name, 'value');
        expect(field.modifier, FieldModifier.final$);
        expect(field.type?.accept(emitter).toString(), 'String');

        // Test constructor
        final constructor = subClass.constructors.first;
        expect(constructor.constant, isTrue);
        expect(constructor.requiredParameters.length, 1);
        expect(constructor.requiredParameters.first.name, 'this.value');
      });

      group('equals method generation', () {
        test('generates equals method with simple value', () {
          final requestBody = RequestBodyObject(
            name: 'MultiBody',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: StringModel(context: testContext),
                contentType: ContentType.json,
                rawContentType: 'application/json',
              ),
              RequestContent(
                model: StringModel(context: testContext),
                contentType: ContentType.json,
                rawContentType: 'application/json+problem',
              ),
            },
          );

          const expectedMethod = '''
            @override
            bool operator ==(Object other) {
              if (identical(this, other)) return true;
              return other is MultiBodyJson && other.value == value;
            }
          ''';

          final (name, _) = nameManager.requestBodyNames(requestBody);
          final classes = generator.generateClasses(requestBody, name);
          final subClass = classes[1];
          expect(
            collapseWhitespace(format(subClass.accept(emitter).toString())),
            contains(collapseWhitespace(expectedMethod)),
          );
        });

        test('generates equals method with list value', () {
          final requestBody = RequestBodyObject(
            name: 'MultiBody',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: ListModel(
                  content: StringModel(context: testContext),
                  context: testContext,
                ),
                contentType: ContentType.json,
                rawContentType: 'application/json',
              ),
              RequestContent(
                model: StringModel(context: testContext),
                contentType: ContentType.json,
                rawContentType: 'application/json+problem',
              ),
            },
          );

          const expectedMethod = r'''
            @override
            bool operator ==(Object other) {
              if (identical(this, other)) return true;
              const _$deepEquals = DeepCollectionEquality();
              return other is MultiBodyJson && _$deepEquals.equals(other.value, value);
            }
          ''';

          final (name, _) = nameManager.requestBodyNames(requestBody);
          final classes = generator.generateClasses(requestBody, name);
          final subClass = classes[1];
          expect(
            collapseWhitespace(format(subClass.accept(emitter).toString())),
            contains(collapseWhitespace(expectedMethod)),
          );
        });
      });

      group('hashCode method generation', () {
        test('generates hashCode method with simple value', () {
          final requestBody = RequestBodyObject(
            name: 'MultiBody',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: StringModel(context: testContext),
                contentType: ContentType.json,
                rawContentType: 'application/json',
              ),
              RequestContent(
                model: StringModel(context: testContext),
                contentType: ContentType.json,
                rawContentType: 'application/json+problem',
              ),
            },
          );

          const expectedMethod = '''
            @override
            int get hashCode => value.hashCode;
          ''';

          final (name, _) = nameManager.requestBodyNames(requestBody);
          final classes = generator.generateClasses(requestBody, name);
          final subClass = classes[1];
          expect(
            collapseWhitespace(format(subClass.accept(emitter).toString())),
            contains(collapseWhitespace(expectedMethod)),
          );
        });

        test('generates hashCode method with list value', () {
          final requestBody = RequestBodyObject(
            name: 'MultiBody',
            context: testContext,
            description: null,
            isRequired: true,
            content: {
              RequestContent(
                model: ListModel(
                  content: StringModel(context: testContext),
                  context: testContext,
                ),
                contentType: ContentType.json,
                rawContentType: 'application/json',
              ),
              RequestContent(
                model: StringModel(context: testContext),
                contentType: ContentType.json,
                rawContentType: 'application/json+problem',
              ),
            },
          );

          const expectedMethod = '''
            @override
            int get hashCode {
              const deepEquals = DeepCollectionEquality();
              return deepEquals.hash(value);
            }
          ''';

          final (name, _) = nameManager.requestBodyNames(requestBody);
          final classes = generator.generateClasses(requestBody, name);
          final subClass = classes[1];
          expect(
            collapseWhitespace(format(subClass.accept(emitter).toString())),
            contains(collapseWhitespace(expectedMethod)),
          );
        });
      });
    });
  });
} 
