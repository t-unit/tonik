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

  group('ClassGenerator equals method generation', () {
    test('generates equals method with simple properties', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
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

      const expectedMethod = '''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          return other is User && 
            other.name == name && other.age == age;
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates equals method with complex types', () {
      final addressModel = ClassModel(
        isDeprecated: false,
        name: 'Address',
        properties: [
          Property(
            name: 'street',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'address',
            model: addressModel,
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      const expectedMethod = '''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          return other is User && 
            other.name == name && other.address == address;
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates equals method with list types', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
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
        ],
        context: context,
      );

      const expectedMethod = r'''
      @override
      bool operator ==(Object other) {
        if (identical(this, other)) return true;
        const _$deepEquals = DeepCollectionEquality();
        return other is User && 
          other.name == name && 
          _$deepEquals.other.tags, tags;
      }
      ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates equals method with normalized property names', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: [
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
        ],
        context: context,
      );

      const expectedMethod = '''
        @override
        bool operator ==(Object other) {
          if (identical(this, other)) return true;
          return other is User && 
            other.firstName == firstName && other.lastName == lastName;
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates equals method with deeply nested list types', () {
      final nestedListModel = ClassModel(
        isDeprecated: false,
        name: 'NestedData',
        properties: [
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
        ],
        context: context,
      );

      const expectedMethod = r'''
      @override
      bool operator ==(Object other) {
        if (identical(this, other)) return true;
        const _$deepEquals = DeepCollectionEquality();
        return other is NestedData && 
          other.name == name && 
          _$deepEquals.other.nestedList, nestedList;
      }
      ''';

      final generatedClass = generator.generateClass(nestedListModel);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates equals method for class with no properties', () {
      final emptyModel = ClassModel(
        isDeprecated: false,
        name: 'Empty',
        properties: const [],
        context: context,
      );

      const expectedMethod = '''
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Empty;
  }
''';

      final generatedClass = generator.generateClass(emptyModel);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
