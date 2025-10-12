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

  group('OneOfGenerator labelProperties generation', () {
    test('generates labelProperties for primitive-only variants', () {
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

      final labelProps = baseClass.methods.firstWhere(
        (m) => m.name == 'labelProperties',
      );
      expect(
        labelProps.returns?.accept(emitter).toString(),
        'Map<String,String>',
      );
      expect(labelProps.optionalParameters.length, 1);
      expect(labelProps.optionalParameters.first.name, 'allowEmpty');
      expect(labelProps.optionalParameters.first.required, isFalse);

      const expectedMethod = '''
        Map<String, String> labelProperties({bool allowEmpty = true}) {
          return switch (this) {
            PrimitiveChoiceI() => <String, String>{},
            PrimitiveChoiceS() => <String, String>{},
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test(
      'generates labelProperties for class-only variants with discriminator',
      () {
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

        final labelProps = baseClass.methods.firstWhere(
          (m) => m.name == 'labelProperties',
        );
        expect(
          labelProps.returns?.accept(emitter).toString(),
          'Map<String,String>',
        );
        expect(labelProps.optionalParameters.length, 1);
        expect(labelProps.optionalParameters.first.name, 'allowEmpty');
        expect(labelProps.optionalParameters.first.required, isFalse);

        final generated = format(baseClass.accept(emitter).toString());
        const expectedMethod = '''
        Map<String, String> labelProperties({bool allowEmpty = true}) {
          return switch (this) {
            ChoiceA(:final value) => {
              ...value.labelProperties(allowEmpty: allowEmpty),
              'type': 'a',
            },
            ChoiceB(:final value) => {
              ...value.labelProperties(allowEmpty: allowEmpty),
              'type': 'b',
            },
          };
        }
      ''';
        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test('generates labelProperties for mixed variants', () {
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
        Map<String, String> labelProperties({bool allowEmpty = true}) {
          return switch (this) {
            MixedChoiceM(:final value) => {
              ...value.labelProperties(allowEmpty: allowEmpty),
              'kind': 'm',
            },
            MixedChoiceS() => <String, String>{},
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test(
      'generates labelProperties for class variants without discriminator',
      () {
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
            (discriminatorValue: null, model: classA),
            (discriminatorValue: null, model: classB),
          },
          discriminator: null,
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Choice');
        final generated = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
        Map<String, String> labelProperties({bool allowEmpty = true}) {
          return switch (this) {
            ChoiceA(:final value) => value.labelProperties(allowEmpty: allowEmpty),
            ChoiceB(:final value) => value.labelProperties(allowEmpty: allowEmpty),
          };
        }
      ''';
        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );
  });

  group('OneOfGenerator toLabel generation', () {
    test('generates toLabel for primitive-only variants', () {
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
        String toLabel({bool explode = false, bool allowEmpty = true}) {
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

      final model = OneOfModel(
        name: 'Choice',
        models: {
          (discriminatorValue: 'a', model: classA),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Choice');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toLabel({bool explode = false, bool allowEmpty = true}) {
          return switch (this) {
            ChoiceA(:final value) => {
              ...value.labelProperties(allowEmpty: allowEmpty),
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
        String toLabel({bool explode = false, bool allowEmpty = true}) {
          return switch (this) {
            MixedChoiceM(:final value) => {
              ...value.labelProperties(allowEmpty: allowEmpty),
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
  });
}
