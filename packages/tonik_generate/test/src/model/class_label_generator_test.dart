import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  late ClassGenerator generator;
  late NameManager nameManager;
  late NameGenerator nameGenerator;
  late Context context;

  setUp(() {
    nameGenerator = NameGenerator();
    nameManager = NameManager(
      generator: nameGenerator,
      stableModelSorter: StableModelSorter(),
    );
    generator = ClassGenerator(nameManager: nameManager, package: 'example');
    context = Context.initial();
  });

  group('ClassGenerator toLabel generation', () {
    test('inherits toLabel for class with only simple properties', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'SimpleClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'age',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedClass = generator.generateClass(model);
      expect(generatedClass.extend?.symbol, 'ObjectParameterEncodable');
    });

    test(
      'inherits toLabel that throws for class with nested class property',
      () {
        final model = ClassModel(
          isDeprecated: false,
          name: 'NestedClass',
          properties: [
            Property(
              name: 'nested',
              model: ClassModel(
                isDeprecated: false,
                context: context,
                name: 'Nested',
                properties: [
                  Property(
                    name: 'value',
                    model: StringModel(context: context),
                    isRequired: true,
                    isNullable: false,
                    isDeprecated: false,
                    examples: const [],
                    defaultValue: null,
                  ),
                ],
                examples: const [],
              ),
              isRequired: true,
              isNullable: false,
              isDeprecated: false,
              examples: const [],
              defaultValue: null,
            ),
          ],
          context: context,
          examples: const [],
        );

        final generatedClass = generator.generateClass(model);
        expect(generatedClass.extend?.symbol, 'ObjectParameterEncodable');
      },
    );
  });

  group('ClassGenerator toLabel method for label encoding', () {
    test('inherits toLabel for class with only simple properties', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'SimpleClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'age',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedClass = generator.generateClass(model);
      expect(generatedClass.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('inherits toLabel for class with composite properties requiring '
        'runtime checks', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'CompositeClass',
        properties: [
          Property(
            name: 'name',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'value',
            model: OneOfModel(
              isDeprecated: false,
              context: context,
              name: 'Value',
              discriminator: 'type',
              models: [
                (
                  discriminatorValue: 'string',
                  model: StringModel(context: context),
                ),
                (
                  discriminatorValue: 'integer',
                  model: IntegerModel(context: context),
                ),
              ],
              examples: const [],
            ),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedClass = generator.generateClass(model);
      expect(generatedClass.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('inherits toLabel for class with mixed properties including '
        'nullable composites', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'MixedClass',
        properties: [
          Property(
            name: 'id',
            model: IntegerModel(context: context),
            isRequired: true,
            isNullable: false,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
          Property(
            name: 'optionalValue',
            model: AnyOfModel(
              isDeprecated: false,
              context: context,
              name: 'OptionalValue',
              discriminator: 'type',
              models: [
                (
                  discriminatorValue: 'date',
                  model: DateTimeModel(context: context),
                ),
                (
                  discriminatorValue: 'decimal',
                  model: DecimalModel(context: context),
                ),
              ],
              examples: const [],
            ),
            isRequired: false,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final generatedClass = generator.generateClass(model);
      expect(generatedClass.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('inherits toLabel for empty class', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'EmptyClass',
        properties: const [],
        context: context,
        examples: const [],
      );

      final generatedClass = generator.generateClass(model);
      expect(generatedClass.extend?.symbol, 'ObjectParameterEncodable');
    });
  });
}
