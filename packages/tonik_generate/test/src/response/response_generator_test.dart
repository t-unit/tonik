import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/response/response_generator.dart';
import 'package:tonik_generate/src/util/name_generator.dart';
import 'package:tonik_generate/src/util/name_manager.dart';

void main() {
  late DartEmitter emitter;
  late NameManager nameManager;
  late ResponseGenerator generator;
  late Context testContext;

  final format =
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;

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

    group('class generation', () {
      test('generates class with headers and single body', () {
        final response = ResponseObject(
          name: 'HeaderResponse',
          context: testContext,
          description: 'Response with headers and single body',
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
            'X-Optional': ResponseHeaderObject(
              name: 'X-Optional',
              context: testContext,
              description: 'Optional header',
              model: IntegerModel(context: testContext),
              isRequired: false,
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

        final generatedClass = generator.generateResponseClass(response);

        // Verify class name and annotation
        expect(generatedClass.name, 'HeaderResponse');
        expect(
          generatedClass.annotations.first.accept(emitter).toString(),
          'immutable',
        );

        // Verify fields
        final fields = generatedClass.fields.toList();
        expect(fields.length, 3);

        // Required header field
        final xTestField = fields[0];
        expect(xTestField.name, 'xTest');
        expect(xTestField.modifier, equals(FieldModifier.final$));
        expect(xTestField.type?.accept(emitter).toString(), 'String');
        expect(xTestField.annotations.isEmpty, isTrue);

        // Optional header field
        final xOptionalField = fields[2];
        expect(xOptionalField.name, 'xOptional');
        expect(xOptionalField.modifier, equals(FieldModifier.final$));
        expect(xOptionalField.type?.accept(emitter).toString(), 'int?');
        expect(xOptionalField.annotations.isEmpty, isTrue);

        // Body field
        final bodyField = fields[1];
        expect(bodyField.name, 'body');
        expect(bodyField.modifier, equals(FieldModifier.final$));
        expect(bodyField.type?.accept(emitter).toString(), 'String');
        expect(bodyField.annotations.isEmpty, isTrue);

        // Verify constructor
        final constructor = generatedClass.constructors.first;
        expect(constructor.constant, isTrue);

        final params = constructor.optionalParameters.toList();
        expect(params.length, 3);

        final xTestParam = params[0];
        expect(xTestParam.name, 'xTest');
        expect(xTestParam.named, isTrue);
        expect(xTestParam.required, isTrue);
        expect(xTestParam.toThis, isTrue);

        final xOptionalParam = params[2];
        expect(xOptionalParam.name, 'xOptional');
        expect(xOptionalParam.named, isTrue);
        expect(xOptionalParam.required, isFalse);
        expect(xOptionalParam.toThis, isTrue);

        final bodyParam = params[1];
        expect(bodyParam.name, 'body');
        expect(bodyParam.named, isTrue);
        expect(bodyParam.required, isTrue);
        expect(bodyParam.toThis, isTrue);

        // Verify equals method
        final equalsMethod = generatedClass.methods.firstWhere(
          (m) => m.name == 'operator ==',
        );
        expect(equalsMethod.returns?.accept(emitter).toString(), 'bool');
        expect(
          equalsMethod.annotations.first.accept(emitter).toString(),
          'override',
        );
        expect(equalsMethod.requiredParameters.length, 1);
        expect(
          equalsMethod.requiredParameters.first.type
              ?.accept(emitter)
              .toString(),
          'Object',
        );

        // Verify hashCode method
        final hashCodeMethod = generatedClass.methods.firstWhere(
          (m) => m.name == 'hashCode',
        );
        expect(hashCodeMethod.type, equals(MethodType.getter));
        expect(hashCodeMethod.returns?.accept(emitter).toString(), 'int');
        expect(
          hashCodeMethod.annotations.first.accept(emitter).toString(),
          'override',
        );

        // Verify copyWith method
        final copyWithMethod = generatedClass.methods.firstWhere(
          (m) => m.name == 'copyWith',
        );
        expect(
          copyWithMethod.returns?.accept(emitter).toString(),
          'HeaderResponse',
        );

        final copyWithParams = copyWithMethod.optionalParameters.toList();
        expect(copyWithParams.length, 3);

        expect(copyWithParams[0].name, 'xTest');
        expect(copyWithParams[0].type?.accept(emitter).toString(), 'String?');

        expect(copyWithParams[2].name, 'xOptional');
        expect(copyWithParams[2].type?.accept(emitter).toString(), 'int?');

        expect(copyWithParams[1].name, 'body');
        expect(copyWithParams[1].type?.accept(emitter).toString(), 'String?');
      });

      test('handles name conflict between header and body field', () {
        final response = ResponseObject(
          name: 'ConflictResponse',
          context: testContext,
          description: 'Response with header named body',
          headers: {
            'Body': ResponseHeaderObject(
              name: 'Body',
              context: testContext,
              description: 'Header that conflicts with body field',
              model: StringModel(context: testContext),
              isRequired: true,
              isDeprecated: false,
              explode: false,
              encoding: ResponseHeaderEncoding.simple,
            ),
          },
          bodies: {
            ResponseBody(
              model: IntegerModel(context: testContext),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        );

        final generatedClass = generator.generateResponseClass(response);
        final fields = generatedClass.fields.toList();
        expect(fields.length, 2);

        // Header field should be renamed to bodyHeader
        final headerField = fields[0];
        expect(headerField.name, 'bodyHeader');
        expect(headerField.type?.accept(emitter).toString(), 'String');
        expect(headerField.modifier, equals(FieldModifier.final$));
        expect(headerField.annotations.isEmpty, isTrue);

        // Body field should keep original name
        final bodyField = fields[1];
        expect(bodyField.name, 'body');
        expect(bodyField.type?.accept(emitter).toString(), 'int');
        expect(bodyField.modifier, equals(FieldModifier.final$));
        expect(bodyField.annotations.isEmpty, isTrue);

        // Verify constructor parameters maintain the same names
        final constructor = generatedClass.constructors.first;
        final params = constructor.optionalParameters.toList();
        expect(params.length, 2);

        final headerParam = params[0];
        expect(headerParam.name, 'bodyHeader');
        expect(headerParam.named, isTrue);
        expect(headerParam.required, isTrue);
        expect(headerParam.toThis, isTrue);

        final bodyParam = params[1];
        expect(bodyParam.name, 'body');
        expect(bodyParam.named, isTrue);
        expect(bodyParam.required, isTrue);
        expect(bodyParam.toThis, isTrue);
      });
    });

    group('equals method generation', () {
      test('generates equals method with simple properties', () {
        final response = ResponseObject(
          name: 'SimpleResponse',
          context: testContext,
          description: 'Response with simple properties',
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
              model: IntegerModel(context: testContext),
              rawContentType: 'application/json',
              contentType: ContentType.json,
            ),
          },
        );

        const expectedMethod = '''
          @override
          bool operator ==(Object other) {
            if (identical(this, other)) return true;
            return other is SimpleResponse && 
              other.xTest == xTest && 
              other.body == body;
          }
        ''';

        final generatedClass = generator.generateResponseClass(response);
        expect(
          collapseWhitespace(format(generatedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test(
        'generates equals method with list header using DeepCollectionEquality',
        () {
          final response = ResponseObject(
            name: 'ListHeaderResponse',
            context: testContext,
            description: 'Response with list header',
            headers: {
              'X-List': ResponseHeaderObject(
                name: 'X-List',
                context: testContext,
                description: 'List header',
                model: ListModel(
                  content: StringModel(context: testContext),
                  context: testContext,
                ),
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

          const expectedMethod = '''
          @override
          bool operator ==(Object other) {
            if (identical(this, other)) return true;
            const deepEquals = DeepCollectionEquality(); 
            return other is ListHeaderResponse &&
              deepEquals.equals(other.xList, xList) &&
              other.body == body;
          }
        ''';

          final generatedClass = generator.generateResponseClass(response);
          expect(
            collapseWhitespace(
              format(generatedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        },
      );
    });

    group('hashCode method generation', () {
      test('generates hashCode method with single property', () {
        final response = ResponseObject(
          name: 'SinglePropertyResponse',
          context: testContext,
          description: 'Response with single header',
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

        const expectedMethod = '''
          @override
          int get hashCode { 
            return Object.hash(xTest, body);
          }
        ''';

        final generatedClass = generator.generateResponseClass(response);
        expect(
          collapseWhitespace(format(generatedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates hashCode method with multiple properties', () {
        final response = ResponseObject(
          name: 'MultiPropertyResponse',
          context: testContext,
          description: 'Response with multiple headers',
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
            'X-Other': ResponseHeaderObject(
              name: 'X-Other',
              context: testContext,
              description: 'Other header',
              model: IntegerModel(context: testContext),
              isRequired: false,
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

        const expectedMethod = '''
          @override
          int get hashCode { 
             return Object.hash(xTest, body, xOther);
          }
        ''';

        final generatedClass = generator.generateResponseClass(response);
        expect(
          collapseWhitespace(format(generatedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates hashCode method with list header '
          'using DeepCollectionEquality', () {
        final response = ResponseObject(
          name: 'ListHeaderResponse',
          context: testContext,
          description: 'Response with list header',
          headers: {
            'X-List': ResponseHeaderObject(
              name: 'X-List',
              context: testContext,
              description: 'List header',
              model: ListModel(
                content: StringModel(context: testContext),
                context: testContext,
              ),
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

        const expectedMethod = '''
          @override
          int get hashCode {
            const deepEquals = DeepCollectionEquality(); 
            return Object.hash(deepEquals.hash(xList), body);
          }
        ''';

        final generatedClass = generator.generateResponseClass(response);
        expect(
          collapseWhitespace(format(generatedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('copyWith method generation', () {
      test('generates copyWith method with all properties', () {
        final response = ResponseObject(
          name: 'CopyWithResponse',
          context: testContext,
          description: 'Response with multiple properties',
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
              model: IntegerModel(context: testContext),
              isRequired: false,
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

        const expectedMethod = '''
          CopyWithResponse copyWith({String? xRequired, String? body, int? xOptional}) {
            return CopyWithResponse(
              xRequired: xRequired ?? this.xRequired,
              body: body ?? this.body,
              xOptional: xOptional ?? this.xOptional,
            );
          }
        ''';

        final generatedClass = generator.generateResponseClass(response);
        expect(
          collapseWhitespace(format(generatedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates copyWith method with single property', () {
        final response = ResponseObject(
          name: 'SimpleCopyWithResponse',
          context: testContext,
          description: 'Response with single header',
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

        const expectedMethod = '''
          SimpleCopyWithResponse copyWith({String? xTest, String? body}) {
            return SimpleCopyWithResponse(
              xTest: xTest ?? this.xTest,
              body: body ?? this.body,
            );
          }
        ''';

        final generatedClass = generator.generateResponseClass(response);
        expect(
          collapseWhitespace(format(generatedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });
  });
}
