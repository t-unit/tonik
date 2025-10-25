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
  final format =
      DartFormatter(
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
        name: 'AnyOfPrimitive',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        discriminator: null,
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
        name: 'AnyOfPrimitive',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
          (discriminatorValue: 'bool', model: BooleanModel(context: context)),
        },
        discriminator: null,
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
          if (string != null) {
            final stringMatrix = string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringMatrix);
          }
          if (int != null) {
            final intMatrix = int!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(intMatrix);
          }
          if (bool != null) {
            final boolMatrix = bool!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(boolMatrix);
          }
          if (values.isEmpty) return '';
          if (values.length > 1) {
            throw EncodingException(
              'Ambiguous anyOf matrix encoding for AnyOfPrimitive: multiple values provided, anyOf requires exactly one value',
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
          if (discriminatorValue != null) {
            map.putIfAbsent('type', () => discriminatorValue);
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
          name: 'AnyOfMixed',
          models: {
            (
              discriminatorValue: 'string',
              model: StringModel(context: context),
            ),
            (
              discriminatorValue: 'data',
              model: ClassModel(
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
          if (string != null) {
            final stringMatrix = string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringMatrix);
          }
          if (data != null) {
            final dataMatrix = data!.parameterProperties(allowEmpty: allowEmpty);
            mapValues.add(dataMatrix);
            discriminatorValue ??= r'data';
          }
          if (values.isEmpty && mapValues.isEmpty) return '';
          if (mapValues.isNotEmpty && values.isNotEmpty) {
            throw EncodingException(
              'Ambiguous anyOf matrix encoding for AnyOfMixed: mixing simple and complex values',
            );
          }
          if (values.isNotEmpty) {
            if (values.length > 1) {
              throw EncodingException(
                'Ambiguous anyOf matrix encoding for AnyOfMixed: multiple values provided, anyOf requires exactly one value',
              );
            }
            return values.first;
          } else {
            final map = <String, String>{};
            for (final m in mapValues) {
              map.addAll(m);
            }
            if (discriminatorValue != null) {
              map.putIfAbsent('type', () => discriminatorValue);
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
        name: 'Status',
        values: const {'active', 'inactive'},
        isNullable: false,
        context: context,
      );

      final model = AnyOfModel(
        name: 'AnyOfEnum',
        models: {
          (discriminatorValue: 'status', model: enumModel),
          (discriminatorValue: 'string', model: StringModel(context: context)),
        },
        discriminator: null,
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
              'Ambiguous anyOf matrix encoding for AnyOfEnum: multiple values provided, anyOf requires exactly one value',
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
        name: 'AnyOfEmpty',
        models: const {},
        discriminator: null,
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
        name: 'OneOfType',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
        },
        discriminator: null,
        context: context,
      );

      final model = AnyOfModel(
        name: 'AnyOfNested',
        models: {
          (discriminatorValue: 'oneof', model: oneOfModel),
          (discriminatorValue: 'bool', model: BooleanModel(context: context)),
        },
        discriminator: null,
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
          if (oneOfType != null) {
            final oneOfTypeMatrix = oneOfType!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(oneOfTypeMatrix);
          }
          if (bool != null) {
            final boolMatrix = bool!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(boolMatrix);
          }
          if (values.isEmpty) return '';
          if (values.length > 1) {
            throw EncodingException(
              'Ambiguous anyOf matrix encoding for AnyOfNested: multiple values provided, anyOf requires exactly one value',
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
        name: 'InnerChoice',
        models: {
          (discriminatorValue: 'str', model: StringModel(context: context)),
          (
            discriminatorValue: 'obj',
            model: ClassModel(
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
        name: 'TestAnyOf',
        models: {
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: innerOneOf),
        },
        discriminator: null,
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
          if (string != null) {
            final stringMatrix = string!.toMatrix(
              paramName,
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringMatrix);
          }
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
          if (values.isEmpty && mapValues.isEmpty) return '';
          if (mapValues.isNotEmpty && values.isNotEmpty) {
            throw EncodingException(
              'Ambiguous anyOf matrix encoding for TestAnyOf: mixing simple and complex values',
            );
          }
          if (values.isNotEmpty) {
            if (values.length > 1) {
              throw EncodingException(
                'Ambiguous anyOf matrix encoding for TestAnyOf: multiple values provided, anyOf requires exactly one value',
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
  });
}
