import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/model/all_of_generator.dart';
import 'package:tonik_generate/src/model/any_of_generator.dart';
import 'package:tonik_generate/src/model/one_of_generator.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  test(
    'allOf keeps sorted order and repeated models in generated members',
    () {
      final context = Context.initial();
      final zebra = ClassModel(
        name: 'Zebra',
        context: context.push('Zebra'),
        properties: const [],
        isDeprecated: false,
        examples: const [],
      );
      final alpha = ClassModel(
        name: 'Alpha',
        context: context.push('Alpha'),
        properties: const [],
        isDeprecated: false,
        examples: const [],
      );
      final model = AllOfModel(
        name: 'Choice',
        context: context,
        models: [zebra, alpha, zebra],
        isDeprecated: false,
        examples: const [],
      );
      final generator = AllOfGenerator(
        nameManager: NameManager(
          generator: NameGenerator(),
          stableModelSorter: StableModelSorter(),
        ),
        package: 'test_package',
        stableModelSorter: StableModelSorter(),
      );
      final classes = generator
          .generateClasses(model)
          .whereType<Class>()
          .toList();
      final fields = classes.first.fields;
      expect(fields.map((field) => field.type!.symbol), [
        'Alpha',
        'Zebra',
        'Zebra',
      ]);
      expect(fields.map((field) => field.name).toSet(), hasLength(3));
    },
  );

  test(
    'oneOf keeps sorted order and repeated models in generated members',
    () {
      final context = Context.initial();
      final zebra = ClassModel(
        name: 'Zebra',
        context: context.push('Zebra'),
        properties: const [],
        isDeprecated: false,
        examples: const [],
      );
      final alpha = ClassModel(
        name: 'Alpha',
        context: context.push('Alpha'),
        properties: const [],
        isDeprecated: false,
        examples: const [],
      );
      final model = OneOfModel(
        name: 'Choice',
        context: context,
        models: [
          (model: zebra, discriminatorValue: null),
          (model: alpha, discriminatorValue: null),
          (model: zebra, discriminatorValue: null),
        ],
        isDeprecated: false,
        examples: const [],
      );
      final generator = OneOfGenerator(
        nameManager: NameManager(
          generator: NameGenerator(),
          stableModelSorter: StableModelSorter(),
        ),
        package: 'test_package',
        stableModelSorter: StableModelSorter(),
      );
      final classes = generator
          .generateClasses(model)
          .whereType<Class>()
          .toList();
      expect(classes, hasLength(4));
      expect(classes.skip(1).map((c) => c.fields.single.type!.symbol), [
        'Alpha',
        'Zebra',
        'Zebra',
      ]);
      expect(classes.map((c) => c.name).toSet(), hasLength(4));
      expect(
        generator.generateClasses(model).map((c) => c.name),
        classes.map((c) => c.name),
      );
    },
  );

  test(
    'anyOf keeps sorted order and repeated models in generated members',
    () {
      final context = Context.initial();
      final zebra = ClassModel(
        name: 'Zebra',
        context: context.push('Zebra'),
        properties: const [],
        isDeprecated: false,
        examples: const [],
      );
      final alpha = ClassModel(
        name: 'Alpha',
        context: context.push('Alpha'),
        properties: const [],
        isDeprecated: false,
        examples: const [],
      );
      final model = AnyOfModel(
        name: 'Choice',
        context: context,
        models: [
          (model: zebra, discriminatorValue: null),
          (model: alpha, discriminatorValue: null),
          (model: zebra, discriminatorValue: null),
        ],
        isDeprecated: false,
        examples: const [],
      );
      final generator = AnyOfGenerator(
        nameManager: NameManager(
          generator: NameGenerator(),
          stableModelSorter: StableModelSorter(),
        ),
        package: 'test_package',
        stableModelSorter: StableModelSorter(),
      );
      final classes = generator
          .generateClasses(model)
          .whereType<Class>()
          .toList();
      final fields = classes.first.fields;
      expect(fields.map((field) => field.type!.symbol), [
        'Alpha',
        'Zebra',
        'Zebra',
      ]);
      expect(fields.map((field) => field.name).toSet(), hasLength(3));
    },
  );
}
