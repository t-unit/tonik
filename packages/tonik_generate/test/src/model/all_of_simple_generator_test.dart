import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late AllOfGenerator generator;
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
    generator = AllOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  test('generates toSimple for allOf with list of DateTime', () {
    final model = AllOfModel(
      isDeprecated: false,
      description: null,
      name: 'AllOfDateTimeList',
      models: {
        ListModel(
          content: DateTimeModel(context: context),
          context: context,
        ),
      },
      context: context,
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToSimple = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          final values = <String>{};
          final listSimple = list
            .map((e) => e.toSimple(explode: explode, allowEmpty: allowEmpty))
            .toList()
            .toSimple( explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
          values.add(listSimple);
          if (values.length > 1) {
            throw EncodingException(
              'Inconsistent allOf simple encoding: all values must encode to the same result',
            );
          }
          return values.first;
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToSimple)),
    );
  });

  test('generates toSimple for allOf with two lists', () {
    final oneOfModel = OneOfModel(
      isDeprecated: false,
      description: null,
      name: 'ArrayOneOfModel',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (discriminatorValue: null, model: IntegerModel(context: context)),
      },
      discriminator: null,
      context: context,
    );

    final model = AllOfModel(
      isDeprecated: false,
      description: null,
      name: 'AllOfDoubleList',
      models: {
        ListModel(
          content: DateTimeModel(context: context),
          context: context,
        ),
        ListModel(
          content: oneOfModel,
          context: context,
        ),
      },
      context: context,
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToSimple = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          final values = <String>{};
          final listSimple = list
            .map((e) => e.toSimple(explode: explode, allowEmpty: allowEmpty))
            .toList()
            .toSimple( explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
          values.add(listSimple);
          final list2Simple = list2
            .map((e) => e.toSimple(explode: explode, allowEmpty: allowEmpty))
            .toList()
            .toSimple( explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true, );
          values.add(list2Simple);
          if (values.length > 1) {
            throw EncodingException(
              'Inconsistent allOf simple encoding: all values must encode to the same result',
            );
          }
          return values.first;
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToSimple)),
    );
  });

  test('generates toSimple merging all class properties', () {
    final model = AllOfModel(
      isDeprecated: false,
      description: null,
      name: 'CombinedModel',
      models: <Model>{
        ClassModel(
          isDeprecated: false,
          description: null,
          name: 'Base',
          properties: [
            Property(
              description: null,
              name: 'id',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        ),
        ClassModel(
          isDeprecated: false,
          description: null,
          name: 'Mixin',
          properties: [
            Property(
              description: null,
              name: 'value',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        ),
      },
      context: context,
    );

    final combinedClass = generator.generateClass(model);

    const expectedToSimpleMethod = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toSimple(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';

    expect(
      collapseWhitespace(format(combinedClass.accept(emitter).toString())),
      contains(collapseWhitespace(expectedToSimpleMethod)),
    );
  });

  test('generates toSimple returning primary primitive value', () {
    final model = AllOfModel(
      isDeprecated: false,
      description: null,
      name: 'StringDecimalModel',
      models: {
        StringModel(context: context),
        DecimalModel(context: context),
      },
      context: context,
    );

    final combinedClass = generator.generateClass(model);

    const expectedToSimpleMethod = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          return bigDecimal.toSimple(explode: explode, allowEmpty: allowEmpty);
        }
      ''';

    expect(
      collapseWhitespace(format(combinedClass.accept(emitter).toString())),
      contains(collapseWhitespace(expectedToSimpleMethod)),
    );
  });

  test(
    'generates toSimple returning enum value for enum and string models',
    () {
      final model = AllOfModel(
        isDeprecated: false,
        description: null,
        name: 'EnumStringModel',
        models: {
          EnumModel(
            isDeprecated: false,
            description: null,
            name: 'Status',
            values: const {'active', 'inactive'},
            isNullable: false,
            context: context,
          ),
          StringModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);

      const expectedToSimpleMethod = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          return status.toSimple(explode: explode, allowEmpty: allowEmpty);
        }
      ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedToSimpleMethod)),
      );
    },
  );

  test(
    'throws exception for mixed types in toSimple',
    () {
      final model = AllOfModel(
        isDeprecated: false,
        description: null,
        name: 'MixedModel',
        models: <Model>{
          StringModel(context: context),
          ClassModel(
            isDeprecated: false,
            description: null,
            name: 'UserData',
            properties: [
              Property(
                description: null,
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          ),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);

      const expectedToSimpleMethod = '''
          String toSimple({required bool explode, required bool allowEmpty}) {
            throw EncodingException(
              'Simple encoding not supported: contains complex types',
            );
          }
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedToSimpleMethod)),
      );
    },
  );

  test(
    'generates toSimple returning primary model value for primitive-only '
    'mixed types',
    () {
      final model = AllOfModel(
        isDeprecated: false,
        description: null,
        name: 'MixedModel',
        models: {
          StringModel(context: context),
          EnumModel(
            isDeprecated: false,
            description: null,
            name: 'Status',
            values: const {'active', 'inactive'},
            isNullable: false,
            context: context,
          ),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);

      const expectedToSimpleMethod = '''
          String toSimple({required bool explode, required bool allowEmpty}) {
            return status.toSimple(explode: explode, allowEmpty: allowEmpty);
          }
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedToSimpleMethod)),
      );
    },
  );

  test('allOf with mixed anyOf and primitive validates at runtime', () {
    final anyOfModel = AnyOfModel(
      isDeprecated: false,
      description: null,
      name: 'FlexibleValue',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            description: null,
            name: 'Data',
            properties: [
              Property(
                description: null,
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          ),
        ),
      },
      discriminator: null,
      context: context,
    );

    final model = AllOfModel(
      isDeprecated: false,
      description: null,
      name: 'Combined',
      models: {
        IntegerModel(context: context),
        anyOfModel,
      },
      context: context,
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedToSimpleMethod = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException(
              'Simple encoding not supported: contains complex types',
            );
          }
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toSimple(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedToSimpleMethod)),
    );
  });

  test('allOf with mixed anyOf and primitive allows fromSimple decoding', () {
    final anyOfModel = AnyOfModel(
      isDeprecated: false,
      description: null,
      name: 'FlexibleValue',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (
          discriminatorValue: null,
          model: ClassModel(
            isDeprecated: false,
            description: null,
            name: 'Data',
            properties: [
              Property(
                description: null,
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          ),
        ),
      },
      discriminator: null,
      context: context,
    );

    final model = AllOfModel(
      isDeprecated: false,
      description: null,
      name: 'Combined',
      models: {
        IntegerModel(context: context),
        anyOfModel,
      },
      context: context,
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedFromSimpleMethod = '''
        factory Combined.fromSimple(String? value, {required bool explode}) {
          return Combined(
            flexibleValue: FlexibleValue.fromSimple(value, explode: explode),
            int: value.decodeSimpleInt(context: r'Combined.int'),
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedFromSimpleMethod)),
    );
  });

  test('generates fromSimple for allOf with list of int', () {
    final model = AllOfModel(
      isDeprecated: false,
      description: null,
      name: 'AllOfIntList',
      models: {
        ListModel(
          content: IntegerModel(context: context),
          context: context,
        ),
      },
      context: context,
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedFromSimple = '''
        factory AllOfIntList.fromSimple(String? value, {required bool explode}) {
          return AllOfIntList(
            list: value
              .decodeSimpleStringList(context: r'AllOfIntList.list')
              .map((e) => e.decodeSimpleInt(context: r'AllOfIntList.list'))
              .toList(),
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedFromSimple)),
    );
  });

  test('generates fromSimple for allOf with list of DateTime', () {
    final model = AllOfModel(
      isDeprecated: false,
      description: null,
      name: 'AllOfDateTimeList',
      models: {
        ListModel(
          content: DateTimeModel(context: context),
          context: context,
        ),
      },
      context: context,
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedFromSimple = '''
        factory AllOfDateTimeList.fromSimple(String? value, {required bool explode}) {
          return AllOfDateTimeList(
            list: value
              .decodeSimpleStringList(context: r'AllOfDateTimeList.list')
              .map(
                (e) => e.decodeSimpleDateTime(context: r'AllOfDateTimeList.list'),
              )
              .toList(),
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedFromSimple)),
    );
  });

  test('generates fromSimple for allOf with list of Date', () {
    final model = AllOfModel(
      isDeprecated: false,
      description: null,
      name: 'AllOfDateList',
      models: {
        ListModel(
          content: DateModel(context: context),
          context: context,
        ),
      },
      context: context,
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedFromSimple = '''
        factory AllOfDateList.fromSimple(String? value, {required bool explode}) {
          return AllOfDateList(
            list: value
              .decodeSimpleStringList(context: r'AllOfDateList.list')
              .map((e) => e.decodeSimpleDate(context: r'AllOfDateList.list'))
              .toList(),
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedFromSimple)),
    );
  });

  test('generates fromSimple for allOf with two lists', () {
    final oneOfModel = OneOfModel(
      isDeprecated: false,
      description: null,
      name: 'ArrayOneOfModel',
      models: {
        (discriminatorValue: null, model: StringModel(context: context)),
        (discriminatorValue: null, model: IntegerModel(context: context)),
      },
      discriminator: null,
      context: context,
    );

    final model = AllOfModel(
      isDeprecated: false,
      description: null,
      name: 'AllOfDoubleList',
      models: {
        ListModel(
          content: DateTimeModel(context: context),
          context: context,
        ),
        ListModel(
          content: oneOfModel,
          context: context,
        ),
      },
      context: context,
    );

    final combinedClass = generator.generateClass(model);
    final generated = format(combinedClass.accept(emitter).toString());

    const expectedFromSimple = '''
        factory AllOfDoubleList.fromSimple(String? value, {required bool explode}) {
          return AllOfDoubleList(
            list: value
              .decodeSimpleStringList(context: r'AllOfDoubleList.list')
              .map((e) => e.decodeSimpleDateTime(context: r'AllOfDoubleList.list'))
              .toList(),
            list2: value
              .decodeSimpleStringList(context: r'AllOfDoubleList.list2')
              .map((e) => ArrayOneOfModel.fromSimple(e, explode: explode))
              .toList(),
          );
        }
      ''';

    expect(
      collapseWhitespace(generated),
      contains(collapseWhitespace(expectedFromSimple)),
    );
  });

  test('generates fromSimple merging properties from single value', () {
    final model = AllOfModel(
      isDeprecated: false,
      description: null,
      name: 'CombinedModel',
      models: <Model>{
        ClassModel(
          isDeprecated: false,
          description: null,
          name: 'Base',
          properties: [
            Property(
              description: null,
              name: 'id',
              model: StringModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        ),
        ClassModel(
          isDeprecated: false,
          description: null,
          name: 'Mixin',
          properties: [
            Property(
              description: null,
              name: 'value',
              model: IntegerModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        ),
      },
      context: context,
    );

    final combinedClass = generator.generateClass(model);

    const expectedFromSimpleMethod = r'''
        factory CombinedModel.fromSimple(String? value, {required bool explode}) {
          return CombinedModel(
            $base: Base.fromSimple(value, explode: explode),
            $mixin: Mixin.fromSimple(value, explode: explode),
          );
        }
      ''';

    expect(
      collapseWhitespace(format(combinedClass.accept(emitter).toString())),
      contains(collapseWhitespace(expectedFromSimpleMethod)),
    );
  });

  test(
    'generates fromSimple validating single value against all primitive '
    'types',
    () {
      final model = AllOfModel(
        isDeprecated: false,
        description: null,
        name: 'StringDecimalModel',
        models: <Model>{
          StringModel(context: context),
          DecimalModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);

      const expectedFromSimpleMethod = '''
        factory StringDecimalModel.fromSimple(
          String? value, {
          required bool explode,
        }) {
          return StringDecimalModel(
            bigDecimal: value.decodeSimpleBigDecimal(
              context: r'StringDecimalModel.bigDecimal',
            ),
            string: value.decodeSimpleString(context: r'StringDecimalModel.string'),
          );
        }
      ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedFromSimpleMethod)),
      );
    },
  );

  test(
    'generates fromSimple validating single value against enum and string',
    () {
      final model = AllOfModel(
        isDeprecated: false,
        description: null,
        name: 'EnumStringModel',
        models: {
          EnumModel(
            isDeprecated: false,
            description: null,
            name: 'Status',
            values: const {'active', 'inactive'},
            isNullable: false,
            context: context,
          ),
          StringModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);

      const expectedFromSimpleMethod = '''
        factory EnumStringModel.fromSimple(String? value, {required bool explode}) {
          return EnumStringModel(
            status: Status.fromSimple(value, explode: explode),
            string: value.decodeSimpleString(context: r'EnumStringModel.string'),
          );
        }
      ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedFromSimpleMethod)),
      );
    },
  );

  test(
    'generates fromSimple for mixed types attempting decode',
    () {
      final model = AllOfModel(
        isDeprecated: false,
        description: null,
        name: 'MixedModel',
        models: {
          StringModel(context: context),
          EnumModel(
            isDeprecated: false,
            description: null,
            name: 'Status',
            values: const {'active', 'inactive'},
            isNullable: false,
            context: context,
          ),
          ClassModel(
            isDeprecated: false,
            description: null,
            name: 'UserData',
            properties: [
              Property(
                description: null,
                name: 'id',
                model: IntegerModel(context: context),
                isRequired: true,
                isNullable: false,
                isDeprecated: false,
              ),
            ],
            context: context,
          ),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);

      const expectedFromSimpleMethod = '''
        factory MixedModel.fromSimple(String? value, {required bool explode}) {
          return MixedModel(
            userData: UserData.fromSimple(value, explode: explode),
            status: Status.fromSimple(value, explode: explode),
            string: value.decodeSimpleString(context: r'MixedModel.string'),
          );
        }
      ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedFromSimpleMethod)),
      );
    },
  );
}
