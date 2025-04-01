import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/model/class_generator.dart';
import 'package:tonic_generate/src/util/name_generator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

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

  group('ClassGenerator JSON generation', () {
    test('generates toJson method for simple string property', () {
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
        },
        context: context,
      );

      const expectedMethod = '''
        Map<String, dynamic> toJson() => {r'name': name};
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toJson method for multiple primitive properties', () {
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
          Property(
            name: 'isActive',
            model: BooleanModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        Map<String, dynamic> toJson() => {
          r'name': name,
          r'age': age,
          r'isActive': isActive,
        };
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toJson method with nullable properties', () {
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
        Map<String, dynamic> toJson() => {r'name': name, r'bio': bio};
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toJson method with optional non-nullable properties', () {
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
            name: 'nickname',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: false,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        Map<String, dynamic> toJson() => {
          r'name': name, 
          if (nickname != null) r'nickname': nickname, 
        };
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toJson method with raw property names', () {
      final model = ClassModel(
        name: 'User',
        properties: {
          Property(
            name: '_id',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'user-name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        Map<String, dynamic> toJson() => {r'_id': id, r'user-name': userName};
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
