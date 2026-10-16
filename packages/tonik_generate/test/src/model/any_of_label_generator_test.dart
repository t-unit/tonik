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
      package: 'example',
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
        models: [
          (discriminatorValue: 'string', model: StringModel(context: context)),
          (discriminatorValue: 'int', model: IntegerModel(context: context)),
          (discriminatorValue: 'bool', model: BooleanModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
        String toLabel({required bool explode, required bool allowEmpty}) {
          final _$values = <String>{};
          if (this.bool != null) {
            final _$boolLabel = this.bool!.toLabel(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$boolLabel);
          }
          if (this.int != null) {
            final _$intLabel = this.int!.toLabel(explode: explode, allowEmpty: allowEmpty);
            _$values.add(_$intLabel);
          }
          if (this.string != null) {
            final _$stringLabel = this.string!.toLabel(
              explode: explode,
              allowEmpty: allowEmpty,
            );
            _$values.add(_$stringLabel);
          }
          if (_$values.isEmpty) return '';
          return _$values.first;
        }
      ''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
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
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
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
            examples: const [],
            defaultValue: null,
            isReadOnly: false,
            isWriteOnly: false,
            nameOverride: null,
            description: null,
          ),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        additionalPropertiesPolicy: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfComplex',
        models: [
          (discriminatorValue: 'class1', model: class1),
          (discriminatorValue: 'class2', model: class2),
        ],
        discriminator: 'type',
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(generatedClass.accept(emitter).toString());

      const expectedMethod = r'''
String toLabel({required bool explode, required bool allowEmpty}) { final _$mapValues = <Map<String, PropertyValue>>[]; String? _$discriminatorValue; if (this.class1 != null) { final _$class1Label = this.class1!.parameterProperties(allowEmpty: allowEmpty); _$mapValues.add(_$class1Label); _$discriminatorValue ??= r'class1'; } if (this.class2 != null) { final _$class2Label = this.class2!.parameterProperties(allowEmpty: allowEmpty); _$mapValues.add(_$class2Label); _$discriminatorValue ??= r'class2'; } final _$map = <String, PropertyValue>{}; for (final _$m in _$mapValues) { _$map.addAll(_$m); } final _$discValue = _$discriminatorValue; if (_$discValue != null) { _$map.putIfAbsent(r'type', () => PropertyValue.scalar(_$discValue)); } return _$map.toLabel(explode: explode, allowEmpty: allowEmpty); }
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toLabel that detects mixed encoding ambiguity', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfMixed',
        models: [
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
                  examples: const [],
                  defaultValue: null,
                  isReadOnly: false,
                  isWriteOnly: false,
                  nameOverride: null,
                  description: null,
                ),
              ],
              context: context,
              examples: const [],
              nameOverride: null,
              description: null,
              additionalPropertiesPolicy: null,
              isNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
          ),
        ],
        discriminator: 'type',
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final generatedClass = generator.generateClass(model);
      final classCode = format(
        generatedClass.methods
            .firstWhere((m) => m.name == 'toLabel')
            .accept(emitter)
            .toString(),
      );

      const expectedMethod = r'''
String toLabel({required bool explode, required bool allowEmpty}) { final _$values = <String>{}; final _$mapValues = <Map<String, PropertyValue>>[]; String? _$discriminatorValue; if (this.data != null) { final _$dataLabel = this.data!.parameterProperties(allowEmpty: allowEmpty); _$mapValues.add(_$dataLabel); _$discriminatorValue ??= r'data'; } if (this.string != null) { final _$stringLabel = this.string!.toLabel( explode: explode, allowEmpty: allowEmpty, ); _$values.add(_$stringLabel); } if (_$values.isEmpty && _$mapValues.isEmpty) return ''; if (_$mapValues.isNotEmpty && _$values.isNotEmpty) { throw EncodingException( r'Ambiguous anyOf label encoding for AnyOfMixed: mixing simple and complex values', ); } if (_$values.isNotEmpty) { return _$values.first; } else { final _$map = <String, PropertyValue>{}; for (final _$m in _$mapValues) { _$map.addAll(_$m); } final _$discValue = _$discriminatorValue; if (_$discValue != null) { _$map.putIfAbsent(r'type', () => PropertyValue.scalar(_$discValue)); } return _$map.toLabel(explode: explode, allowEmpty: allowEmpty); } }
''';

      expect(
        collapseWhitespace(classCode),
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('generates toLabel for empty AnyOf', () {
      final model = AnyOfModel(
        isDeprecated: false,
        name: 'AnyOfEmpty',
        models: const [],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
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
        contains(collapseWhitespace(format(expectedMethod))),
      );
    });

    test('toLabel uses runtime check for nested oneOf', () {
      final innerOneOf = OneOfModel(
        isDeprecated: false,
        name: 'InnerChoice',
        models: [
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
                  examples: const [],
                  defaultValue: null,
                  isReadOnly: false,
                  isWriteOnly: false,
                  nameOverride: null,
                  description: null,
                ),
              ],
              context: context,
              examples: const [],
              nameOverride: null,
              description: null,
              additionalPropertiesPolicy: null,
              isNullable: false,
              isReadOnly: false,
              isWriteOnly: false,
            ),
          ),
        ],
        discriminator: 'type',
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final model = AnyOfModel(
        isDeprecated: false,
        name: 'TestAnyOf',
        models: [
          (discriminatorValue: null, model: StringModel(context: context)),
          (discriminatorValue: null, model: innerOneOf),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
      );

      final klass = generator.generateClass(model);
      final generated = format(klass.accept(emitter).toString());

      const expected = r'''
String toLabel({required bool explode, required bool allowEmpty}) { final _$values = <String>{}; final _$mapValues = <Map<String, PropertyValue>>[]; if (this.innerChoice != null) { switch (this.innerChoice!.currentEncodingShape) { case EncodingShape.simple: _$values.add( this.innerChoice!.toLabel(explode: explode, allowEmpty: allowEmpty), ); break; case EncodingShape.complex: final _$innerChoiceLabel = this.innerChoice!.parameterProperties( allowEmpty: allowEmpty, ); _$mapValues.add(_$innerChoiceLabel); break; case EncodingShape.mixed: throw EncodingException( 'Cannot encode field with mixed encoding shape', ); } } if (this.string != null) { final _$stringLabel = this.string!.toLabel( explode: explode, allowEmpty: allowEmpty, ); _$values.add(_$stringLabel); } if (_$values.isEmpty && _$mapValues.isEmpty) return ''; if (_$mapValues.isNotEmpty && _$values.isNotEmpty) { throw EncodingException( r'Ambiguous anyOf label encoding for TestAnyOf: mixing simple and complex values', ); } if (_$values.isNotEmpty) { return _$values.first; } else { final _$map = <String, PropertyValue>{}; for (final _$m in _$mapValues) { _$map.addAll(_$m); } return _$map.toLabel(explode: explode, allowEmpty: allowEmpty); } }
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
        models: [
          (discriminatorValue: null, model: BinaryModel(context: context)),
          (discriminatorValue: null, model: StringModel(context: context)),
        ],
        context: context,
        examples: const [],
        nameOverride: null,
        description: null,
        discriminator: null,
        isNullable: false,
        isReadOnly: false,
        isWriteOnly: false,
        defaultValue: null,
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
