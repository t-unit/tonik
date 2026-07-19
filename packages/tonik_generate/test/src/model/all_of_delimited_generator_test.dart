import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('AllOfGenerator delimited generation', () {
    late AllOfGenerator generator;
    late NameManager nameManager;
    late NameGenerator nameGenerator;
    late Context context;
    late DartEmitter emitter;

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

    AllOfModel simpleModel() => AllOfModel(
      isDeprecated: false,
      name: 'AllOfSimple',
      models: {
        StringModel(context: context),
        IntegerModel(context: context),
      },
      context: context,
      examples: const [],
    );

    test('toPipeDelimited has the delimited signature', () {
      final generatedClass = generator.generateClass(simpleModel());
      final method = generatedClass.methods.firstWhere(
        (m) => m.name == 'toPipeDelimited',
      );

      expect(
        method.returns?.accept(emitter).toString(),
        'List<ParameterEntry>',
      );
      expect(method.requiredParameters.length, 1);
      expect(method.requiredParameters.first.name, 'paramName');
      expect(method.optionalParameters.length, 2);
      expect(
        method.optionalParameters.map((p) => p.name),
        containsAll(['allowEmpty', 'allowReserved']),
      );
    });

    test('toPipeDelimited delegates to the parameterProperties encoder', () {
      final generatedClass = generator.generateClass(simpleModel());

      const expectedMethod = '''
        List<ParameterEntry> toPipeDelimited(String paramName, {required bool allowEmpty, bool allowReserved = false, }) {
          return parameterProperties(allowEmpty: allowEmpty).toPipeDelimited(paramName, allowEmpty: allowEmpty, allowReserved: allowReserved, );
        }
      ''';

      final generatedCode = generatedClass.accept(emitter).toString();
      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toSpaceDelimited delegates to the parameterProperties encoder', () {
      final generatedClass = generator.generateClass(simpleModel());

      const expectedMethod = '''
        List<ParameterEntry> toSpaceDelimited(String paramName, {required bool allowEmpty, bool allowReserved = false, }) {
          return parameterProperties(allowEmpty: allowEmpty).toSpaceDelimited(paramName, allowEmpty: allowEmpty, allowReserved: allowReserved, );
        }
      ''';

      final generatedCode = generatedClass.accept(emitter).toString();
      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
