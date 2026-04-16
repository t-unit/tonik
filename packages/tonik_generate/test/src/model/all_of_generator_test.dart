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

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = AllOfGenerator(
      nameManager: nameManager,
      package: 'example',
      stableModelSorter: StableModelSorter(),
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

    test('generates class implementing ParameterEncodable & UriEncodable', () {
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

      expect(combinedClass.implements.length, 2);
      expect(
        combinedClass.implements
            .map((e) => e.accept(emitter).toString())
            .toSet(),
        {'ParameterEncodable', 'UriEncodable'},
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

      const expectedGetter = r'''
        EncodingShape get currentEncodingShape {
          final _$shapes = <EncodingShape>{};
          _$shapes.add(int.currentEncodingShape);
          _$shapes.add(value.currentEncodingShape);
          if (_$shapes.length > 1) return EncodingShape.mixed;
          return _$shapes.first;
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
        [r'$base', r'$mixin'],
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
            final _$map = <String, Object?>{};
            final _$$baseJson = $base.toJson();
            if (_$$baseJson is! Map<String, Object?>) {
              throw EncodingException(
                'Expected \$base.toJson() to return Map<String, Object?>, got ${_$$baseJson.runtimeType}',
              );
            }
            _$map.addAll(_$$baseJson);
            final _$$mixinJson = $mixin.toJson();
            if (_$$mixinJson is! Map<String, Object?>) {
              throw EncodingException(
                'Expected \$mixin.toJson() to return Map<String, Object?>, got ${_$$mixinJson.runtimeType}',
              );
            }
            _$map.addAll(_$$mixinJson);
            return _$map;
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
        [r'$base', r'$mixin'],
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
              other.$base == this.$base &&
              other.$mixin == this.$mixin;
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
              other.status == this.status &&
              other.string == this.string;
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

      expect(fieldNames, ['user', 'userModel']);

      final paramNames = combinedClass.constructors.first.optionalParameters
          .map((p) => p.name)
          .toList();
      expect(paramNames, ['user', 'userModel']);
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

      expect(fieldNames, ['bigDecimal', 'int', 'string']);
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

      const expectedToLabel = r'''
        final _$listLabel = list
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

      const expectedToMatrix = r'''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final _$values = <String>{};
          final _$listMatrix = list
            .map<String>((e) => e.uriEncode(allowEmpty: allowEmpty))
            .toList()
            .toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
              alreadyEncoded: true,
            );
          _$values.add(_$listMatrix);
          if (_$values.length > 1) {
            throw EncodingException(
              r'Inconsistent allOf matrix encoding for AllOfDateTimeList: all values must encode to the same result',
            );
          }
          return _$values.first;
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

      const expectedToJson = r'''
        Object? toJson() {
          final _$values = <Object?>[];
          final _$listJson = list.map((e) => e.toTimeZonedIso8601String()).toList();
          _$values.add(_$listJson);
          const deepEquals = DeepCollectionEquality();
          for (var i = 1; i < _$values.length; i++) {
            if (!deepEquals.equals(_$values[0], _$values[i])) {
              throw EncodingException(
                'Inconsistent allOf JSON encoding: all arrays must encode to the same result',
              );
            }
          }
          return _$values.first;
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

      const expectedToJson = r'''
        Object? toJson() {
          final _$values = <Object?>[];
          final _$listJson = list.map((e) => e.toTimeZonedIso8601String()).toList();
          _$values.add(_$listJson);
          final _$list2Json = list2.map((e) => e.toJson()).toList();
          _$values.add(_$list2Json);
          const deepEquals = DeepCollectionEquality();
          for (var i = 1; i < _$values.length; i++) {
            if (!deepEquals.equals(_$values[0], _$values[i])) {
              throw EncodingException(
                'Inconsistent allOf JSON encoding: all arrays must encode to the same result',
              );
            }
          }
          return _$values.first;
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
            r'parameterProperties not supported for AllOfIntList: contains array types',
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
            r'Cannot encode AllOfMixedListClass to JSON: allOf mixing arrays with other types is not supported',
          );
      ''';

      const expectedParameterProperties = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
        }) =>
          throw EncodingException(
            r'parameterProperties not supported for AllOfMixedListClass: allOf mixing arrays with other types is not supported',
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
            r'Cannot encode AllOfMixedListPrimitive to JSON: allOf mixing arrays with other types is not supported',
          );
      ''';

      const expectedParameterProperties = '''
        Map<String, String> parameterProperties({
          bool allowEmpty = true,
          bool allowLists = true,
        }) =>
          throw EncodingException(
            r'parameterProperties not supported for AllOfMixedListPrimitive: allOf mixing arrays with other types is not supported',
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
            r'Cannot encode AllOfMultiListClass to JSON: allOf mixing arrays with other types is not supported',
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

        const expectedParameterProperties = r'''
          Map<String, String> parameterProperties({
            bool allowEmpty = true,
            bool allowLists = true,
          }) {
            final _$mergedProperties = <String, String>{};
            _$mergedProperties.addAll(
              testClass1.parameterProperties(
                allowEmpty: allowEmpty,
                allowLists: allowLists,
              ),
            );
            _$mergedProperties.addAll(
              testClass2.parameterProperties(
                allowEmpty: allowEmpty,
                allowLists: allowLists,
              ),
            );
            return _$mergedProperties;
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
              r'parameterProperties not supported for AllOfWithList: contains array types',
            );
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedParameterProperties)),
        );
      },
    );

    test(
      'generates parameterProperties that throws when contains maps',
      () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'AllOfWithMap',
          models: {
            MapModel(
              valueModel: StringModel(context: context),
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
              r'parameterProperties not supported for AllOfWithMap: contains map types',
            );
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedParameterProperties)),
        );
      },
    );

    test(
      'generates parameterProperties that throws for allOf mixing map and class',
      () {
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
          name: 'AllOfMixedMapClass',
          models: {
            MapModel(
              valueModel: IntegerModel(context: context),
              context: context,
            ),
            classModel,
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
              r'parameterProperties not supported for AllOfMixedMapClass: contains map types',
            );
        ''';

        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedParameterProperties)),
        );
      },
    );
  });

  group('nullable allOf', () {
    test('generates Raw-prefixed class for nullable allOf', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'Pet',
        models: {
          ClassModel(
            isDeprecated: false,
            name: 'Cat',
            properties: const [],
            context: context,
          ),
          ClassModel(
            isDeprecated: false,
            name: 'Dog',
            properties: const [],
            context: context,
          ),
        },
        context: context,
        isNullable: true,
      );

      nameManager.prime(
        models: {model},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      final klass = generator.generateClass(model);

      // Verify the class uses Raw prefix.
      expect(klass.name, r'$RawPet');
    });

    test('generates normal class for non-nullable allOf', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'Pet',
        models: {
          ClassModel(
            isDeprecated: false,
            name: 'Cat',
            properties: const [],
            context: context,
          ),
          ClassModel(
            isDeprecated: false,
            name: 'Dog',
            properties: const [],
            context: context,
          ),
        },
        context: context,
      );

      nameManager.prime(
        models: {model},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      final klass = generator.generateClass(model);

      // Verify the class uses the normal name (no Raw prefix).
      expect(klass.name, 'Pet');
    });

    test('generate method creates typedef for nullable allOf', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'Response',
        models: {
          ClassModel(
            isDeprecated: false,
            name: 'Base',
            properties: const [],
            context: context,
          ),
        },
        context: context,
        isNullable: true,
      );

      nameManager.prime(
        models: {model},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      final result = generator.generate(model);
      final formatted = format(result.code);

      // Verify typedef exists pointing to nullable Raw class.
      expect(
        collapseWhitespace(formatted),
        contains(collapseWhitespace(r'typedef Response = $RawResponse?;')),
      );
    });

    test('generate method does not create typedef for non-nullable allOf', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'Response',
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

      nameManager.prime(
        models: {model},
        requestBodies: const [],
        responses: const [],
        operations: const [],
        tags: const [],
        servers: const [],
      );

      final result = generator.generate(model);

      // Verify no typedef is generated.
      expect(result.code, isNot(contains('typedef')));
    });

    test('encoding methods have @override annotation', () {
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

      final encodingMethods = [
        'toJson',
        'toSimple',
        'toForm',
        'toLabel',
        'toMatrix',
        'toDeepObject',
      ];
      for (final methodName in encodingMethods) {
        final method = combinedClass.methods.firstWhere(
          (m) => m.name == methodName,
          orElse: () => throw StateError('Method $methodName not found'),
        );
        expect(
          method.annotations,
          hasLength(1),
          reason: '$methodName should have @override annotation',
        );
        expect(
          method.annotations.first.accept(emitter).toString(),
          'override',
          reason: '$methodName should have @override annotation',
        );
      }
    });
  });

  group('uriEncode', () {
    test('generates uriEncode method with useQueryComponent parameter', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'Combined',
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
        },
        context: context,
      );

      nameManager.prime(
        models: {model},
        requestBodies: const <RequestBody>[],
        responses: const <Response>[],
        operations: const <Operation>[],
        tags: const <Tag>[],
        servers: const <Server>[],
      );

      final generatedClass = generator.generateClass(model);
      final uriEncodeMethod = generatedClass.methods.firstWhere(
        (m) => m.name == 'uriEncode',
      );

      expect(uriEncodeMethod.optionalParameters, hasLength(2));

      final allowEmptyParam = uriEncodeMethod.optionalParameters.firstWhere(
        (p) => p.name == 'allowEmpty',
      );
      expect(allowEmptyParam.type?.accept(DartEmitter()).toString(), 'bool');
      expect(allowEmptyParam.named, isTrue);
      expect(allowEmptyParam.required, isTrue);

      final useQueryComponentParam = uriEncodeMethod.optionalParameters
          .firstWhere((p) => p.name == 'useQueryComponent');
      expect(
        useQueryComponentParam.type?.accept(DartEmitter()).toString(),
        'bool',
      );
      expect(useQueryComponentParam.named, isTrue);
      expect(useQueryComponentParam.required, isFalse);
      expect(
        useQueryComponentParam.defaultTo?.accept(DartEmitter()).toString(),
        'false',
      );
    });
  });

  group('toForm', () {
    test('generates toForm method with useQueryComponent parameter', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'Value',
        models: {
          StringModel(context: context),
          IntegerModel(context: context),
        },
        context: context,
      );

      final klass = generator.generateClass(model);

      final toFormMethod = klass.methods.firstWhere(
        (m) => m.name == 'toForm',
      );

      expect(toFormMethod.optionalParameters.length, 3);

      final explodeParam = toFormMethod.optionalParameters.firstWhere(
        (p) => p.name == 'explode',
      );
      expect(explodeParam.type?.accept(DartEmitter()).toString(), 'bool');
      expect(explodeParam.named, isTrue);
      expect(explodeParam.required, isTrue);

      final allowEmptyParam = toFormMethod.optionalParameters.firstWhere(
        (p) => p.name == 'allowEmpty',
      );
      expect(allowEmptyParam.type?.accept(DartEmitter()).toString(), 'bool');
      expect(allowEmptyParam.named, isTrue);
      expect(allowEmptyParam.required, isTrue);

      final useQueryComponentParam = toFormMethod.optionalParameters.firstWhere(
        (p) => p.name == 'useQueryComponent',
      );
      expect(
        useQueryComponentParam.type?.accept(DartEmitter()).toString(),
        'bool',
      );
      expect(useQueryComponentParam.named, isTrue);
      expect(useQueryComponentParam.required, isFalse);
      expect(
        useQueryComponentParam.defaultTo?.accept(DartEmitter()).toString(),
        'false',
      );
    });
  });

  group('allOf with nullable component models', () {
    test(
      'fromSimple generates value without null assertion for nullable '
      'component',
      () {
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
            ClassModel(
              isDeprecated: false,
              name: 'NullableClass',
              properties: const [],
              context: context,
              isNullable: true,
            ),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);
        final generated = format(combinedClass.accept(emitter).toString());

        expect(
          generated,
          contains('NullableClass.fromSimple(value, explode: explode)'),
        );
        expect(generated, isNot(contains('value!')));
      },
    );

    test(
      'currentEncodingShape uses braces around if statement for nullable '
      'component',
      () {
        // OneOfModel with mixed content (simple + complex) has mixed
        // encodingShape, which triggers the dynamic currentEncodingShape
        // getter. The nullable ClassModel triggers the if-branch with braces.
        final nullableClass = ClassModel(
          isDeprecated: false,
          name: 'NullableClass',
          properties: const [],
          context: context,
          isNullable: true,
        );
        final statusOneOf = OneOfModel(
          isDeprecated: false,
          name: 'Status',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'State',
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
          models: {statusOneOf, nullableClass},
          context: context,
        );

        final combinedClass = generator.generateClass(model);
        final generated = format(combinedClass.accept(emitter).toString());

        expect(
          generated,
          contains('if (nullableClass != null) {'),
        );
        expect(
          generated,
          contains('shapes.add(nullableClass!.currentEncodingShape);'),
        );
      },
    );

    test(
      'fromForm generates value without null assertion for nullable component',
      () {
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
            ClassModel(
              isDeprecated: false,
              name: 'NullableClass',
              properties: const [],
              context: context,
              isNullable: true,
            ),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);
        final generated = format(combinedClass.accept(emitter).toString());

        expect(
          generated,
          contains('NullableClass.fromForm(value, explode: explode)'),
        );
        expect(generated, isNot(contains('value!')));
      },
    );
  });

  group('AllOfGenerator additionalProperties', () {
    group('unrestricted additionalProperties', () {
      late AllOfModel model;

      setUp(() {
        model = AllOfModel(
          isDeprecated: false,
          name: 'ExtendedConfig',
          models: {
            ClassModel(
              isDeprecated: false,
              name: 'Base',
              context: context,
              properties: [
                Property(
                  name: 'id',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
          },
          context: context,
          additionalProperties:
              const UnrestrictedAdditionalProperties(),
        );
      });

      test('generates fromJson with AP collection', () {
        const expectedMethod = r'''
  factory ExtendedConfig.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'ExtendedConfig');
    const _$knownKeys = {r'id'};
    final _$additional = <String, Object?>{};
    for (final _$entry in _$map.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value;
      }
    }
    return ExtendedConfig(
      $base: Base.fromJson(json),
      additionalProperties: _$additional,
    );
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates toJson merging member JSON and spreading AP', () {
        const expectedMethod = r'''
  @override
  Object? toJson() {
    final _$map = <String, Object?>{};
    final _$$baseJson = $base.toJson();
    if (_$$baseJson is! Map<String, Object?>) {
      throw EncodingException(
        'Expected \$base.toJson() to return Map<String, Object?>, got ${_$$baseJson.runtimeType}',
      );
    }
    _$map.addAll(_$$baseJson);
    _$map.addAll(additionalProperties);
    return _$map;
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('typed additionalProperties with string values', () {
      late AllOfModel model;

      setUp(() {
        model = AllOfModel(
          isDeprecated: false,
          name: 'TypedExtended',
          models: {
            ClassModel(
              isDeprecated: false,
              name: 'Base',
              context: context,
              properties: [
                Property(
                  name: 'name',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
          },
          context: context,
          additionalProperties: TypedAdditionalProperties(
            valueModel: StringModel(context: context),
          ),
        );
      });

      test('generates fromJson decoding string AP values', () {
        const expectedMethod = r'''
  factory TypedExtended.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'TypedExtended');
    const _$knownKeys = {r'name'};
    final _$additional = <String, String>{};
    for (final _$entry in _$map.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeJsonString(
          context: r'TypedExtended.additionalProperties',
        );
      }
    }
    return TypedExtended(
      $base: Base.fromJson(json),
      additionalProperties: _$additional,
    );
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('typed additionalProperties with complex values', () {
      late AllOfModel model;

      setUp(() {
        model = AllOfModel(
          isDeprecated: false,
          name: 'ComplexExtended',
          models: {
            ClassModel(
              isDeprecated: false,
              name: 'Base',
              context: context,
              properties: [
                Property(
                  name: 'id',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
          },
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
  factory ComplexExtended.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'ComplexExtended');
    const _$knownKeys = {r'id'};
    final _$additional = <String, Widget>{};
    for (final _$entry in _$map.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = Widget.fromJson(_$entry.value);
      }
    }
    return ComplexExtended(
      $base: Base.fromJson(json),
      additionalProperties: _$additional,
    );
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates toJson encoding complex AP values', () {
        const expectedMethod = r'''
  @override
  Object? toJson() {
    final _$map = <String, Object?>{};
    final _$$baseJson = $base.toJson();
    if (_$$baseJson is! Map<String, Object?>) {
      throw EncodingException(
        'Expected \$base.toJson() to return Map<String, Object?>, got ${_$$baseJson.runtimeType}',
      );
    }
    _$map.addAll(_$$baseJson);
    _$map.addAll(additionalProperties.map((k, v) => MapEntry(k, v.toJson())));
    return _$map;
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('NoAdditionalProperties', () {
      test('generates fromJson without AP logic', () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'StrictAllOf',
          models: {
            ClassModel(
              isDeprecated: false,
              name: 'Base',
              context: context,
              properties: [
                Property(
                  name: 'name',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
          },
          context: context,
          additionalProperties: const NoAdditionalProperties(),
        );

        const expectedMethod = r'''
  factory StrictAllOf.fromJson(Object? json) {
    return StrictAllOf($base: Base.fromJson(json));
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('known keys across multiple members', () {
      test('collects keys from all member classes', () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'MultiMember',
          models: {
            ClassModel(
              isDeprecated: false,
              name: 'First',
              context: context,
              properties: [
                Property(
                  name: 'alpha',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
            ClassModel(
              isDeprecated: false,
              name: 'Second',
              context: context,
              properties: [
                Property(
                  name: 'beta',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
          },
          context: context,
          additionalProperties:
              const UnrestrictedAdditionalProperties(),
        );

        const expectedMethod = r'''
  factory MultiMember.fromJson(Object? json) {
    final _$map = json.decodeMap(context: r'MultiMember');
    const _$knownKeys = {r'alpha', r'beta'};
    final _$additional = <String, Object?>{};
    for (final _$entry in _$map.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value;
      }
    }
    return MultiMember(
      first: First.fromJson(json),
      second: Second.fromJson(json),
      additionalProperties: _$additional,
    );
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('fromSimple with additionalProperties', () {
      test('generates fromSimple capturing unrestricted AP', () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'ExtendedConfig',
          models: {
            ClassModel(
              isDeprecated: false,
              name: 'Base',
              context: context,
              properties: [
                Property(
                  name: 'id',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
          },
          context: context,
          additionalProperties: const UnrestrictedAdditionalProperties(),
        );

        const expectedMethod = r'''
  factory ExtendedConfig.fromSimple(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'id'},
      listKeys: {},
      context: r'ExtendedConfig',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'id'};
    final _$additional = <String, String>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeSimpleString(
          context: r'ExtendedConfig.additionalProperties',
        );
      }
    }
    return ExtendedConfig(
      $base: Base.fromSimple(value, explode: explode),
      additionalProperties: _$additional,
    );
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates fromSimple capturing typed string AP', () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'TypedExtended',
          models: {
            ClassModel(
              isDeprecated: false,
              name: 'Base',
              context: context,
              properties: [
                Property(
                  name: 'name',
                  model: StringModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
          },
          context: context,
          additionalProperties: TypedAdditionalProperties(
            valueModel: StringModel(context: context),
          ),
        );

        const expectedMethod = r'''
  factory TypedExtended.fromSimple(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'name'},
      listKeys: {},
      context: r'TypedExtended',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'name'};
    final _$additional = <String, String>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeSimpleString(
          context: r'TypedExtended.additionalProperties',
        );
      }
    }
    return TypedExtended(
      $base: Base.fromSimple(value, explode: explode),
      additionalProperties: _$additional,
    );
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates fromSimple without AP for typed complex AP', () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'ComplexExtended',
          models: {
            ClassModel(
              isDeprecated: false,
              name: 'Base',
              context: context,
              properties: [
                Property(
                  name: 'id',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
          },
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

        const expectedMethod = r'''
  factory ComplexExtended.fromSimple(String? value, {required bool explode}) {
    return ComplexExtended($base: Base.fromSimple(value, explode: explode));
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test(
        'generates fromSimple with AP collecting keys from multiple members',
        () {
          final model = AllOfModel(
            isDeprecated: false,
            name: 'MultiMember',
            models: {
              ClassModel(
                isDeprecated: false,
                name: 'First',
                context: context,
                properties: [
                  Property(
                    name: 'alpha',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
              ),
              ClassModel(
                isDeprecated: false,
                name: 'Second',
                context: context,
                properties: [
                  Property(
                    name: 'beta',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
              ),
            },
            context: context,
            additionalProperties: const UnrestrictedAdditionalProperties(),
          );

          const expectedMethod = r'''
  factory MultiMember.fromSimple(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: ',',
      expectedKeys: {r'alpha', r'beta'},
      listKeys: {},
      context: r'MultiMember',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'alpha', r'beta'};
    final _$additional = <String, String>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeSimpleString(
          context: r'MultiMember.additionalProperties',
        );
      }
    }
    return MultiMember(
      first: First.fromSimple(value, explode: explode),
      second: Second.fromSimple(value, explode: explode),
      additionalProperties: _$additional,
    );
  }''';

          final combinedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(combinedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        },
      );
    });

    group('fromForm with additionalProperties', () {
      test('generates fromForm capturing unrestricted AP', () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'ExtendedConfig',
          models: {
            ClassModel(
              isDeprecated: false,
              name: 'Base',
              context: context,
              properties: [
                Property(
                  name: 'id',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
          },
          context: context,
          additionalProperties: const UnrestrictedAdditionalProperties(),
        );

        const expectedMethod = r'''
  factory ExtendedConfig.fromForm(String? value, {required bool explode}) {
    final _$values = value.decodeObject(
      explode: explode,
      explodeSeparator: '&',
      expectedKeys: {r'id'},
      listKeys: {},
      context: r'ExtendedConfig',
      captureAdditionalKeys: true,
    );
    const _$knownKeys = {r'id'};
    final _$additional = <String, String>{};
    for (final _$entry in _$values.entries) {
      if (!_$knownKeys.contains(_$entry.key)) {
        _$additional[_$entry.key] = _$entry.value.decodeFormString(
          context: r'ExtendedConfig.additionalProperties',
        );
      }
    }
    return ExtendedConfig(
      $base: Base.fromForm(value, explode: explode),
      additionalProperties: _$additional,
    );
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('parameterProperties with additionalProperties', () {
      test('generates parameterProperties with unrestricted AP loop', () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'ExtendedConfig',
          models: {
            ClassModel(
              isDeprecated: false,
              name: 'Base',
              context: context,
              properties: [
                Property(
                  name: 'id',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
          },
          context: context,
          additionalProperties: const UnrestrictedAdditionalProperties(),
        );

        const expectedMethod = r'''
  Map<String, String> parameterProperties({
    bool allowEmpty = true,
    bool allowLists = true,
  }) {
    final _$mergedProperties = <String, String>{};
    _$mergedProperties.addAll(
      $base.parameterProperties(allowEmpty: allowEmpty, allowLists: allowLists),
    );
    for (final _$e in additionalProperties.entries) {
      _$mergedProperties[_$e.key] = _$e.value?.toString() ?? '';
    }
    return _$mergedProperties;
  }''';

        final combinedClass = generator.generateClass(model);
        expect(
          collapseWhitespace(
            format(combinedClass.accept(emitter).toString()),
          ),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test(
        'generates parameterProperties with typed simple AP uriEncode loop',
        () {
          final model = AllOfModel(
            isDeprecated: false,
            name: 'TypedExtended',
            models: {
              ClassModel(
                isDeprecated: false,
                name: 'Base',
                context: context,
                properties: [
                  Property(
                    name: 'name',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
              ),
            },
            context: context,
            additionalProperties: TypedAdditionalProperties(
              valueModel: StringModel(context: context),
            ),
          );

          const expectedMethod = r'''
  Map<String, String> parameterProperties({
    bool allowEmpty = true,
    bool allowLists = true,
  }) {
    final _$mergedProperties = <String, String>{};
    _$mergedProperties.addAll(
      $base.parameterProperties(allowEmpty: allowEmpty, allowLists: allowLists),
    );
    for (final _$e in additionalProperties.entries) {
      _$mergedProperties[_$e.key] = _$e.value.uriEncode(allowEmpty: allowEmpty);
    }
    return _$mergedProperties;
  }''';

          final combinedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(combinedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        },
      );

      test(
        'generates parameterProperties with typed complex AP throwing',
        () {
          final model = AllOfModel(
            isDeprecated: false,
            name: 'ComplexExtended',
            models: {
              ClassModel(
                isDeprecated: false,
                name: 'Base',
                context: context,
                properties: [
                  Property(
                    name: 'id',
                    model: IntegerModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                ],
              ),
            },
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

          const expectedMethod = r'''
  Map<String, String> parameterProperties({
    bool allowEmpty = true,
    bool allowLists = true,
  }) {
    final _$mergedProperties = <String, String>{};
    _$mergedProperties.addAll(
      $base.parameterProperties(allowEmpty: allowEmpty, allowLists: allowLists),
    );
    if (additionalProperties.isNotEmpty) {
      throw EncodingException(
        r'Additional properties with complex types cannot be parameter encoded.',
      );
    }
    return _$mergedProperties;
  }''';

          final combinedClass = generator.generateClass(model);
          expect(
            collapseWhitespace(
              format(combinedClass.accept(emitter).toString()),
            ),
            contains(collapseWhitespace(expectedMethod)),
          );
        },
      );
    });
  });

  group('with useImmutableCollections', () {
    late AllOfGenerator immutableGenerator;

    setUp(() {
      immutableGenerator = AllOfGenerator(
        nameManager: nameManager,
        package: 'example',
        stableModelSorter: StableModelSorter(),
        useImmutableCollections: true,
      );
    });

    test('allOf with ListModel component uses IList field type', () {
      final model = AllOfModel(
        isDeprecated: false,
        name: 'WithList',
        models: {
          ListModel(
            content: StringModel(context: context),
            context: context,
          ),
        },
        context: context,
      );

      final combinedClass = immutableGenerator.generateClass(model);

      final listField = combinedClass.fields.first;
      final typeRef = listField.type! as TypeReference;
      expect(typeRef.symbol, 'IList');
      expect(
        typeRef.url,
        'package:fast_immutable_collections/'
        'fast_immutable_collections.dart',
      );
      expect(typeRef.types.length, 1);
      expect(
        (typeRef.types.first as TypeReference).symbol,
        'String',
      );

      // Equality should use direct == (IList has built-in value equality)
      final generated = format(
        combinedClass.accept(emitter).toString(),
      );
      const expectedEquals = '''
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is WithList && other.iList == this.iList;
}
''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedEquals)),
      );
    });

    test(
      'allOf with additional properties and useImmutableCollections',
      () {
        final model = AllOfModel(
          isDeprecated: false,
          name: 'ExtendedImmutable',
          models: {
            ClassModel(
              isDeprecated: false,
              name: 'Base',
              context: context,
              properties: [
                Property(
                  name: 'id',
                  model: IntegerModel(context: context),
                  isRequired: true,
                  isNullable: false,
                  isDeprecated: false,
                ),
              ],
            ),
          },
          context: context,
          additionalProperties:
              const UnrestrictedAdditionalProperties(),
        );

        final combinedClass = immutableGenerator.generateClass(model);
        final generated = format(
          combinedClass.accept(emitter).toString(),
        );

        // AP field type should be IMap
        final apField = combinedClass.fields.firstWhere(
          (f) => f.name == 'additionalProperties',
        );
        final apTypeRef = apField.type! as TypeReference;
        expect(apTypeRef.symbol, 'IMap');
        expect(
          apTypeRef.url,
          'package:fast_immutable_collections/'
          'fast_immutable_collections.dart',
        );
        expect(apTypeRef.types.length, 2);
        expect(apTypeRef.types.first.symbol, 'String');

        // Constructor default should be IMapConst
        final defaultCtor = combinedClass.constructors.firstWhere(
          (c) => c.name == null,
        );
        final apParam = defaultCtor.optionalParameters.firstWhere(
          (p) => p.name == 'additionalProperties',
        );
        expect(
          apParam.defaultTo?.accept(emitter).toString(),
          'const IMapConst({})',
        );

        // fromJson should use .lock on _$additional
        const expectedFromJson = r'''
factory ExtendedImmutable.fromJson(Object? json) {
  final _$map = json.decodeMap(context: r'ExtendedImmutable');
  const _$knownKeys = {r'id'};
  final _$additional = <String, Object?>{};
  for (final _$entry in _$map.entries) {
    if (!_$knownKeys.contains(_$entry.key)) {
      _$additional[_$entry.key] = _$entry.value;
    }
  }
  return ExtendedImmutable(
    $base: Base.fromJson(json),
    additionalProperties: _$additional.lock,
  );
}
''';
        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedFromJson)),
        );

        // toJson should use .unlock on AP
        const expectedToJson = r'''
Object? toJson() {
  final _$map = <String, Object?>{};
  final _$$baseJson = $base.toJson();
  if (_$$baseJson is! Map<String, Object?>) {
    throw EncodingException(
      'Expected \$base.toJson() to return Map<String, Object?>, got ${_$$baseJson.runtimeType}',
    );
  }
  _$map.addAll(_$$baseJson);
  _$map.addAll(additionalProperties.unlock);
  return _$map;
}
''';
        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(expectedToJson)),
        );
      },
    );
  });
}
