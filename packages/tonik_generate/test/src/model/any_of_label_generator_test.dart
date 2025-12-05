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

  group('AnyOfGenerator toLabel generation', () {
    test('generates toLabel for primitive-only AnyOf', () {
      final model = AnyOfModel(
        isDeprecated: false,
        description: null,
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
        String toLabel({required bool explode, required bool allowEmpty}) {
          final values = <String>{};
          if (bool != null) {
            final boolLabel = bool!.toLabel(explode: explode, allowEmpty: allowEmpty);
            values.add(boolLabel);
          }
          if (int != null) {
            final intLabel = int!.toLabel(explode: explode, allowEmpty: allowEmpty);
            values.add(intLabel);
          }
          if (string != null) {
            final stringLabel = string!.toLabel(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringLabel);
          }
          if (values.isEmpty) return '';
          if (values.length > 1) {
            throw EncodingException(
              'Ambiguous anyOf label encoding for AnyOfPrimitive: multiple values provided, anyOf requires exactly one value',
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

    test('generates toLabel for complex-only AnyOf', () {
      final class1 = ClassModel(
        isDeprecated: false,
        description: null,
        name: 'Class1',
        properties: [
          Property(
            description: null,
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
        description: null,
        name: 'Class2',
        properties: [
          Property(
            description: null,
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
        description: null,
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
        String toLabel({required bool explode, required bool allowEmpty}) {
          final mapValues = <Map<String, String>>[];
          String? discriminatorValue;
          if (class1 != null) {
            final class1Label = class1!.parameterProperties(allowEmpty: allowEmpty);
            mapValues.add(class1Label);
            discriminatorValue ??= r'class1';
          }
          if (class2 != null) {
            final class2Label = class2!.parameterProperties(allowEmpty: allowEmpty);
            mapValues.add(class2Label);
            discriminatorValue ??= r'class2';
          }
          final map = <String, String>{};
          for (final m in mapValues) {
            map.addAll(m);
          }
          if (discriminatorValue != null) {
            map.putIfAbsent('type', () => discriminatorValue);
          }
          return map.toLabel(
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

    test('generates toLabel that detects mixed encoding ambiguity', () {
      final model = AnyOfModel(
        isDeprecated: false,
        description: null,
        name: 'AnyOfMixed',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (
            discriminatorValue: 'data',
            model: ClassModel(
              isDeprecated: false,
              description: null,
              name: 'Data',
              properties: [
                Property(
                  description: null,
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
        String toLabel({required bool explode, required bool allowEmpty}) {
          final values = <String>{};
          final mapValues = <Map<String, String>>[];
          String? discriminatorValue;
          if (data != null) {
            final dataLabel = data!.parameterProperties(allowEmpty: allowEmpty);
            mapValues.add(dataLabel);
            discriminatorValue ??= r'data';
          }
          if (string != null) {
            final stringLabel = string!.toLabel(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringLabel);
          }
          if (values.isEmpty && mapValues.isEmpty) return '';
          if (mapValues.isNotEmpty && values.isNotEmpty) {
            throw EncodingException(
              'Ambiguous anyOf label encoding for AnyOfMixed: mixing simple and complex values',
            );
          }
          if (values.isNotEmpty) {
            if (values.length > 1) {
              throw EncodingException(
                'Ambiguous anyOf label encoding for AnyOfMixed: multiple values provided, anyOf requires exactly one value',
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
            return map.toLabel(
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
    });

    test('generates toLabel for empty AnyOf', () {
      final model = AnyOfModel(
        isDeprecated: false,
        description: null,
        name: 'AnyOfEmpty',
        models: const {},
        discriminator: null,
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return '';
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(expectedMethod)),
      );
    });

    test('toLabel uses runtime check for nested oneOf', () {
      final innerOneOf = OneOfModel(
        isDeprecated: false,
        description: null,
        name: 'InnerChoice',
        models: {
          (discriminatorValue: 'str', model: StringModel(context: context)),
          (
            discriminatorValue: 'obj',
            model: ClassModel(
              isDeprecated: false,
              description: null,
              name: 'Inner',
              properties: [
                Property(
                  description: null,
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
        description: null,
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
        String toLabel({required bool explode, required bool allowEmpty}) {
          final values = <String>{};
          final mapValues = <Map<String, String>>[];
          if (innerChoice != null) {
            switch (innerChoice!.currentEncodingShape) {
              case EncodingShape.simple:
                values.add(
                  innerChoice!.toLabel(explode: explode, allowEmpty: allowEmpty),
                );
                break;
              case EncodingShape.complex:
                final innerChoiceLabel = innerChoice!.parameterProperties(
                  allowEmpty: allowEmpty,
                );
                mapValues.add(innerChoiceLabel);
                break;
              case EncodingShape.mixed:
                throw EncodingException(
                  'Cannot encode field with mixed encoding shape',
                );
            }
          }
          if (string != null) {
            final stringLabel = string!.toLabel(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            values.add(stringLabel);
          }
          if (values.isEmpty && mapValues.isEmpty) return '';
          if (mapValues.isNotEmpty && values.isNotEmpty) {
            throw EncodingException(
              'Ambiguous anyOf label encoding for TestAnyOf: mixing simple and complex values',
            );
          }
          if (values.isNotEmpty) {
            if (values.length > 1) {
              throw EncodingException(
                'Ambiguous anyOf label encoding for TestAnyOf: multiple values provided, anyOf requires exactly one value',
              );
            }
            return values.first;
          } else {
            final map = <String, String>{};
            for (final m in mapValues) {
              map.addAll(m);
            }
            return map.toLabel(
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
