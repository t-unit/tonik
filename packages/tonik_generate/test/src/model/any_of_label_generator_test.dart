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

  group('AnyOfGenerator labelProperties generation', () {
    test('generates labelProperties for primitive-only AnyOf', () {
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
      final labelPropsMethod = generatedClass.methods.firstWhere(
        (m) => m.name == 'labelProperties',
      );

      expect(
        labelPropsMethod.returns?.accept(emitter).toString(),
        'Map<String,String>',
      );
      expect(labelPropsMethod.optionalParameters.length, 1);
      expect(
        labelPropsMethod.optionalParameters.map((p) => p.name),
        containsAll(['allowEmpty']),
      );

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        Map<String, String> labelProperties({required bool allowEmpty}) {
          return <String, String>{};
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates labelProperties for complex-only AnyOf', () {
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
        Map<String, String> labelProperties({required bool allowEmpty}) {
          final mapValues = <Map<String, String>>[];
          String? discriminatorValue;
          if (class1 != null) {
            final class1Label = class1!.labelProperties(allowEmpty: allowEmpty);
            mapValues.add(class1Label);
            discriminatorValue ??= r'class1';
          }
          if (class2 != null) {
            final class2Label = class2!.labelProperties(allowEmpty: allowEmpty);
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
          return map;
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates labelProperties with runtime shape checks', () {
      final anyOfModel = AnyOfModel(
        name: 'NestedAnyOf',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (
            discriminatorValue: 'complex',
            model: ClassModel(
              name: 'ComplexData',
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
            ),
          ),
        },
        discriminator: 'type',
        context: context,
      );

      final model = AnyOfModel(
        name: 'AnyOfWithNested',
        models: {
          (discriminatorValue: 'nested', model: anyOfModel),
        },
        discriminator: 'kind',
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        Map<String, String> labelProperties({required bool allowEmpty}) {
          final mapValues = <Map<String, String>>[];
          String? discriminatorValue;
          if (nestedAnyOf != null) {
            switch (nestedAnyOf!.currentEncodingShape) {
              case EncodingShape.simple:
                break;
              case EncodingShape.complex:
                final nestedAnyOfLabel = nestedAnyOf!.labelProperties(
                  allowEmpty: allowEmpty,
                );
                mapValues.add(nestedAnyOfLabel);
                discriminatorValue ??= r'nested';
                break;
              case EncodingShape.mixed:
                throw EncodingException(
                  'Cannot encode field with mixed encoding shape',
                );
            }
          }
          final map = <String, String>{};
          for (final m in mapValues) {
            map.addAll(m);
          }
          if (discriminatorValue != null) {
            map.putIfAbsent('kind', () => discriminatorValue);
          }
          return map;
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });
  });

  group('AnyOfGenerator toLabel generation', () {
    test('generates toLabel for primitive-only AnyOf', () {
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
      final toLabelMethod = generatedClass.methods.firstWhere(
        (m) => m.name == 'toLabel',
      );

      expect(toLabelMethod.returns?.accept(emitter).toString(), 'String');
      expect(toLabelMethod.optionalParameters.length, 2);
      expect(
        toLabelMethod.optionalParameters.map((p) => p.name),
        containsAll(['explode', 'allowEmpty']),
      );

      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return labelProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toLabel for complex-only AnyOf', () {
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
        String toLabel({required bool explode, required bool allowEmpty}) {
          return labelProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toLabel that detects mixed encoding ambiguity', () {
      final model = AnyOfModel(
        name: 'AnyOfMixed',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (
            discriminatorValue: 'class',
            model: ClassModel(
              name: 'Class',
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
        String toLabel({required bool explode, required bool allowEmpty}) {
          return labelProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toLabel for empty AnyOf', () {
      final model = AnyOfModel(
        name: 'AnyOfEmpty',
        models: const {},
        discriminator: null,
        context: context,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());
      const expectedMethod = '''
        String toLabel({required bool explode, required bool allowEmpty}) {
          return labelProperties(
            allowEmpty: allowEmpty,
          ).toLabel(explode: explode, allowEmpty: allowEmpty);
        }
      ''';
      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });
  });
}
