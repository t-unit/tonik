import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/class_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('ClassGenerator toDeepObject generation', () {
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

    test('inherits toDeepObject method through the typed hook', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'SimpleModel',
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
            name: 'count',
            model: IntegerModel(context: context),
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

      final result = generator.generateClass(model);
      expect(result.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('inherits toDeepObject method for empty model', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'EmptyModel',
        properties: const [],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);
      expect(result.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('toDeepObject method inherits encoding for single '
        'property model', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'TestModel',
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
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);
      expect(result.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('toDeepObject method inherits encoding for multiple '
        'properties model', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'ComplexModel',
        properties: [
          Property(
            name: 'firstName',
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
          Property(
            name: 'email',
            model: StringModel(context: context),
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

      final result = generator.generateClass(model);
      expect(result.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('toDeepObject method inherits encoding through '
        'the parameterProperties encoder', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'ModelWithList',
        properties: [
          Property(
            name: 'tags',
            model: ListModel(
              content: StringModel(context: context),
              context: context,
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

      final result = generator.generateClass(model);
      expect(result.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('toDeepObject method works with nullable required properties', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'NullableModel',
        properties: [
          Property(
            name: 'optionalName',
            model: StringModel(context: context),
            isRequired: true,
            isNullable: true,
            isDeprecated: false,
            examples: const [],
            defaultValue: null,
          ),
        ],
        context: context,
        examples: const [],
      );

      final result = generator.generateClass(model);
      expect(result.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('toDeepObject method works with optional properties', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'OptionalModel',
        properties: [
          Property(
            name: 'optionalField',
            model: IntegerModel(context: context),
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

      final result = generator.generateClass(model);
      expect(result.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('toDeepObject method works with mixed simple and complex types', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'MixedModel',
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
            name: 'nested',
            model: ClassModel(
              isDeprecated: false,
              name: 'NestedClass',
              properties: [
                Property(
                  name: 'value',
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

      final result = generator.generateClass(model);
      expect(result.extend?.symbol, 'ObjectParameterEncodable');
    });

    test('toDeepObject method is inherited from ObjectParameterEncodable', () {
      final model = ClassModel(
        isDeprecated: false,
        name: 'EncodedModel',
        properties: [
          Property(
            name: 'data',
            model: StringModel(context: context),
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

      final result = generator.generateClass(model);
      expect(result.extend?.symbol, 'ObjectParameterEncodable');
    });
  });
}
