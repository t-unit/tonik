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
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      const expectedMethod = '''
        Object? toJson() => {r'name': name};
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
          Property(
            name: 'isActive',
            model: BooleanModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      const expectedMethod = '''
        Object? toJson() => {r'name': name, r'age': age, r'isActive': isActive};
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
        properties: [
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
        ],
        context: context,
      );

      const expectedMethod = '''
        Object? toJson() => {r'name': name, r'bio': bio};
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
        properties: [
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
        ],
        context: context,
      );

      const expectedMethod = '''
        Object? toJson() => {
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
        properties: [
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
        ],
        context: context,
      );

      const expectedMethod = '''
        Object? toJson() => {r'_id': id, r'user-name': userName};
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
        ],
        context: context,
      );

      const expectedMethod = '''
        Object? toJson() => {
          r'name': name,
          r'createdAt': createdAt.toTimeZonedIso8601String(),
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
        name: 'User',
        properties: [
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
        ],
        context: context,
      );

      const expectedMethod = '''
        Object? toJson() => {
          r'tags': tags,
          r'meetingTimes': meetingTimes
              .map((e) => e.toTimeZonedIso8601String())
              .toList(),
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
        properties: const [],
        context: context,
      );
      final mixinModel = ClassModel(
        name: 'Mixin',
        properties: const [],
        context: context,
      );

      final allOfModel = AllOfModel(
        name: 'Combined',
        models: {baseModel, mixinModel},
        context: context,
      );

      final catModel = ClassModel(
        name: 'Cat',
        properties: const [],
        context: context,
      );
      final dogModel = ClassModel(
        name: 'Dog',
        properties: const [],
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
        properties: [
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
        ],
        context: context,
      );

      const expectedMethod = '''
        Object? toJson() => {
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
          context: context,
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
        );

        const expectedMethod = '''
  factory User.fromJson(Object? json) {
    final map = json.decodeMap(context: 'User');
    return User(
      name: map[r'name'].decodeJsonString(context: r'User.name'),
      age: map[r'age'].decodeJsonInt(context: r'User.age'),
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(format(generatedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates fromJson method with nullable properties', () {
      final model = ClassModel(
        context: context,
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
            name: 'bio',
            model: StringModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
      );

      const expectedMethod = '''
  factory User.fromJson(Object? json) {
    final map = json.decodeMap(context: 'User');
    return User(
      name: map[r'name'].decodeJsonString(context: r'User.name'),
      bio: map[r'bio'].decodeJsonNullableString(context: r'User.bio'),
    );
  }''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromJson method with required nullable properties', () {
      final model = ClassModel(
        context: context,
        name: 'User',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
      );

      const expectedMethod = '''
  factory User.fromJson(Object? json) {
    final map = json.decodeMap(context: 'User');
    return User(
      name: map[r'name'].decodeJsonNullableString(context: r'User.name'),
    );
  }''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromJson method with property name normalization', () {
      final model = ClassModel(
        context: context,
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
            name: '_id',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
      );

      const expectedMethod = '''
  factory User.fromJson(Object? json) {
    final map = json.decodeMap(context: 'User');
    return User(
      firstName: map[r'first-name'].decodeJsonString(
        context: r'User.first-name',
      ),
      id: map[r'_id'].decodeJsonString(context: r'User._id'),
    );
  }''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromJson method with properties named json and map', () {
      final model = ClassModel(
        context: context,
        name: 'Test',
        properties: [
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
        ],
      );

      const expectedMethod = '''
  factory Test.fromJson(Object? json) {
    final map = json.decodeMap(context: 'Test');
    return Test(
      json: map[r'json'].decodeJsonString(context: r'Test.json'),
      map: map[r'map'].decodeJsonString(context: r'Test.map'),
    );
  }''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromJson method for class without properties', () {
      final model = ClassModel(
        context: context,
        name: 'EmptyClass',
        properties: const [],
      );

      const expectedMethod = '''
  factory EmptyClass.fromJson(Object? json) {
    return EmptyClass();
  }''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromSimple method for class without properties', () {
      final model = ClassModel(
        context: context,
        name: 'EmptyClass',
        properties: const [],
      );

      const expectedMethod = '''
  factory EmptyClass.fromSimple(String? value) {
    return EmptyClass();
  }''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
