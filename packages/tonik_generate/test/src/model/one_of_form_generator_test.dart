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

  group('toForm method generation', () {
    test('toForm delegates to active variant value', () {
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

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Result');

      const expectedMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          return switch (this) {
            ResultSuccess(:final value) => value.toForm( explode: explode, allowEmpty: allowEmpty, ),
            ResultError(:final value) => value.toForm( explode: explode, allowEmpty: allowEmpty, ),
          };
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toForm injects discriminator for complex variants', () {
      final userModel = ClassModel(
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
        name: 'Response',
        models: {
          (
            discriminatorValue: 'user',
            model: userModel,
          ),
          (
            discriminatorValue: 'message',
            model: StringModel(context: context),
          ),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Response');

      const expectedMethod = '''
        String toForm({required bool explode, required bool allowEmpty}) {
          return switch (this) {
            ResponseUser(:final value) => {
              ...value.formProperties(allowEmpty: allowEmpty),
              'type': 'user',
            }.toForm(explode: explode, allowEmpty: allowEmpty),
            ResponseMessage(:final value) => value.toForm( explode: explode, allowEmpty: allowEmpty, ),
          };
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });

  group('fromForm constructor generation', () {
    test('fromForm tries variants in declaration order (primitive-only)', () {
      final model = OneOfModel(
        name: 'Result',
        models: {
          (
            discriminatorValue: 'error',
            model: IntegerModel(context: context),
          ),
          (
            discriminatorValue: 'success',
            model: StringModel(context: context),
          ),
        },
        discriminator: null,
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Result');

      const expectedMethod = '''
        factory Result.fromForm(String? value, {required bool explode}) {
          try {
            return ResultError(value.decodeFormInt(context: r'Result'));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          try {
            return ResultSuccess(value.decodeFormString(context: r'Result'));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          throw SimpleDecodingException('Invalid form value for Result');
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('fromForm tries complex variants using fromForm with explode', () {
      final userModel = ClassModel(
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
        name: 'Response',
        models: {
          (discriminatorValue: 'user', model: userModel),
          (discriminatorValue: 'msg', model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Response');

      const expectedMethod = '''
        factory Response.fromForm(String? value, {required bool explode}) {
          try {
            return ResponseUser(User.fromForm(value, explode: explode));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          try {
            return ResponseMsg(value.decodeFormString(context: r'Response'));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          throw SimpleDecodingException('Invalid form value for Response');
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'fromForm uses discriminator for fast-path routing with explode=true',
      () {
        final classA = ClassModel(
          name: 'A',
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
        );

        final classB = ClassModel(
          name: 'B',
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
          name: 'Choice',
          models: {
            (discriminatorValue: 'a', model: classA),
            (discriminatorValue: 'b', model: classB),
          },
          discriminator: 'type',
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'Choice');

        const expectedMethod = '''
          factory Choice.fromForm(String? value, {required bool explode}) {
            if (explode && value != null && value.isNotEmpty) {
              final pairs = value.split(',');
              String? discriminator;
              for (final pair in pairs) {
                final parts = pair.split('=');
                if (parts.length == 2) {
                  final key = Uri.decodeComponent(parts[0]);
                  if (key == 'type') {
                    discriminator = parts[1];
                    break;
                  }
                }
              }
              if (discriminator == 'a') {
                return ChoiceA(A.fromForm(value, explode: true));
              }
              if (discriminator == 'b') {
                return ChoiceB(B.fromForm(value, explode: true));
              }
            }
            try {
              return ChoiceA(A.fromForm(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            try {
              return ChoiceB(B.fromForm(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            throw SimpleDecodingException('Invalid form value for Choice');
          }
        ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );
  });

  group('formProperties method generation', () {
    test('formProperties delegates for class-only variants', () {
      final classA = ClassModel(
        name: 'A',
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
      );
      final classB = ClassModel(
        name: 'B',
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
        name: 'Choice',
        models: {
          (discriminatorValue: 'a', model: classA),
          (discriminatorValue: 'b', model: classB),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Choice');

      final formProps = baseClass.methods.firstWhere(
        (m) => m.name == 'formProperties',
      );
      expect(
        formProps.returns?.accept(emitter).toString(),
        'Map<String,String>',
      );
      expect(formProps.optionalParameters, hasLength(1));
      expect(formProps.optionalParameters.first.name, 'allowEmpty');
      expect(formProps.optionalParameters.first.required, isTrue);

      final generated = format(baseClass.accept(emitter).toString());
      const expectedMethod = '''
        Map<String, String> formProperties({required bool allowEmpty}) {
          return switch (this) {
            ChoiceA(:final value) => value.formProperties(allowEmpty: allowEmpty),
            ChoiceB(:final value) => value.formProperties(allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('formProperties returns empty map for primitive-only variants', () {
      final model = OneOfModel(
        name: 'Simple',
        models: {
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
          (discriminatorValue: 'str', model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Simple');

      final generated = format(baseClass.accept(emitter).toString());
      const expectedMethod = '''
        Map<String, String> formProperties({required bool allowEmpty}) {
          return switch (this) {
            SimpleInt(:final value) => <String, String>{},
            SimpleStr(:final value) => <String, String>{},
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('formProperties mixing class and primitive variants', () {
      final classM = ClassModel(
        name: 'M',
        properties: [
          Property(
            name: 'flag',
            model: BooleanModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final model = OneOfModel(
        name: 'MixedChoice',
        models: {
          (discriminatorValue: 'm', model: classM),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        discriminator: 'kind',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'MixedChoice');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
          Map<String, String> formProperties({required bool allowEmpty}) {
            return switch (this) {
              MixedChoiceM(:final value) => value.formProperties(
                allowEmpty: allowEmpty,
              ),
              MixedChoiceS(:final value) => <String, String>{},
            };
          }
        ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'formProperties without discriminator does not inject discriminator',
      () {
        final classA = ClassModel(
          name: 'A',
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
        );

        final model = OneOfModel(
          name: 'NoDiscriminator',
          models: {
            (discriminatorValue: null, model: classA),
            (discriminatorValue: null, model: StringModel(context: context)),
          },
          discriminator: null,
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere(
          (c) => c.name == 'NoDiscriminator',
        );
        final generated = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
          Map<String, String> formProperties({required bool allowEmpty}) {
            return switch (this) {
              NoDiscriminatorA(:final value) => value.formProperties(
                allowEmpty: allowEmpty,
              ),
              NoDiscriminatorAnonymous(:final value) => <String, String>{},
            };
          }
        ''';
        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );
  });

  group('fromForm constructor structure', () {
    test('fromForm constructor has correct signature', () {
      final model = OneOfModel(
        name: 'Test',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Test');
      final fromFormConstructor = baseClass.constructors.firstWhere(
        (c) => c.name == 'fromForm',
      );

      expect(fromFormConstructor.factory, isTrue);
      expect(fromFormConstructor.requiredParameters.length, 1);
      expect(fromFormConstructor.requiredParameters[0].name, 'value');
      expect(
        fromFormConstructor.requiredParameters[0].type
            ?.accept(emitter)
            .toString(),
        'String?',
      );
      expect(fromFormConstructor.optionalParameters.length, 1);
      expect(fromFormConstructor.optionalParameters[0].name, 'explode');
      expect(
        fromFormConstructor.optionalParameters[0].type
            ?.accept(emitter)
            .toString(),
        'bool',
      );
      expect(fromFormConstructor.optionalParameters[0].required, isTrue);
    });
  });

  group('toForm method structure', () {
    test('toForm method has correct signature', () {
      final model = OneOfModel(
        name: 'Test',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Test');
      final toFormMethod = baseClass.methods.firstWhere(
        (m) => m.name == 'toForm',
      );

      expect(toFormMethod.returns?.accept(emitter).toString(), 'String');
      expect(toFormMethod.optionalParameters, hasLength(2));
      expect(
        toFormMethod.optionalParameters.map((p) => p.name),
        containsAll(['explode', 'allowEmpty']),
      );
      expect(
        toFormMethod.optionalParameters.every((p) => p.required),
        isTrue,
      );
    });
  });
}
