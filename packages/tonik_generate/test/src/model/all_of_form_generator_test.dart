import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late AllOfGenerator generator;
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
    generator = AllOfGenerator(
      nameManager: nameManager,
      package: 'example',
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });
  group('form encoding - complex types', () {
    test('generates fromForm constructor for complex allOf model', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'CombinedModel',
        models: {
          ClassModel(
            isDeprecated: false,
            name: 'Base',
            properties: [
              Property(
                name: 'id',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
          ClassModel(
            isDeprecated: false,
            name: 'Mixin',
            properties: [
              Property(
                name: 'value',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
        },
        context: context,
        examples: const [],
      );

      final combinedClass = generator.generateClass(model);

      const expectedFromFormMethod = r'''
        factory CombinedModel.fromForm(String? value, {required bool explode}) {
          return CombinedModel(
            $base: Base.fromForm(value, explode: explode),
            $mixin: Mixin.fromForm(value, explode: explode),
          );
        }
      ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedFromFormMethod)),
      );
    });

    test('generates toForm method merging all class properties', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'CombinedModel',
        models: {
          ClassModel(
            isDeprecated: false,
            name: 'Base',
            properties: [
              Property(
                name: 'id',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
          ClassModel(
            isDeprecated: false,
            name: 'Mixin',
            properties: [
              Property(
                name: 'value',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
        },
        context: context,
        examples: const [],
      );

      final combinedClass = generator.generateClass(model);

      const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
          );
        }
      ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedToFormMethod)),
      );
    });
  });

  test('allOf with class and mixed oneOf validates at runtime', () {
    final oneOfModel = OneOfModel(
      isDeprecated: false,
      name: 'Choice',
      models: {
        (discriminatorValue: null, model: IntegerModel(context: context)),
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            name: 'Option',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
        ),
      },
      context: context,
      examples: const [],
    );

    final classModel = ClassModel(
      isDeprecated: false,
      name: 'Base',
      properties: [
        Property(
          name: 'id',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'Combined',
      models: {
        classModel,
        oneOfModel,
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException(
              r'Cannot encode Combined: mixing simple values (primitives/enums) and complex types is not supported',
            );
          }
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  group('form encoding - primitive types', () {
    test('generates toForm returning primary primitive value', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'StringDecimalModel',
        models: <Model>{
          StringModel(context: context),
          DecimalModel(context: context),
        },
        context: context,
        examples: const [],
      );

      final combinedClass = generator.generateClass(model);

      const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return bigDecimal.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
        }
      ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedToFormMethod)),
      );
    });

    test(
      'generates fromForm validating single value against all primitive types',
      () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'StringDecimalModel',
          models: <Model>{
            StringModel(context: context),
            DecimalModel(context: context),
          },
          context: context,
          examples: const [],
        );

        final combinedClass = generator.generateClass(model);

        const expectedFromFormMethod = '''
        factory StringDecimalModel.fromForm(String? value, {required bool explode}) {
          return StringDecimalModel(
            bigDecimal: value.decodeFormBigDecimal(
              context: r'StringDecimalModel.bigDecimal',
            ),
            string: value.decodeFormString(context: r'StringDecimalModel.string'),
          );
        }
      ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedFromFormMethod)),
        );
      },
    );

    test(
      'generates toForm returning enum value for enum and string models',
      () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'EnumStringModel',
          models: {
            EnumModel(
              isDeprecated: false,
              name: 'Status',
              values: {
                const EnumEntry(value: 'active'),
                const EnumEntry(value: 'inactive'),
              },
              isNullable: false,
              context: context,
              examples: const [],
            ),
            StringModel(context: context),
          },
          context: context,
          examples: const [],
        );

        final combinedClass = generator.generateClass(model);

        const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return status.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
        }
      ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedToFormMethod)),
        );
      },
    );

    test(
      'generates fromForm validating single value against enum and string',
      () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'EnumStringModel',
          models: {
            EnumModel(
              isDeprecated: false,
              name: 'Status',
              values: {
                const EnumEntry(value: 'active'),
                const EnumEntry(value: 'inactive'),
              },
              isNullable: false,
              context: context,
              examples: const [],
            ),
            StringModel(context: context),
          },
          context: context,
          examples: const [],
        );

        final combinedClass = generator.generateClass(model);

        const expectedFromFormMethod = '''
        factory EnumStringModel.fromForm(String? value, {required bool explode}) {
          return EnumStringModel(
            status: Status.fromForm(value, explode: explode),
            string: value.decodeFormString(context: r'EnumStringModel.string'),
          );
        }
      ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedFromFormMethod)),
        );
      },
    );
  });

  group('form encoding - mixed types', () {
    test(
      'generates fromForm for mixed types attempting decode',
      () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'MixedModel',
          models: {
            StringModel(context: context),
            ClassModel(
              isDeprecated: false,
              name: 'Complex',
              properties: [
                Property(
                  name: 'value',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                  examples: const [],
                  defaultValue: null,
                ),
              ],
              context: context,
              examples: const [],
            ),
          },
          context: context,
          examples: const [],
        );

        final combinedClass = generator.generateClass(model);

        const expectedFromFormMethod = '''
        factory MixedModel.fromForm(String? value, {required bool explode}) {
          return MixedModel(
            complex: Complex.fromForm(value, explode: explode),
            string: value.decodeFormString(context: r'MixedModel.string'),
          );
        }
      ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedFromFormMethod)),
        );
      },
    );

    test(
      'throws exception for mixed types in toForm',
      () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'MixedModel',
          models: {
            IntegerModel(context: context),
            ClassModel(
              isDeprecated: false,
              name: 'Complex',
              properties: const [],
              context: context,
              examples: const [],
            ),
          },
          context: context,
          examples: const [],
        );

        final combinedClass = generator.generateClass(model);

        const expectedToFormMethod = '''
          List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
            throw EncodingException(
              'Form encoding not supported: contains complex types',
            );
          }
        ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedToFormMethod)),
        );
      },
    );
  });

  test('allOf with mixed oneOf and primitive validates at runtime', () {
    final oneOfModel = OneOfModel(
      isDeprecated: false,
      name: 'Choice',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            name: 'Data',
            properties: [
              Property(
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
        ),
      },
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'Combined',
      models: {
        IntegerModel(context: context),
        oneOfModel,
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = r'''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException(
              r'Cannot encode Combined: mixing simple values (primitives/enums) and complex types is not supported',
            );
          }
          final _$entryLists = <List<ParameterEntry>>[];
          final _$values = <String>{};
          final _$intForm = int.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
          _$entryLists.add(_$intForm);
          _$values.add(_$intForm.map((e) => e.value).join(','));
          final _$choiceForm = choice.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
          _$entryLists.add(_$choiceForm);
          _$values.add(_$choiceForm.map((e) => e.value).join(','));
          if (_$values.length > 1) {
            throw EncodingException(
              r'Inconsistent allOf form encoding for Combined: all values must encode to the same result',
            );
          }
          return _$entryLists.first;
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('allOf with mixed oneOf and primitive allows fromForm decoding', () {
    final oneOfModel = OneOfModel(
      isDeprecated: false,
      name: 'Choice',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            name: 'Data',
            properties: [
              Property(
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
        ),
      },
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'Combined',
      models: {
        IntegerModel(context: context),
        oneOfModel,
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedFromFormMethod = '''
        factory Combined.fromForm(String? value, {required bool explode}) {
          return Combined(
            int: value.decodeFormInt(context: r'Combined.int'),
            choice: Choice.fromForm(value, explode: explode),
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedFromFormMethod)),
    );
  });

  test('allOf with multiple mixed anyOf models validates all at runtime', () {
    final anyOfModel1 = AnyOfModel(
      isDeprecated: false,
      name: 'FlexibleA',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            name: 'DataA',
            properties: [
              Property(
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
        ),
      },
      context: context,
      examples: const [],
    );

    final anyOfModel2 = AnyOfModel(
      isDeprecated: false,
      name: 'FlexibleB',
      models: {
        (discriminatorValue: null, model: IntegerModel(context: context)),
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            name: 'DataB',
            properties: [
              Property(
                name: 'value',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
        ),
      },
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'MultiDynamic',
      models: {
        StringModel(context: context),
        anyOfModel1,
        anyOfModel2,
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = r'''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException(
              r'Cannot encode MultiDynamic: mixing simple values (primitives/enums) and complex types is not supported',
            );
          }
          final _$entryLists = <List<ParameterEntry>>[];
          final _$values = <String>{};
          final _$flexibleAForm = flexibleA.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
          _$entryLists.add(_$flexibleAForm);
          _$values.add(_$flexibleAForm.map((e) => e.value).join(','));
          final _$flexibleBForm = flexibleB.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
          _$entryLists.add(_$flexibleBForm);
          _$values.add(_$flexibleBForm.map((e) => e.value).join(','));
          final _$stringForm = string.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
          _$entryLists.add(_$stringForm);
          _$values.add(_$stringForm.map((e) => e.value).join(','));
          if (_$values.length > 1) {
            throw EncodingException(
              r'Inconsistent allOf form encoding for MultiDynamic: all values must encode to the same result',
            );
          }
          return _$entryLists.first;
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('allOf with mixed anyOf, oneOf, and primitives validates all '
      'dynamic types', () {
    final anyOfModel = AnyOfModel(
      isDeprecated: false,
      name: 'FlexibleValue',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            name: 'Data',
            properties: [
              Property(
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
        ),
      },
      context: context,
      examples: const [],
    );

    final oneOfModel = OneOfModel(
      isDeprecated: false,
      name: 'Choice',
      models: {
        (discriminatorValue: null, model: IntegerModel(context: context)),
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            name: 'Option',
            properties: [
              Property(
                name: 'name',
                model: StringModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
        ),
      },
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'ComplexMixed',
      models: {
        StringModel(context: context),
        anyOfModel,
        oneOfModel,
        DecimalModel(context: context),
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = r'''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException(
              r'Cannot encode ComplexMixed: mixing simple values (primitives/enums) and complex types is not supported',
            );
          }
          final _$entryLists = <List<ParameterEntry>>[];
          final _$values = <String>{};
          final _$flexibleValueForm = flexibleValue.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
          _$entryLists.add(_$flexibleValueForm);
          _$values.add(_$flexibleValueForm.map((e) => e.value).join(','));
          final _$bigDecimalForm = bigDecimal.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
          _$entryLists.add(_$bigDecimalForm);
          _$values.add(_$bigDecimalForm.map((e) => e.value).join(','));
          final _$choiceForm = choice.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
          _$entryLists.add(_$choiceForm);
          _$values.add(_$choiceForm.map((e) => e.value).join(','));
          final _$stringForm = string.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
          _$entryLists.add(_$stringForm);
          _$values.add(_$stringForm.map((e) => e.value).join(','));
          if (_$values.length > 1) {
            throw EncodingException(
              r'Inconsistent allOf form encoding for ComplexMixed: all values must encode to the same result',
            );
          }
          return _$entryLists.first;
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('generates toForm for allOf with list of int', () {
    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfIntList',
      models: {
        ListModel(
          content: IntegerModel(context: context),
          context: context,
          examples: const [],
        ),
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToForm = r'''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          final _$entryLists = <List<ParameterEntry>>[];
          final _$values = <String>{};
          final _$listForm = list
              .map(
                (e) => e.uriEncode(
                  allowEmpty: allowEmpty,
                  useQueryComponent: useQueryComponent,
                ),
              )
              .toList()
              .toForm(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
                useQueryComponent: useQueryComponent,
                alreadyEncoded: true,
              );
          _$entryLists.add(_$listForm);
          _$values.add(_$listForm.map((e) => e.value).join(','));
          if (_$values.length > 1) {
            throw EncodingException(
              r'Inconsistent allOf form encoding: all values must encode to the same result',
            );
          }
          return _$entryLists.first;
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToForm)),
    );
  });

  test('generates toForm for allOf with list of DateTime', () {
    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfDateTimeList',
      models: {
        ListModel(
          content: DateTimeModel(context: context),
          context: context,
          examples: const [],
        ),
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToForm = r'''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          final _$entryLists = <List<ParameterEntry>>[];
          final _$values = <String>{};
          final _$listForm = list
              .map(
                (e) => e.uriEncode(
                  allowEmpty: allowEmpty,
                  useQueryComponent: useQueryComponent,
                ),
              )
              .toList()
              .toForm(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
                useQueryComponent: useQueryComponent,
                alreadyEncoded: true,
              );
          _$entryLists.add(_$listForm);
          _$values.add(_$listForm.map((e) => e.value).join(','));
          if (_$values.length > 1) {
            throw EncodingException(
              r'Inconsistent allOf form encoding: all values must encode to the same result',
            );
          }
          return _$entryLists.first;
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToForm)),
    );
  });

  test('allOf with mixed anyOf and primitive validates at runtime', () {
    final anyOfModel = AnyOfModel(
      isDeprecated: false,
      name: 'FlexibleValue',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            name: 'Data',
            properties: [
              Property(
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
                examples: const [],
                defaultValue: null,
              ),
            ],
            context: context,
            examples: const [],
          ),
        ),
      },
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'Combined',
      models: {
        IntegerModel(context: context),
        anyOfModel,
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = r'''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException(
              r'Cannot encode Combined: mixing simple values (primitives/enums) and complex types is not supported',
            );
          }
          final _$entryLists = <List<ParameterEntry>>[];
          final _$values = <String>{};
          final _$flexibleValueForm = flexibleValue.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
          _$entryLists.add(_$flexibleValueForm);
          _$values.add(_$flexibleValueForm.map((e) => e.value).join(','));
          final _$intForm = int.toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );
          _$entryLists.add(_$intForm);
          _$values.add(_$intForm.map((e) => e.value).join(','));
          if (_$values.length > 1) {
            throw EncodingException(
              r'Inconsistent allOf form encoding for Combined: all values must encode to the same result',
            );
          }
          return _$entryLists.first;
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('generates fromForm for allOf with list of double', () {
    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfDoubleList',
      models: {
        ListModel(
          content: DoubleModel(context: context),
          context: context,
          examples: const [],
        ),
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedFromForm = '''
        factory AllOfDoubleList.fromForm(String? value, {required bool explode}) {
          return AllOfDoubleList(
            list: value
              .decodeFormStringList(context: r'AllOfDoubleList.list')
              .map((e) => e.decodeFormDouble(context: r'AllOfDoubleList.list'))
              .toList(),
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedFromForm)),
    );
  });

  test('generates fromForm for allOf with list of DateTime', () {
    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfDateTimeList',
      models: {
        ListModel(
          content: DateTimeModel(context: context),
          context: context,
          examples: const [],
        ),
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedFromForm = '''
        factory AllOfDateTimeList.fromForm(String? value, {required bool explode}) {
          return AllOfDateTimeList(
            list: value
              .decodeFormStringList(context: r'AllOfDateTimeList.list')
              .map((e) => e.decodeFormDateTime(context: r'AllOfDateTimeList.list'))
              .toList(),
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedFromForm)),
    );
  });

  test('generates toForm threading explodedValues for an object member with '
      'a simple-content array property', () {
    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfObjectArray',
      models: {
        ClassModel(
          isDeprecated: false,
          name: 'Meta',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        ),
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
            explodedValues: <String, List<String>>{
              r'tags': meta.tags
                  .map(
                    (e) => e.uriEncode(
                      allowEmpty: true,
                      useQueryComponent: useQueryComponent,
                      allowReserved:
                          fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
                    ),
                  )
                  .toList(),
            },
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('generates toForm without explodedValues when a bare array member is '
      'combined with an object member', () {
    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfListAndObject',
      models: {
        ListModel(
          content: StringModel(context: context),
          context: context,
          examples: const [],
        ),
        ClassModel(
          isDeprecated: false,
          name: 'Meta',
          properties: [
            Property(
              name: 'note',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        ),
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('null-guards exploded array of a nullable object member without '
      'unwrapping the member for the null test', () {
    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfNullableObject',
      models: {
        ClassModel(
          isDeprecated: false,
          name: 'Meta',
          isNullable: true,
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        ),
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
            explodedValues: <String, List<String>>{
              r'tags': meta == null
                  ? const <String>[]
                  : meta!.tags
                      .map(
                        (e) => e.uriEncode(
                          allowEmpty: true,
                          useQueryComponent: useQueryComponent,
                          allowReserved:
                              fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
                        ),
                      )
                      .toList(),
            },
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('collapses a duplicate exploded array key from two members to the '
      'last-merged member', () {
    ClassModel member(String name) => ClassModel(
      isDeprecated: false,
      name: name,
      properties: [
        Property(
          name: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfDuplicateArray',
      models: {member('Alpha'), member('Beta')},
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
            explodedValues: <String, List<String>>{
              r'tags': beta.tags
                  .map(
                    (e) => e.uriEncode(
                      allowEmpty: true,
                      useQueryComponent: useQueryComponent,
                      allowReserved:
                          fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
                    ),
                  )
                  .toList(),
            },
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('agrees on the list member as merge winner for a duplicate raw name '
      'shared by a list member and a scalar member', () {
    final listMember = ClassModel(
      isDeprecated: false,
      name: 'ZListMember',
      properties: [
        Property(
          name: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      context: context,
      examples: const [],
    );
    final scalarMember = ClassModel(
      isDeprecated: false,
      name: 'AScalarMember',
      properties: [
        Property(
          name: 'tags',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfListScalarDuplicate',
      models: {listMember, scalarMember},
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
            explodedValues: <String, List<String>>{
              r'tags': zListMember.tags
                  .map(
                    (e) => e.uriEncode(
                      allowEmpty: true,
                      useQueryComponent: useQueryComponent,
                      allowReserved:
                          fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
                    ),
                  )
                  .toList(),
            },
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('falls back to an earlier member when the later duplicate array member '
      'is null at runtime', () {
    final alpha = ClassModel(
      isDeprecated: false,
      name: 'Alpha',
      properties: [
        Property(
          name: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      context: context,
      examples: const [],
    );
    final beta = ClassModel(
      isDeprecated: false,
      name: 'Beta',
      isNullable: true,
      properties: [
        Property(
          name: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfNullableDuplicateArray',
      models: {alpha, beta},
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
            explodedValues: <String, List<String>>{
              r'tags': beta == null
                  ? alpha.tags
                        .map(
                          (e) => e.uriEncode(
                            allowEmpty: true,
                            useQueryComponent: useQueryComponent,
                            allowReserved:
                                fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
                          ),
                        )
                        .toList()
                  : beta!.tags
                        .map(
                          (e) => e.uriEncode(
                            allowEmpty: true,
                            useQueryComponent: useQueryComponent,
                            allowReserved:
                                fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
                          ),
                        )
                        .toList(),
            },
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('selects the empty list for a duplicate array key whose winning later '
      'member is present with a null array property', () {
    final alpha = ClassModel(
      isDeprecated: false,
      name: 'Alpha',
      properties: [
        Property(
          name: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      context: context,
      examples: const [],
    );
    final beta = ClassModel(
      isDeprecated: false,
      name: 'Beta',
      properties: [
        Property(
          name: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfNullLeafDuplicateArray',
      models: {alpha, beta},
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
            explodedValues: <String, List<String>>{
              r'tags': beta.tags == null
                  ? const <String>[]
                  : beta.tags!
                      .map(
                        (e) => e.uriEncode(
                          allowEmpty: true,
                          useQueryComponent: useQueryComponent,
                          allowReserved:
                              fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
                        ),
                      )
                      .toList(),
            },
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('threads an optional array property of a nested allOf member through '
      'the composed field path', () {
    final inner = AllOfModel(
      isDeprecated: false,
      name: 'Inner',
      models: {
        ClassModel(
          isDeprecated: false,
          name: 'Meta',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
              isRequired: false,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        ),
      },
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'Outer',
      models: {inner},
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
            explodedValues: <String, List<String>>{
              r'tags': inner.meta.tags == null
                  ? const <String>[]
                  : inner.meta.tags!
                      .map(
                        (e) => e.uriEncode(
                          allowEmpty: true,
                          useQueryComponent: useQueryComponent,
                          allowReserved:
                              fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
                        ),
                      )
                      .toList(),
            },
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('null-guards a write-only required array property whose member field '
      'the writeOnly flag widens to nullable', () {
    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfWriteOnlyArray',
      models: {
        ClassModel(
          isDeprecated: false,
          name: 'Meta',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                context: context,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              isWriteOnly: true,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        ),
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
            explodedValues: <String, List<String>>{
              r'tags': meta.tags == null
                  ? const <String>[]
                  : meta.tags!
                      .map(
                        (e) => e.uriEncode(
                          allowEmpty: true,
                          useQueryComponent: useQueryComponent,
                          allowReserved:
                              fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
                        ),
                      )
                      .toList(),
            },
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('null-guards a required array property whose ListModel is itself '
      'nullable on a member class', () {
    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfNullableListArray',
      models: {
        ClassModel(
          isDeprecated: false,
          name: 'Meta',
          properties: [
            Property(
              name: 'tags',
              model: ListModel(
                content: StringModel(context: context),
                isNullable: true,
                context: context,
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        ),
      },
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
            explodedValues: <String, List<String>>{
              r'tags': meta.tags == null
                  ? const <String>[]
                  : meta.tags!
                      .map(
                        (e) => e.uriEncode(
                          allowEmpty: true,
                          useQueryComponent: useQueryComponent,
                          allowReserved:
                              fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
                        ),
                      )
                      .toList(),
            },
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });

  test('emits the empty list for a duplicate array key whose scalar member '
      'sorts last', () {
    final listMember = ClassModel(
      isDeprecated: false,
      name: 'AListMember',
      properties: [
        Property(
          name: 'tags',
          model: ListModel(
            content: StringModel(context: context),
            context: context,
            examples: const [],
          ),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      context: context,
      examples: const [],
    );
    final scalarMember = ClassModel(
      isDeprecated: false,
      name: 'ZScalarMember',
      properties: [
        Property(
          name: 'tags',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: false,
          examples: const [],
          defaultValue: null,
        ),
      ],
      context: context,
      examples: const [],
    );

    final model = AllOfModel(
      isDeprecated: false,
      name: 'AllOfScalarLastDuplicate',
      models: {listMember, scalarMember},
      context: context,
      examples: const [],
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToFormMethod = '''
        List<ParameterEntry> toForm( String paramName, { required bool explode, required bool allowEmpty, bool useQueryComponent = false, bool allowReserved = false, Map<String, FormFieldEncoding> fieldEncodings = const {}, }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved, fieldEncodings: fieldEncodings,
          ).toForm(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
            useQueryComponent: useQueryComponent,
            fieldEncodings: fieldEncodings,
            explodedValues: <String, List<String>>{
              r'tags': aListMember.tags
                  .map(
                    (e) => e.uriEncode(
                      allowEmpty: true,
                      useQueryComponent: useQueryComponent,
                      allowReserved:
                          fieldEncodings[r'tags']?.allowReserved ?? allowReserved,
                    ),
                  )
                  .toList(),
            },
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToFormMethod)),
    );
  });
}
