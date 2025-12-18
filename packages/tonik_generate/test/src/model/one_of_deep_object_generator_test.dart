import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('OneOfGenerator toDeepObject generation', () {
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
      nameManager = NameManager(generator: nameGenerator);
      generator = OneOfGenerator(
        nameManager: nameManager,
        package: 'package:example',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    test('generates toDeepObject method with correct signature', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'OneOfPrimitive',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == model.name);
      final generated = format(baseClass.accept(emitter).toString());

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowLists: false,
          ).toDeepObject(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('generates toDeepObject for simple-only OneOf', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'OneOfSimple',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == model.name);
      final generated = format(baseClass.accept(emitter).toString());

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowLists: false,
          ).toDeepObject(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('generates toDeepObject for complex OneOf', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'OneOfComplex',
        models: {
          (
            discriminatorValue: 'model1',
            model: ClassModel(
              isDeprecated: false,
              name: 'Model1',
              properties: [
                Property(
                  name: 'field1',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
              context: context,
            ),
          ),
          (
            discriminatorValue: 'model2',
            model: ClassModel(
              isDeprecated: false,
              name: 'Model2',
              properties: [
                Property(
                  name: 'field2',
                  model: IntegerModel(context: context),
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

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == model.name);
      final generated = format(baseClass.accept(emitter).toString());

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowLists: false,
          ).toDeepObject(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('toDeepObject passes allowLists=false to parameterProperties', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'OneOfWithAllowLists',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == model.name);
      final generated = format(baseClass.accept(emitter).toString());

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowLists: false,
          ).toDeepObject(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('toDeepObject passes alreadyEncoded=true', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'OneOfEncoded',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == model.name);
      final generated = format(baseClass.accept(emitter).toString());

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowLists: false,
          ).toDeepObject(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('toDeepObject handles discriminator', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'OneOfWithDiscriminator',
        models: {
          (
            discriminatorValue: 'model1',
            model: ClassModel(
              isDeprecated: false,
              name: 'Model1',
              properties: [
                Property(
                  name: 'field1',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
              context: context,
            ),
          ),
          (
            discriminatorValue: 'model2',
            model: ClassModel(
              isDeprecated: false,
              name: 'Model2',
              properties: [
                Property(
                  name: 'field2',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
              context: context,
            ),
          ),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == model.name);
      final generated = format(baseClass.accept(emitter).toString());

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return parameterProperties(
            allowEmpty: allowEmpty,
            allowLists: false,
          ).toDeepObject(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });
  });
}
