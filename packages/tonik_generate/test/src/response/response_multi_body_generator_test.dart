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
  late List<Spec> classesWithHeaders;
  late List<Spec> classesWithoutHeaders;

  setUp(() {
    emitter = DartEmitter(orderDirectives: true, useNullSafetySyntax: true);
    nameManager = NameManager(generator: NameGenerator());
    generator = ResponseGenerator(
      nameManager: nameManager,
      package: 'test_package',
    );
    testContext = Context.initial();

    // Setup response with headers
    final responseWithHeaders = ResponseObject(
      name: 'TestResponse',
      context: testContext,
      description: 'Test response with multiple bodies',
      headers: {
        'Content-Type': ResponseHeaderObject(
          name: 'Content-Type',
          context: testContext,
          description: 'Content type header',
          model: StringModel(context: testContext),
          isRequired: true,
          isDeprecated: false,
          explode: false,
          encoding: ResponseHeaderEncoding.simple,
        ),
        'body': ResponseHeaderObject(
          name: 'body',
          context: testContext,
          description: 'Body header',
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
          rawContentType: 'text/plain',
          contentType: ContentType.json,
        ),
        ResponseBody(
          model: IntegerModel(context: testContext),
          rawContentType: 'application/json',
          contentType: ContentType.json,
        ),
      },
    );
    classesWithHeaders = generator.generateMultiBodyResponseClasses(
      responseWithHeaders,
    );

    // Setup response without headers
    final responseWithoutHeaders = ResponseObject(
      name: 'MultiContentResponse',
      context: testContext,
      description: 'Response with multiple content types',
      headers: const {},
      bodies: {
        ResponseBody(
          model: StringModel(context: testContext),
          rawContentType: 'application/json',
          contentType: ContentType.json,
        ),
        ResponseBody(
          model: StringModel(context: testContext),
          rawContentType: 'application/problem+json',
          contentType: ContentType.json,
        ),
      },
    );
    classesWithoutHeaders = generator.generateMultiBodyResponseClasses(
      responseWithoutHeaders,
    );
  });

  group('response with headers', () {
    test('generates correct number of classes (main + copyWith helpers)', () {
      // 3 main classes + 4 copyWith helpers (interface + impl for
      // each subclass)
      expect(classesWithHeaders.whereType<Class>().length, 7);
    });

    group('base sealed class', () {
      late Class baseClass;

      setUp(() {
        baseClass = classesWithHeaders.whereType<Class>().firstWhere(
          (c) => c.name == 'TestResponse',
        );
      });

      test('has correct class definition', () {
        expect(baseClass.name, 'TestResponse');
        expect(baseClass.sealed, isTrue);
        expect(
          baseClass.annotations.first.accept(emitter).toString(),
          'immutable',
        );
      });

      test('has correct header fields', () {
        final fields = baseClass.fields.toList();
        expect(fields.length, 2);

        final contentTypeField = fields[0];
        expect(contentTypeField.name, 'contentType');
        expect(contentTypeField.type?.accept(emitter).toString(), 'String');
        expect(contentTypeField.modifier, FieldModifier.final$);

        final bodyHeaderField = fields[1];
        expect(bodyHeaderField.name, 'bodyHeader');
        expect(bodyHeaderField.type?.accept(emitter).toString(), 'String');
        expect(bodyHeaderField.modifier, FieldModifier.final$);
      });

      test('has correct constructor', () {
        final constructor = baseClass.constructors.first;
        expect(constructor.constant, isTrue);

        final params = constructor.optionalParameters.toList();
        expect(params.length, 2);
        expect(params[0].name, 'contentType');
        expect(params[0].required, isTrue);
        expect(params[0].toThis, isTrue);
        expect(params[1].name, 'bodyHeader');
        expect(params[1].required, isTrue);
        expect(params[1].toThis, isTrue);
      });

      test('has no methods', () {
        expect(baseClass.methods.isEmpty, isTrue);
      });
    });

    group('plain text implementation', () {
      late Class plainClass;

      setUp(() {
        plainClass = classesWithHeaders.whereType<Class>().firstWhere(
          (c) => c.name == 'TestResponsePlain',
        );
      });

      test('has correct class definition', () {
        expect(plainClass.name, 'TestResponsePlain');
        expect(plainClass.extend?.accept(emitter).toString(), 'TestResponse');
        expect(
          plainClass.annotations.first.accept(emitter).toString(),
          'immutable',
        );
      });

      test('has correct body field', () {
        final fields = plainClass.fields.toList();
        expect(fields.length, 1);
        expect(fields[0].name, 'body');
        expect(fields[0].type?.accept(emitter).toString(), 'String');
        expect(fields[0].modifier, FieldModifier.final$);
      });

      test('has correct constructor with super calls', () {
        final constructor = plainClass.constructors.first;
        expect(constructor.constant, isTrue);

        final params = constructor.optionalParameters.toList();
        expect(params.length, 3);

        expect(params[0].name, 'contentType');
        expect(params[0].required, isTrue);
        expect(params[0].toSuper, isTrue);

        expect(params[1].name, 'bodyHeader');
        expect(params[1].required, isTrue);
        expect(params[1].toSuper, isTrue);

        expect(params[2].name, 'body');
        expect(params[2].required, isTrue);
        expect(params[2].toThis, isTrue);
      });

      group('generated methods', () {
        late List<Method> methods;

        setUp(() {
          methods = plainClass.methods.toList();
        });

        test('has equals method', () {
          final equals = methods.firstWhere((m) => m.name == 'operator ==');
          expect(equals, isNotNull);
          expect(equals.returns?.accept(emitter).toString(), 'bool');
        });

        test('has hashCode method', () {
          final hashCode = methods.firstWhere((m) => m.name == 'hashCode');
          expect(hashCode, isNotNull);
          expect(hashCode.returns?.accept(emitter).toString(), 'int');
        });

        test('has copyWith getter returning interface type', () {
          final copyWith = methods.firstWhere((m) => m.name == 'copyWith');
          expect(copyWith, isNotNull);
          expect(copyWith.type, MethodType.getter);
          expect(
            copyWith.returns?.accept(emitter).toString(),
            r'$$TestResponsePlainCopyWith<TestResponsePlain>',
          );
        });
      });
    });

    group('json implementation', () {
      late Class jsonClass;

      setUp(() {
        jsonClass = classesWithHeaders.whereType<Class>().firstWhere(
          (c) => c.name == 'TestResponseJson',
        );
      });

      test('has correct class definition', () {
        expect(jsonClass.name, 'TestResponseJson');
        expect(jsonClass.extend?.accept(emitter).toString(), 'TestResponse');
        expect(
          jsonClass.annotations.first.accept(emitter).toString(),
          'immutable',
        );
      });

      test('has correct body field', () {
        final fields = jsonClass.fields.toList();
        expect(fields.length, 1);
        expect(fields[0].name, 'body');
        expect(fields[0].type?.accept(emitter).toString(), 'int');
        expect(fields[0].modifier, FieldModifier.final$);
      });

      test('has correct constructor with super calls', () {
        final constructor = jsonClass.constructors.first;
        expect(constructor.constant, isTrue);

        final params = constructor.optionalParameters.toList();
        expect(params.length, 3);

        expect(params[0].name, 'contentType');
        expect(params[0].required, isTrue);
        expect(params[0].toSuper, isTrue);

        expect(params[1].name, 'bodyHeader');
        expect(params[1].required, isTrue);
        expect(params[1].toSuper, isTrue);

        expect(params[2].name, 'body');
        expect(params[2].required, isTrue);
        expect(params[2].toThis, isTrue);
      });

      group('generated methods', () {
        late List<Method> methods;

        setUp(() {
          methods = jsonClass.methods.toList();
        });

        test('has equals method', () {
          final equals = methods.firstWhere((m) => m.name == 'operator ==');
          expect(equals, isNotNull);
          expect(equals.returns?.accept(emitter).toString(), 'bool');
        });

        test('has hashCode method', () {
          final hashCode = methods.firstWhere((m) => m.name == 'hashCode');
          expect(hashCode, isNotNull);
          expect(hashCode.returns?.accept(emitter).toString(), 'int');
        });

        test('has copyWith getter returning interface type', () {
          final copyWith = methods.firstWhere((m) => m.name == 'copyWith');
          expect(copyWith, isNotNull);
          expect(copyWith.type, MethodType.getter);
          expect(
            copyWith.returns?.accept(emitter).toString(),
            r'$$TestResponseJsonCopyWith<TestResponseJson>',
          );
        });
      });
    });
  });

  group('response without headers', () {
    test('generates correct number of classes (main only, no copyWith)', () {
      // 3 main classes, no copyWith helpers since there are no header fields
      expect(classesWithoutHeaders.whereType<Class>().length, 3);
    });

    group('base sealed class', () {
      late Class baseClass;

      setUp(() {
        baseClass = classesWithoutHeaders.whereType<Class>().firstWhere(
          (c) => c.name == 'MultiContentResponse',
        );
      });

      test('has correct class definition', () {
        expect(baseClass.name, 'MultiContentResponse');
        expect(baseClass.sealed, isTrue);
        expect(
          baseClass.annotations.first.accept(emitter).toString(),
          'immutable',
        );
      });

      test('has no fields', () {
        expect(baseClass.fields.isEmpty, isTrue);
      });

      test('has empty constant constructor', () {
        final constructor = baseClass.constructors.first;
        expect(constructor.constant, isTrue);
        expect(constructor.optionalParameters.isEmpty, isTrue);
      });

      test('has no methods', () {
        expect(baseClass.methods.isEmpty, isTrue);
      });
    });

    group('json implementation', () {
      late Class jsonClass;

      setUp(() {
        jsonClass = classesWithoutHeaders.whereType<Class>().firstWhere(
          (c) => c.name == 'MultiContentResponseJson',
        );
      });

      test('has correct class definition', () {
        expect(jsonClass.name, 'MultiContentResponseJson');
        expect(
          jsonClass.extend?.accept(emitter).toString(),
          'MultiContentResponse',
        );
        expect(
          jsonClass.annotations.first.accept(emitter).toString(),
          'immutable',
        );
      });

      test('has correct body field', () {
        final fields = jsonClass.fields.toList();
        expect(fields.length, 1);
        expect(fields[0].name, 'body');
        expect(fields[0].type?.accept(emitter).toString(), 'String');
        expect(fields[0].modifier, FieldModifier.final$);
      });

      test('has constructor with only body parameter', () {
        final constructor = jsonClass.constructors.first;
        expect(constructor.constant, isTrue);

        final params = constructor.optionalParameters.toList();
        expect(params.length, 1);
        expect(params[0].name, 'body');
        expect(params[0].required, isTrue);
        expect(params[0].toThis, isTrue);
      });

      group('generated methods', () {
        late List<Method> methods;

        setUp(() {
          methods = jsonClass.methods.toList();
        });

        test('has equals method', () {
          final equals = methods.firstWhere((m) => m.name == 'operator ==');
          expect(equals, isNotNull);
          expect(equals.returns?.accept(emitter).toString(), 'bool');
        });

        test('has hashCode method', () {
          final hashCode = methods.firstWhere((m) => m.name == 'hashCode');
          expect(hashCode, isNotNull);
          expect(hashCode.returns?.accept(emitter).toString(), 'int');
          expect(hashCode.lambda, isTrue);
        });

        test('does not have copyWith method', () {
          expect(methods.any((m) => m.name == 'copyWith'), isFalse);
        });
      });
    });

    group('problem+json implementation', () {
      late Class problemJsonClass;

      setUp(() {
        problemJsonClass = classesWithoutHeaders.whereType<Class>().firstWhere(
          (c) => c.name == 'MultiContentResponseProblemJson',
        );
      });

      test('has correct class definition', () {
        expect(problemJsonClass.name, 'MultiContentResponseProblemJson');
        expect(
          problemJsonClass.extend?.accept(emitter).toString(),
          'MultiContentResponse',
        );
        expect(
          problemJsonClass.annotations.first.accept(emitter).toString(),
          'immutable',
        );
      });

      test('has correct body field', () {
        final fields = problemJsonClass.fields.toList();
        expect(fields.length, 1);
        expect(fields[0].name, 'body');
        expect(fields[0].type?.accept(emitter).toString(), 'String');
        expect(fields[0].modifier, FieldModifier.final$);
      });

      test('has constructor with only body parameter', () {
        final constructor = problemJsonClass.constructors.first;
        expect(constructor.constant, isTrue);

        final params = constructor.optionalParameters.toList();
        expect(params.length, 1);
        expect(params[0].name, 'body');
        expect(params[0].required, isTrue);
        expect(params[0].toThis, isTrue);
      });

      test('has equals and hashCode methods', () {
        final methods = problemJsonClass.methods.toList();
        expect(methods.any((m) => m.name == 'operator =='), isTrue);
        expect(methods.any((m) => m.name == 'hashCode'), isTrue);
      });
    });
  });
}
