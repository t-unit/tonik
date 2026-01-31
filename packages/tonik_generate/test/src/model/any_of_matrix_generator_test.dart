import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late AnyOfGenerator generator;
  late NameManager nameManager;
  late NameGenerator nameGenerator;
  late Context context;
  late DartEmitter emitter;
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(generator: nameGenerator);
    generator = AnyOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('AnyOfGenerator toMatrix generation', () {
    test('generates toMatrix method with correct signature', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfPrimitive',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final toMatrixMethod = generatedClass.methods.firstWhere(
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

    test('generates toMatrix for primitive-only AnyOf', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfPrimitive',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
          (discriminatorValue: 'bool', model: BooleanModel(context: context)),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final values = <String>{};
          if (bool != null) {
            final boolMatrix = bool!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(boolMatrix);
          }
          if (int != null) {
            final intMatrix = int!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(intMatrix);
          }
          if (string != null) {
            final stringMatrix = string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringMatrix);
          }
          if (values.isEmpty) return '';
          if (values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf matrix encoding for AnyOfPrimitive: multiple values provided, anyOf requires exactly one value',
            );
          }
          return values.first;
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix for complex-only AnyOf', () {
      final class1 = ClassModel(
        isDeprecated: false,
        name: 'Class1',
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

      final class2 = ClassModel(
        isDeprecated: false,
        name: 'Class2',
        properties: [
          Property(
            name: 'number',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
          ),
        ],
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfComplex',
        models: {
          (discriminatorValue: 'class1', model: class1),
          (discriminatorValue: 'class2', model: class2),
        },
        discriminator: 'type',
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final mapValues = <Map<String, String>>[];
          String? discriminatorValue;
          if (class1 != null) {
            final class1Matrix = class1!.parameterProperties(allowEmpty: allowEmpty);
            mapValues.add(class1Matrix);
            discriminatorValue ??= r'class1';
          }
          if (class2 != null) {
            final class2Matrix = class2!.parameterProperties(allowEmpty: allowEmpty);
            mapValues.add(class2Matrix);
            discriminatorValue ??= r'class2';
          }
          final map = <String, String>{};
          for (final m in mapValues) {
            map.addAll(m);
          }
          final discValue = discriminatorValue;
          if (discValue != null) {
            map.putIfAbsent('type', () => discValue);
          }
          return map.toMatrix(
            paramName,
            explode: explode,
            allowEmpty: allowEmpty,
            alreadyEncoded: true,
          );
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test(
      'generates toMatrix for mixed AnyOf that throws on ambiguous encoding',
      () {
        final model = AnyOfModel(
          isDeprecated: false,
          name: 'AnyOfMixed',
          models: {
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
            (
              discriminatorValue: 'data',
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
          discriminator: 'type',
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final values = <String>{};
          final mapValues = <Map<String, String>>[];
          String? discriminatorValue;
          if (data != null) {
            final dataMatrix = data!.parameterProperties(allowEmpty: allowEmpty);
            mapValues.add(dataMatrix);
            discriminatorValue ??= r'data';
          }
          if (string != null) {
            final stringMatrix = string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringMatrix);
          }
          if (values.isEmpty && mapValues.isEmpty) return '';
          if (mapValues.isNotEmpty && values.isNotEmpty) {
            throw EncodingException(
              r'Ambiguous anyOf matrix encoding for AnyOfMixed: mixing simple and complex values',
            );
          }
          if (values.isNotEmpty) {
            if (values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf matrix encoding for AnyOfMixed: multiple values provided, anyOf requires exactly one value',
              );
            }
            return values.first;
          } else {
            final map = <String, String>{};
            for (final m in mapValues) {
              map.addAll(m);
            }
            final discValue = discriminatorValue;
            if (discValue != null) {
              map.putIfAbsent('type', () => discValue);
            }
            return map.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
              alreadyEncoded: true,
            );
          }
        }
      ''';

        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      },
    );

    test('generates toMatrix for AnyOf with enum variants', () {
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

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfEnum',
        models: {
          (discriminatorValue: 'status', model: enumModel),
          (discriminatorValue: 'string', model: StringModel(context: context)),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final values = <String>{};
          if (status != null) {
            final statusMatrix = status!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(statusMatrix);
          }
          if (string != null) {
            final stringMatrix = string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringMatrix);
          }
          if (values.isEmpty) return '';
          if (values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf matrix encoding for AnyOfEnum: multiple values provided, anyOf requires exactly one value',
            );
          }
          return values.first;
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix for empty AnyOf', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfEmpty',
        models: const {},
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          return '';
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('generates toMatrix for AnyOf with nested composition types', () {
      final oneOfModel = OneOfModel(
        isDeprecated: false,
        name: 'OneOfType',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        context: context,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfNested',
        models: {
          (discriminatorValue: 'oneof', model: oneOfModel),
          (discriminatorValue: 'bool', model: BooleanModel(context: context)),
        },
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final values = <String>{};
          if (bool != null) {
            final boolMatrix = bool!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(boolMatrix);
          }
          if (oneOfType != null) {
            final oneOfTypeMatrix = oneOfType!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(oneOfTypeMatrix);
          }
          if (values.isEmpty) return '';
          if (values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf matrix encoding for AnyOfNested: multiple values provided, anyOf requires exactly one value',
            );
          }
          return values.first;
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toMatrix uses runtime check for nested oneOf', () {
      final innerOneOf = OneOfModel(
        isDeprecated: false,
        name: 'InnerChoice',
        models: {
          (discriminatorValue: 'str', model: StringModel(context: context)),
          (
            discriminatorValue: 'obj',
            model: ClassModel(
              isDeprecated: false,
              name: 'Inner',
              properties: [
                Property(
                  name: 'field',
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

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'TestAnyOf',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: innerOneOf),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expected = '''
        String toMatrix(
          String paramName, {
          required bool explode,
          required bool allowEmpty,
        }) {
          final values = <String>{};
          final mapValues = <Map<String, String>>[];
          if (innerChoice != null) {
            switch (innerChoice!.currentEncodingShape) {
              case EncodingShape.simple:
                values.add(
                  innerChoice!.toMatrix(
                    paramName,
                    explode: explode,
                    allowEmpty: allowEmpty,
                  ),
                );
                break;
              case EncodingShape.complex:
                final innerChoiceMatrix = innerChoice!.parameterProperties(
                  allowEmpty: allowEmpty,
                );
                mapValues.add(innerChoiceMatrix);
                break;
              case EncodingShape.mixed:
                throw EncodingException(
                  'Cannot encode field with mixed encoding shape',
                );
            }
          }
          if (string != null) {
            final stringMatrix = string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringMatrix);
          }
          if (values.isEmpty && mapValues.isEmpty) return '';
          if (mapValues.isNotEmpty && values.isNotEmpty) {
            throw EncodingException(
              r'Ambiguous anyOf matrix encoding for TestAnyOf: mixing simple and complex values',
            );
          }
          if (values.isNotEmpty) {
            if (values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf matrix encoding for TestAnyOf: multiple values provided, anyOf requires exactly one value',
              );
            }
            return values.first;
          } else {
            final map = <String, String>{};
            for (final m in mapValues) {
              map.addAll(m);
            }
            return map.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
              alreadyEncoded: true,
            );
          }
        }
      ''';

      expect(
        collapseWhitespace(generated),
        contains(collapseWhitespace(expected)),
      );
    });

    group('toMatrix with list models', () {
      test('generates toMatrix for AnyOf with List<String> variant', () {
        final listModel = ListModel(
          content: StringModel(context: context),
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'StringOrList',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: listModel),
          },
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = '''
          String toMatrix(
            String paramName, {
            required bool explode,
            required bool allowEmpty,
          }) {
            final values = <String>{};
            if (list != null) {
              final listMatrix = list!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              values.add(listMatrix);
            }
            if (string != null) {
              final stringMatrix = string!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              values.add(stringMatrix);
            }
            if (values.isEmpty) return '';
            if (values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf matrix encoding for StringOrList: multiple values provided, anyOf requires exactly one value',
              );
            }
            return values.first;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates toMatrix for AnyOf with List<int> variant', () {
        final listModel = ListModel(
          content: IntegerModel(context: context),
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'StringOrIntList',
          models: {
            (discriminatorValue: null, model: StringModel(context: context)),
            (discriminatorValue: null, model: listModel),
          },
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = '''
          String toMatrix(
            String paramName, {
            required bool explode,
            required bool allowEmpty,
          }) {
            final values = <String>{};
            if (list != null) {
              final listMatrix = list!
                  .map((e) => e.uriEncode(allowEmpty: allowEmpty))
                  .toList()
                  .toMatrix(
                    paramName,
                    explode: explode,
                    allowEmpty: allowEmpty,
                    alreadyEncoded: true,
                  );
              values.add(listMatrix);
            }
            if (string != null) {
              final stringMatrix = string!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              values.add(stringMatrix);
            }
            if (values.isEmpty) return '';
            if (values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf matrix encoding for StringOrIntList: multiple values provided, anyOf requires exactly one value',
              );
            }
            return values.first;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });

      test('generates toMatrix for AnyOf with only list variants', () {
        final listStringModel = ListModel(
          content: StringModel(context: context),
          context: context,
        );
        final listIntModel = ListModel(
          content: IntegerModel(context: context),
          context: context,
        );

        final model = AnyOfModel(
          isDeprecated: false,
          name: 'StringListOrIntList',
          models: {
            (discriminatorValue: null, model: listStringModel),
            (discriminatorValue: null, model: listIntModel),
          },
          context: context,
        );

        final generatedClass = generator.generateClass(model);
        final classCode = format(generatedClass.accept(emitter).toString());

        const expectedMethod = '''
          String toMatrix(
            String paramName, {
            required bool explode,
            required bool allowEmpty,
          }) {
            final values = <String>{};
            if (list != null) {
              final listMatrix = list!
                  .map((e) => e.uriEncode(allowEmpty: allowEmpty))
                  .toList()
                  .toMatrix(
                    paramName,
                    explode: explode,
                    allowEmpty: allowEmpty,
                    alreadyEncoded: true,
                  );
              values.add(listMatrix);
            }
            if (list2 != null) {
              final list2Matrix = list2!.toMatrix(
                paramName,
                explode: explode,
                allowEmpty: allowEmpty,
              );
              values.add(list2Matrix);
            }
            if (values.isEmpty) return '';
            if (values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf matrix encoding for StringListOrIntList: multiple values provided, anyOf requires exactly one value',
              );
            }
            return values.first;
          }
        ''';
        expect(
          collapseWhitespace(classCode),
          contains(collapseWhitespace(expectedMethod)),
        );
      });
    });
  });
}
