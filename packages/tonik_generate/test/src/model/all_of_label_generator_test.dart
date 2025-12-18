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
    nameManager = NameManager(generator: nameGenerator);
    generator = AllOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('AllOfGenerator toLabel generation', () {
    test('generates toLabel for complex-only AllOf', () {
      final class1 = ClassModel(
        isDeprecated: false,
        name: 'Class1',
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

      final class2 = ClassModel(
        isDeprecated: false,
        name: 'Class2',
        properties: [
          Property(
            name: 'number',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfComplex',
        models: {class1, class2},
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
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toLabel for primitive-only AllOf', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfPrimitive',
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return int.toLabel(explode: explode, allowEmpty: allowEmpty);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toLabel with runtime validation for dynamic models', () {
      final anyOfModel = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfModel',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (
            discriminatorValue: 'complex',
            model: ClassModel(
              isDeprecated: false,
              name: 'ComplexData',
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
            ),
          ),
        },
        discriminator: 'type',
        context: context,
      );

      final classModel = ClassModel(
        isDeprecated: false,
        name: 'ClassModel',
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

      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfWithDynamic',
        models: {anyOfModel, classModel},
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException('Simple encoding not supported: contains complex types');
          }
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toLabel that throws for cannotBeSimplyEncoded', () {
      final classModel = ClassModel(
        isDeprecated: false,
        name: 'ClassModel',
        properties: [
          Property(
            name: 'nested',
            model: ClassModel(
              isDeprecated: false,
              name: 'NestedClass',
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
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final model = AllOfModel(
        isDeprecated: false,
        name: 'AllOfComplex',
        models: {classModel},
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
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });
  });
}
