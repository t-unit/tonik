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

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = OneOfGenerator(
      nameManager: nameManager,
      package: 'example',
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  test('generates simple encoding shape getter for primitive oneOf', () {
    final model = OneOfModel(
      isDeprecated: false,
      name: 'Value',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (discriminatorValue: null, model: IntegerModel(context: context)),
      },
      context: context,
    );

    final classes = generator.generateClasses(model);
    final baseClass = classes.firstWhere((c) => c.name == 'Value');
    final generated = format(baseClass.accept(emitter).toString());

    const expectedGetter = '''
      EncodingShape get currentEncodingShape {
        return switch (this) {
          ValueInt() => EncodingShape.simple,
          ValueString() => EncodingShape.simple,
        };
      }
    ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedGetter)),
    );
  });

  test('generates complex encoding shape getter for class oneOf', () {
    final classA = ClassModel(
      isDeprecated: false,
      name: 'A',
      properties: const [],
      context: context,
    );
    final classB = ClassModel(
      isDeprecated: false,
      name: 'B',
      properties: const [],
      context: context,
    );

    final model = OneOfModel(
      isDeprecated: false,
      name: 'Value',
      models: {
        (discriminatorValue: null, model: classA),
        (discriminatorValue: null, model: classB),
      },
      context: context,
    );

    final classes = generator.generateClasses(model);
    final baseClass = classes.firstWhere((c) => c.name == 'Value');
    final generated = format(baseClass.accept(emitter).toString());

    const expectedGetter = '''
      EncodingShape get currentEncodingShape {
        return switch (this) {
          ValueA(:final value) => value.currentEncodingShape,
          ValueB(:final value) => value.currentEncodingShape,
        };
      }
    ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedGetter)),
    );
  });

  group('doc comments', () {
    test('generates sealed class with doc comment from description', () {
      final model = OneOfModel(
        isDeprecated: false,
        description: 'Represents either a string or an integer value',
        name: 'Value',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      expect(
        baseClass.docs,
        ['/// Represents either a string or an integer value'],
      );
    });

    test('generates sealed class with multiline doc comment', () {
      final model = OneOfModel(
        isDeprecated: false,
        description: 'A flexible value type.\nCan be string or integer.',
        name: 'Value',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      expect(baseClass.docs, [
        '/// A flexible value type.',
        '/// Can be string or integer.',
      ]);
    });

    test(
      'generates sealed class without doc comment when description is null',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');

        expect(baseClass.docs, isEmpty);
      },
    );

    test(
      'generates sealed class without doc comment when description is empty',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          description: '',
          name: 'Value',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: IntegerModel(context: context)),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');

        expect(baseClass.docs, isEmpty);
      },
    );
  });

  test(
    'generates sealed class implementing ParameterEncodable & UriEncodable',
    () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      expect(baseClass.implements.length, 2);
      expect(
        baseClass.implements.map((e) => e.accept(emitter).toString()).toSet(),
        {'ParameterEncodable', 'UriEncodable'},
      );
    },
  );

  test('generates mixed encoding shape getter for mixed oneOf', () {
    final classA = ClassModel(
      isDeprecated: false,
      name: 'A',
      properties: const [],
      context: context,
    );

    final model = OneOfModel(
      isDeprecated: false,
      name: 'Value',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (discriminatorValue: null, model: classA),
      },
      context: context,
    );

    final classes = generator.generateClasses(model);
    final baseClass = classes.firstWhere((c) => c.name == 'Value');
    final generated = format(baseClass.accept(emitter).toString());

    const expectedGetter = '''
      EncodingShape get currentEncodingShape {
        return switch (this) {
          ValueA(:final value) => value.currentEncodingShape,
          ValueString() => EncodingShape.simple,
        };
      }
    ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedGetter)),
    );
  });

  test('generates sealed class with standard constructor', () {
    final model = OneOfModel(
      isDeprecated: false,
      name: 'Result',
      models: {
        (discriminatorValue: 'success', model: StringModel(context: context)),
      },
      context: context,
    );

    final classes = generator.generateClasses(model);

    // Should have one sealed base class and one subclass
    expect(classes, hasLength(2));

    // Check base class
    final baseClass = classes.firstWhere((c) => c.name == 'Result');
    expect(baseClass.sealed, isTrue);

    // Base class should have a default const constructor,
    // fromSimple, fromForm, and fromJson factories
    expect(baseClass.constructors.length, 4);
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
      isDeprecated: false,
      name: 'Result',
      models: {
        (discriminatorValue: 'success', model: StringModel(context: context)),
        (discriminatorValue: 'error', model: IntegerModel(context: context)),
      },
      context: context,
    );

    final classes = generator.generateClasses(model);

    // Should have one sealed base class and two subclasses
    expect(classes, hasLength(3));

    // Check base class
    final baseClass = classes.firstWhere((c) => c.name == 'Result');
    expect(baseClass.sealed, isTrue);
    expect(baseClass.constructors.length, 4);
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
      isDeprecated: false,
      name: 'Result',
      models: {
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            name: 'Success',
            properties: const [],
            context: context,
          ),
        ),
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            name: 'Error',
            properties: const [],
            context: context,
          ),
        ),
      },
      context: context,
    );

    final classes = generator.generateClasses(model);

    // Should have one sealed base class and two subclasses
    expect(classes, hasLength(3));

    // Check base class
    final baseClass = classes.firstWhere((c) => c.name == 'Result');
    expect(baseClass.sealed, isTrue);
    expect(baseClass.constructors.length, 4);
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
      isDeprecated: false,
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
      context: context,
    );

    final classes = generator.generateClasses(model);

    // Should have one sealed base class and one subclass
    expect(classes, hasLength(2));

    // Check base class
    final baseClass = classes.firstWhere((c) => c.name == 'Result');
    expect(baseClass.sealed, isTrue);
    expect(baseClass.constructors.length, 4);
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
      isDeprecated: false,
      name: 'TestOneOf',
      models: {
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            name: 'TestClass',
            properties: const [],
            context: context,
          ),
        ),
      },
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

  group('subclass equals', () {
    test('generates equals method for primitive type', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Result',
        models: {
          (discriminatorValue: 'success', model: StringModel(context: context)),
        },
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
            return other is ResultSuccess && other.value == this.value;
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
        isDeprecated: false,
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
            return other is ResultStrings && _$deepEquals.equals(other.value, this.value);
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

  group('subclass names', () {
    test('generates meaningful names for primitive models', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
          (discriminatorValue: null, model: BooleanModel(context: context)),
          (discriminatorValue: null, model: DateTimeModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final classNames = classes.map((c) => c.name).toList();

      expect(classNames, contains('ValueString'));
      expect(classNames, contains('ValueInt'));
      expect(classNames, contains('ValueBool'));
      expect(classNames, contains('ValueDateTime'));
    });

    test('generates meaningful names for complex models', () {
      final classA = ClassModel(
        isDeprecated: false,
        name: 'ClassA',
        properties: const [],
        context: context,
      );
      final allOfModel = AllOfModel(
        isDeprecated: false,
        name: 'AllOfExample',
        models: {classA},
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (discriminatorValue: null, model: classA),
          (discriminatorValue: null, model: allOfModel),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final classNames = classes.map((c) => c.name).toList();

      expect(classNames, contains('ValueClassA'));
      expect(classNames, contains('ValueAllOfExample'));
    });

    test('generates meaningful names for alias models', () {
      final aliasModel = AliasModel(
        name: 'user-profile',
        model: StringModel(context: context),
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (discriminatorValue: null, model: aliasModel),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final classNames = classes.map((c) => c.name).toList();

      expect(classNames, contains('ValueUserProfile'));
    });
  });

  group('parameterProperties', () {
    test('method exists with correct signature', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      final method = baseClass.methods.firstWhere(
        (m) => m.name == 'parameterProperties',
        orElse: () => throw StateError('parameterProperties method not found'),
      );

      expect(method.name, 'parameterProperties');
      expect(
        method.returns?.accept(emitter).toString().replaceAll(' ', ''),
        'Map<String,String>',
      );
      expect(method.optionalParameters.length, 2);

      final allowEmptyParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'allowEmpty',
      );
      expect(allowEmptyParam.named, isTrue);
      expect(allowEmptyParam.required, isFalse);
      expect(
        allowEmptyParam.defaultTo?.accept(emitter).toString(),
        'true',
      );
      expect(
        allowEmptyParam.type?.accept(emitter).toString(),
        'bool',
      );

      final allowListsParam = method.optionalParameters.firstWhere(
        (p) => p.name == 'allowLists',
      );
      expect(allowListsParam.named, isTrue);
      expect(allowListsParam.required, isFalse);
      expect(
        allowListsParam.defaultTo?.accept(emitter).toString(),
        'true',
      );
      expect(
        allowListsParam.type?.accept(emitter).toString(),
        'bool',
      );
    });

    test('throws for primitive-only oneOf', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      const expectedMethod = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
        }) =>
          throw EncodingException(
            r'parameterProperties not supported for Value: only contains primitive types',
          );
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('delegates to value for complex variant without discriminator', () {
      final userModel = ClassModel(
        isDeprecated: false,
        name: 'User',
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
        isDeprecated: false,
        name: 'Response',
        models: {
          (discriminatorValue: null, model: userModel),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Response');

      const expectedMethod = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
        }) {
          return switch (this) {
            ResponseUser(:final value) => value.parameterProperties(
              allowEmpty: allowEmpty,
              allowLists: allowLists,
            ),
          };
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('injects discriminator for complex variant with discriminator', () {
      final userModel = ClassModel(
        isDeprecated: false,
        name: 'User',
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

      final companyModel = ClassModel(
        isDeprecated: false,
        name: 'Company',
        properties: [
          Property(
            name: 'title',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Entity',
        models: {
          (discriminatorValue: 'person', model: userModel),
          (discriminatorValue: 'company', model: companyModel),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Entity');

      const expectedMethod = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
        }) {
          return switch (this) {
            EntityCompany(:final value) => {
              ...value.parameterProperties(
                allowEmpty: allowEmpty,
                allowLists: allowLists,
              ),
              r'type': r'company',
            },
            EntityUser(:final value) => {
              ...value.parameterProperties(
                allowEmpty: allowEmpty,
                allowLists: allowLists,
              ),
              r'type': r'person',
            },
          };
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'throws at runtime for mixed primitive/complex without discriminator',
      () {
        final userModel = ClassModel(
          isDeprecated: false,
          name: 'User',
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
          isDeprecated: false,
          name: 'Value',
          models: {
            (discriminatorValue: null, model: userModel),
            (discriminatorValue: null, model: StringModel(context: context)),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');

        const expectedMethod = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
        }) {
          return switch (this) {
            ValueUser(:final value) => value.parameterProperties(
              allowEmpty: allowEmpty,
              allowLists: allowLists,
            ),
            ValueString() => throw EncodingException(
              r'parameterProperties not supported for Value: cannot determine properties at runtime',
            ),
          };
        }
      ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'throws at runtime for mixed primitive/complex with discriminator',
      () {
        final userModel = ClassModel(
          isDeprecated: false,
          name: 'User',
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
          isDeprecated: false,
          name: 'Response',
          models: {
            (discriminatorValue: 'user', model: userModel),
            (
              discriminatorValue: 'message',
              model: StringModel(context: context),
            ),
          },
          discriminator: 'type',
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Response');

        const expectedMethod = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
        }) {
          return switch (this) {
            ResponseMessage() => throw EncodingException(
              r'parameterProperties not supported for Response: cannot determine properties at runtime',
            ),
            ResponseUser(:final value) => {
              ...value.parameterProperties(
                allowEmpty: allowEmpty,
                allowLists: allowLists,
              ),
              r'type': r'user',
            },
          };
        }
      ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'checks runtime encoding shape for mixed-encoded variant without '
      'discriminator',
      () {
        final innerOneOf = OneOfModel(
          isDeprecated: false,
          name: 'Inner',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'Data',
                properties: [
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
                context: context,
              ),
            ),
          },
          context: context,
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Outer',
          models: {
            (discriminatorValue: null, model: innerOneOf),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Outer');

        const expectedMethod = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
        }) {
          return switch (this) {
            OuterInner(:final value) => value.currentEncodingShape == EncodingShape.complex
              ? value.parameterProperties(
                  allowEmpty: allowEmpty,
                  allowLists: allowLists,
                )
              : throw EncodingException(
                  r'parameterProperties not supported for Outer: cannot determine properties at runtime',
                ),
          };
        }
      ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'checks runtime encoding shape for mixed-encoded variant with '
      'discriminator',
      () {
        final innerOneOf = OneOfModel(
          isDeprecated: false,
          name: 'Inner',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'Data',
                properties: [
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
                context: context,
              ),
            ),
          },
          context: context,
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Outer',
          models: {
            (discriminatorValue: 'inner', model: innerOneOf),
          },
          discriminator: 'type',
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Outer');

        const expectedMethod = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
        }) {
          return switch (this) {
            OuterInner(:final value) => value.currentEncodingShape == EncodingShape.complex
              ? {
                  ...value.parameterProperties(
                    allowEmpty: allowEmpty,
                    allowLists: allowLists,
                  ),
                  r'type': r'inner',
                }
              : throw EncodingException(
                  r'parameterProperties not supported for Outer: cannot determine properties at runtime',
                ),
          };
        }
      ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  test('uses stable sorting for discriminated models', () {
    final sharedContext = context.push('TestOneOf').push('oneOf');

    final model = OneOfModel(
      isDeprecated: false,
      name: 'TestOneOf',
      models: {
        (
          discriminatorValue: 'zebra',
          model: StringModel(context: sharedContext),
        ),
        (
          discriminatorValue: 'apple',
          model: IntegerModel(context: sharedContext),
        ),
        (
          discriminatorValue: 'banana',
          model: BooleanModel(context: sharedContext),
        ),
      },
      discriminator: 'type',
      context: context.push('TestOneOf'),
    );

    nameManager.prime(
      models: {model},
      requestBodies: const [],
      responses: const [],
      operations: const [],
      tags: const [],
      servers: const [],
    );

    final classes = generator.generateClasses(model);
    final variantNames = classes
        .where((c) => c.name != 'TestOneOf')
        .map((c) => c.name)
        .toList();

    // Verify variants are in stable sorted order by discriminator value.
    expect(variantNames, [
      'TestOneOfApple',
      'TestOneOfBanana',
      'TestOneOfZebra',
    ]);
  });

  group('nullable oneOf', () {
    test('generates Raw-prefixed sealed class for nullable oneOf', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Pet',
        models: {
          (
            discriminatorValue: null,
            model: ClassModel(
              isDeprecated: false,
              name: 'Cat',
              properties: const [],
              context: context,
            ),
          ),
          (
            discriminatorValue: null,
            model: ClassModel(
              isDeprecated: false,
              name: 'Dog',
              properties: const [],
              context: context,
            ),
          ),
        },
        context: context,
        isNullable: true,
      );

      nameManager.prime(
        models: {model},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      final classes = generator.generateClasses(model, r'$RawPet');
      final baseClass = classes.first;

      // Verify the sealed class uses Raw prefix.
      expect(baseClass.name, r'$RawPet');
      expect(baseClass.sealed, isTrue);
    });

    test('generates normal sealed class for non-nullable oneOf', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Pet',
        models: {
          (
            discriminatorValue: null,
            model: ClassModel(
              isDeprecated: false,
              name: 'Cat',
              properties: const [],
              context: context,
            ),
          ),
          (
            discriminatorValue: null,
            model: ClassModel(
              isDeprecated: false,
              name: 'Dog',
              properties: const [],
              context: context,
            ),
          ),
        },
        context: context,
      );

      nameManager.prime(
        models: {model},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.first;

      // Verify the sealed class uses the normal name (no Raw prefix).
      expect(baseClass.name, 'Pet');
      expect(baseClass.sealed, isTrue);
    });

    test('generate method creates typedef for nullable oneOf', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Response',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
        isNullable: true,
      );

      nameManager.prime(
        models: {model},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      final result = generator.generate(model);
      final formatted = format(result.code);

      // Verify typedef exists pointing to nullable Raw class.
      expect(
        collapseWhitespace(formatted),
        contains(collapseWhitespace(r'typedef Response = $RawResponse?;')),
      );
    });

    test('generate method does not create typedef for non-nullable oneOf', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Response',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );

      nameManager.prime(
        models: {model},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      final result = generator.generate(model);

      // Verify no typedef is generated.
      expect(result.code, isNot(contains('typedef')));
    });
  });

  test('encoding methods have @override annotation', () {
    final model = OneOfModel(
      isDeprecated: false,
      name: 'TestOneOf',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (discriminatorValue: null, model: IntegerModel(context: context)),
      },
      context: context,
    );

    final classes = generator.generateClasses(model);
    final baseClass = classes.firstWhere((c) => c.name == 'TestOneOf');

    final encodingMethods = [
      'toSimple',
      'toForm',
      'toLabel',
      'toMatrix',
      'toDeepObject',
      'toJson',
    ];

    for (final methodName in encodingMethods) {
      final method = baseClass.methods.firstWhere(
        (m) => m.name == methodName,
        orElse: () => throw StateError('Method $methodName not found'),
      );

      expect(
        method.annotations.any(
          (a) => a.accept(emitter).toString().contains('override'),
        ),
        isTrue,
        reason: '$methodName should have @override annotation',
      );
    }
  });

  group('uriEncode', () {
    test('generates uriEncode method with useQueryComponent parameter', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'StringOrNumber',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );

      nameManager.prime(
        models: {model},
        requestBodies: const <RequestBody>[],
        responses: const <Response>[],
        operations: const <Operation>[],
        tags: const <Tag>[],
        servers: const <Server>[],
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'StringOrNumber');
      final uriEncodeMethod = baseClass.methods.firstWhere(
        (m) => m.name == 'uriEncode',
      );

      expect(uriEncodeMethod.optionalParameters, hasLength(2));

      final allowEmptyParam = uriEncodeMethod.optionalParameters.firstWhere(
        (p) => p.name == 'allowEmpty',
      );
      expect(allowEmptyParam.type?.accept(DartEmitter()).toString(), 'bool');
      expect(allowEmptyParam.named, isTrue);
      expect(allowEmptyParam.required, isTrue);

      final useQueryComponentParam = uriEncodeMethod.optionalParameters
          .firstWhere((p) => p.name == 'useQueryComponent');
      expect(
        useQueryComponentParam.type?.accept(DartEmitter()).toString(),
        'bool',
      );
      expect(useQueryComponentParam.named, isTrue);
      expect(useQueryComponentParam.required, isFalse);
      expect(
        useQueryComponentParam.defaultTo?.accept(DartEmitter()).toString(),
        'false',
      );
    });
  });

  group('toForm', () {
    test('generates toForm method with useQueryComponent parameter', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      final toFormMethod = baseClass.methods.firstWhere(
        (m) => m.name == 'toForm',
      );

      expect(toFormMethod.optionalParameters.length, 3);

      final explodeParam = toFormMethod.optionalParameters.firstWhere(
        (p) => p.name == 'explode',
      );
      expect(explodeParam.type?.accept(DartEmitter()).toString(), 'bool');
      expect(explodeParam.named, isTrue);
      expect(explodeParam.required, isTrue);

      final allowEmptyParam = toFormMethod.optionalParameters.firstWhere(
        (p) => p.name == 'allowEmpty',
      );
      expect(allowEmptyParam.type?.accept(DartEmitter()).toString(), 'bool');
      expect(allowEmptyParam.named, isTrue);
      expect(allowEmptyParam.required, isTrue);

      final useQueryComponentParam = toFormMethod.optionalParameters.firstWhere(
        (p) => p.name == 'useQueryComponent',
      );
      expect(
        useQueryComponentParam.type?.accept(DartEmitter()).toString(),
        'bool',
      );
      expect(useQueryComponentParam.named, isTrue);
      expect(useQueryComponentParam.required, isFalse);
      expect(
        useQueryComponentParam.defaultTo?.accept(DartEmitter()).toString(),
        'false',
      );
    });
  });

  group('ListModel handling', () {
    test('currentEncodingShape returns complex for ListModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
          ),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      final generated = format(baseClass.accept(emitter).toString());

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace('''
            EncodingShape get currentEncodingShape {
              return switch (this) {
                ValueInt() => EncodingShape.simple,
                ValueList() => EncodingShape.complex,
              };
            }
          '''),
        ),
      );
    });

    test('fromSimple uses decode helpers for ListModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
          ),
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      final generated = format(baseClass.accept(emitter).toString());

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace('''
            factory Value.fromSimple(String? value, {required bool explode}) {
              try {
                return ValueList(value.decodeSimpleStringList(context: r'Value'));
              } on DecodingException catch (_) {
              } on FormatException catch (_) {}
              try {
                return ValueString(value.decodeSimpleString(context: r'Value'));
              } on DecodingException catch (_) {
              } on FormatException catch (_) {}
              throw SimpleDecodingException(r'Invalid simple value for Value');
            }
          '''),
        ),
      );
    });

    test('fromForm uses decode helpers for ListModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
          ),
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      final generated = format(baseClass.accept(emitter).toString());

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace('''
            factory Value.fromForm(String? value, {required bool explode}) {
              try {
                return ValueList(value.decodeFormStringList(context: r'Value'));
              } on DecodingException catch (_) {
              } on FormatException catch (_) {}
              try {
                return ValueString(value.decodeFormString(context: r'Value'));
              } on DecodingException catch (_) {
              } on FormatException catch (_) {}
              throw SimpleDecodingException(r'Invalid form value for Value');
            }
          '''),
        ),
      );
    });

    test('fromJson uses decode helpers for ListModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
          ),
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      final generated = format(baseClass.accept(emitter).toString());

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace('''
            factory Value.fromJson(Object? json) {
              if (json is String) {
                return ValueString(json);
              }
              try {
                return ValueList(json.decodeJsonList<String>(context: r'Value'));
              } on Object catch (_) {}
              throw JsonDecodingException(r'Invalid JSON for Value');
            }
          '''),
        ),
      );
    });

    test('throws for ListModel with complex content in simple encoding', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: ListModel(
              content: ClassModel(
                properties: const [],
                context: context,
                isDeprecated: false,
              ),
              context: context,
            ),
          ),
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      final generated = format(baseClass.accept(emitter).toString());

      // Complex ListModel variant should throw SimpleDecodingException
      // instead of being silently excluded
      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace(
            'throw SimpleDecodingException(\n'
            "r'List types with complex content cannot be decoded "
            "from simple encoding in Value',\n);",
          ),
        ),
      );
    });

    test('parameterProperties throws exception for ListModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
          ),
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Value');

      final generated = format(baseClass.accept(emitter).toString());

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace('''
            Map<String, String> parameterProperties({
              bool allowEmpty = true,
              bool allowLists = true,
            }) {
              return switch (this) {
                ValueList() => throw EncodingException(
                  'Lists are not supported in parameterProperties',
                ),
                ValueString() => throw EncodingException(
                  r'parameterProperties not supported for Value: cannot determine properties at runtime',
                ),
              };
            }
          '''),
        ),
      );
    });

    test(
      'fromSimple with discriminator excludes ListModel from '
      'discriminator dispatch',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          discriminator: 'type',
          models: {
            (
              discriminatorValue: 'list',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
            ),
            (
              discriminatorValue: 'str',
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        // ListModel should NOT appear in the discriminator dispatch block
        // and should only be handled via the try/catch decode path
        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace('''
              factory Value.fromSimple(String? value, {required bool explode}) {
                try {
                  return ValueList(value.decodeSimpleStringList(context: r'Value'));
                } on DecodingException catch (_) {
                } on FormatException catch (_) {}
                try {
                  return ValueStr(value.decodeSimpleString(context: r'Value'));
                } on DecodingException catch (_) {
                } on FormatException catch (_) {}
                throw SimpleDecodingException(r'Invalid simple value for Value');
              }
            '''),
          ),
        );
      },
    );

    test(
      'fromForm with discriminator excludes ListModel from '
      'discriminator dispatch',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          discriminator: 'type',
          models: {
            (
              discriminatorValue: 'list',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
            ),
            (
              discriminatorValue: 'str',
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace('''
              factory Value.fromForm(String? value, {required bool explode}) {
                try {
                  return ValueList(value.decodeFormStringList(context: r'Value'));
                } on DecodingException catch (_) {
                } on FormatException catch (_) {}
                try {
                  return ValueStr(value.decodeFormString(context: r'Value'));
                } on DecodingException catch (_) {
                } on FormatException catch (_) {}
                throw SimpleDecodingException(r'Invalid form value for Value');
              }
            '''),
          ),
        );
      },
    );

    test(
      'toSimple with discriminator and ListModel with simple content '
      'uses buildSimpleParameterExpression',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          discriminator: 'type',
          models: {
            (
              discriminatorValue: 'list',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
            ),
            (
              discriminatorValue: 'str',
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace('''
              @override
              String toSimple({required bool explode, required bool allowEmpty}) {
                return switch (this) {
                  ValueList(:final value) => value.toSimple(
                    explode: explode,
                    allowEmpty: allowEmpty,
                  ),
                  ValueStr(:final value) => value.toSimple(
                    explode: explode,
                    allowEmpty: allowEmpty,
                  ),
                };
              }
            '''),
          ),
        );
      },
    );

    test(
      'toSimple with discriminator and ListModel with complex content '
      'throws EncodingException',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          discriminator: 'type',
          models: {
            (
              discriminatorValue: 'list',
              model: ListModel(
                content: ClassModel(
                  properties: const [],
                  context: context,
                  isDeprecated: false,
                ),
                context: context,
              ),
            ),
            (
              discriminatorValue: 'str',
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace('''
              @override
              String toSimple({required bool explode, required bool allowEmpty}) {
                return switch (this) {
                  ValueList() => throw EncodingException(
                    'Lists with complex content are not supported for encoding',
                  ),
                  ValueStr(:final value) => value.toSimple(
                    explode: explode,
                    allowEmpty: allowEmpty,
                  ),
                };
              }
            '''),
          ),
        );
      },
    );

    test(
      'toForm with discriminator and ListModel with simple content '
      'uses buildFormParameterExpression',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          discriminator: 'type',
          models: {
            (
              discriminatorValue: 'list',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
            ),
            (
              discriminatorValue: 'str',
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace('''
              @override
              String toForm({
                required bool explode,
                required bool allowEmpty,
                bool useQueryComponent = false,
              }) {
                return switch (this) {
                  ValueList(:final value) => value.toForm(
                    explode: explode,
                    allowEmpty: allowEmpty,
                  ),
                  ValueStr(:final value) => value.toForm(
                    explode: explode,
                    allowEmpty: allowEmpty,
                    useQueryComponent: useQueryComponent,
                  ),
                };
              }
            '''),
          ),
        );
      },
    );

    test(
      'toForm with discriminator and ListModel with complex content '
      'throws EncodingException',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          discriminator: 'type',
          models: {
            (
              discriminatorValue: 'list',
              model: ListModel(
                content: ClassModel(
                  properties: const [],
                  context: context,
                  isDeprecated: false,
                ),
                context: context,
              ),
            ),
            (
              discriminatorValue: 'str',
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace('''
              @override
              String toForm({
                required bool explode,
                required bool allowEmpty,
                bool useQueryComponent = false,
              }) {
                return switch (this) {
                  ValueList() => throw EncodingException(
                    'Lists with complex content are not supported for encoding',
                  ),
                  ValueStr(:final value) => value.toForm(
                    explode: explode,
                    allowEmpty: allowEmpty,
                    useQueryComponent: useQueryComponent,
                  ),
                };
              }
            '''),
          ),
        );
      },
    );

    test(
      'toLabel with discriminator and ListModel with simple content '
      'uses buildLabelParameterExpression',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          discriminator: 'type',
          models: {
            (
              discriminatorValue: 'list',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
            ),
            (
              discriminatorValue: 'str',
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace('''
              @override
              String toLabel({required bool explode, required bool allowEmpty}) {
                return switch (this) {
                  ValueList(:final value) => value.toLabel(
                    explode: explode,
                    allowEmpty: allowEmpty,
                  ),
                  ValueStr(:final value) => value.toLabel(
                    explode: explode,
                    allowEmpty: allowEmpty,
                  ),
                };
              }
            '''),
          ),
        );
      },
    );

    test(
      'toLabel with discriminator and ListModel with complex content '
      'throws EncodingException',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          discriminator: 'type',
          models: {
            (
              discriminatorValue: 'list',
              model: ListModel(
                content: ClassModel(
                  properties: const [],
                  context: context,
                  isDeprecated: false,
                ),
                context: context,
              ),
            ),
            (
              discriminatorValue: 'str',
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace('''
              @override
              String toLabel({required bool explode, required bool allowEmpty}) {
                return switch (this) {
                  ValueList() => throw EncodingException(
                    'Lists with complex content are not supported for encoding',
                  ),
                  ValueStr(:final value) => value.toLabel(
                    explode: explode,
                    allowEmpty: allowEmpty,
                  ),
                };
              }
            '''),
          ),
        );
      },
    );

    test(
      'parameterProperties with discriminator and ListModel '
      'throws EncodingException',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          discriminator: 'type',
          models: {
            (
              discriminatorValue: 'list',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
            ),
            (
              discriminatorValue: 'str',
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace('''
              Map<String, String> parameterProperties({
                bool allowEmpty = true,
                bool allowLists = true,
              }) {
                return switch (this) {
                  ValueList() => throw EncodingException(
                    'Lists are not supported in parameterProperties',
                  ),
                  ValueStr() => throw EncodingException(
                    r'parameterProperties not supported for Value: cannot determine properties at runtime',
                  ),
                };
              }
            '''),
          ),
        );
      },
    );
  });

  group('nullable variant encoding', () {
    test(
      'currentEncodingShape generates null check for nullable ClassModel '
      'variant',
      () {
        final nullableClass = ClassModel(
          isDeprecated: false,
          name: 'Details',
          properties: [
            Property(
              name: 'info',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
          isNullable: true,
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          models: {
            (discriminatorValue: null, model: nullableClass),
            (
              discriminatorValue: null,
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        const expectedGetter = '''
          EncodingShape get currentEncodingShape {
            return switch (this) {
              ValueDetails(:final value) => value == null
                ? EncodingShape.simple
                : value.currentEncodingShape,
              ValueString() => EncodingShape.simple,
            };
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedGetter)),
        );
      },
    );

    test(
      'toSimple generates null check for nullable ClassModel variant',
      () {
        final nullableClass = ClassModel(
          isDeprecated: false,
          name: 'Details',
          properties: [
            Property(
              name: 'info',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
          isNullable: true,
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          models: {
            (discriminatorValue: null, model: nullableClass),
            (
              discriminatorValue: null,
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        expect(
          collapseWhitespace(generated),
          contains(
            collapseWhitespace(
              'ValueDetails(:final value) => value == null '
              "? '' : value.toSimple(explode: explode, "
              'allowEmpty: allowEmpty),',
            ),
          ),
        );
      },
    );

    test(
      'parameterProperties generates null check for nullable ClassModel '
      'variant',
      () {
        final nullableClass = ClassModel(
          isDeprecated: false,
          name: 'Details',
          properties: [
            Property(
              name: 'info',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
          isNullable: true,
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          models: {
            (discriminatorValue: null, model: nullableClass),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Value');
        final generated = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
          Map<String, String> parameterProperties({
            bool allowEmpty = true,
            bool allowLists = true,
          }) {
            return switch (this) {
              ValueDetails(:final value) => value == null
                ? <String, String>{}
                : value.parameterProperties(
                    allowEmpty: allowEmpty,
                    allowLists: allowLists,
                  ),
            };
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'nullable ClassModel variant subclass has nullable value field',
      () {
        final nullableClass = ClassModel(
          isDeprecated: false,
          name: 'Details',
          properties: [
            Property(
              name: 'info',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
          isNullable: true,
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          models: {
            (discriminatorValue: null, model: nullableClass),
            (
              discriminatorValue: null,
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final subclass = classes.firstWhere((c) => c.name == 'ValueDetails');
        final valueField = subclass.fields.firstWhere(
          (f) => f.name == 'value',
        );
        final fieldType = valueField.type!.accept(emitter).toString();

        expect(fieldType, 'Details?');
      },
    );

    test(
      'nullable ListModel variant subclass has nullable value field',
      () {
        final nullableList = ListModel(
          name: 'Items',
          content: StringModel(context: context),
          context: context,
          isNullable: true,
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          models: {
            (discriminatorValue: null, model: nullableList),
            (
              discriminatorValue: null,
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final subclass = classes.firstWhere((c) => c.name == 'ValueItems');
        final valueField = subclass.fields.firstWhere(
          (f) => f.name == 'value',
        );
        final fieldType = valueField.type!.accept(emitter).toString();

        expect(fieldType, 'List<String>?');
      },
    );

    test(
      'non-nullable ClassModel variant subclass has non-nullable value field',
      () {
        final nonNullableClass = ClassModel(
          isDeprecated: false,
          name: 'Details',
          properties: [
            Property(
              name: 'info',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Value',
          models: {
            (discriminatorValue: null, model: nonNullableClass),
            (
              discriminatorValue: null,
              model: StringModel(context: context),
            ),
          },
          context: context,
        );

        final classes = generator.generateClasses(model);
        final subclass = classes.firstWhere((c) => c.name == 'ValueDetails');
        final valueField = subclass.fields.firstWhere(
          (f) => f.name == 'value',
        );
        final fieldType = valueField.type!.accept(emitter).toString();

        expect(fieldType, 'Details');
      },
    );
  });

  group('MapModel in OneOf', () {
    test('currentEncodingShape returns complex for MapModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: MapModel(
              name: 'Tags',
              valueModel: StringModel(context: context),
              context: context,
            ),
          ),
          (
            discriminatorValue: null,
            model: IntegerModel(context: context),
          ),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'Value',
      );
      final generated = format(
        baseClass.accept(emitter).toString(),
      );

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace('''
            EncodingShape get currentEncodingShape {
              return switch (this) {
                ValueInt() => EncodingShape.simple,
                ValueTags() => EncodingShape.complex,
              };
            }
          '''),
        ),
      );
    });

    test('toSimple throws EncodingException for MapModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: MapModel(
              name: 'Tags',
              valueModel: StringModel(context: context),
              context: context,
            ),
          ),
          (
            discriminatorValue: null,
            model: StringModel(context: context),
          ),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'Value',
      );
      final generated = format(
        baseClass.accept(emitter).toString(),
      );

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace('''
            ValueTags() => throw EncodingException(
              'Map types cannot be simple-encoded',
            ),
          '''),
        ),
      );
    });

    test('toForm throws EncodingException for MapModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: MapModel(
              name: 'Tags',
              valueModel: StringModel(context: context),
              context: context,
            ),
          ),
          (
            discriminatorValue: null,
            model: StringModel(context: context),
          ),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'Value',
      );
      final generated = format(
        baseClass.accept(emitter).toString(),
      );

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace('''
            ValueTags() => throw EncodingException(
              'Map types cannot be form-encoded',
            ),
          '''),
        ),
      );
    });

    test('parameterProperties throws for MapModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: MapModel(
              name: 'Tags',
              valueModel: StringModel(context: context),
              context: context,
            ),
          ),
          (
            discriminatorValue: null,
            model: StringModel(context: context),
          ),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'Value',
      );
      final generated = format(
        baseClass.accept(emitter).toString(),
      );

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace('''
            ValueTags() => throw EncodingException(
              'Map types cannot be parameter encoded',
            ),
          '''),
        ),
      );
    });

    test('toLabel throws EncodingException for MapModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: MapModel(
              name: 'Tags',
              valueModel: StringModel(context: context),
              context: context,
            ),
          ),
          (
            discriminatorValue: null,
            model: StringModel(context: context),
          ),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'Value',
      );
      final generated = format(
        baseClass.accept(emitter).toString(),
      );

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace('''
            ValueTags() => throw EncodingException(
              'Map types cannot be label-encoded',
            ),
          '''),
        ),
      );
    });

    test('fromJson uses decodeJsonMap for MapModel', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: MapModel(
              name: 'Tags',
              valueModel: StringModel(context: context),
              context: context,
            ),
          ),
          (
            discriminatorValue: null,
            model: StringModel(context: context),
          ),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'Value',
      );
      final generated = format(
        baseClass.accept(emitter).toString(),
      );

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace('decodeJsonMap')),
      );
    });
  });

  group('with useImmutableCollections', () {
    late OneOfGenerator immutableGenerator;

    setUp(() {
      immutableGenerator = OneOfGenerator(
        nameManager: nameManager,
        package: 'example',
        stableModelSorter: StableModelSorter(),
        useImmutableCollections: true,
      );
    });

    test('variant with ListModel uses IList and no DeepCollectionEquality', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          (
            discriminatorValue: null,
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
          ),
          (
            discriminatorValue: null,
            model: IntegerModel(context: context),
          ),
        },
        context: context,
      );

      final classes = immutableGenerator.generateClasses(model);

      // Find the list variant subclass by name
      final listSubclass = classes.firstWhere(
        (c) => c.name == 'ValueList',
      );

      // Verify the value field is IList<String>
      final valueField = listSubclass.fields.firstWhere(
        (f) => f.name == 'value',
      );
      final typeRef = valueField.type! as TypeReference;
      expect(typeRef.symbol, 'IList');
      expect(
        typeRef.url,
        'package:fast_immutable_collections/'
        'fast_immutable_collections.dart',
      );
      expect(typeRef.types.length, 1);
      expect(
        (typeRef.types.first as TypeReference).symbol,
        'String',
      );

      // Equality should use direct == (IList has built-in value equality)
      final generated = format(
        listSubclass.accept(emitter).toString(),
      );
      const expectedEquals = '''
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is ValueList && other.value == this.value;
}
''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedEquals)),
      );
    });
  });
}
