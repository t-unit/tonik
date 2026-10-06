import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('NameManager generateVariantName', () {
    test('generates variant names for models with explicit names', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );

      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: Context.initial()
            .push('components')
            .push('schemas')
            .push('User'),
        examples: const [],
      );

      final variantName = nameManager.generateVariantName(
        parentClassName: 'UserOrString',
        model: classModel,
        discriminatorValue: 'user',
      );

      expect(variantName, 'UserOrStringUser');
    });

    test('generates variant names for primitive models', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );

      final stringModel = StringModel(
        context: Context.initial()
            .push('components')
            .push('schemas')
            .push('String'),
      );

      final variantName = nameManager.generateVariantName(
        parentClassName: 'MixedType',
        model: stringModel,
        discriminatorValue: 'string',
      );

      expect(variantName, 'MixedTypeString');
    });

    test('generates variant names using discriminator values', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );

      final anonymousModel = ClassModel(
        isDeprecated: false,
        properties: const [],
        context: Context.initial()
            .push('components')
            .push('schemas')
            .push('Anonymous'),
        examples: const [],
      );

      final variantName = nameManager.generateVariantName(
        parentClassName: 'MixedType',
        model: anonymousModel,
        discriminatorValue: 'custom',
      );

      expect(variantName, 'MixedTypeCustom');
    });

    test('generates variant names using generated discriminator names', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );

      final anonymousModel = ClassModel(
        isDeprecated: false,
        properties: const [],
        context: Context.initial()
            .push('components')
            .push('schemas')
            .push('Anonymous'),
        examples: const [],
      );

      final variantName = nameManager.generateVariantName(
        parentClassName: 'MixedType',
        model: anonymousModel,
        discriminatorValue: null, // No discriminator value provided
      );

      expect(variantName, 'MixedTypeClass');
    });

    test('ensures uniqueness of variant names', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );

      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: Context.initial()
            .push('components')
            .push('schemas')
            .push('User'),
        examples: const [],
      );

      // Generate the same variant name twice
      final variantName1 = nameManager.generateVariantName(
        parentClassName: 'UserOrString',
        model: classModel,
        discriminatorValue: 'user',
      );

      final variantName2 = nameManager.generateVariantName(
        parentClassName: 'UserOrString',
        model: classModel,
        discriminatorValue: 'user',
      );

      // Both calls should return the same name (cached)
      expect(variantName1, variantName2);
      expect(variantName1, 'UserOrStringUser');
    });

    test('generates unique names for different parent classes', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(
        generator: nameGenerator,
        stableModelSorter: StableModelSorter(),
      );

      final classModel = ClassModel(
        isDeprecated: false,
        name: 'User',
        properties: const [],
        context: Context.initial()
            .push('components')
            .push('schemas')
            .push('User'),
        examples: const [],
      );

      // Generate variant names for different parent classes
      final variantName1 = nameManager.generateVariantName(
        parentClassName: 'UserOrString',
        model: classModel,
        discriminatorValue: 'user',
      );

      final variantName2 = nameManager.generateVariantName(
        parentClassName: 'UserOrInt',
        model: classModel,
        discriminatorValue: 'user',
      );

      // Different parent classes should generate different names
      expect(variantName1, 'UserOrStringUser');
      expect(variantName2, 'UserOrIntUser');
      expect(variantName1, isNot(variantName2));
    });

    test('keeps distinct models with colliding hash codes separate', () {
      final nameManager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final firstModel = _HashCollidingClassModel(name: 'User');
      final secondModel = _HashCollidingClassModel(name: 'User');

      final firstName = nameManager.generateVariantName(
        parentClassName: 'Result',
        model: firstModel,
        discriminatorValue: null,
      );
      final secondName = nameManager.generateVariantName(
        parentClassName: 'Result',
        model: secondModel,
        discriminatorValue: null,
      );

      expect(firstName, 'ResultUser');
      expect(secondName, 'ResultUserModel');
      expect(
        nameManager.generateVariantName(
          parentClassName: 'Result',
          model: firstModel,
          discriminatorValue: null,
        ),
        'ResultUser',
      );
      expect(
        nameManager.generateVariantName(
          parentClassName: 'Result',
          model: secondModel,
          discriminatorValue: null,
        ),
        'ResultUserModel',
      );
    });

    test('distinguishes absent and literal null discriminators', () {
      final nameManager = NameManager(
        generator: NameGenerator(),
        stableModelSorter: StableModelSorter(),
      );
      final model = StringModel(context: Context.initial());

      final withoutDiscriminator = nameManager.generateVariantName(
        parentClassName: 'Result',
        model: model,
        discriminatorValue: null,
      );
      final withLiteralNull = nameManager.generateVariantName(
        parentClassName: 'Result',
        model: model,
        discriminatorValue: 'null',
      );

      expect(withoutDiscriminator, 'ResultString');
      expect(withLiteralNull, 'ResultNull');
    });
  });
}

class _HashCollidingClassModel({required super.name}) extends ClassModel {
  this
    : super(
        isDeprecated: false,
        properties: const [],
        context: Context.initial(),
        examples: const [],
      );

  @override
  // Force collisions for the cache regression without changing model state.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => 1;

  @override
  // Preserve model identity equality while forcing hash collisions.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) => identical(this, other);
}
