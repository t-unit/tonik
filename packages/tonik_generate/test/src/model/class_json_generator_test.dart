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

  group('ClassGenerator toJson generation', () {
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

    test('generates toJson method with mixed property types', () {
      final enumModel = EnumModel<String>(
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
      );

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
            name: 'createdAt',
            model: DateTimeModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'status',
            model: enumModel,
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
        },
        context: context,
      );

      const expectedMethod = '''
        Map<String, dynamic> toJson() => {
          r'name': name,
          r'createdAt': createdAt.toIso8601String(),
          r'status': status.toJson(),
          r'homeAddress': homeAddress?.toJson(),
        };
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toJson method with List of various types', () {
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
            name: 'meetingTimes',
            model: ListModel(
              content: DateTimeModel(context: context),
              context: context,
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'addresses',
            model: ListModel(content: addressModel, context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        Map<String, dynamic> toJson() => {
          r'tags': tags,
          r'meetingTimes': meetingTimes.map((e) => e.toIso8601String()).toList(),
          r'addresses': addresses?.map((e) => e.toJson()).toList(),
        };
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toJson method with polymorphic model types', () {
      final baseModel = ClassModel(
        name: 'Base',
        properties: const {},
        context: context,
      );
      final mixinModel = ClassModel(
        name: 'Mixin',
        properties: const {},
        context: context,
      );

      final allOfModel = AllOfModel(
        name: 'Combined',
        models: {baseModel, mixinModel},
        context: context,
      );

      final catModel = ClassModel(
        name: 'Cat',
        properties: const {},
        context: context,
      );
      final dogModel = ClassModel(
        name: 'Dog',
        properties: const {},
        context: context,
      );

      final oneOfModel = OneOfModel(
        name: 'Pet',
        models: {
          (discriminatorValue: 'cat', model: catModel),
          (discriminatorValue: 'dog', model: dogModel),
        },
        discriminator: 'petType',
        context: context,
      );

      final model = ClassModel(
        name: 'Container',
        properties: {
          Property(
            name: 'combinedData',
            model: allOfModel,
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'pet',
            model: oneOfModel,
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = '''
        Map<String, dynamic> toJson() => {
          r'combinedData': combinedData.toJson(),
          r'pet': pet?.toJson(),
        };
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('ClassGenerator fromJson generation', () {
    test(
      'generates fromJson method with type validation for simple properties',
      () {
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

        const expectedMethod = r'''
        factory User.fromJson(dynamic json) {
          final map = json;
          if (map is! Map<String, dynamic>) {
            throw ArgumentError('Invalid JSON for User: $json');
          }
          final $name = map[r'name'];
          if ($name is! String) {
            throw ArgumentError('Expected String for name of User, got ${$name}');
          }
          final $age = map[r'age'];
          if ($age is! int) {
            throw ArgumentError('Expected int for age of User, got ${$age}');
          }
          return User(name: $name, age: $age);
        }
        ''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(format(generatedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates fromJson method with nullable properties', () {
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

      const expectedMethod = r'''
        factory User.fromJson(dynamic json) {
          final map = json;
          if (map is! Map<String, dynamic>) {
            throw ArgumentError('Invalid JSON for User: $json');
          }
          final $name = map[r'name'];
          if ($name is! String) {
            throw ArgumentError('Expected String for name of User, got ${$name}');
          }
          final $bio = map[r'bio'];
          if ($bio != null && $bio is! String) {
            throw ArgumentError('Expected String? for bio of User, got ${$bio}');
          }
          return User(name: $name, bio: $bio);
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromJson method with required nullable properties', () {
      final model = ClassModel(
        name: 'User',
        properties: {
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = r'''
        factory User.fromJson(dynamic json) {
          final map = json;
          if (map is! Map<String, dynamic>) {
            throw ArgumentError('Invalid JSON for User: $json');
          }
          final $name = map[r'name'];
          if ($name != null && $name is! String) {
            throw ArgumentError('Expected String? for name of User, got ${$name}');
          }
          return User(name: $name);
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromJson method with property name normalization', () {
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
            name: '_id',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = r'''
        factory User.fromJson(dynamic json) {
          final map = json;
          if (map is! Map<String, dynamic>) {
            throw ArgumentError('Invalid JSON for User: $json');
          }
          final $firstName = map[r'first-name'];
          if ($firstName is! String) {
            throw ArgumentError(
              'Expected String for first-name of User, got ${$firstName}',
            );
          }
          final $id = map[r'_id'];
          if ($id is! String) {
            throw ArgumentError('Expected String for _id of User, got ${$id}');
          }
          return User(firstName: $firstName, id: $id);
        }
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromJson method with properties named json and map', () {
      final model = ClassModel(
        name: 'Test',
        properties: {
          Property(
            name: 'json',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'map',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        },
        context: context,
      );

      const expectedMethod = r'''
        factory Test.fromJson(dynamic json) {
          final map = json;
          if (map is! Map<String, dynamic>) {
            throw ArgumentError('Invalid JSON for Test: $json');
          }
          final $json = map[r'json'];
          if ($json is! String) {
            throw ArgumentError('Expected String for json of Test, got ${$json}');
          }
          final $map = map[r'map'];
          if ($map is! String) {
            throw ArgumentError('Expected String for map of Test, got ${$map}');
          }
          return Test(json: $json, map: $map);
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
