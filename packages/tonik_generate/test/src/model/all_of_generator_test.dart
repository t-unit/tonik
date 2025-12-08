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
        isDeprecated: false,
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
        isDeprecated: false,
        name: 'Combined',
        models: {
          ClassModel(
            isDeprecated: false,
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

    group('doc comments', () {
      test('generates class with doc comment from description', () {
        final model = AllOfModel(
          isDeprecated: false,
          description: 'Combines multiple schemas into one',
          name: 'Combined',
          models: {
            StringModel(context: context),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);

        expect(
          combinedClass.docs,
          ['/// Combines multiple schemas into one'],
        );
      });

      test('generates class with multiline doc comment', () {
        final model = AllOfModel(
          isDeprecated: false,
          description: 'A combined model.\nInherits from multiple schemas.',
          name: 'Combined',
          models: {
            StringModel(context: context),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);

        expect(combinedClass.docs, [
          '/// A combined model.',
          '/// Inherits from multiple schemas.',
        ]);
      });

      test('generates class without doc comment when description is null', () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'Combined',
          models: {
            StringModel(context: context),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);

        expect(combinedClass.docs, isEmpty);
      });

      test('generates class without doc comment when description is empty', () {
        final model = AllOfModel(
          isDeprecated: false,
          description: '',
          name: 'Combined',
          models: {
            StringModel(context: context),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);

        expect(combinedClass.docs, isEmpty);
      });
    });

    test('generates getter for mixed allOf', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'Combined',
        models: {
          StringModel(context: context),
          ClassModel(
            isDeprecated: false,
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
        isDeprecated: false,
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
        isDeprecated: false,
        name: 'Combined',
        models: {
          ClassModel(
            isDeprecated: false,
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
            isDeprecated: false,
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
        isDeprecated: false,
        name: 'Combined',
        models: {
          StringModel(context: context),
          ClassModel(
            isDeprecated: false,
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
        isDeprecated: false,
        name: 'Value',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              isDeprecated: false,
              name: 'Data',
              properties: const [],
              context: context,
            ),
          ),
        },
        context: context,
      );

      final model = AllOfModel(
        isDeprecated: false,
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
        isDeprecated: false,
        name: 'CombinedModel',
        models: {
          ClassModel(
            isDeprecated: false,
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
            isDeprecated: false,
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
        isDeprecated: false,
        name: 'CombinedModel',
        models: {
          ClassModel(
            isDeprecated: false,
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
            isDeprecated: false,
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
                'Expected \$base.toJson() to return Map<String, Object?>, got ${$baseJson.runtimeType}',
              );
            }
            map.addAll($baseJson);
            final $mixinJson = $mixin.toJson();
            if ($mixinJson is! Map<String, Object?>) {
              throw EncodingException(
                'Expected \$mixin.toJson() to return Map<String, Object?>, got ${$mixinJson.runtimeType}',
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
        isDeprecated: false,
        name: 'CombinedModel',
        models: {
          ClassModel(
            isDeprecated: false,
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
            isDeprecated: false,
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
        isDeprecated: false,
        name: 'CombinedModel',
        models: {
          ClassModel(
            isDeprecated: false,
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
            isDeprecated: false,
            name: 'Mixin',
            properties: [
              Property(
                name: 'metadata',
                model: ClassModel(
                  isDeprecated: false,
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
        isDeprecated: false,
        name: 'CombinedModel',
        models: <Model>{
          ClassModel(
            isDeprecated: false,
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
            isDeprecated: false,
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
  });

  group('with primitive models', () {
    test('handles string and decimal models with single value', () {
      final model = AllOfModel(
        isDeprecated: false,
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

    test('handles enum and string models with single value', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'EnumStringModel',
        models: {
          EnumModel(
            isDeprecated: false,
            name: 'Status',
            values: {
              const EnumEntry(value: 'active'),
              const EnumEntry(value: 'inactive'),
            },
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

    test('handles date and string models with single value', () {
      final model = AllOfModel(
        isDeprecated: false,
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
          isDeprecated: false,
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
        isDeprecated: false,
        name: 'MixedModel',
        models: <Model>{
          StringModel(context: context),
          ClassModel(
            isDeprecated: false,
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
      'generates toJson returning most appropriate value for mixed types',
      () {
        final model = AllOfModel(
          isDeprecated: false,
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
        isDeprecated: false,
        name: 'CombinedModel',
        models: {
          ClassModel(
            isDeprecated: false,
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
            isDeprecated: false,
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
        isDeprecated: false,
        name: 'CombinedModel',
        models: {
          ClassModel(
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
          ),
          ClassModel(
            isDeprecated: false,
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
        isDeprecated: false,
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

  group('allOf with list models', () {
    test('generates toLabel for allOf with list of DateTime', () {
      final model = AllOfModel(
        isDeprecated: false,
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
        final listLabel = list
          .map((e) => e.uriEncode(allowEmpty: allowEmpty))
          .toList()
          .toLabel(
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedToLabel)),
      );
    });

    test('generates toMatrix for allOf with list of DateTime', () {
      final model = AllOfModel(
        isDeprecated: false,
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

    test('generates toJson for allOf with list of DateTime', () {
      final model = AllOfModel(
        isDeprecated: false,
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
          const deepEquals = DeepCollectionEquality();
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
        isDeprecated: false,
        name: 'ArrayOneOfModel',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: IntegerModel(context: context)),
        },
        context: context,
      );

      final model = AllOfModel(
        isDeprecated: false,
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
          const deepEquals = DeepCollectionEquality();
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
        isDeprecated: false,
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
          bool allowLists = true,
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
        isDeprecated: false,
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
        isDeprecated: false,
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
          bool allowLists = true,
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
        isDeprecated: false,
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
          bool allowLists = true,
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
        isDeprecated: false,
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
        isDeprecated: false,
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

    test(
      'generates parameterProperties with allowLists parameter for '
      'complex allOf',
      () {
        final classModel1 = ClassModel(
          isDeprecated: false,
          name: 'TestClass1',
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

        final classModel2 = ClassModel(
          isDeprecated: false,
          name: 'TestClass2',
          properties: [
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

        final model = AllOfModel(
          isDeprecated: false,
          name: 'AllOfComplex',
          models: {
            classModel1,
            classModel2,
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);
        final generated = format(combinedClass.accept(emitter).toString());

        const expectedParameterProperties = '''
          Map<String, String> parameterProperties({
            bool allowEmpty = true,
            bool allowLists = true,
          }) {
            final mergedProperties = <String, String>{};
            mergedProperties.addAll(
              testClass1.parameterProperties(
                allowEmpty: allowEmpty,
                allowLists: allowLists,
              ),
            );
            mergedProperties.addAll(
              testClass2.parameterProperties(
                allowEmpty: allowEmpty,
                allowLists: allowLists,
              ),
            );
            return mergedProperties;
          }
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedParameterProperties)),
        );
      },
    );

    test(
      'generates parameterProperties that throws when contains lists',
      () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'AllOfWithList',
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
            bool allowLists = true,
          }) =>
            throw EncodingException(
              'parameterProperties not supported for AllOfWithList: contains array types',
            );
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedParameterProperties)),
        );
      },
    );
  });
}
