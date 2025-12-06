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

  group('toLabel', () {
    test('generates toLabel for primitive-only variants', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'PrimitiveChoice',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
        description: null,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'PrimitiveChoice',
      );
      final generated = format(baseClass.accept(emitter).toString());

      final toLabelMethod = baseClass.methods.firstWhere(
        (m) => m.name == 'toLabel',
      );

      expect(toLabelMethod.returns?.accept(emitter).toString(), 'String');
      expect(toLabelMethod.optionalParameters.length, 2);
      expect(
        toLabelMethod.optionalParameters.map((p) => p.name),
        containsAll(['explode', 'allowEmpty']),
      );

      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return switch (this) {
            PrimitiveChoiceI(:final value) => value.toLabel(explode: explode, allowEmpty: allowEmpty),
            PrimitiveChoiceS(:final value) => value.toLabel(explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toLabel for class variants with discriminator', () {
      final classA = ClassModel(
        isDeprecated: false,
        name: 'A',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            description: null,
          ),
        ],
        context: context,
        description: null,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Choice',
        models: {
          (discriminatorValue: 'a', model: classA),
        },
        discriminator: 'type',
        context: context,
        description: null,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Choice');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return switch (this) {
            ChoiceA(:final value) => {
              ...value.parameterProperties(allowEmpty: allowEmpty),
              'type': 'a',
            }.toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toLabel for mixed variants', () {
      final classM = ClassModel(
        isDeprecated: false,
        name: 'M',
        properties: [
          Property(
            name: 'flag',
            model: BooleanModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            description: null,
          ),
        ],
        context: context,
        description: null,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'MixedChoice',
        models: {
          (discriminatorValue: 'm', model: classM),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        discriminator: 'kind',
        context: context,
        description: null,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'MixedChoice');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return switch (this) {
            MixedChoiceM(:final value) => {
              ...value.parameterProperties(allowEmpty: allowEmpty),
              'kind': 'm',
            }.toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true),
            MixedChoiceS(:final value) => value.toLabel(explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('toLabel handles mixed-encoded variant without discriminator', () {
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
                  description: null,
                ),
              ],
              context: context,
              description: null,
            ),
          ),
        },
        discriminator: null,
        context: context,
        description: null,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Outer',
        models: {
          (discriminatorValue: null, model: innerOneOf),
        },
        discriminator: null,
        context: context,
        description: null,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Outer');

      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return switch (this) {
            OuterInner(:final value) => value.toLabel( explode: explode, allowEmpty: allowEmpty, ),
          };
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toLabel handles mixed-encoded variant with discriminator', () {
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
                  description: null,
                ),
              ],
              context: context,
              description: null,
            ),
          ),
        },
        discriminator: null,
        context: context,
        description: null,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Outer',
        models: {
          (discriminatorValue: 'inner', model: innerOneOf),
        },
        discriminator: 'type',
        context: context,
        description: null,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Outer');

      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return switch (this) {
            OuterInner(:final value) => value.currentEncodingShape == EncodingShape.complex
              ? {
                  ...value.parameterProperties(allowEmpty: allowEmpty),
                  'type': 'inner',
                }.toLabel(
                  explode: explode,
                  allowEmpty: allowEmpty,
                  alreadyEncoded: true,
                )
              : value.toLabel(explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'toLabel handles multiple mixed-encoded variants with discriminator',
      () {
        final innerOneOfA = OneOfModel(
          isDeprecated: false,
          name: 'InnerA',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'DataA',
                properties: [
                  Property(
                    name: 'a',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                    description: null,
                  ),
                ],
                context: context,
                description: null,
              ),
            ),
          },
          discriminator: null,
          context: context,
          description: null,
        );

        final innerOneOfB = OneOfModel(
          isDeprecated: false,
          name: 'InnerB',
          models: {
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'DataB',
                properties: [
                  Property(
                    name: 'b',
                    model: IntegerModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                    description: null,
                  ),
                ],
                context: context,
                description: null,
              ),
            ),
          },
          discriminator: null,
          context: context,
          description: null,
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Outer',
          models: {
            (discriminatorValue: 'a', model: innerOneOfA),
            (discriminatorValue: 'b', model: innerOneOfB),
          },
          discriminator: 'type',
          context: context,
          description: null,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Outer');

        const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return switch (this) {
            OuterInnerA(:final value) => value.currentEncodingShape == EncodingShape.complex
              ? {
                  ...value.parameterProperties(allowEmpty: allowEmpty),
                  'type': 'a',
                }.toLabel(
                  explode: explode,
                  allowEmpty: allowEmpty,
                  alreadyEncoded: true,
                )
              : value.toLabel(explode: explode, allowEmpty: allowEmpty),
            OuterInnerB(:final value) => value.currentEncodingShape == EncodingShape.complex
              ? {
                  ...value.parameterProperties(allowEmpty: allowEmpty),
                  'type': 'b',
                }.toLabel(
                  explode: explode,
                  allowEmpty: allowEmpty,
                  alreadyEncoded: true,
                )
              : value.toLabel(explode: explode, allowEmpty: allowEmpty),
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
}
