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

  group('toMatrix', () {
    test('generates toMatrix method with correct signature', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'PrimitiveChoice',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'PrimitiveChoice',
      );

      final toMatrixMethod = baseClass.methods.firstWhere(
        (m) => m.name == 'toMatrix',
      );

      expect(toMatrixMethod.returns?.accept(emitter).toString(), 'String');
      expect(toMatrixMethod.requiredParameters.length, 1);
      expect(toMatrixMethod.requiredParameters.first.name, 'paramName');
      expect(
        toMatrixMethod.requiredParameters.first.type
            ?.accept(emitter)
            .toString(),
        'String',
      );
      expect(toMatrixMethod.optionalParameters.length, 2);
      expect(
        toMatrixMethod.optionalParameters.map((p) => p.name),
        containsAll(['explode', 'allowEmpty']),
      );
    });

    test('generates toMatrix for primitive-only variants', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'PrimitiveChoice',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'PrimitiveChoice',
      );
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(String paramName, {required bool explode, required bool allowEmpty}) {
          return switch (this) {
            PrimitiveChoiceI(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
            PrimitiveChoiceS(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toMatrix for class variants with discriminator', () {
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

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Choice',
        models: {
          (discriminatorValue: 'a', model: classA),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Choice');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(String paramName, {required bool explode, required bool allowEmpty}) {
          return switch (this) {
            ChoiceA(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toMatrix for mixed variants with discriminator', () {
      final classM = ClassModel(
        isDeprecated: false,
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
        isDeprecated: false,
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
        String toMatrix(String paramName, {required bool explode, required bool allowEmpty}) {
          return switch (this) {
            MixedChoiceM(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
            MixedChoiceS(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toMatrix for mixed encoding shape with discriminator', () {
      final listModel = ListModel(
        content: StringModel(context: context),
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'MixedEncodingChoice',
        models: {
          (discriminatorValue: 'list', model: listModel),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'MixedEncodingChoice',
      );
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(String paramName, {required bool explode, required bool allowEmpty}) {
          return switch (this) {
            MixedEncodingChoiceList(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
            MixedEncodingChoiceS(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toMatrix for complex variants without discriminator', () {
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
        name: 'ComplexChoice',
        models: {
          (discriminatorValue: null, model: classA),
          (discriminatorValue: null, model: classB),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'ComplexChoice');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(String paramName, {required bool explode, required bool allowEmpty}) {
          return switch (this) {
            ComplexChoiceA(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
            ComplexChoiceB(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toMatrix for enum variants', () {
      final enumModel = EnumModel(
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
        name: 'StatusChoice',
        models: {
          (discriminatorValue: 'status', model: enumModel),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'StatusChoice');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(String paramName, {required bool explode, required bool allowEmpty}) {
          return switch (this) {
            StatusChoiceS(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
            StatusChoiceStatus(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toMatrix for list variant with mixed encoding', () {
      final listModel = ListModel(
        content: StringModel(context: context),
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'ListChoice',
        models: {
          (discriminatorValue: 'list', model: listModel),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'ListChoice');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(String paramName, {required bool explode, required bool allowEmpty}) {
          return switch (this) {
            ListChoiceList(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test(
      'generates toMatrix for multiple class variants with discriminator',
      () {
        final classA = ClassModel(
          isDeprecated: false,
          name: 'A',
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
        );

        final classB = ClassModel(
          isDeprecated: false,
          name: 'B',
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
        );

        final classC = ClassModel(
          isDeprecated: false,
          name: 'C',
          properties: [
            Property(
              name: 'c',
              model: BooleanModel(context: context),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
            ),
          ],
          context: context,
        );

        final model = OneOfModel(
          isDeprecated: false,
          name: 'MultiChoice',
          models: {
            (discriminatorValue: 'a', model: classA),
            (discriminatorValue: 'b', model: classB),
            (discriminatorValue: 'c', model: classC),
          },
          discriminator: 'type',
          context: context,
        );

        final classes = generator.generateClasses(model);
        final baseClass = classes.firstWhere((c) => c.name == 'MultiChoice');
        final generated = format(baseClass.accept(emitter).toString());

        const expectedMethod = '''
        String toMatrix(String paramName, {required bool explode, required bool allowEmpty}) {
          return switch (this) {
            MultiChoiceA(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
            MultiChoiceB(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
            MultiChoiceC(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
        expect(
          collapseWhitespace(generated),
          contains(collapseWhitespace(format(expectedMethod))),
        );
      },
    );

    test('generates toMatrix for nested OneOf variants', () {
      final innerOneOf = OneOfModel(
        isDeprecated: false,
        name: 'Inner',
        models: {
          (discriminatorValue: 'i', model: IntegerModel(context: context)),
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'Outer',
        models: {
          (discriminatorValue: 'inner', model: innerOneOf),
          (discriminatorValue: 'b', model: BooleanModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'Outer');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(String paramName, {required bool explode, required bool allowEmpty}) {
          return switch (this) {
            OuterB(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
            OuterInner(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toMatrix for single primitive variant', () {
      final model = OneOfModel(
        isDeprecated: false,
        name: 'SingleChoice',
        models: {
          (discriminatorValue: 's', model: StringModel(context: context)),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'SingleChoice');
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(String paramName, {required bool explode, required bool allowEmpty}) {
          return switch (this) {
            SingleChoiceS(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toMatrix for single class variant with discriminator', () {
      final classA = ClassModel(
        isDeprecated: false,
        name: 'A',
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
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'SingleClassChoice',
        models: {
          (discriminatorValue: 'a', model: classA),
        },
        discriminator: 'type',
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'SingleClassChoice',
      );
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(String paramName, {required bool explode, required bool allowEmpty}) {
          return switch (this) {
            SingleClassChoiceA(:final value) => value.toMatrix(paramName, explode: explode, allowEmpty: allowEmpty),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });
  });

  group('toMatrix with list models', () {
    test('generates toMatrix for OneOf with List<String> variant', () {
      final listModel = ListModel(
        content: StringModel(context: context),
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'StringOrList',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: listModel),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'StringOrList');
      final generated = format(baseClass.accept(emitter).toString());

      // For List<String>, should call toMatrix directly (no mapping needed)
      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return switch (this) {
            StringOrListList(:final value) => value.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            ),
            StringOrListString(:final value) => value.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            ),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix for OneOf with List<int> variant', () {
      final listModel = ListModel(
        content: IntegerModel(context: context),
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'StringOrIntList',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: listModel),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'StringOrIntList');
      final generated = format(baseClass.accept(emitter).toString());

      // For List<int>, should map each element to string then call toMatrix
      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return switch (this) {
            StringOrIntListList(:final value) => value
              .map((e) => e.uriEncode(allowEmpty: allowEmpty))
              .toList()
              .toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
                alreadyEncoded: true,
              ),
            StringOrIntListString(:final value) => value.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            ),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix for OneOf with List<DateTime> variant', () {
      final listModel = ListModel(
        content: DateTimeModel(context: context),
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'StringOrDateTimeList',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: listModel),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'StringOrDateTimeList',
      );
      final generated = format(baseClass.accept(emitter).toString());

      // For List<DateTime>, should map each element to string then
      // call toMatrix
      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return switch (this) {
            StringOrDateTimeListList(:final value) => value
                .map((e) => e.uriEncode(allowEmpty: allowEmpty))
                .toList()
                .toMatrix(
                  paramName,
                  explode: explode,
                  allowEmpty: allowEmpty,
                  alreadyEncoded: true,
                ),
            StringOrDateTimeListString(:final value) => value.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            ),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix for OneOf with List<Enum> variant', () {
      final enumModel = EnumModel(
        isDeprecated: false,
        name: 'Status',
        values: {
          const EnumEntry(value: 'active'),
          const EnumEntry(value: 'inactive'),
        },
        isNullable: false,
        context: context,
      );
      final listModel = ListModel(
        content: enumModel,
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'StringOrEnumList',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: listModel),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere((c) => c.name == 'StringOrEnumList');
      final generated = format(baseClass.accept(emitter).toString());

      // For List<Enum>, should map each element to string then call toMatrix
      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return switch (this) {
            StringOrEnumListList(:final value) => value
                .map((e) => e.uriEncode(allowEmpty: allowEmpty))
                .toList()
                .toMatrix(
                  paramName,
                  explode: explode,
                  allowEmpty: allowEmpty,
                  alreadyEncoded: true,
                ),
            StringOrEnumListString(:final value) => value.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            ),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix for OneOf with only list variants', () {
      final listStringModel = ListModel(
        content: StringModel(context: context),
        context: context,
      );
      final listIntModel = ListModel(
        content: IntegerModel(context: context),
        context: context,
      );

      final model = OneOfModel(
        isDeprecated: false,
        name: 'StringListOrIntList',
        models: {
          (discriminatorValue: null, model: listStringModel),
          (discriminatorValue: null, model: listIntModel),
        },
        context: context,
      );

      final classes = generator.generateClasses(model);
      final baseClass = classes.firstWhere(
        (c) => c.name == 'StringListOrIntList',
      );
      final generated = format(baseClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return switch (this) {
            StringListOrIntListList(:final value) => value
              .map((e) => e.uriEncode(allowEmpty: allowEmpty))
              .toList()
              .toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
                alreadyEncoded: true,
            ),
            StringListOrIntListListModel(:final value) => value.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            ),
          };
        }
      ''';
      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expectedMethod)),
      );
    });
  });
}
