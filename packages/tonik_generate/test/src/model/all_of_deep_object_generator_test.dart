import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('AllOfGenerator toDeepObject generation', () {
    late AllOfGenerator generator;
    late NameManager nameManager;
    late NameGenerator nameGenerator;
    late Context context;
    late DartEmitter emitter;

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

    test('generates toDeepObject method with correct signature', () {
      final model = AllOfModel(
        name: 'AllOfPrimitive',
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
        },
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

    test('generates toDeepObject for simple-only AllOf', () {
      final model = AllOfModel(
        name: 'AllOfSimple',
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

      final generatedCode = generatedClass.accept(emitter).toString();
      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('generates toDeepObject for complex AllOf', () {
      final model = AllOfModel(
        name: 'AllOfComplex',
        models: {
          ClassModel(
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
          ClassModel(
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
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

      final generatedCode = generatedClass.accept(emitter).toString();
      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('generates toDeepObject for empty AllOf', () {
      final model = AllOfModel(
        name: 'AllOfEmpty',
        models: const {},
        context: context,
      );

      final generatedClass = generator.generateClass(model);

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

      final generatedCode = generatedClass.accept(emitter).toString();
      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('toDeepObject passes allowLists=false to parameterProperties', () {
      final model = AllOfModel(
        name: 'AllOfWithAllowLists',
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

      final generatedCode = generatedClass.accept(emitter).toString();
      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });

    test('toDeepObject passes alreadyEncoded=true', () {
      final model = AllOfModel(
        name: 'AllOfEncoded',
        models: {
          StringModel(context: context),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);

      const expectedToDeepObjectMethod = '''
        List<ParameterEntry> toDeepObject(String paramName, {required bool explode, required bool allowEmpty, }) {
          return parameterProperties(allowEmpty: allowEmpty, allowLists: false, ).toDeepObject(paramName, explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
        }
      ''';

      final generatedCode = generatedClass.accept(emitter).toString();
      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedToDeepObjectMethod)),
      );
    });
  });
}
