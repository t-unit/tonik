import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/util/name_generator.dart';
import 'package:tonik_generate/src/util/name_manager.dart';

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
        expect(toJson.returns?.accept(emitter).toString(), 'dynamic');

        final generatedCode = format(baseClass.accept(emitter).toString());
        const expectedMethod = '''
          dynamic toJson() {
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

      test('fromJson method handles primitive values', () {
        final fromJson = baseClass.methods.firstWhere(
          (m) => m.name == 'fromJson',
        );
        expect(fromJson.static, isTrue);
        expect(fromJson.returns?.accept(emitter).toString(), 'Result');
        expect(
          fromJson.requiredParameters.first.type?.accept(emitter).toString(),
          'dynamic',
        );

        final generatedCode = format(baseClass.accept(emitter).toString());
        const expectedMethod = r'''
          static Result fromJson(dynamic json) {
            return switch (json) {
              String s => ResultSuccess(s),
              int s => ResultError(s),
              _ => throw ArgumentError(
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
                properties: {
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                },
                context: context,
              ),
            ),
            (
              discriminatorValue: 'error',
              model: ClassModel(
                name: 'Error',
                properties: {
                  Property(
                    name: 'value',
                    model: IntegerModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                },
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
        expect(toJson.returns?.accept(emitter).toString(), 'dynamic');

        const expectedMethod = '''
          dynamic toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              ResultSuccess(:final value) => (value.toJson(), 'success'),
              ResultError(:final value) => (value.toJson(), 'error'),
            };

            if (discriminator != null && json is Map<String, dynamic>) {
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

      test('fromJson method handles discriminator for complex types', () {
        final fromJson = baseClass.methods.firstWhere(
          (m) => m.name == 'fromJson',
        );
        expect(fromJson.static, isTrue);
        expect(
          fromJson.requiredParameters.first.type?.accept(emitter).toString(),
          'dynamic',
        );

        const expectedMethod = '''
          static Result fromJson(dynamic json) {
            final discriminator = json is Map<String, dynamic> ? json['type'] : null;

            final result = switch (discriminator) {
              'success' => ResultSuccess(Success.fromJson(json)),
              'error' => ResultError(Error.fromJson(json)),
              _ => null,
            };

            if (result != null) {
              return result;
            }

            throw ArgumentError('Invalid JSON for Result');
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
                properties: {
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                },
                context: context,
              ),
            ),
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: 'error',
              model: ClassModel(
                name: 'Error',
                properties: {
                  Property(
                    name: 'value',
                    model: IntegerModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                  ),
                },
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
          expect(toJson.returns?.accept(emitter).toString(), 'dynamic');

          const expectedMethod = '''
          dynamic toJson() {
            final (dynamic json, String? discriminator) = switch (this) {
              ResultSuccess(:final value) => (value.toJson(), null),
              ResultAnonymous(:final value) => (value, null),
              ResultError(:final value) => (value.toJson(), 'error'),
            };

            if (discriminator != null && json is Map<String, dynamic>) {
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

      test('fromJson method with type detection fallbacks', () {
        final fromJson = baseClass.methods.firstWhere(
          (m) => m.name == 'fromJson',
        );
        expect(fromJson.static, isTrue);
        expect(
          fromJson.requiredParameters.first.type?.accept(emitter).toString(),
          'dynamic',
        );

        const expectedMethod = '''
          static Result fromJson(dynamic json) {
            final discriminator = json is Map<String, dynamic> ? json['discriminator'] : null;

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
            } catch (_) {}

            throw ArgumentError('Invalid JSON for Result');
          }''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });
  });
}
