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

  group('AllOfGenerator', () {
    group('with class models', () {
      test('generates class with references to each model', () {
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

        // Should have fields for each model
        expect(combinedClass.name, 'CombinedModel');
        expect(combinedClass.constructors, hasLength(2));
        expect(combinedClass.constructors.first.constant, isTrue);

        // Should have fields for each model
        expect(combinedClass.fields, hasLength(2));
        expect(
          combinedClass.fields.map((f) => f.name),
          containsAll(['base', 'mixin']),
        );

        // Check field types
        final baseField = combinedClass.fields.firstWhere(
          (f) => f.name == 'base',
        );
        expect(baseField.type?.accept(emitter).toString(), 'Base');

        final mixinField = combinedClass.fields.firstWhere(
          (f) => f.name == 'mixin',
        );
        expect(mixinField.type?.accept(emitter).toString(), 'Mixin');
      });

      test('generates toJson method that combines all model properties', () {
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

        const expectedMethod = r'''
          Object? toJson() {
            final map = <String, Object?>{};
            final baseJson = base.toJson();
            if (baseJson is! Map<String, Object?>) {
              throw EncodingException(
                'Expected base.toJson() to return Map<String, Object?>, got ${baseJson.runtimeType}',
              );
            }
            map.addAll(baseJson);
            final mixinJson = mixin.toJson();
            if (mixinJson is! Map<String, Object?>) {
              throw EncodingException(
                'Expected mixin.toJson() to return Map<String, Object?>, got ${mixinJson.runtimeType}',
              );
            }
            map.addAll(mixinJson);
            return map;
          }
        ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates fromJson method that validates all model properties', () {
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

        const expectedMethod = '''
          factory CombinedModel.fromJson(Object? json) {
            return CombinedModel(
              base: Base.fromJson(json),
              mixin: Mixin.fromJson(json),
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

        // Should have fields for each model
        expect(combinedClass.fields, hasLength(2));
        expect(
          combinedClass.fields.map((f) => f.name),
          containsAll(['base', 'mixin']),
        );

        // Check field types
        final baseField = combinedClass.fields.firstWhere(
          (f) => f.name == 'base',
        );
        expect(baseField.type?.accept(emitter).toString(), 'Base');

        final mixinField = combinedClass.fields.firstWhere(
          (f) => f.name == 'mixin',
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

        const expectedEquals = '''
          @override
          bool operator ==(Object other) {
            if (identical(this, other)) return true;
            return other is CombinedModel &&
              other.base == base &&
              other.mixin == mixin;
          }
        ''';

        const expectedHashCode = '''
          @override
          int get hashCode {
            return Object.hashAll([base, mixin]);
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
          name: 'StringDecimalModel',
          models: <Model>{
            StringModel(context: context),
            DecimalModel(context: context),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);

        // Should have fields for each model
        expect(combinedClass.fields, hasLength(2));
        expect(
          combinedClass.fields.map((f) => f.name),
          containsAll(['string', 'bigDecimal']),
        );

        // Check field types
        final stringField = combinedClass.fields.firstWhere(
          (f) => f.name == 'string',
        );
        expect(stringField.type?.accept(emitter).toString(), 'String');

        final decimalField = combinedClass.fields.firstWhere(
          (f) => f.name == 'bigDecimal',
        );
        expect(decimalField.type?.accept(emitter).toString(), 'BigDecimal');

        // Check toJson - should return the string value
        const expectedToJson = '''
          Object? toJson() => string;
        ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedToJson)),
        );

        // Check fromJson - should decode single value into both types
        const expectedFromJson = '''
          factory StringDecimalModel.fromJson(Object? json) {
            return StringDecimalModel(
              string: json.decodeJsonString(context: r'StringDecimalModel'),
              bigDecimal: json.decodeJsonBigDecimal(context: r'StringDecimalModel'),
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

        // Should have fields for each model
        expect(combinedClass.fields, hasLength(2));
        expect(
          combinedClass.fields.map((f) => f.name),
          containsAll(['status', 'string']),
        );

        // Check field types
        final enumField = combinedClass.fields.firstWhere(
          (f) => f.name == 'status',
        );
        expect(enumField.type?.accept(emitter).toString(), 'Status');

        final stringField = combinedClass.fields.firstWhere(
          (f) => f.name == 'string',
        );
        expect(stringField.type?.accept(emitter).toString(), 'String');

        // Check toJson - should return the string value
        const expectedToJson = '''
          Object? toJson() => status.toJson();
        ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedToJson)),
        );

        // Check fromJson - should decode single value into both types
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

        // Check equals and hashCode
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
          name: 'DateStringModel',
          models: <Model>{
            DateModel(context: context),
            StringModel(context: context),
          },
          context: context,
        );

        final combinedClass = generator.generateClass(model);

        // Should have fields for each model
        expect(combinedClass.fields, hasLength(2));
        expect(
          combinedClass.fields.map((f) => f.name),
          containsAll(['date', 'string']),
        );

        // Check field types
        final dateField = combinedClass.fields.firstWhere(
          (f) => f.name == 'date',
        );
        expect(dateField.type?.accept(emitter).toString(), 'Date');

        final stringField = combinedClass.fields.firstWhere(
          (f) => f.name == 'string',
        );
        expect(stringField.type?.accept(emitter).toString(), 'String');

        // Check toJson - should return the ISO string
        const expectedToJson = '''
          Object? toJson() => date.toJson();
        ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedToJson)),
        );

        // Check fromJson - should decode single value into both types
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

      test('handles number models with single value', () {
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

        // Should have fields for each model
        expect(combinedClass.fields, hasLength(3));
        expect(
          combinedClass.fields.map((f) => f.name).toList(),
          containsAll(['num', 'double', 'int']),
        );

        // Check field types
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

        // Check toJson - should return the number value
        const expectedToJson = '''
          Object? toJson() => num;
        ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedToJson)),
        );

        // Check fromJson - should decode single value into all number types
        const expectedFromJson = '''
          factory NumberModel.fromJson(Object? json) {
            return NumberModel(
              num: json.decodeJsonNum(context: r'NumberModel'),
              double: json.decodeJsonDouble(context: r'NumberModel'),
              int: json.decodeJsonInt(context: r'NumberModel'),
            );
          }
        ''';

        expect(
          collapseWhitespace(format(combinedClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedFromJson)),
        );
      });
    });
  });
}
