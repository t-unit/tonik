import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('ClassGenerator delimited generation', () {
    late ClassGenerator generator;
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
      generator = ClassGenerator(
        nameManager: nameManager,
        package: 'example',
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    ClassModel singlePropertyModel() => ClassModel(
      isDeprecated: false,
      name: 'TestModel',
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
    );

    test('toPipeDelimited has the delimited signature', () {
      final result = generator.generateClass(singlePropertyModel());
      final method = result.methods.firstWhere(
        (m) => m.name == 'toPipeDelimited',
      );

      expect(
        method.returns?.accept(emitter).toString(),
        'List<ParameterEntry>',
      );
      expect(method.requiredParameters.length, 1);
      expect(method.requiredParameters.first.name, 'paramName');
      expect(
        method.requiredParameters.first.type?.accept(emitter).toString(),
        'String',
      );
      expect(method.optionalParameters.length, 2);
      expect(method.optionalParameters.first.name, 'allowEmpty');
      expect(method.optionalParameters.first.required, isTrue);
      expect(method.optionalParameters.first.named, isTrue);
      expect(method.optionalParameters.last.name, 'allowReserved');
      expect(method.optionalParameters.last.required, isFalse);
      expect(method.optionalParameters.last.named, isTrue);
    });

    test('toSpaceDelimited has the delimited signature', () {
      final result = generator.generateClass(singlePropertyModel());
      final method = result.methods.firstWhere(
        (m) => m.name == 'toSpaceDelimited',
      );

      expect(
        method.returns?.accept(emitter).toString(),
        'List<ParameterEntry>',
      );
      expect(method.requiredParameters.length, 1);
      expect(method.requiredParameters.first.name, 'paramName');
      expect(method.optionalParameters.length, 2);
      expect(method.optionalParameters.first.name, 'allowEmpty');
      expect(method.optionalParameters.last.name, 'allowReserved');
    });

    test('toPipeDelimited delegates to the parameterProperties encoder', () {
      final result = generator.generateClass(singlePropertyModel());

      const expectedMethod = '''
        List<ParameterEntry> toPipeDelimited(String paramName, {required bool allowEmpty, bool allowReserved = false, }) {
          return parameterProperties(allowEmpty: allowEmpty).toPipeDelimited(paramName, allowEmpty: allowEmpty, allowReserved: allowReserved, );
        }
      ''';

      final generatedCode = result.accept(emitter).toString();
      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toSpaceDelimited delegates to the parameterProperties encoder', () {
      final result = generator.generateClass(singlePropertyModel());

      const expectedMethod = '''
        List<ParameterEntry> toSpaceDelimited(String paramName, {required bool allowEmpty, bool allowReserved = false, }) {
          return parameterProperties(allowEmpty: allowEmpty).toSpaceDelimited(paramName, allowEmpty: allowEmpty, allowReserved: allowReserved, );
        }
      ''';

      final generatedCode = result.accept(emitter).toString();
      expect(
        collapseWhitespace(generatedCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('delimited methods carry the @override annotation', () {
      final result = generator.generateClass(singlePropertyModel());

      for (final methodName in ['toPipeDelimited', 'toSpaceDelimited']) {
        final method = result.methods.firstWhere((m) => m.name == methodName);
        expect(
          method.annotations.any(
            (a) => a.accept(emitter).toString().contains('override'),
          ),
          isTrue,
        );
      }
    });
  });
}
