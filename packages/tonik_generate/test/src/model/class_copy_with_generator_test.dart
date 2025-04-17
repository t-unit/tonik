import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/util/name_generator.dart';
import 'package:tonik_generate/src/util/name_manager.dart';

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

  group('ClassGenerator copyWith generation', () {
    test('generates copyWith method for simple properties', () {
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
        User copyWith({String? name, int? age}) {
          return User(name: name ?? this.name, age: age ?? this.age);
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates copyWith method with nullable properties', () {
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
        User copyWith({String? name, String? bio}) {
          return User(name: name ?? this.name, bio: bio ?? this.bio);
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates copyWith method with optional non-nullable properties', () {
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
            isRequired: false, // Optional in constructor
            isNullable: false, // But not nullable
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        User copyWith({String? name, String? nickname}) {
          return User(name: name ?? this.name, nickname: nickname ?? this.nickname);
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates copyWith method with complex types', () {
      final addressModel = ClassModel(
        name: 'Address',
        properties: {
          Property(
            name: 'street',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        },
        context: context,
      );

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
            name: 'homeAddress',
            model: addressModel,
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
          Property(
            name: 'workAddress',
            model: addressModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        User copyWith({String? name, Address? homeAddress, Address? workAddress}) {
          return User(
            name: name ?? this.name,
            homeAddress: homeAddress ?? this.homeAddress,
            workAddress: workAddress ?? this.workAddress,
          );
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates copyWith method with list types', () {
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
          Property(
            name: 'optionalTags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
            ),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        User copyWith({
          String? name,
          List<String>? tags,
          List<String>? optionalTags,
        }) {
          return User(
            name: name ?? this.name,
            tags: tags ?? this.tags,
            optionalTags: optionalTags ?? this.optionalTags,
          );
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates copyWith method with normalized property names', () {
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
          Property(
            name: '_id',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        User copyWith({String? firstName, String? lastName, String? id}) {
          return User(
            firstName: firstName ?? this.firstName,
            lastName: lastName ?? this.lastName,
            id: id ?? this.id,
          );
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
