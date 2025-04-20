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

  group('ClassGenerator hashCode method generation', () {
    test('generates hashCode method', () {
      final model = ClassModel(
        name: 'User',
        properties: {
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
        },
        context: context,
      );

      const expectedMethod = '''
        @override
        int get hashCode { return Object.hash(name, age); }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates hashCode method with multiple properties', () {
      final model = ClassModel(
        name: 'User',
        properties: {
          Property(
            name: 'id',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'email',
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
        },
        context: context,
      );

      const expectedMethod = '''
        @override
        int get hashCode { return Object.hash(id, name, email, age); }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates hashCode method with nullable properties', () {
      final model = ClassModel(
        name: 'User',
        properties: {
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'bio',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        @override
        int get hashCode { return Object.hash(name, bio); }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates hashCode method with normalized property names', () {
      final model = ClassModel(
        name: 'User',
        properties: {
          Property(
            name: 'first-name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'last_name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        @override
        int get hashCode { return Object.hash(firstName, lastName); }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates hashCode method with list types', () {
      final model = ClassModel(
        name: 'User',
        properties: {
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        @override
        int get hashCode {
          const deepEquals = DeepCollectionEquality();
          return Object.hash(name, deepEquals.hash(tags));
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates hashCode method with deeply nested list types', () {
      final nestedListModel = ClassModel(
        name: 'NestedData',
        properties: {
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'nestedList',
            model: ListModel(
              content: ListModel(
                content: StringModel(context: context),
                context: context,
              ),
              context: context,
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        @override
        int get hashCode {
          const deepEquals = DeepCollectionEquality();
          return Object.hash(name, deepEquals.hash(nestedList));
        }
        ''';

      final generatedClass = generator.generateClass(nestedListModel);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
