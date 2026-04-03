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

  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = OneOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
      stableModelSorter: StableModelSorter(),
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
          isDeprecated: false,
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
          context: context,
        );

        generatedClasses = generator.generateClasses(model);
        baseClass = generatedClasses.firstWhere((c) => c.name == 'Result');
      });

      test('toJson method handles primitive values', () {
        final toJson = baseClass.methods.firstWhere((m) => m.name == 'toJson');
        expect(toJson.returns?.accept(emitter).toString(), 'Object?');

        final generatedCode = format(baseClass.accept(emitter).toString());
        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              ResultError(:final value) => (value, r'error'),
              ResultSuccess(:final value) => (value, r'success'),
            };

            return _$json;
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
              int s => ResultError(s),
              String s => ResultSuccess(s),
              _ => throw JsonDecodingException(
                r'Invalid JSON type for Result: ${json.runtimeType}',
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
          isDeprecated: false,
          name: 'Result',
          models: {
            (
              discriminatorValue: 'success',
              model: ClassModel(
                isDeprecated: false,
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
                isDeprecated: false,
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

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              ResultError(:final value) => (value.toJson(), r'error'),
              ResultSuccess(:final value) => (value.toJson(), r'success'),
            };

            if (_$discriminator != null && _$json is Map<String, Object?>) {
              _$json.putIfAbsent(r'type', () => _$discriminator);
            }

            return _$json;
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

        const expectedMethod = r'''
          factory Result.fromJson(Object? json) {
            final _$discriminator = json is Map<String, Object?> ? json[r'type'] : null;

            final _$result = switch (_$discriminator) {
              r'error' => ResultError(Error.fromJson(json)),
              r'success' => ResultSuccess(Success.fromJson(json)),
              _ => null,
            };

            if (_$result != null) {
              return _$result;
            }

            try {
              return ResultError(Error.fromJson(json));
            } on Object catch (_) {}

            try {
              return ResultSuccess(Success.fromJson(json));
            } on Object catch (_) {}

            throw JsonDecodingException(r'Invalid JSON for Result');
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
          isDeprecated: false,
          name: 'Result',
          models: {
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
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
                isDeprecated: false,
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

          const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              ResultError(:final value) => (value.toJson(), r'error'),
              ResultSuccess(:final value) => (value.toJson(), null),
              ResultString(:final value) => (value, null),
            };

            if (_$discriminator != null && _$json is Map<String, Object?>) {
              _$json.putIfAbsent(r'discriminator', () => _$discriminator);
            }

            return _$json;
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

        const expectedMethod = r'''
          factory Result.fromJson(Object? json) {
            final _$discriminator = json is Map<String, Object?> ? json[r'discriminator'] : null;

            final _$result = switch (_$discriminator) {
              r'error' => ResultError(Error.fromJson(json)),
              _ => null,
            };

            if (_$result != null) {
              return _$result;
            }

            if (json is String) {
              return ResultString(json);
            }

            try {
              return ResultError(Error.fromJson(json));
            } on Object catch (_) {}

            try {
              return ResultSuccess(Success.fromJson(json));
            } on Object catch (_) {}

            throw JsonDecodingException(r'Invalid JSON for Result');
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
          isDeprecated: false,
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
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'TimestampValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              TimestampValueString(:final value) => (value, r'string'),
              TimestampValueTimestamp(:final value) => ( value.toTimeZonedIso8601String(), r'timestamp', ),
            };

            return _$json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles Date models correctly', () {
        final model = OneOfModel(
          isDeprecated: false,
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
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'DateValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              DateValueDate(:final value) => (value.toJson(), r'date'),
              DateValueString(:final value) => (value, r'string'),
            };

            return _$json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles Decimal models correctly', () {
        final model = OneOfModel(
          isDeprecated: false,
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
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'NumericValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              NumericValueDecimal(:final value) => (value.toString(), r'decimal'),
              NumericValueInteger(:final value) => (value, r'integer'),
            };

            return _$json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles Uri models correctly', () {
        final model = OneOfModel(
          isDeprecated: false,
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
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'UriValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              UriValueString(:final value) => (value, r'string'),
              UriValueUri(:final value) => (value.toString(), r'uri'),
            };

            return _$json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles Enum models correctly', () {
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

        final model = OneOfModel(
          isDeprecated: false,
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
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'StatusValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              StatusValueStatus(:final value) => (value.toJson(), r'status'),
              StatusValueString(:final value) => (value, r'string'),
            };

            return _$json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles Class models correctly', () {
        final classModel = ClassModel(
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

        final model = OneOfModel(
          isDeprecated: false,
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
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'UserValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              UserValueString(:final value) => (value, r'string'),
              UserValueUser(:final value) => (value.toJson(), r'user'),
            };

            return _$json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('toJson method handles AllOf models correctly', () {
        final allOfModel = AllOfModel(
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
          },
          context: context,
        );

        final model = OneOfModel(
          isDeprecated: false,
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
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'CombinedValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              CombinedValueCombined(:final value) => (value.toJson(), r'combined'),
              CombinedValueString(:final value) => (value, r'string'),
            };

            return _$json;
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
            isDeprecated: false,
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
            context: context,
          );

          final generatedClasses = generator.generateClasses(model);
          final baseClass = generatedClasses.firstWhere(
            (c) => c.name == 'ListValue',
          );
          final generatedCode = format(baseClass.accept(emitter).toString());

          const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              ListValueList(:final value) => (value, r'list'),
              ListValueString(:final value) => (value, r'string'),
            };

            return _$json;
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
            isDeprecated: false,
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
            isDeprecated: false,
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
            context: context,
          );

          final generatedClasses = generator.generateClasses(model);
          final baseClass = generatedClasses.firstWhere(
            (c) => c.name == 'ItemListValue',
          );
          final generatedCode = format(baseClass.accept(emitter).toString());

          const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              ItemListValueItems(:final value) => ( value.map((e) => e.toJson()).toList(), r'items', ),
              ItemListValueString(:final value) => (value, r'string'),
            };

            return _$json;
          }''';

          expect(
            collapseWhitespace(generatedCode),
            contains(collapseWhitespace(expectedMethod)),
          );
        },
      );

      test('toJson method handles AnyOf models correctly', () {
        final anyOfModel = AnyOfModel(
          isDeprecated: false,
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
          isDeprecated: false,
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
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'FlexibleValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              FlexibleValueBoolean(:final value) => (value, r'boolean'),
              FlexibleValueFlexible(:final value) => (value.toJson(), r'flexible'),
            };

            return _$json;
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
          isDeprecated: false,
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
          context: context,
        );

        final generatedClasses = generator.generateClasses(model);
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == 'IdentifierValue',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              IdentifierValueNumber(:final value) => (value, r'number'),
              IdentifierValueUserId(:final value) => (value, r'userId'),
            };

            return _$json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });
  });

  group(r'nullable oneOf with $Raw-prefixed class name', () {
    test(
      r'fromJson throws raw string literal for $Raw-prefixed class name',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Pet',
          models: {
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'Cat',
                properties: const [],
                context: context,
              ),
            ),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'Dog',
                properties: const [],
                context: context,
              ),
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

        final generatedClasses = generator.generateClasses(model, r'$RawPet');
        final baseClass = generatedClasses.firstWhere(
          (c) => c.name == r'$RawPet',
        );
        final generatedCode = format(baseClass.accept(emitter).toString());

        expect(
          generatedCode,
          contains(r"r'Invalid JSON for $RawPet'"),
        );
      },
    );
  });

  group('special characters in discriminator', () {
    test(
      'toJson escapes discriminator value containing single quote',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Result',
          models: {
            (
              discriminatorValue: "it's-success",
              model: ClassModel(
                isDeprecated: false,
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
          },
          discriminator: 'type',
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Result');
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              ResultSuccess(:final value) => (value.toJson(), r"it's-success"),
            };

            if (_$discriminator != null && _$json is Map<String, Object?>) {
              _$json.putIfAbsent(r'type', () => _$discriminator);
            }

            return _$json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test(
      'toJson escapes discriminator field name containing single quote',
      () {
        final model = OneOfModel(
          isDeprecated: false,
          name: 'Result',
          models: {
            (
              discriminatorValue: 'success',
              model: ClassModel(
                isDeprecated: false,
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
          },
          discriminator: "it's-type",
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Result');
        final generatedCode = format(baseClass.accept(emitter).toString());

        const expectedMethod = r'''
          Object? toJson() {
            final (dynamic _$json, String? _$discriminator) = switch (this) {
              ResultSuccess(:final value) => (value.toJson(), r'success'),
            };

            if (_$discriminator != null && _$json is Map<String, Object?>) {
              _$json.putIfAbsent(r"it's-type", () => _$discriminator);
            }

            return _$json;
          }''';

        expect(
          collapseWhitespace(generatedCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });
}
