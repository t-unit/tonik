import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late OneOfGenerator generator;
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
    generator = OneOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('OneOf JSON serialization', () {
    group('with primitive types', () {
      late List<Class> generatedClasses;
      late Class baseClass;

      setUp(() {
        final model = OneOfModel(
          name: 'Result',
          models: {
            (
              discriminatorValue: 'success',
              model: StringModel(context: context),
            ),
            (
              discriminatorValue: 'error',
              model: IntegerModel(context: context),
            ),
          },
          discriminator: null,
          context: context,
        );

        generatedClasses = generator.generateClasses(model);
        baseClass = generatedClasses.firstWhere((c) => c.name == 'Result');
      });

      test('toJson method handles primitive values', () {
        final toJson = baseClass.methods.firstWhere((m) => m.name == 'toJson');
        expect(toJson.returns?.accept(emitter).toString(), 'Object?');

        final generatedCode = format(baseClass.accept(emitter).toString());
        const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              ResultSuccess(:final value) => (value, 'success'),
              ResultError(:final value) => (value, 'error'),
            };

            return json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('fromJson factory handles primitive values', () {
        final fromJsonCtor = baseClass.constructors.firstWhere(
          (c) => c.name == 'fromJson',
        );
        expect(fromJsonCtor.factory, isTrue);
        expect(
          fromJsonCtor.requiredParameters.first.type
              ?.accept(emitter)
              .toString(),
          'Object?',
        );

        final generatedCode = format(baseClass.accept(emitter).toString());
        const expectedMethod = r'''
          factory Result.fromJson(Object? json) {
            return switch (json) {
              String s => ResultSuccess(s),
              int s => ResultError(s),
              _ => throw JsonDecodingException(
                'Invalid JSON type for Result: ${json.runtimeType}',
              ),
            };
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('with complex types and discriminator', () {
      late List<Class> generatedClasses;
      late Class baseClass;

      setUp(() {
        final model = OneOfModel(
          name: 'Result',
          models: {
            (
              discriminatorValue: 'success',
              model: ClassModel(
                name: 'Success',
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
            (
              discriminatorValue: 'error',
              model: ClassModel(
                name: 'Error',
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
            ),
          },
          discriminator: 'type',
          context: context,
        );

        generatedClasses = generator.generateClasses(model);
        baseClass = generatedClasses.firstWhere((c) => c.name == 'Result');
      });

      test('toJson method includes discriminator for complex types', () {
        final toJson = baseClass.methods.firstWhere((m) => m.name == 'toJson');
        expect(toJson.returns?.accept(emitter).toString(), 'Object?');

        const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              ResultSuccess(:final value) => (value.toJson(), 'success'),
              ResultError(:final value) => (value.toJson(), 'error'),
            };

            if (discriminator != null && json is Map<String, Object?>) {
              json.putIfAbsent('type', () => discriminator);
            }

            return json;
          }''';

        final generatedCode = format(baseClass.accept(emitter).toString());
        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('fromJson factory handles discriminator for complex types', () {
        final fromJsonCtor = baseClass.constructors.firstWhere(
          (c) => c.name == 'fromJson',
        );
        expect(fromJsonCtor.factory, isTrue);
        expect(
          fromJsonCtor.requiredParameters.first.type
              ?.accept(emitter)
              .toString(),
          'Object?',
        );

        const expectedMethod = '''
          factory Result.fromJson(Object? json) {
            final discriminator = json is Map<String, Object?> ? json['type'] : null;

            final result = switch (discriminator) {
              'success' => ResultSuccess(Success.fromJson(json)),
              'error' => ResultError(Error.fromJson(json)),
              _ => null,
            };

            if (result != null) {
              return result;
            }

            throw JsonDecodingException('Invalid JSON for Result');
          }''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('with mixed types', () {
      late List<Class> generatedClasses;
      late Class baseClass;

      setUp(() {
        final model = OneOfModel(
          name: 'Result',
          models: {
            (
              discriminatorValue: null,
              model: ClassModel(
                name: 'Success',
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
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: 'error',
              model: ClassModel(
                name: 'Error',
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
            ),
          },
          discriminator: 'discriminator',
          context: context,
        );

        generatedClasses = generator.generateClasses(model);
        baseClass = generatedClasses.firstWhere((c) => c.name == 'Result');
      });

      test(
        'toJson method handles mixed types with and without discriminator',
        () {
          final toJson = baseClass.methods.firstWhere(
            (m) => m.name == 'toJson',
          );
          expect(toJson.returns?.accept(emitter).toString(), 'Object?');

          const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              ResultSuccess(:final value) => (value.toJson(), null),
              ResultAnonymous(:final value) => (value, null),
              ResultError(:final value) => (value.toJson(), 'error'),
            };

            if (discriminator != null && json is Map<String, Object?>) {
              json.putIfAbsent('discriminator', () => discriminator);
            }

            return json;
          }''';

          final generatedCode = format(baseClass.accept(emitter).toString());
          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedMethod)),
          );
        },
      );

      test('fromJson factory with type detection fallbacks', () {
        final fromJsonCtor = baseClass.constructors.firstWhere(
          (c) => c.name == 'fromJson',
        );
        expect(fromJsonCtor.factory, isTrue);
        expect(
          fromJsonCtor.requiredParameters.first.type
              ?.accept(emitter)
              .toString(),
          'Object?',
        );

        const expectedMethod = '''
          factory Result.fromJson(Object? json) {
            final discriminator = json is Map<String, Object?> ? json['discriminator'] : null;

            final result = switch (discriminator) {
              'error' => ResultError(Error.fromJson(json)),
              _ => null,
            };

            if (result != null) {
              return result;
            }

            if (json is String) {
              return ResultAnonymous(json);
            }

            try {
              return ResultSuccess(Success.fromJson(json));
            } on Object catch (_) {}

            throw JsonDecodingException('Invalid JSON for Result');
          }''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });

    group('with complex data types', () {
      test('toJson method handles DateTime models correctly', () {
        final model = OneOfModel(
          name: 'TimestampValue',
          models: {
            (
              discriminatorValue: 'timestamp',
              model: DateTimeModel(context: context),
            ),
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
          },
          discriminator: null,
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'TimestampValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              TimestampValueTimestamp(:final value) => ( value.toTimeZonedIso8601String(), 'timestamp', ),
              TimestampValueString(:final value) => (value, 'string'),
            };

            return json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles Date models correctly', () {
        final model = OneOfModel(
          name: 'DateValue',
          models: {
            (
              discriminatorValue: 'date',
              model: DateModel(context: context),
            ),
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
          },
          discriminator: null,
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'DateValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              DateValueDate(:final value) => (value.toJson(), 'date'),
              DateValueString(:final value) => (value, 'string'),
            };

            return json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles Decimal models correctly', () {
        final model = OneOfModel(
          name: 'NumericValue',
          models: {
            (
              discriminatorValue: 'decimal',
              model: DecimalModel(context: context),
            ),
            (
              discriminatorValue: 'integer',
              model: IntegerModel(context: context),
            ),
          },
          discriminator: null,
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'NumericValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              NumericValueDecimal(:final value) => (value.toString(), 'decimal'),
              NumericValueInteger(:final value) => (value, 'integer'),
            };

            return json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles Uri models correctly', () {
        final model = OneOfModel(
          name: 'UriValue',
          models: {
            (
              discriminatorValue: 'uri',
              model: UriModel(context: context),
            ),
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
          },
          discriminator: null,
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'UriValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              UriValueUri(:final value) => (value.toString(), 'uri'),
              UriValueString(:final value) => (value, 'string'),
            };

            return json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles Enum models correctly', () {
        final enumModel = EnumModel<String>(
          name: 'Status',
          values: const {'active', 'inactive'},
          isNullable: false,
          context: context,
        );

        final model = OneOfModel(
          name: 'StatusValue',
          models: {
            (
              discriminatorValue: 'status',
              model: enumModel,
            ),
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
          },
          discriminator: null,
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'StatusValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              StatusValueStatus(:final value) => (value.toJson(), 'status'),
              StatusValueString(:final value) => (value, 'string'),
            };

            return json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles Class models correctly', () {
        final classModel = ClassModel(
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

        final model = OneOfModel(
          name: 'UserValue',
          models: {
            (
              discriminatorValue: 'user',
              model: classModel,
            ),
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
          },
          discriminator: null,
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'UserValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              UserValueUser(:final value) => (value.toJson(), 'user'),
              UserValueString(:final value) => (value, 'string'),
            };

            return json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles AllOf models correctly', () {
        final allOfModel = AllOfModel(
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
          },
          context: context,
        );

        final model = OneOfModel(
          name: 'CombinedValue',
          models: {
            (
              discriminatorValue: 'combined',
              model: allOfModel,
            ),
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
          },
          discriminator: null,
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'CombinedValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              CombinedValueCombined(:final value) => (value.toJson(), 'combined'),
              CombinedValueString(:final value) => (value, 'string'),
            };

            return json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test(
        'toJson method handles List models with primitive content correctly',
        () {
          final listModel = ListModel(
            content: StringModel(context: context),
            context: context,
          );

          final model = OneOfModel(
            name: 'ListValue',
            models: {
              (
                discriminatorValue: 'list',
                model: listModel,
              ),
              (
                discriminatorValue: 'string',
                model: StringModel(context: context),
              ),
            },
            discriminator: null,
            context: context,
          );

          final generatedClasses = generator.generateClasses(model);
          final baseClass = generatedClasses.firstWhere(
            (c) => c.name == 'ListValue',
          );
          final generatedCode = format(baseClass.accept(emitter).toString());

          const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              ListValueList(:final value) => (value, 'list'),
              ListValueString(:final value) => (value, 'string'),
            };

            return json;
          }''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedMethod)),
          );
        },
      );

      test(
        'toJson method handles List models with complex content correctly',
        () {
          final classModel = ClassModel(
            name: 'Item',
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

          final listModel = ListModel(
            content: classModel,
            context: context,
          );

          final model = OneOfModel(
            name: 'ItemListValue',
            models: {
              (
                discriminatorValue: 'items',
                model: listModel,
              ),
              (
                discriminatorValue: 'string',
                model: StringModel(context: context),
              ),
            },
            discriminator: null,
            context: context,
          );

          final generatedClasses = generator.generateClasses(model);
          final baseClass = generatedClasses.firstWhere(
            (c) => c.name == 'ItemListValue',
          );
          final generatedCode = format(baseClass.accept(emitter).toString());

          const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              ItemListValueItems(:final value) => ( value.map((e) => e.toJson()).toList(), 'items', ),
              ItemListValueString(:final value) => (value, 'string'),
            };

            return json;
          }''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedMethod)),
          );
        },
      );

      test('toJson method handles AnyOf models correctly', () {
        final anyOfModel = AnyOfModel(
          name: 'Flexible',
          models: {
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
            (
              discriminatorValue: 'int',
              model: IntegerModel(context: context),
            ),
          },
          discriminator: 'type',
          context: context,
        );

        final model = OneOfModel(
          name: 'FlexibleValue',
          models: {
            (
              discriminatorValue: 'flexible',
              model: anyOfModel,
            ),
            (
              discriminatorValue: 'boolean',
              model: BooleanModel(context: context),
            ),
          },
          discriminator: null,
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'FlexibleValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              FlexibleValueFlexible(:final value) => (value.toJson(), 'flexible'),
              FlexibleValueBoolean(:final value) => (value, 'boolean'),
            };

            return json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles Alias models correctly', () {
        final aliasModel = AliasModel(
          name: 'UserId',
          model: StringModel(context: context),
          context: context,
        );

        final model = OneOfModel(
          name: 'IdentifierValue',
          models: {
            (
              discriminatorValue: 'userId',
              model: aliasModel,
            ),
            (
              discriminatorValue: 'number',
              model: IntegerModel(context: context),
            ),
          },
          discriminator: null,
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'IdentifierValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
          Object? toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              IdentifierValueUserId(:final value) => (value, 'userId'),
              IdentifierValueNumber(:final value) => (value, 'number'),
            };

            return json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });
  });
}
