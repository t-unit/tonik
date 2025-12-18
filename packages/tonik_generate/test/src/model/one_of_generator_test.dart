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
            return other is ResultStrings && _$deepEquals.other.value, value;
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
            'parameterProperties not supported for Value: only contains primitive types',
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
              'type': 'company',
            },
            EntityUser(:final value) => {
              ...value.parameterProperties(
                allowEmpty: allowEmpty,
                allowLists: allowLists,
              ),
              'type': 'person',
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
              'parameterProperties not supported for Value: cannot determine properties at runtime',
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
              'parameterProperties not supported for Response: cannot determine properties at runtime',
            ),
            ResponseUser(:final value) => {
              ...value.parameterProperties(
                allowEmpty: allowEmpty,
                allowLists: allowLists,
              ),
              'type': 'user',
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
                  'parameterProperties not supported for Outer: cannot determine properties at runtime',
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
                  'type': 'inner',
                }
              : throw EncodingException(
                  'parameterProperties not supported for Outer: cannot determine properties at runtime',
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
    final variantNames =
        classes.where((c) => c.name != 'TestOneOf').map((c) => c.name).toList();

    // Verify variants are in stable sorted order by discriminator value.
    expect(variantNames, [
      'TestOneOfApple',
      'TestOneOfBanana',
      'TestOneOfZebra',
    ]);
  });
}
