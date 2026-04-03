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
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = AnyOfGenerator(
      nameManager: nameManager,
      package: 'package:example',
      stableModelSorter: StableModelSorter(),
    );
    context = Context.initial();
    emitter = DartEmitter(useNullSafetySyntax: true);
  });

  group('AnyOfGenerator toLabel generation', () {
    test('generates toLabel for primitive-only AnyOf', () {
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

      const expectedMethod = r'''
        String toLabel({required bool explode, required bool allowEmpty}) {
          final _$values = <String>{};
          if (bool != null) {
            final _$boolLabel = bool!.toLabel(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$boolLabel);
          }
          if (int != null) {
            final _$intLabel = int!.toLabel(explode: explode, allowEmpty: allowEmpty);
            _$values.add(_$intLabel);
          }
          if (string != null) {
            final _$stringLabel = string!.toLabel(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$stringLabel);
          }
          if (_$values.isEmpty) return '';
          if (_$values.length > 1) {
            throw EncodingException(
              r'Ambiguous anyOf label encoding for AnyOfPrimitive: multiple values provided, anyOf requires exactly one value',
            );
          }
          return _$values.first;
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

      const expectedMethod = r'''
        String toLabel({required bool explode, required bool allowEmpty}) {
          final _$mapValues = <Map<String, String>>[];
          String? _$discriminatorValue;
          if (class1 != null) {
            final _$class1Label = class1!.parameterProperties(allowEmpty: allowEmpty);
            _$mapValues.add(_$class1Label);
            _$discriminatorValue ??= r'class1';
          }
          if (class2 != null) {
            final _$class2Label = class2!.parameterProperties(allowEmpty: allowEmpty);
            _$mapValues.add(_$class2Label);
            _$discriminatorValue ??= r'class2';
          }
          final _$map = <String, String>{};
          for (final _$m in _$mapValues) {
            _$map.addAll(_$m);
          }
          final _$discValue = _$discriminatorValue;
          if (_$discValue != null) {
            _$map.putIfAbsent(r'type', () => _$discValue);
          }
          return _$map.toLabel(
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
        name: 'AnyOfMixed',
        models: {
          (discriminatorValue: 'string', model: StringModel(context: context)),
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

      const expectedMethod = r'''
        String toLabel({required bool explode, required bool allowEmpty}) {
          final _$values = <String>{};
          final _$mapValues = <Map<String, String>>[];
          String? _$discriminatorValue;
          if (data != null) {
            final _$dataLabel = data!.parameterProperties(allowEmpty: allowEmpty);
            _$mapValues.add(_$dataLabel);
            _$discriminatorValue ??= r'data';
          }
          if (string != null) {
            final _$stringLabel = string!.toLabel(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$stringLabel);
          }
          if (_$values.isEmpty && _$mapValues.isEmpty) return '';
          if (_$mapValues.isNotEmpty && _$values.isNotEmpty) {
            throw EncodingException(
              r'Ambiguous anyOf label encoding for AnyOfMixed: mixing simple and complex values',
            );
          }
          if (_$values.isNotEmpty) {
            if (_$values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf label encoding for AnyOfMixed: multiple values provided, anyOf requires exactly one value',
              );
            }
            return _$values.first;
          } else {
            final _$map = <String, String>{};
            for (final _$m in _$mapValues) {
              _$map.addAll(_$m);
            }
            final _$discValue = _$discriminatorValue;
            if (_$discValue != null) {
              _$map.putIfAbsent(r'type', () => _$discValue);
            }
            return _$map.toLabel(
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
        name: 'AnyOfEmpty',
        models: const {},
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

      const expected = r'''
        String toLabel({required bool explode, required bool allowEmpty}) {
          final _$values = <String>{};
          final _$mapValues = <Map<String, String>>[];
          if (innerChoice != null) {
            switch (innerChoice!.currentEncodingShape) {
              case EncodingShape.simple:
                _$values.add(
                  innerChoice!.toLabel(explode: explode, allowEmpty: allowEmpty),
                );
                break;
              case EncodingShape.complex:
                final _$innerChoiceLabel = innerChoice!.parameterProperties(
                  allowEmpty: allowEmpty,
                );
                _$mapValues.add(_$innerChoiceLabel);
                break;
              case EncodingShape.mixed:
                throw EncodingException(
                  'Cannot encode field with mixed encoding shape',
                );
            }
          }
          if (string != null) {
            final _$stringLabel = string!.toLabel(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$stringLabel);
          }
          if (_$values.isEmpty && _$mapValues.isEmpty) return '';
          if (_$mapValues.isNotEmpty && _$values.isNotEmpty) {
            throw EncodingException(
              r'Ambiguous anyOf label encoding for TestAnyOf: mixing simple and complex values',
            );
          }
          if (_$values.isNotEmpty) {
            if (_$values.length > 1) {
              throw EncodingException(
                r'Ambiguous anyOf label encoding for TestAnyOf: multiple values provided, anyOf requires exactly one value',
              );
            }
            return _$values.first;
          } else {
            final _$map = <String, String>{};
            for (final _$m in _$mapValues) {
              _$map.addAll(_$m);
            }
            return _$map.toLabel(
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

  group('BinaryModel field encoding', () {
    test('throws EncodingException for BinaryModel field in toLabel', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'WithBinary',
        models: {
          (discriminatorValue: null, model: BinaryModel(context: context)),
          (discriminatorValue: null, model: StringModel(context: context)),
        },
        context: context,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      expect(
        generated,
        contains(
          "throw EncodingException('Binary data cannot be label-encoded')",
        ),
      );
    });
  });
}
