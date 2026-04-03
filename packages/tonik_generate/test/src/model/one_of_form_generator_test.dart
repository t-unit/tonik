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

  group('toForm', () {
    test('toForm delegates to active variant value', () {
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

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == r'Result');

      const expectedMethod = '''
        String toForm({ required bool explode, required bool allowEmpty, bool useQueryComponent = false, }) {
          return switch (this) {
            ResultError(:final value) => value.toForm( explode: explode, allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, ),
            ResultSuccess(:final value) => value.toForm( explode: explode, allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, ),
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
      final baseClass = classes.firstWhere((c) => c.name == r'Response');

      const expectedMethod = '''
        String toForm({ required bool explode, required bool allowEmpty, bool useQueryComponent = false, }) {
          return switch (this) {
            ResponseMessage(:final value) => value.toForm( explode: explode, allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, ),
            ResponseUser(:final value) => {
              ...value.parameterProperties(allowEmpty: allowEmpty),
              r'type': r'user',
            }.toForm(
              explode: explode,
              allowEmpty: allowEmpty,
              useQueryComponent: useQueryComponent,
            ),
          };
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toForm method has correct signature', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Test',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == r'Test');
      final toFormMethod = baseClass.methods.firstWhere(
        (m) => m.name == 'toForm',
      );

      expect(toFormMethod.returns?.accept(emitter).toString(), 'String');
      expect(toFormMethod.optionalParameters, hasLength(3));
      expect(
        toFormMethod.optionalParameters.map((p) => p.name),
        containsAll(['explode', 'allowEmpty', 'useQueryComponent']),
      );
      expect(
        toFormMethod.optionalParameters.take(2).every((p) => p.required),
        isTrue,
      );
      expect(
        toFormMethod.optionalParameters.last.required,
        isFalse,
      );
    });
  });

  group('fromForm', () {
    test('fromForm constructor has correct signature', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'Test',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == r'Test');
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

    test('fromForm tries variants in declaration order (primitive-only)', () {
      final model = OneOfModel(
        isDeprecated: false,
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
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == r'Result');

      const expectedMethod = '''
        factory Result.fromForm(String? value, {required bool explode}) {
          try {
            return ResultError(value.decodeFormInt(context: r'Result'));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          try {
            return ResultSuccess(value.decodeFormString(context: r'Result'));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          throw SimpleDecodingException(r'Invalid form value for Result');
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('fromForm tries complex variants using fromForm with explode', () {
      final userModel = ClassModel(
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
        name: 'Response',
        models: {
          (discriminatorValue: 'user', model: userModel),
          (discriminatorValue: 'msg', model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == r'Response');

      const expectedMethod = '''
        factory Response.fromForm(String? value, {required bool explode}) {
          try {
            return ResponseMsg(value.decodeFormString(context: r'Response'));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          try {
            return ResponseUser(User.fromForm(value, explode: explode));
          } on DecodingException catch (_) { } on FormatException catch (_) {}
          throw SimpleDecodingException(r'Invalid form value for Response');
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
          isDeprecated: false,
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
          isDeprecated: false,
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
          isDeprecated: false,
          name: 'Choice',
          models: {
            (discriminatorValue: 'a', model: classA),
            (discriminatorValue: 'b', model: classB),
          },
          discriminator: 'type',
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == r'Choice');

        const expectedMethod = r'''
          factory Choice.fromForm(String? value, {required bool explode}) {
            if (explode && value != null && value.isNotEmpty) {
              final _$pairs = value.split(',');
              String? _$discriminator;
              for (final pair in _$pairs) {
                final _$parts = pair.split('=');
                if (_$parts.length == 2) {
                  final _$key = Uri.decodeComponent(_$parts[0]);
                  if (_$key == r'type') {
                    _$discriminator = _$parts[1];
                    break;
                  }
                }
              }
              if (_$discriminator == r'a') {
                return ChoiceA(A.fromForm(value, explode: explode));
              }
              if (_$discriminator == r'b') {
                return ChoiceB(B.fromForm(value, explode: explode));
              }
            }
            try {
              return ChoiceA(A.fromForm(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            try {
              return ChoiceB(B.fromForm(value, explode: explode));
            } on DecodingException catch (_) { } on FormatException catch (_) {}
            throw SimpleDecodingException(r'Invalid form value for Choice');
          }
        ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('toForm handles mixed-encoded variant without discriminator', () {
      final innerOneOf = OneOfModel(
        isDeprecated: false,
        name: 'Inner',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              isDeprecated: false,
              name: 'Data',
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
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Outer',
        models: {
          (discriminatorValue: null, model: innerOneOf),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == r'Outer');

      const expectedMethod = '''
        String toForm({ required bool explode, required bool allowEmpty, bool useQueryComponent = false, }) {
          return switch (this) {
            OuterInner(:final value) => value.toForm( explode: explode, allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, ),
          };
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toForm handles mixed-encoded variant with discriminator', () {
      final innerOneOf = OneOfModel(
        isDeprecated: false,
        name: 'Inner',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (
            discriminatorValue: null,
            model: ClassModel(
              isDeprecated: false,
              name: 'Data',
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
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Outer',
        models: {
          (discriminatorValue: 'inner', model: innerOneOf),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == r'Outer');

      const expectedMethod = '''
        String toForm({ required bool explode, required bool allowEmpty, bool useQueryComponent = false, }) {
          return switch (this) {
            OuterInner(:final value) => value.currentEncodingShape == EncodingShape.complex
              ? {
                  ...value.parameterProperties(allowEmpty: allowEmpty),
                  r'type': r'inner',
                }.toForm(
                  explode: explode,
                  allowEmpty: allowEmpty,
                  useQueryComponent: useQueryComponent,
                )
              : value.toForm( explode: explode, allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, ),
          };
        }
      ''';

      expect(
        collapseWhitespace(format(baseClass.accept(emitter).toString())),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'toForm handles multiple mixed-encoded variants with discriminator',
      () {
        final innerOneOfA = OneOfModel(
          isDeprecated: false,
          name: 'InnerA',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'DataA',
                properties: [
                  Property(
                    name: 'a',
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
          context: context,
        );

        final innerOneOfB = OneOfModel(
          isDeprecated: false,
          name: 'InnerB',
          models: {
            (discriminatorValue: null, model: IntegerModel(context: context)),
            (
              discriminatorValue: null,
              model: ClassModel(
                isDeprecated: false,
                name: 'DataB',
                properties: [
                  Property(
                    name: 'b',
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
          context: context,
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'Outer',
          models: {
            (discriminatorValue: 'a', model: innerOneOfA),
            (discriminatorValue: 'b', model: innerOneOfB),
          },
          discriminator: 'type',
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == r'Outer');

        const expectedMethod = '''
        String toForm({ required bool explode, required bool allowEmpty, bool useQueryComponent = false, }) {
          return switch (this) {
            OuterInnerA(:final value) => value.currentEncodingShape == EncodingShape.complex
              ? {
                  ...value.parameterProperties(allowEmpty: allowEmpty),
                  r'type': r'a',
                }.toForm(
                  explode: explode,
                  allowEmpty: allowEmpty,
                  useQueryComponent: useQueryComponent,
                )
              : value.toForm( explode: explode, allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, ),
            OuterInnerB(:final value) => value.currentEncodingShape == EncodingShape.complex
              ? {
                  ...value.parameterProperties(allowEmpty: allowEmpty),
                  r'type': r'b',
                }.toForm(
                  explode: explode,
                  allowEmpty: allowEmpty,
                  useQueryComponent: useQueryComponent,
                )
              : value.toForm( explode: explode, allowEmpty: allowEmpty, useQueryComponent: useQueryComponent, ),
          };
        }
      ''';

        expect(
          collapseWhitespace(format(baseClass.accept(emitter).toString())),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('throws EncodingException for BinaryModel variant in toForm', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'WithBinary',
        models: {
          (
            discriminatorValue: 'binary',
            model: BinaryModel(context: context),
          ),
          (
            discriminatorValue: 'text',
            model: StringModel(context: context),
          ),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == r'WithBinary');
      final generated = format(baseClass.accept(emitter).toString());

      expect(
        collapseWhitespace(generated),
        contains(
          collapseWhitespace(
            'throw EncodingException(\n'
            "'Binary data cannot be form-encoded',\n"
            ')',
          ),
        ),
      );
    });
  });
}
