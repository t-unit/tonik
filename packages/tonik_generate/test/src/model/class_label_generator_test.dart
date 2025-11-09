import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late ClassGenerator generator;
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
    generator = ClassGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('ClassGenerator toLabel generation', () {
    test('generates toLabel for class with only simple properties', () {
      final model = ClassModel(
        name: 'SimpleClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'age',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final toLabelMethod = generatedClass.methods.firstWhere(
        (m) => m.name == 'toLabel',
      );

      expect(toLabelMethod.returns?.accept(emitter).toString(), 'String');
      expect(toLabelMethod.optionalParameters.length, 2);
      expect(
        toLabelMethod.optionalParameters.map((p) => p.name),
        containsAll(['explode', 'allowEmpty']),
      );

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates toLabel that throws for class with nested class property',
      () {
        final model = ClassModel(
          name: 'NestedClass',
          properties: [
            Property(
              name: 'nested',
              model: ClassModel(
                context: context,
                name: 'Nested',
                properties: [
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  group('ClassGenerator toLabel method for label encoding', () {
    test('generates toLabel for class with only simple properties', () {
      final model = ClassModel(
        name: 'SimpleClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'age',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates toLabel for class with composite properties requiring '
      'runtime checks',
      () {
        final model = ClassModel(
          name: 'CompositeClass',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'value',
              model: OneOfModel(
                context: context,
                name: 'Value',
                discriminator: 'type',
                models: {
                  (
                    discriminatorValue: 'string',
                    model: StringModel(context: context),
                  ),
                  (
                    discriminatorValue: 'integer',
                    model: IntegerModel(context: context),
                  ),
                },
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates toLabel for class with mixed properties including '
      'nullable composites',
      () {
        final model = ClassModel(
          name: 'MixedClass',
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
            Property(
              name: 'optionalValue',
              model: AnyOfModel(
                context: context,
                name: 'OptionalValue',
                discriminator: 'type',
                models: {
                  (
                    discriminatorValue: 'date',
                    model: DateTimeModel(context: context),
                  ),
                  (
                    discriminatorValue: 'decimal',
                    model: DecimalModel(context: context),
                  ),
                },
              ),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());
        const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates toLabel for empty class', () {
      final model = ClassModel(
        name: 'EmptyClass',
        properties: const [],
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
