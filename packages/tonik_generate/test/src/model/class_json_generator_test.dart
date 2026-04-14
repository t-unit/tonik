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

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

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

  group('ClassGenerator toJson generation', () {
    test('generates toJson method for simple string property', () {
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
        isDeprecated: false,
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
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        context: context,
      );

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
        isDeprecated: false,
        name: 'Base',
        properties: const [],
        context: context,
      );
      final mixinModel = ClassModel(
        isDeprecated: false,
        name: 'Mixin',
        properties: const [],
        context: context,
      );

      final allOfModel = AllOfModel(
        isDeprecated: false,
        name: 'Combined',
        models: {baseModel, mixinModel},
        context: context,
      );

      final catModel = ClassModel(
        isDeprecated: false,
        name: 'Cat',
        properties: const [],
        context: context,
      );
      final dogModel = ClassModel(
        isDeprecated: false,
        name: 'Dog',
        properties: const [],
        context: context,
      );

      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'Pet',
        models: {
          (discriminatorValue: 'cat', model: catModel),
          (discriminatorValue: 'dog', model: dogModel),
        },
        discriminator: 'petType',
        context: context,
      );

      final model = ClassModel(
        isDeprecated: false,
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

    test('generates toJson method with polymorphic model types', () {
      final baseModel = ClassModel(
        isDeprecated: false,
        name: 'Base',
        properties: const [],
        context: context,
      );
      final mixinModel = ClassModel(
        isDeprecated: false,
        name: 'Mixin',
        properties: const [],
        context: context,
      );

      final allOfModel = AllOfModel(
        isDeprecated: false,
        name: 'Combined',
        models: {baseModel, mixinModel},
        context: context,
      );

      final catModel = ClassModel(
        isDeprecated: false,
        name: 'Cat',
        properties: const [],
        context: context,
      );
      final dogModel = ClassModel(
        isDeprecated: false,
        name: 'Dog',
        properties: const [],
        context: context,
      );

      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'Pet',
        models: {
          (discriminatorValue: 'cat', model: catModel),
          (discriminatorValue: 'dog', model: dogModel),
        },
        discriminator: 'petType',
        context: context,
      );

      final model = ClassModel(
        isDeprecated: false,
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

    test('generates toJson method for Uri property', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Resource',
        properties: [
          Property(
            name: 'endpoint',
            model: UriModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      const expectedMethod = '''
        Object? toJson() => {r'endpoint': endpoint.toString()};
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toJson method for nullable Uri property', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Resource',
        properties: [
          Property(
            name: 'callback',
            model: UriModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      const expectedMethod = '''
        Object? toJson() => {r'callback': callback?.toString()};
        ''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toJson method for multiple Uri properties', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'Resource',
        properties: [
          Property(
            name: 'endpoint',
            model: UriModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
          Property(
            name: 'callback',
            model: UriModel(context: context),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
          ),
          Property(
            name: 'webhook',
            model: UriModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      const expectedMethod = '''
        Object? toJson() => {
          r'endpoint': endpoint.toString(),
          r'callback': callback?.toString(),
          r'webhook': webhook.toString(),
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
          isDeprecated: false,
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

        const expectedMethod = r'''
  factory User.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'User');
    return User(
      name: _$map[r'name'].decodeJsonString(context: r'User.name'),
      age: _$map[r'age'].decodeJsonInt(context: r'User.age'),
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
        isDeprecated: false,
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

      const expectedMethod = r'''
  factory User.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'User');
    return User(
      name: _$map[r'name'].decodeJsonString(context: r'User.name'),
      bio: _$map[r'bio'].decodeJsonNullableString(context: r'User.bio'),
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
        isDeprecated: false,
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

      const expectedMethod = r'''
  factory User.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'User');
    return User(
      name: _$map[r'name'].decodeJsonNullableString(context: r'User.name'),
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
        isDeprecated: false,
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

      const expectedMethod = r'''
  factory User.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'User');
    return User(
      firstName: _$map[r'first-name'].decodeJsonString(
        context: r'User.first-name',
      ),
      id: _$map[r'_id'].decodeJsonString(context: r'User._id'),
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
        isDeprecated: false,
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

      const expectedMethod = r'''
  factory Test.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'Test');
    return Test(
      json: _$map[r'json'].decodeJsonString(context: r'Test.json'),
      map: _$map[r'map'].decodeJsonString(context: r'Test.map'),
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
        isDeprecated: false,
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

    test(
      'generates fromJson with null check for required property '
      'referencing nullable ClassModel',
      () {
        // ClassModel with isNullable=true produces `typedef Foo = $RawFoo?`,
        // so fromJson must use the nullable decoder.
        final nullableClass = ClassModel(
          isDeprecated: false,
          name: 'NullableLicense',
          properties: [
            Property(
              name: 'key',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
          isNullable: true,
        );

        final model = ClassModel(
          isDeprecated: false,
          context: context,
          name: 'Repo',
          properties: [
            Property(
              name: 'license',
              model: nullableClass,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        const expectedMethod = r'''
  factory Repo.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'Repo');
    return Repo(
      license: _$map[r'license'] == null
          ? null
          : NullableLicense.fromJson(_$map[r'license']),
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(format(generatedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'generates fromJson with null check for required property '
      'referencing nullable AliasModel',
      () {
        // AliasModel wrapping a string with isNullable=true
        final nullableAlias = AliasModel(
          name: 'NullableDescription',
          model: StringModel(context: context),
          isNullable: true,
          context: context,
        );

        final model = ClassModel(
          isDeprecated: false,
          context: context,
          name: 'Item',
          properties: [
            Property(
              name: 'description',
              model: nullableAlias,
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
        );

        const expectedMethod = r'''
  factory Item.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'Item');
    return Item(
      description: _$map[r'description'].decodeJsonNullableString(
        context: r'Item.description',
      ),
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(format(generatedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates fromSimple method for class without properties', () {
      final model = ClassModel(
        isDeprecated: false,
        context: context,
        name: 'EmptyClass',
        properties: const [],
      );

      const expectedMethod = '''
  factory EmptyClass.fromSimple(String? value, {required bool explode}) {
    return EmptyClass();
  }''';

      final generatedClass = generator.generateClass(model);
      expect(
        collapseWhitespace(format(generatedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('ClassGenerator additionalProperties', () {
    group('unrestricted additionalProperties', () {
      late ClassModel model;

      setUp(() {
        model = ClassModel(
          isDeprecated: false,
          name: 'Config',
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
          additionalProperties: const UnrestrictedAdditionalProperties(),
        );
      });

      test('generates fromJson with AP collection', () {
        const expectedMethod = r'''
  factory Config.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'Config');
    const _$knownKeys = {r'name'};
    final _$additional = <String, Object?>{};
    for (final _$entry in _$map.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value;
      }
    }
    return Config(
      name: _$map[r'name'].decodeJsonString(context: r'Config.name'),
      additionalProperties: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates toJson spreading AP into map', () {
        const expectedMethod =
            "Object? toJson() => {r'name': name, ...additionalProperties};";

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates fromSimple with AP capture', () {
        const expectedMethod = r'''
  factory Config.fromSimple(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'name'},
      listKeys: {},
      context: r'Config',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'name'};
    final _$additional = <String, Object?>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeSimpleString(
          context: r'Config.additionalProperties',
        );
      }
    }
    return Config(
      name: _$values[r'name'].decodeSimpleString(context: r'Config.name'),
      additionalProperties: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates fromForm with AP capture', () {
        const expectedMethod = r'''
  factory Config.fromForm(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'name'},
      listKeys: {},
      context: r'Config',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'name'};
    final _$additional = <String, Object?>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeFormString(
          context: r'Config.additionalProperties',
        );
      }
    }
    return Config(
      name: _$values[r'name'].decodeFormString(context: r'Config.name'),
      additionalProperties: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates parameterProperties with AP loop', () {
        const expectedMethod = r'''
  Map<String, String> parameterProperties({
    bool allowEmpty = true,
    bool allowLists = true,
    bool useQueryComponent = false,
  }) {
    final _$result = <String, String>{};
    _$result[r'name'] = name.uriEncode(
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    );
    for (final _$e in additionalProperties.entries) {
      _$result[_$e.key] = _$e.value?.toString() ?? '';
    }
    return _$result;
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('typed additionalProperties with string values', () {
      late ClassModel model;

      setUp(() {
        model = ClassModel(
          isDeprecated: false,
          name: 'Labels',
          properties: [
            Property(
              name: 'id',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
          additionalProperties: TypedAdditionalProperties(
            valueModel: StringModel(context: context),
          ),
        );
      });

      test('generates fromJson decoding string AP values', () {
        const expectedMethod = r'''
  factory Labels.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'Labels');
    const _$knownKeys = {r'id'};
    final _$additional = <String, String>{};
    for (final _$entry in _$map.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeJsonString(
          context: r'Labels.additionalProperties',
        );
      }
    }
    return Labels(
      id: _$map[r'id'].decodeJsonInt(context: r'Labels.id'),
      additionalProperties: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates toJson spreading typed AP directly', () {
        const expectedMethod =
            "Object? toJson() => {r'id': id, ...additionalProperties};";

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates fromSimple decoding string AP values', () {
        const expectedMethod = r'''
  factory Labels.fromSimple(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'id'},
      listKeys: {},
      context: r'Labels',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'id'};
    final _$additional = <String, String>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeSimpleString(
          context: r'Labels.additionalProperties',
        );
      }
    }
    return Labels(
      id: _$values[r'id'].decodeSimpleInt(context: r'Labels.id'),
      additionalProperties: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates fromForm decoding string AP values', () {
        const expectedMethod = r'''
  factory Labels.fromForm(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'id'},
      listKeys: {},
      context: r'Labels',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'id'};
    final _$additional = <String, String>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeFormString(
          context: r'Labels.additionalProperties',
        );
      }
    }
    return Labels(
      id: _$values[r'id'].decodeFormInt(context: r'Labels.id'),
      additionalProperties: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('typed additionalProperties with complex values', () {
      late ClassModel model;

      setUp(() {
        model = ClassModel(
          isDeprecated: false,
          name: 'WidgetMap',
          properties: [
            Property(
              name: 'version',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
          additionalProperties: TypedAdditionalProperties(
            valueModel: ClassModel(
              isDeprecated: false,
              name: 'Widget',
              properties: const [],
              context: context,
            ),
          ),
        );
      });

      test('generates fromJson decoding complex AP values', () {
        const expectedMethod = r'''
  factory WidgetMap.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'WidgetMap');
    const _$knownKeys = {r'version'};
    final _$additional = <String, Widget>{};
    for (final _$entry in _$map.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = Widget.fromJson(_$entry.value);
      }
    }
    return WidgetMap(
      version: _$map[r'version'].decodeJsonInt(context: r'WidgetMap.version'),
      additionalProperties: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates toJson encoding complex AP values', () {
        const expectedMethod = '''
  Object? toJson() => {
    r'version': version,
    ...additionalProperties.map((k, v) => MapEntry(k, v.toJson())),
  };''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates fromSimple without AP capture', () {
        const expectedMethod = r'''
  factory WidgetMap.fromSimple(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'version'},
      listKeys: {},
      context: r'WidgetMap',
    );
    return WidgetMap(
      version: _$values[r'version'].decodeSimpleInt(
        context: r'WidgetMap.version',
      ),
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('NoAdditionalProperties', () {
      test('generates fromJson without AP logic', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Strict',
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
          additionalProperties: const NoAdditionalProperties(),
        );

        const expectedMethod = r'''
  factory Strict.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'Strict');
    return Strict(
      name: _$map[r'name'].decodeJsonString(context: r'Strict.name'),
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('AP field name collision', () {
      test('renames AP field to additionalProperties2', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'Collision',
          properties: [
            Property(
              name: 'additionalProperties',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
          additionalProperties: const UnrestrictedAdditionalProperties(),
        );

        const expectedMethod = r'''
  factory Collision.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'Collision');
    const _$knownKeys = {r'additionalProperties'};
    final _$additional = <String, Object?>{};
    for (final _$entry in _$map.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value;
      }
    }
    return Collision(
      additionalProperties: _$map[r'additionalProperties'].decodeJsonString(
        context: r'Collision.additionalProperties',
      ),
      additionalProperties2: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('nullable typed additionalProperties', () {
      test('generates fromJson with nullable AP value decoding', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'MixedNullable',
          properties: [
            Property(
              name: 'name',
              model: StringModel(context: context),
              isRequired: false,
              isNullable: true,
              isDeprecated: false,
            ),
          ],
          context: context,
          additionalProperties: TypedAdditionalProperties(
            valueModel: AliasModel(
              name: 'NullableString',
              model: StringModel(context: context),
              context: context,
              isNullable: true,
            ),
          ),
        );

        const expectedMethod = r'''
  factory MixedNullable.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'MixedNullable');
    const _$knownKeys = {r'name'};
    final _$additional = <String, NullableString>{};
    for (final _$entry in _$map.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeJsonNullableString(
          context: r'MixedNullable.additionalProperties',
        );
      }
    }
    return MixedNullable(
      name: _$map[r'name'].decodeJsonNullableString(
        context: r'MixedNullable.name',
      ),
      additionalProperties: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('typed primitive AP captures in fromSimple/fromForm', () {
      test('generates fromSimple with AP capture for int values', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'IntTyped',
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
          additionalProperties: TypedAdditionalProperties(
            valueModel: IntegerModel(context: context),
          ),
        );

        const expectedMethod = r'''
  factory IntTyped.fromSimple(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'name'},
      listKeys: {},
      context: r'IntTyped',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'name'};
    final _$additional = <String, int>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeSimpleInt(
          context: r'IntTyped.additionalProperties',
        );
      }
    }
    return IntTyped(
      name: _$values[r'name'].decodeSimpleString(context: r'IntTyped.name'),
      additionalProperties: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates fromForm with AP capture for int values', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'IntTyped',
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
          additionalProperties: TypedAdditionalProperties(
            valueModel: IntegerModel(context: context),
          ),
        );

        const expectedMethod = r'''
  factory IntTyped.fromForm(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'name'},
      listKeys: {},
      context: r'IntTyped',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'name'};
    final _$additional = <String, int>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeFormInt(
          context: r'IntTyped.additionalProperties',
        );
      }
    }
    return IntTyped(
      name: _$values[r'name'].decodeFormString(context: r'IntTyped.name'),
      additionalProperties: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates fromSimple with AP capture for bool values', () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'BoolTyped',
          properties: [
            Property(
              name: 'label',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
          additionalProperties: TypedAdditionalProperties(
            valueModel: BooleanModel(context: context),
          ),
        );

        const expectedMethod = r'''
  factory BoolTyped.fromSimple(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'label'},
      listKeys: {},
      context: r'BoolTyped',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'label'};
    final _$additional = <String, bool>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeSimpleBool(
          context: r'BoolTyped.additionalProperties',
        );
      }
    }
    return BoolTyped(
      label: _$values[r'label'].decodeSimpleString(context: r'BoolTyped.label'),
      additionalProperties: _$additional,
    );
  }''';

        final generatedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(generatedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });
  });
}
