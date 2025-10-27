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

  group('currentEncodingShape', () {
    test('generates simple encoding shape getter for simple allOf', () {
      final model = AllOfModel(
        name: 'Combined',
        models: {
          StringModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final getter = combinedClass.methods.firstWhere(
        (m) => m.name == 'currentEncodingShape',
      );

      expect(getter.type, MethodType.getter);
      expect(
        getter.returns?.accept(emitter).toString(),
        'EncodingShape',
      );
      expect(getter.lambda, isTrue);
      expect(
        getter.body?.accept(emitter).toString(),
        'EncodingShape.simple',
      );
    });

    test('generates complex encoding shape getter for complex allOf', () {
      final model = AllOfModel(
        name: 'Combined',
        models: {
          ClassModel(
            name: 'Base',
            properties: const [],
            context: context,
          ),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final getter = combinedClass.methods.firstWhere(
        (m) => m.name == 'currentEncodingShape',
      );

      expect(getter.type, MethodType.getter);
      expect(
        getter.returns?.accept(emitter).toString(),
        'EncodingShape',
      );
      expect(getter.lambda, isTrue);
      expect(
        getter.body?.accept(emitter).toString(),
        'EncodingShape.complex',
      );
    });

    test('generates getter for mixed allOf', () {
      final model = AllOfModel(
        name: 'Combined',
        models: {
          StringModel(context: context),
          ClassModel(
            name: 'Base',
            properties: const [],
            context: context,
          ),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final getter = combinedClass.methods.firstWhere(
        (m) => m.name == 'currentEncodingShape',
      );

      expect(getter.type, MethodType.getter);
      expect(
        getter.returns?.accept(emitter).toString(),
        'EncodingShape',
      );
      expect(getter.lambda, isTrue);
      expect(
        getter.body?.accept(emitter).toString(),
        'EncodingShape.mixed',
      );
    });

    test('generates encoding shape getter with full implementation', () {
      final model = AllOfModel(
        name: 'Combined',
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedGetter = '''
        EncodingShape get currentEncodingShape => EncodingShape.simple;
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });

    test('generates getter for complex allOf with full implementation', () {
      final model = AllOfModel(
        name: 'Combined',
        models: {
          ClassModel(
            name: 'Base',
            properties: [
              Property(
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
            name: 'Mixin',
            properties: [
              Property(
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
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedGetter = '''
        EncodingShape get currentEncodingShape => EncodingShape.complex;
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });

    test('generates getter for mixed allOf with full implementation', () {
      final model = AllOfModel(
        name: 'Combined',
        models: {
          StringModel(context: context),
          ClassModel(
            name: 'Data',
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
          ),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedGetter = '''
        EncodingShape get currentEncodingShape => EncodingShape.mixed;
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });

    test('generates getter for allOf with nested oneOf composition', () {
      final oneOfModel = OneOfModel(
        name: 'Value',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'Data',
              properties: const [],
              context: context,
            ),
          ),
        },
        discriminator: null,
        context: context,
      );

      final model = AllOfModel(
        name: 'Combined',
        models: {
          oneOfModel,
          IntegerModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedGetter = '''
        EncodingShape get currentEncodingShape {
          final shapes = <EncodingShape>{};
          shapes.add(int.currentEncodingShape);
          shapes.add(value.currentEncodingShape);
          if (shapes.length > 1) return EncodingShape.mixed;
          return shapes.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedGetter)),
      );
    });
  });

  group('with class models', () {
    test('generates class with references to each model', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: {
          ClassModel(
            name: 'Base',
            properties: [
              Property(
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
            name: 'Mixin',
            properties: [
              Property(
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

      expect(combinedClass.name, 'CombinedModel');
      expect(combinedClass.constructors, hasLength(4));
      expect(combinedClass.constructors.first.constant, isTrue);

      expect(combinedClass.fields, hasLength(2));
      expect(
        combinedClass.fields.map((f) => f.name),
        equals([r'$base', r'$mixin']),
      );

      final baseField = combinedClass.fields.firstWhere(
        (f) => f.name == r'$base',
      );
      expect(baseField.type?.accept(emitter).toString(), 'Base');

      final mixinField = combinedClass.fields.firstWhere(
        (f) => f.name == r'$mixin',
      );
      expect(mixinField.type?.accept(emitter).toString(), 'Mixin');
    });

    test('generates toJson method combining all model properties', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: {
          ClassModel(
            name: 'Base',
            properties: [
              Property(
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
            name: 'Mixin',
            properties: [
              Property(
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

      const expectedMethod = r'''
          Object? toJson() {
            final map = <String, Object?>{};
            final $baseJson = $base.toJson();
            if ($baseJson is! Map<String, Object?>) {
              throw EncodingException(
                'Expected $base.toJson() to return Map<String, Object?>, got ${$baseJson.runtimeType}',
              );
            }
            map.addAll($baseJson);
            final $mixinJson = $mixin.toJson();
            if ($mixinJson is! Map<String, Object?>) {
              throw EncodingException(
                'Expected $mixin.toJson() to return Map<String, Object?>, got ${$mixinJson.runtimeType}',
              );
            }
            map.addAll($mixinJson);
            return map;
          }
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates fromJson method validating all model properties', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: {
          ClassModel(
            name: 'Base',
            properties: [
              Property(
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
            name: 'Mixin',
            properties: [
              Property(
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

      const expectedMethod = r'''
          factory CombinedModel.fromJson(Object? json) {
            return CombinedModel(
              $base: Base.fromJson(json),
              $mixin: Mixin.fromJson(json),
            );
          }
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('handles nested models correctly', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: {
          ClassModel(
            name: 'Base',
            properties: [
              Property(
                name: 'items',
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
          ),
          ClassModel(
            name: 'Mixin',
            properties: [
              Property(
                name: 'metadata',
                model: ClassModel(
                  name: 'Metadata',
                  properties: [
                    Property(
                      name: 'count',
                      model: IntegerModel(context: context),
                      isRequired: true,
                      isNullable: false,
                      isDeprecated: false,
                    ),
                  ],
                  context: context,
                ),
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

      expect(combinedClass.fields, hasLength(2));
      expect(
        combinedClass.fields.map((f) => f.name),
        equals([r'$base', r'$mixin']),
      );

      final baseField = combinedClass.fields.firstWhere(
        (f) => f.name == r'$base',
      );
      expect(baseField.type?.accept(emitter).toString(), 'Base');

      final mixinField = combinedClass.fields.firstWhere(
        (f) => f.name == r'$mixin',
      );
      expect(mixinField.type?.accept(emitter).toString(), 'Mixin');
    });

    test('generates equals and hashCode methods', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: <Model>{
          ClassModel(
            name: 'Base',
            properties: [
              Property(
                name: 'items',
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
          ),
          ClassModel(
            name: 'Mixin',
            properties: [
              Property(
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

      const expectedEquals = r'''
          @override
          bool operator ==(Object other) {
            if (identical(this, other)) return true;
            return other is CombinedModel &&
              other.$base == $base &&
              other.$mixin == $mixin;
          }
        ''';

      const expectedHashCode = r'''
          @override
          int get hashCode {
            return Object.hashAll([$base, $mixin]);
          }
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        allOf(
          contains(collapseWhitespace(expectedEquals)),
          contains(collapseWhitespace(expectedHashCode)),
        ),
      );
    });

    test('generates toSimple merging all class properties', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: <Model>{
          ClassModel(
            name: 'Base',
            properties: [
              Property(
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
            name: 'Mixin',
            properties: [
              Property(
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

    test('generates fromSimple merging properties from single value', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: <Model>{
          ClassModel(
            name: 'Base',
            properties: [
              Property(
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
            name: 'Mixin',
            properties: [
              Property(
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
  });

  group('with primitive models', () {
    test('handles string and decimal models with single value', () {
      final model = AllOfModel(
        name: 'StringDecimalModel',
        models: <Model>{
          StringModel(context: context),
          DecimalModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);

      expect(combinedClass.fields, hasLength(2));
      expect(
        combinedClass.fields.map((f) => f.name),
        containsAll(['string', 'bigDecimal']),
      );

      final stringField = combinedClass.fields.firstWhere(
        (f) => f.name == 'string',
      );
      expect(stringField.type?.accept(emitter).toString(), 'String');

      final decimalField = combinedClass.fields.firstWhere(
        (f) => f.name == 'bigDecimal',
      );
      expect(decimalField.type?.accept(emitter).toString(), 'BigDecimal');

      const expectedToJson = '''
          Object? toJson() => bigDecimal;
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedToJson)),
      );

      const expectedFromJson = '''
          factory StringDecimalModel.fromJson(Object? json) {
            return StringDecimalModel(
              bigDecimal: json.decodeJsonBigDecimal(context: r'StringDecimalModel'),
              string: json.decodeJsonString(context: r'StringDecimalModel'),
            );
          }
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedFromJson)),
      );
    });

    test('generates toSimple returning primary primitive value', () {
      final model = AllOfModel(
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
      'generates fromSimple validating single value against all primitive '
      'types',
      () {
        final model = AllOfModel(
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

    test('handles enum and string models with single value', () {
      final model = AllOfModel(
        name: 'EnumStringModel',
        models: {
          EnumModel(
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

      expect(combinedClass.fields, hasLength(2));
      expect(
        combinedClass.fields.map((f) => f.name),
        containsAll(['status', 'string']),
      );

      final enumField = combinedClass.fields.firstWhere(
        (f) => f.name == 'status',
      );
      expect(enumField.type?.accept(emitter).toString(), 'Status');

      final stringField = combinedClass.fields.firstWhere(
        (f) => f.name == 'string',
      );
      expect(stringField.type?.accept(emitter).toString(), 'String');

      const expectedToJson = '''
          Object? toJson() => status.toJson();
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedToJson)),
      );

      const expectedFromJson = '''
          factory EnumStringModel.fromJson(Object? json) {
            return EnumStringModel(
              status: Status.fromJson(json),
              string: json.decodeJsonString(context: r'EnumStringModel'),
            );
          }
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedFromJson)),
      );

      const expectedEquals = '''
          @override
          bool operator ==(Object other) {
            if (identical(this, other)) return true;
            return other is EnumStringModel &&
              other.status == status &&
              other.string == string;
          }
        ''';

      const expectedHashCode = '''
          @override
          int get hashCode {
            return Object.hashAll([status, string]);
          }
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        allOf(
          contains(collapseWhitespace(expectedEquals)),
          contains(collapseWhitespace(expectedHashCode)),
        ),
      );
    });

    test(
      'generates toSimple returning enum value for enum and string models',
      () {
        final model = AllOfModel(
          name: 'EnumStringModel',
          models: {
            EnumModel(
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
      'generates fromSimple validating single value against enum and string',
      () {
        final model = AllOfModel(
          name: 'EnumStringModel',
          models: {
            EnumModel(
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

    test('handles date and string models with single value', () {
      final model = AllOfModel(
        name: 'DateStringModel',
        models: <Model>{
          DateModel(context: context),
          StringModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);

      expect(combinedClass.fields, hasLength(2));
      expect(
        combinedClass.fields.map((f) => f.name),
        containsAll(['date', 'string']),
      );

      final dateField = combinedClass.fields.firstWhere(
        (f) => f.name == 'date',
      );
      expect(dateField.type?.accept(emitter).toString(), 'Date');

      final stringField = combinedClass.fields.firstWhere(
        (f) => f.name == 'string',
      );
      expect(stringField.type?.accept(emitter).toString(), 'String');

      const expectedToJson = '''
          Object? toJson() => date.toJson();
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedToJson)),
      );

      const expectedFromJson = '''
          factory DateStringModel.fromJson(Object? json) {
            return DateStringModel(
              date: json.decodeJsonDate(context: r'DateStringModel'),
              string: json.decodeJsonString(context: r'DateStringModel'),
            );
          }
        ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedFromJson)),
      );
    });

    test(
      'handles number models with single value encoded as most general type',
      () {
        final model = AllOfModel(
          name: 'NumberModel',
          models: <Model>{
            NumberModel(context: context),
            DoubleModel(context: context),
            IntegerModel(context: context),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);

        expect(combinedClass.fields, hasLength(3));
        expect(
          combinedClass.fields.map((f) => f.name).toList(),
          containsAll(['num', 'double', 'int']),
        );

        final numberField = combinedClass.fields.firstWhere(
          (f) => f.name == 'num',
        );
        expect(numberField.type?.accept(emitter).toString(), 'num');

        final doubleField = combinedClass.fields.firstWhere(
          (f) => f.name == 'double',
        );
        expect(doubleField.type?.accept(emitter).toString(), 'double');

        final integerField = combinedClass.fields.firstWhere(
          (f) => f.name == 'int',
        );
        expect(integerField.type?.accept(emitter).toString(), 'int');

        const expectedToJson = '''
          Object? toJson() => double;
        ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedToJson)),
        );

        const expectedFromJson = '''
          factory NumberModel.fromJson(Object? json) {
            return NumberModel(
              double: json.decodeJsonDouble(context: r'NumberModel'),
              int: json.decodeJsonInt(context: r'NumberModel'),
              num: json.decodeJsonNum(context: r'NumberModel'),
            );
          }
        ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedFromJson)),
        );
      },
    );
  });

  group('with mixed models', () {
    test('generates class combining primitive and complex models', () {
      final model = AllOfModel(
        name: 'MixedModel',
        models: <Model>{
          StringModel(context: context),
          ClassModel(
            name: 'UserData',
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
          ),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);

      expect(combinedClass.fields, hasLength(2));
      expect(
        combinedClass.fields.map((f) => f.name),
        containsAll(['string', 'userData']),
      );

      final stringField = combinedClass.fields.firstWhere(
        (f) => f.name == 'string',
      );
      expect(stringField.type?.accept(emitter).toString(), 'String');

      final userDataField = combinedClass.fields.firstWhere(
        (f) => f.name == 'userData',
      );
      expect(userDataField.type?.accept(emitter).toString(), 'UserData');
    });

    test(
      'throws exception for mixed types in fromSimple',
      () {
        final model = AllOfModel(
          name: 'MixedModel',
          models: {
            StringModel(context: context),
            EnumModel(
              name: 'Status',
              values: const {'active', 'inactive'},
              isNullable: false,
              context: context,
            ),
            ClassModel(
              name: 'UserData',
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
            ),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);

        const expectedFromSimpleMethod = '''
        factory MixedModel.fromSimple(String? value, {required bool explode}) {
          throw SimpleDecodingException(
            'Simple encoding not supported for MixedModel: contains complex types',
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
      'throws exception for mixed types in toSimple',
      () {
        final model = AllOfModel(
          name: 'MixedModel',
          models: <Model>{
            StringModel(context: context),
            ClassModel(
              name: 'UserData',
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
          name: 'MixedModel',
          models: {
            StringModel(context: context),
            EnumModel(
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

    test(
      'generates toJson returning most appropriate value for mixed types',
      () {
        final model = AllOfModel(
          name: 'MixedModel',
          models: <Model>{
            StringModel(context: context),
            DateModel(context: context),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);

        const expectedToJson = '''
          Object? toJson() => date;
        ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedToJson)),
        );
      },
    );
  });

  group('property normalization', () {
    test('normalizes model names with special characters', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: {
          ClassModel(
            name: 'User-Profile',
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
          ),
          ClassModel(
            name: 'Account_Info',
            properties: [
              Property(
                name: 'id',
                model: StringModel(context: context),
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

      expect(combinedClass.fields, hasLength(2));
      expect(
        combinedClass.fields.map((f) => f.name),
        containsAll(['userProfile', 'accountInfo']),
      );

      final constructor = combinedClass.constructors.first;
      expect(
        constructor.optionalParameters.map((p) => p.name),
        containsAll(['userProfile', 'accountInfo']),
      );
    });

    test('handles model name conflicts by making them unique', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: {
          ClassModel(
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
          ),
          ClassModel(
            name: 'USER',
            properties: [
              Property(
                name: 'id',
                model: StringModel(context: context),
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

      expect(combinedClass.fields, hasLength(2));
      final fieldNames = combinedClass.fields.map((f) => f.name).toList();

      expect(fieldNames, equals(['user', 'userModel']));

      final paramNames =
          combinedClass.constructors.first.optionalParameters
              .map((p) => p.name)
              .toList();
      expect(paramNames, equals(['user', 'userModel']));
    });

    test('handles primitive models with normalized type names', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
          DecimalModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);

      expect(combinedClass.fields, hasLength(3));
      final fieldNames = combinedClass.fields.map((f) => f.name).toList();

      expect(fieldNames, equals(['bigDecimal', 'int', 'string']));
    });
  });

  group('form encoding - complex types', () {
    test('generates fromForm constructor for complex allOf model', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: <Model>{
          ClassModel(
            name: 'Base',
            properties: [
              Property(
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
            name: 'Mixin',
            properties: [
              Property(
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

      const expectedFromFormMethod = r'''
        factory CombinedModel.fromForm(String? value, {required bool explode}) {
          return CombinedModel(
            $base: Base.fromForm(value, explode: explode),
            $mixin: Mixin.fromForm(value, explode: explode),
          );
        }
      ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedFromFormMethod)),
      );
    });

    test('generates toForm method merging all class properties', () {
      final model = AllOfModel(
        name: 'CombinedModel',
        models: {
          ClassModel(
            name: 'Base',
            properties: [
              Property(
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
            name: 'Mixin',
            properties: [
              Property(
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

      const expectedToFormMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          return parameterProperties(
            allowEmpty: allowEmpty,
          ).toForm(explode: explode, allowEmpty: allowEmpty, alreadyEncoded: true);
        }
      ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedToFormMethod)),
      );
    });
  });

  group('form encoding - primitive types', () {
    test('generates toForm returning primary primitive value', () {
      final model = AllOfModel(
        name: 'StringDecimalModel',
        models: <Model>{
          StringModel(context: context),
          DecimalModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);

      const expectedToFormMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          return bigDecimal.toForm(explode: explode, allowEmpty: allowEmpty);
        }
      ''';

      expect(
        collapseWhitespace(format(combinedClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedToFormMethod)),
      );
    });

    test(
      'generates fromForm validating single value against all primitive types',
      () {
        final model = AllOfModel(
          name: 'StringDecimalModel',
          models: <Model>{
            StringModel(context: context),
            DecimalModel(context: context),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);

        const expectedFromFormMethod = '''
        factory StringDecimalModel.fromForm(String? value, {required bool explode}) {
          return StringDecimalModel(
            bigDecimal: value.decodeFormBigDecimal(
              context: r'StringDecimalModel.bigDecimal',
            ),
            string: value.decodeFormString(context: r'StringDecimalModel.string'),
          );
        }
      ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedFromFormMethod)),
        );
      },
    );

    test(
      'generates toForm returning enum value for enum and string models',
      () {
        final model = AllOfModel(
          name: 'EnumStringModel',
          models: {
            EnumModel(
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

        const expectedToFormMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          return status.toForm(explode: explode, allowEmpty: allowEmpty);
        }
      ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedToFormMethod)),
        );
      },
    );

    test(
      'generates fromForm validating single value against enum and string',
      () {
        final model = AllOfModel(
          name: 'EnumStringModel',
          models: {
            EnumModel(
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

        const expectedFromFormMethod = '''
        factory EnumStringModel.fromForm(String? value, {required bool explode}) {
          return EnumStringModel(
            status: Status.fromForm(value, explode: explode),
            string: value.decodeFormString(context: r'EnumStringModel.string'),
          );
        }
      ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedFromFormMethod)),
        );
      },
    );
  });

  group('form encoding - mixed types', () {
    test(
      'throws exception for mixed types in fromForm',
      () {
        final model = AllOfModel(
          name: 'MixedModel',
          models: {
            StringModel(context: context),
            ClassModel(
              name: 'Complex',
              properties: [
                Property(
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

        const expectedFromFormMethod = '''
        factory MixedModel.fromForm(String? value, {required bool explode}) {
          throw SimpleDecodingException(
            'Simple encoding not supported for MixedModel: contains complex types',
          );
        }
      ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedFromFormMethod)),
        );
      },
    );

    test(
      'throws exception for mixed types in toForm',
      () {
        final model = AllOfModel(
          name: 'MixedModel',
          models: {
            IntegerModel(context: context),
            ClassModel(
              name: 'Complex',
              properties: const [],
              context: context,
            ),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);

        const expectedToFormMethod = '''
          String toForm({required bool explode, required bool allowEmpty}) {
            throw EncodingException(
              'Simple encoding not supported: contains complex types',
            );
          }
        ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedToFormMethod)),
        );
      },
    );
  });

  group('nested dynamic shapes', () {
    test('allOf with mixed anyOf and primitive validates at runtime', () {
      final anyOfModel = AnyOfModel(
        name: 'FlexibleValue',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'Data',
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
            ),
          ),
        },
        discriminator: null,
        context: context,
      );

      final model = AllOfModel(
        name: 'Combined',
        models: {
          IntegerModel(context: context),
          anyOfModel,
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedToFormMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException(
              'Cannot encode Combined: mixing simple values (primitives/enums) and complex types is not supported',
            );
          }
          final map = <String, String>{};
          map.addAll(flexibleValue.parameterProperties(allowEmpty: allowEmpty));
          map.addAll(int.parameterProperties(allowEmpty: allowEmpty));
          return map.toForm(
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToFormMethod)),
      );

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

    test('allOf with mixed oneOf and primitive validates at runtime', () {
      final oneOfModel = OneOfModel(
        name: 'Choice',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'Data',
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
            ),
          ),
        },
        discriminator: null,
        context: context,
      );

      final model = AllOfModel(
        name: 'Combined',
        models: {
          IntegerModel(context: context),
          oneOfModel,
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedToFormMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException(
              'Cannot encode Combined: mixing simple values (primitives/enums) and complex types is not supported',
            );
          }
          final map = <String, String>{};
          map.addAll(int.parameterProperties(allowEmpty: allowEmpty));
          map.addAll(choice.parameterProperties(allowEmpty: allowEmpty));
          return map.toForm(
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToFormMethod)),
      );
    });

    test('allOf with multiple mixed anyOf models validates all at runtime', () {
      final anyOfModel1 = AnyOfModel(
        name: 'FlexibleA',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'DataA',
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
            ),
          ),
        },
        discriminator: null,
        context: context,
      );

      final anyOfModel2 = AnyOfModel(
        name: 'FlexibleB',
        models: {
          (discriminatorValue: null, model: IntegerModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'DataB',
              properties: [
                Property(
                  name: 'value',
                  model: StringModel(context: context),
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
        name: 'MultiDynamic',
        models: {
          StringModel(context: context),
          anyOfModel1,
          anyOfModel2,
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedToFormMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException(
              'Cannot encode MultiDynamic: mixing simple values (primitives/enums) and complex types is not supported',
            );
          }
          final map = <String, String>{};
          map.addAll(flexibleA.parameterProperties(allowEmpty: allowEmpty));
          map.addAll(flexibleB.parameterProperties(allowEmpty: allowEmpty));
          map.addAll(string.parameterProperties(allowEmpty: allowEmpty));
          return map.toForm(
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToFormMethod)),
      );
    });

    test('allOf with mixed anyOf, oneOf, and primitives validates all '
        'dynamic types', () {
      final anyOfModel = AnyOfModel(
        name: 'FlexibleValue',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'Data',
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
            ),
          ),
        },
        discriminator: null,
        context: context,
      );

      final oneOfModel = OneOfModel(
        name: 'Choice',
        models: {
          (discriminatorValue: null, model: IntegerModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              name: 'Option',
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
            ),
          ),
        },
        discriminator: null,
        context: context,
      );

      final model = AllOfModel(
        name: 'ComplexMixed',
        models: {
          StringModel(context: context),
          anyOfModel,
          oneOfModel,
          DecimalModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedToFormMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          if (currentEncodingShape == EncodingShape.mixed) {
            throw EncodingException(
              'Cannot encode ComplexMixed: mixing simple values (primitives/enums) and complex types is not supported',
            );
          }
          final map = <String, String>{};
          map.addAll(flexibleValue.parameterProperties(allowEmpty: allowEmpty));
          map.addAll(bigDecimal.parameterProperties(allowEmpty: allowEmpty));
          map.addAll(choice.parameterProperties(allowEmpty: allowEmpty));
          map.addAll(string.parameterProperties(allowEmpty: allowEmpty));
          return map.toForm(
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToFormMethod)),
      );
    });
  });

  group('allOf with list models', () {
    test('generates fromSimple for allOf with list of int', () {
      final model = AllOfModel(
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

    test('generates fromForm for allOf with list of double', () {
      final model = AllOfModel(
        name: 'AllOfDoubleList',
        models: {
          ListModel(
            content: DoubleModel(context: context),
            context: context,
          ),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedFromForm = '''
        factory AllOfDoubleList.fromForm(String? value, {required bool explode}) {
          return AllOfDoubleList(
            list: value
              .decodeFormStringList(context: r'AllOfDoubleList.list')
              .map((e) => e.decodeFormDouble(context: r'AllOfDoubleList.list'))
              .toList(),
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedFromForm)),
      );
    });

    test('generates fromForm for allOf with list of DateTime', () {
      final model = AllOfModel(
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

      const expectedFromForm = '''
        factory AllOfDateTimeList.fromForm(String? value, {required bool explode}) {
          return AllOfDateTimeList(
            list: value
              .decodeFormStringList(context: r'AllOfDateTimeList.list')
              .map((e) => e.decodeFormDateTime(context: r'AllOfDateTimeList.list'))
              .toList(),
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedFromForm)),
      );
    });

    test('generates toSimple for allOf with list of Date', () {
      final model = AllOfModel(
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

      const expectedToSimple = '''
        String toSimple({required bool explode, required bool allowEmpty}) {
          final values = <String>{};
          final listSimple = list
            .map((e) => e.toSimple(explode: explode, allowEmpty: allowEmpty))
            .toList()
            .toSimple(explode: explode, allowEmpty: allowEmpty);
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

    test('generates toSimple for allOf with list of DateTime', () {
      final model = AllOfModel(
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
            .toSimple(explode: explode, allowEmpty: allowEmpty);
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

    test('generates toForm for allOf with list of int', () {
      final model = AllOfModel(
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

      const expectedToForm = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          final values = <String>{};
          final listForm = list
            .map((e) => e.toForm(explode: explode, allowEmpty: allowEmpty))
            .toList()
            .toForm(explode: explode, allowEmpty: allowEmpty);
          values.add(listForm);
          if (values.length > 1) {
            throw EncodingException(
              'Inconsistent allOf form encoding: all values must encode to the same result',
            );
          }
          return values.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToForm)),
      );
    });

    test('generates toForm for allOf with list of DateTime', () {
      final model = AllOfModel(
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

      const expectedToForm = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          final values = <String>{};
          final listForm = list
            .map((e) => e.toForm(explode: explode, allowEmpty: allowEmpty))
            .toList()
            .toForm(explode: explode, allowEmpty: allowEmpty);
          values.add(listForm);
          if (values.length > 1) {
            throw EncodingException(
              'Inconsistent allOf form encoding: all values must encode to the same result',
            );
          }
          return values.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToForm)),
      );
    });

    test('generates toLabel for allOf with list of DateTime', () {
      final model = AllOfModel(
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

      const expectedToLabel = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          final values = <String>{};
          final listLabel = list
            .map((e) => e.toLabel(explode: explode, allowEmpty: allowEmpty))
            .toList()
            .toLabel(explode: explode, allowEmpty: allowEmpty);
          values.add(listLabel);
          if (values.length > 1) {
            throw EncodingException(
              'Inconsistent allOf label encoding: all values must encode to the same result',
            );
          }
          return values.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToLabel)),
      );
    });

    test('generates toMatrix for allOf with list of DateTime', () {
      final model = AllOfModel(
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

      const expectedToMatrix = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final values = <String>{};
          final listMatrix = list
            .map((e) => e.uriEncode(allowEmpty: allowEmpty))
            .toList()
            .toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
              alreadyEncoded: true,
            );
          values.add(listMatrix);
          if (values.length > 1) {
            throw EncodingException(
              'Inconsistent allOf matrix encoding for AllOfDateTimeList: all values must encode to the same result',
            );
          }
          return values.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToMatrix)),
      );
    });

    test('generates fromSimple for allOf with two lists', () {
      final oneOfModel = OneOfModel(
        name: 'ArrayOneOfModel',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final model = AllOfModel(
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
              .map((e) => ArrayOneOfModel.fromSimple(e, explode: true))
              .toList(),
          );
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedFromSimple)),
      );
    });

    test('generates toSimple for allOf with two lists', () {
      final oneOfModel = OneOfModel(
        name: 'ArrayOneOfModel',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final model = AllOfModel(
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
            .toSimple(explode: explode, allowEmpty: allowEmpty);
          values.add(listSimple);
          final list2Simple = list2
            .map((e) => e.toSimple(explode: explode, allowEmpty: allowEmpty))
            .toList()
            .toSimple(explode: explode, allowEmpty: allowEmpty);
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

    test('generates toJson for allOf with list of DateTime', () {
      final model = AllOfModel(
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

      const expectedToJson = '''
        Object? toJson() {
          final values = <Object?>[];
          final listJson = list.map((e) => e.toTimeZonedIso8601String()).toList();
          values.add(listJson);
          const deepEquals = const DeepCollectionEquality();
          for (var i = 1; i < values.length; i++) {
            if (!deepEquals.equals(values[0], values[i])) {
              throw EncodingException(
                'Inconsistent allOf JSON encoding: all arrays must encode to the same result',
              );
            }
          }
          return values.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToJson)),
      );
    });

    test('generates toJson for allOf with two lists', () {
      final oneOfModel = OneOfModel(
        name: 'ArrayOneOfModel',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final model = AllOfModel(
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

      const expectedToJson = '''
        Object? toJson() {
          final values = <Object?>[];
          final listJson = list.map((e) => e.toTimeZonedIso8601String()).toList();
          values.add(listJson);
          final list2Json = list2.map((e) => e.toJson()).toList();
          values.add(list2Json);
          const deepEquals = const DeepCollectionEquality();
          for (var i = 1; i < values.length; i++) {
            if (!deepEquals.equals(values[0], values[i])) {
              throw EncodingException(
                'Inconsistent allOf JSON encoding: all arrays must encode to the same result',
              );
            }
          }
          return values.first;
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToJson)),
      );
    });

    test('generates parameterProperties exception for allOf with list', () {
      final model = AllOfModel(
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

      const expectedParameterProperties = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
        }) =>
          throw EncodingException(
            'parameterProperties not supported for AllOfIntList: contains array types',
          );
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedParameterProperties)),
      );
    });

    test('generates exception for allOf with mixed list and class', () {
      final classModel = ClassModel(
        name: 'TestClass',
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

      final model = AllOfModel(
        name: 'AllOfMixedListClass',
        models: {
          ListModel(
            content: IntegerModel(context: context),
            context: context,
          ),
          classModel,
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedToJson = '''
        Object? toJson() =>
          throw EncodingException(
            'Cannot encode AllOfMixedListClass to JSON: allOf mixing arrays with other types is not supported',
          );
      ''';

      const expectedParameterProperties = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
        }) =>
          throw EncodingException(
            'parameterProperties not supported for AllOfMixedListClass: allOf mixing arrays with other types is not supported',
          );
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToJson)),
      );
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedParameterProperties)),
      );
    });

    test('generates exception for allOf with mixed list and primitive', () {
      final model = AllOfModel(
        name: 'AllOfMixedListPrimitive',
        models: {
          ListModel(
            content: StringModel(context: context),
            context: context,
          ),
          IntegerModel(context: context),
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedToJson = '''
        Object? toJson() =>
          throw EncodingException(
            'Cannot encode AllOfMixedListPrimitive to JSON: allOf mixing arrays with other types is not supported',
          );
      ''';

      const expectedParameterProperties = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
        }) =>
          throw EncodingException(
            'parameterProperties not supported for AllOfMixedListPrimitive: allOf mixing arrays with other types is not supported',
          );
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToJson)),
      );
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedParameterProperties)),
      );
    });

    test('generates exception for allOf with multiple lists and class', () {
      final classModel = ClassModel(
        name: 'TestClass',
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

      final model = AllOfModel(
        name: 'AllOfMultiListClass',
        models: {
          ListModel(
            content: IntegerModel(context: context),
            context: context,
          ),
          ListModel(
            content: StringModel(context: context),
            context: context,
          ),
          classModel,
        },
        context: context,
      );

      final combinedClass = generator.generateClass(model);
      final generated = format(combinedClass.accept(emitter).toString());

      const expectedToJson = '''
        Object? toJson() =>
          throw EncodingException(
            'Cannot encode AllOfMultiListClass to JSON: allOf mixing arrays with other types is not supported',
          );
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToJson)),
      );
    });
  });
}
