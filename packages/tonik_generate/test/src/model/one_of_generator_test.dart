import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late OneOfGenerator generator;
  late NameManager nameManager;
  late NameGenerator nameGenerator;
  late Context context;
  late DartEmitter emitter;

  final format =
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(generator: nameGenerator);
    generator = OneOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  test('generated code does not include freezed part directive', () {
    final model = OneOfModel(
      name: 'Result',
      models: {
        (discriminatorValue: 'success', model: StringModel(context: context)),
      },
      discriminator: null,
      context: context,
    );

    final result = generator.generate(model);

    expect(result.code, isNotEmpty);
    expect(
      result.code.contains('.freezed.dart'),
      isFalse,
      reason: 'Generated code should not include a part directive for freezed',
    );
    expect(
      result.code.contains('part of'),
      isFalse,
      reason: 'Generated code should not include part directives',
    );
  });

  test('generates sealed class with standard constructor', () {
    final model = OneOfModel(
      name: 'Result',
      models: {
        (discriminatorValue: 'success', model: StringModel(context: context)),
      },
      discriminator: null,
      context: context,
    );

    final classes = generator.generateClasses(model);

    // Should have one sealed base class and one subclass
    expect(classes, hasLength(2));

    // Check base class
    final baseClass = classes.firstWhere((c) => c.name == 'Result');
    expect(baseClass.sealed, isTrue);

    // No freezed annotations
    expect(
      baseClass.annotations.any(
        (a) => a.code.accept(emitter).toString().contains('freezed'),
      ),
      isFalse,
      reason: 'Should not have freezed annotations',
    );

    // No mixins
    expect(baseClass.mixins, isEmpty, reason: 'Should not have freezed mixins');

    // Base class should have a default const constructor and
    // a fromSimple factory
    expect(baseClass.constructors.length, 3);
    final baseConstructor = baseClass.constructors.firstWhere(
      (c) => c.name == null,
    );
    expect(baseConstructor.constant, isTrue);
    expect(baseConstructor.factory, isFalse);

    final fromSimple = baseClass.constructors.firstWhere(
      (c) => c.name == 'fromSimple',
    );
    expect(fromSimple.factory, isTrue);
    expect(
      fromSimple.requiredParameters.first.type?.accept(emitter).toString(),
      'String?',
    );
    expect(fromSimple.optionalParameters.first.name, 'explode');
    expect(
      fromSimple.optionalParameters.first.type?.accept(emitter).toString(),
      'bool',
    );

    // Check success subclass
    final successClass = classes.firstWhere((c) => c.name == 'ResultSuccess');
    expect(successClass.extend?.symbol, 'Result');

    // Success subclass should have one constructor
    expect(successClass.constructors, hasLength(1));
    final successConstructor = successClass.constructors.first;
    expect(successConstructor.name, isNull);
    expect(successConstructor.constant, isTrue);

    // Success subclass should have a value field
    expect(successClass.fields, hasLength(1));
    final successField = successClass.fields.first;
    expect(successField.name, 'value');
    expect(successField.type?.accept(emitter).toString(), 'String');
    expect(successField.modifier, FieldModifier.final$);
  });

  test('generates subclasses for each model in oneOf', () {
    final model = OneOfModel(
      name: 'Result',
      models: {
        (discriminatorValue: 'success', model: StringModel(context: context)),
        (discriminatorValue: 'error', model: IntegerModel(context: context)),
      },
      discriminator: null,
      context: context,
    );

    final classes = generator.generateClasses(model);

    // Should have one sealed base class and two subclasses
    expect(classes, hasLength(3));

    // Check base class
    final baseClass = classes.firstWhere((c) => c.name == 'Result');
    expect(baseClass.sealed, isTrue);
    expect(baseClass.constructors.length, 3);
    expect(
      baseClass.constructors.firstWhere((c) => c.name == null).constant,
      isTrue,
    );
    expect(
      baseClass.constructors.firstWhere((c) => c.name == 'fromSimple').factory,
      isTrue,
    );

    // Check success subclass
    final successClass = classes.firstWhere((c) => c.name == 'ResultSuccess');
    expect(successClass.extend?.symbol, 'Result');
    expect(successClass.constructors, hasLength(1));
    expect(successClass.constructors.first.constant, isTrue);
    expect(successClass.fields, hasLength(1));
    expect(successClass.fields.first.name, 'value');
    expect(
      successClass.fields.first.type?.accept(emitter).toString(),
      'String',
    );

    // Check error subclass
    final errorClass = classes.firstWhere((c) => c.name == 'ResultError');
    expect(errorClass.extend?.symbol, 'Result');
    expect(errorClass.constructors, hasLength(1));
    expect(errorClass.constructors.first.constant, isTrue);
    expect(errorClass.fields, hasLength(1));
    expect(errorClass.fields.first.name, 'value');
    expect(errorClass.fields.first.type?.accept(emitter).toString(), 'int');
  });

  test('uses model name when discriminator value is not available', () {
    final model = OneOfModel(
      name: 'Result',
      models: {
        (
          discriminatorValue: null,
          model: ClassModel(
            name: 'Success',
            properties: const [],
            context: context,
          ),
        ),
        (
          discriminatorValue: null,
          model: ClassModel(
            name: 'Error',
            properties: const [],
            context: context,
          ),
        ),
      },
      discriminator: null,
      context: context,
    );

    final classes = generator.generateClasses(model);

    // Should have one sealed base class and two subclasses
    expect(classes, hasLength(3));

    // Check base class
    final baseClass = classes.firstWhere((c) => c.name == 'Result');
    expect(baseClass.sealed, isTrue);
    expect(baseClass.constructors.length, 3);
    expect(
      baseClass.constructors.firstWhere((c) => c.name == null).constant,
      isTrue,
    );
    expect(
      baseClass.constructors.firstWhere((c) => c.name == 'fromSimple').factory,
      isTrue,
    );

    // Check success subclass (should be named after the model)
    final successClass = classes.firstWhere((c) => c.name == 'ResultSuccess');
    expect(successClass.extend?.symbol, 'Result');
    expect(successClass.constructors, hasLength(1));

    // Check error subclass (should be named after the model)
    final errorClass = classes.firstWhere((c) => c.name == 'ResultError');
    expect(errorClass.extend?.symbol, 'Result');
    expect(errorClass.constructors, hasLength(1));
  });

  test('handles nested models correctly', () {
    final model = OneOfModel(
      name: 'Result',
      models: {
        (
          discriminatorValue: 'data',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
          ),
        ),
      },
      discriminator: null,
      context: context,
    );

    final classes = generator.generateClasses(model);

    // Should have one sealed base class and one subclass
    expect(classes, hasLength(2));

    // Check base class
    final baseClass = classes.firstWhere((c) => c.name == 'Result');
    expect(baseClass.sealed, isTrue);
    expect(baseClass.constructors.length, 3);
    expect(
      baseClass.constructors.firstWhere((c) => c.name == null).constant,
      isTrue,
    );
    expect(
      baseClass.constructors.firstWhere((c) => c.name == 'fromSimple').factory,
      isTrue,
    );

    // Check data subclass with proper list type
    final dataClass = classes.firstWhere((c) => c.name == 'ResultData');
    expect(dataClass.extend?.symbol, 'Result');
    expect(dataClass.constructors, hasLength(1));
    expect(dataClass.constructors.first.constant, isTrue);
    expect(dataClass.fields, hasLength(1));
    expect(dataClass.fields.first.name, 'value');
    expect(
      dataClass.fields.first.type?.accept(emitter).toString(),
      'List<String>',
    );
  });

  test('fromJson factory includes proper catch clause with on Object', () {
    final model = OneOfModel(
      name: 'TestOneOf',
      models: {
        (
          discriminatorValue: null,
          model: ClassModel(
            name: 'TestClass',
            properties: const [],
            context: context,
          ),
        ),
      },
      discriminator: null,
      context: context,
    );

    final classes = generator.generateClasses(model);
    final baseClass = classes.firstWhere((c) => c.name == 'TestOneOf');
    final generatedCode = format(baseClass.accept(emitter).toString());
    expect(
      collapseWhitespace(generatedCode),
      contains(collapseWhitespace('factory TestOneOf.fromJson(Object? json)')),
    );
    expect(
      collapseWhitespace(generatedCode),
      contains(collapseWhitespace('on Object catch (_) {}')),
    );
  });

  group('simpleProperties generation', () {
    test('generates simpleProperties delegating for class-only variants', () {
      final classA = ClassModel(
        name: 'A',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );
      final classB = ClassModel(
        name: 'B',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final model = OneOfModel(
        name: 'Choice',
        models: {
          (discriminatorValue: 'a', model: classA),
          (discriminatorValue: 'b', model: classB),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Choice');

      final simpleProps = baseClass.methods.firstWhere(
        (m) => m.name == 'simpleProperties',
      );
      expect(
        simpleProps.returns?.accept(emitter).toString(),
        'Map<String,String>',
      );
      expect(simpleProps.optionalParameters, hasLength(1));
      expect(simpleProps.optionalParameters.first.name, 'allowEmpty');
      expect(simpleProps.optionalParameters.first.required, isTrue);

      final generated = format(baseClass.accept(emitter).toString());
      const expectedMethod = '''
        Map<String, String> simpleProperties({required bool allowEmpty}) {
          return switch (this) {
            ChoiceA(:final value) => value.simpleProperties(allowEmpty: allowEmpty),
            ChoiceB(:final value) => value.simpleProperties(allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test(
      'generates simpleProperties empty map for primitive-only variants',
      () {
        final model = OneOfModel(
          name: 'PrimitiveChoice',
          models: {
            (discriminatorValue: 'i', model: IntegerModel(context: context)),
            (discriminatorValue: 's', model: StringModel(context: context)),
          },
          discriminator: null,
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere(
          (c) => c.name == 'PrimitiveChoice',
        );
        final generated = format(baseClass.accept(emitter).toString());

        final simpleProps = baseClass.methods.firstWhere(
          (m) => m.name == 'simpleProperties',
        );
        expect(
          simpleProps.returns?.accept(emitter).toString(),
          'Map<String,String>',
        );
        expect(simpleProps.optionalParameters.first.required, isTrue);

        const expectedMethod = '''
        Map<String, String> simpleProperties({required bool allowEmpty}) {
          return switch (this) {
            PrimitiveChoiceI(:final value) => <String, String>{},
            PrimitiveChoiceS(:final value) => <String, String>{},
          };
        }
      ''';
        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test('generates simpleProperties mixing class and primitive variants', () {
      final classM = ClassModel(
        name: 'M',
        properties: [
          Property(
            name: 'flag',
            model: BooleanModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final model = OneOfModel(
        name: 'MixedChoice',
        models: {
          (discriminatorValue: 'm', model: classM),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        discriminator: 'kind',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'MixedChoice');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        Map<String, String> simpleProperties({required bool allowEmpty}) {
          return switch (this) {
            MixedChoiceM(:final value) => value.simpleProperties(allowEmpty: allowEmpty),
            MixedChoiceS(:final value) => <String, String>{},
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });
  });

  group('subclass equals', () {
    test('generates equals method for primitive type', () {
      final model = OneOfModel(
        name: 'Result',
        models: {
          (discriminatorValue: 'success', model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final classes = generator.generateClasses(model);
      final successClass = classes.firstWhere((c) => c.name == 'ResultSuccess');

      const expectedClass = '''
        @immutable
        class ResultSuccess extends Result {
          const ResultSuccess(this.value);

          final String value;

          @override
          bool operator ==(Object other) {
            if (identical(this, other)) return true;
            return other is ResultSuccess && other.value == value;
          }

          @override
          int get hashCode => value.hashCode;
        }
      ''';

      expect(
        collapseWhitespace(format(successClass.accept(emitter).toString())),
        collapseWhitespace(format(expectedClass)),
      );
    });

    test('generates equals method for collection type', () {
      final model = OneOfModel(
        name: 'Result',
        models: {
          (
            discriminatorValue: 'strings',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
          ),
        },
        discriminator: null,
        context: context,
      );

      final classes = generator.generateClasses(model);
      final listClass = classes.firstWhere((c) => c.name == 'ResultStrings');

      const expectedMethod = r'''
        @immutable
        class ResultStrings extends Result {
          const ResultStrings(this.value);
          final List<String> value;
          
          @override
          bool operator ==(Object other) {
            if (identical(this, other)) return true;
            const _$deepEquals = DeepCollectionEquality();
            return other is ResultStrings && _$deepEquals.equals(other.value, value);
          }
          
          @override
          int get hashCode {
            const deepEquals = DeepCollectionEquality();
            return deepEquals.hash(value);
          }
        }
      ''';

      expect(
        collapseWhitespace(format(listClass.accept(emitter).toString())),
        collapseWhitespace(format(expectedMethod)),
      );
    });
  });
}
