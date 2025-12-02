import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('AnyOfGenerator toDeepObject generation', () {
    late AnyOfGenerator generator;
    late NameManager nameManager;
    late NameGenerator nameGenerator;
    late Context context;
    late DartEmitter emitter;

    setUp(() {
      nameGenerator = NameGenerator();
      nameManager = NameManager(generator: nameGenerator);
      generator = AnyOfGenerator(
        nameManager: nameManager,
        package: 'package:example',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    test('generates toDeepObject method with correct signature', () {
      final model = AnyOfModel(
        description: null,
        name: 'AnyOfPrimitive',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final toDeepObjectMethod = generatedClass.methods.firstWhere(
        (m) => m.name == 'toDeepObject',
      );

      expect(
        toDeepObjectMethod.returns?.accept(emitter).toString(),
        'List<ParameterEntry>',
      );
      expect(toDeepObjectMethod.requiredParameters.length, 1);
      expect(toDeepObjectMethod.requiredParameters.first.name, 'paramName');
      expect(
        toDeepObjectMethod.requiredParameters.first.type
            ?.accept(emitter)
            .toString(),
        'String',
      );
      expect(toDeepObjectMethod.optionalParameters.length, 2);
      expect(
        toDeepObjectMethod.optionalParameters.map((p) => p.name),
        containsAll(['explode', 'allowEmpty']),
      );
    });

    test('generates toDeepObject that delegates to parameterProperties', () {
      final model = AnyOfModel(
        description: null,
        name: 'AnyOfSimple',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final generatedCode = generatedClass.accept(emitter).toString();

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('generates toDeepObject for complex AnyOf', () {
      final model = AnyOfModel(
        description: null,
        name: 'AnyOfComplex',
        models: {
          (
            discriminatorValue: 'model1',
            model: ClassModel(
              description: null,
              name: 'Model1',
              properties: [
                Property(
                  description: null,
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
              description: null,
              name: 'Model2',
              properties: [
                Property(
                  description: null,
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
        discriminator: null,
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final generatedCode = generatedClass.accept(emitter).toString();

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('toDeepObject passes allowLists=false to parameterProperties', () {
      final model = AnyOfModel(
        description: null,
        name: 'AnyOfWithAllowLists',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final generatedCode = generatedClass.accept(emitter).toString();

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('toDeepObject passes alreadyEncoded=true', () {
      final model = AnyOfModel(
        description: null,
        name: 'AnyOfEncoded',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final generatedCode = generatedClass.accept(emitter).toString();

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('toDeepObject handles discriminator via parameterProperties', () {
      final model = AnyOfModel(
        description: null,
        name: 'AnyOfWithDiscriminator',
        models: {
          (
            discriminatorValue: 'model1',
            model: ClassModel(
              description: null,
              name: 'Model1',
              properties: [
                Property(
                  description: null,
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
              description: null,
              name: 'Model2',
              properties: [
                Property(
                  description: null,
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

      final generatedClass = generator.generateClass(model);
      final generatedCode = generatedClass.accept(emitter).toString();

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });
  });
}
