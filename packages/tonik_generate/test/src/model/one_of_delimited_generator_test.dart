import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('OneOfGenerator delimited generation', () {
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
      nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );
      generator = OneOfGenerator(
        nameManager: nameManager,
        package: 'example',
        stableModelSorter: StableModelSorter(),
      );
      context = Context.initial();
      emitter = DartEmitter(useNullSafetySyntax: true);
    });

    OneOfModel simpleModel() => OneOfModel(
      isDeprecated: false,
      name: 'OneOfPrimitive',
      models: {
        (discriminatorValue: 'string', model: StringModel(context: context)),
        (discriminatorValue: 'int', model: IntegerModel(context: context)),
      },
      context: context,
      examples: const [],
    );

    test('toPipeDelimited delegates to the parameterProperties encoder', () {
      final classes = generator.generateClasses(simpleModel());
      final baseClass = classes.firstWhere((c) => c.name == 'OneOfPrimitive');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
List<ParameterEntry> toPipeDelimited( String paramName, { required bool allowEmpty, bool allowReserved = false, }) { return parameterProperties(allowEmpty: allowEmpty).toPipeDelimited( paramName, allowEmpty: allowEmpty, allowReserved: allowReserved, ); }
''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toSpaceDelimited delegates to the parameterProperties encoder', () {
      final classes = generator.generateClasses(simpleModel());
      final baseClass = classes.firstWhere((c) => c.name == 'OneOfPrimitive');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
List<ParameterEntry> toSpaceDelimited( String paramName, { required bool allowEmpty, bool allowReserved = false, }) { return parameterProperties(allowEmpty: allowEmpty).toSpaceDelimited( paramName, allowEmpty: allowEmpty, allowReserved: allowReserved, ); }
''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('empty oneOf emits a throwing toPipeDelimited variant', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'EmptyOneOf',
        models: const {},
        context: context,
        examples: const [],
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'EmptyOneOf');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
List<ParameterEntry> toPipeDelimited( String paramName, { required bool allowEmpty, bool allowReserved = false, }) => throw EncodingException( r'EmptyOneOf has no variants and cannot be encoded.', );
''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('empty oneOf emits a throwing toSpaceDelimited variant', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'EmptyOneOf',
        models: const {},
        context: context,
        examples: const [],
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'EmptyOneOf');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
List<ParameterEntry> toSpaceDelimited( String paramName, { required bool allowEmpty, bool allowReserved = false, }) => throw EncodingException( r'EmptyOneOf has no variants and cannot be encoded.', );
''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
