import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

void main() {
  group('NameManager generateVariantName', () {
    test('generates variant names for models with explicit names', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(generator: nameGenerator);

      final classModel = ClassModel(
        name: 'User',
        properties: const [],
        context: Context.initial()
            .push('components')
            .push('schemas')
            .push('User'),
      );

      final variantName = nameManager.generateVariantName(
        parentClassName: 'UserOrString',
        model: classModel,
        discriminatorValue: 'user',
      );

      expect(variantName, equals('UserOrStringUser'));
    });

    test('generates variant names for primitive models', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(generator: nameGenerator);

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

      expect(variantName, equals('MixedTypeString'));
    });

    test('generates variant names using discriminator values', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(generator: nameGenerator);

      final anonymousModel = ClassModel(
        properties: const [],
        context: Context.initial()
            .push('components')
            .push('schemas')
            .push('Anonymous'),
      );

      final variantName = nameManager.generateVariantName(
        parentClassName: 'MixedType',
        model: anonymousModel,
        discriminatorValue: 'custom',
      );

      expect(variantName, equals('MixedTypeCustom'));
    });

    test('generates variant names using generated discriminator names', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(generator: nameGenerator);

      final anonymousModel = ClassModel(
        properties: const [],
        context: Context.initial()
            .push('components')
            .push('schemas')
            .push('Anonymous'),
      );

      final variantName = nameManager.generateVariantName(
        parentClassName: 'MixedType',
        model: anonymousModel,
        discriminatorValue: null, // No discriminator value provided
      );

      expect(variantName, equals('MixedTypeClass'));
    });

    test('ensures uniqueness of variant names', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(generator: nameGenerator);

      final classModel = ClassModel(
        name: 'User',
        properties: const [],
        context: Context.initial()
            .push('components')
            .push('schemas')
            .push('User'),
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
      expect(variantName1, equals(variantName2));
      expect(variantName1, equals('UserOrStringUser'));
    });

    test('generates unique names for different parent classes', () {
      final nameGenerator = NameGenerator();
      final nameManager = NameManager(generator: nameGenerator);

      final classModel = ClassModel(
        name: 'User',
        properties: const [],
        context: Context.initial()
            .push('components')
            .push('schemas')
            .push('User'),
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
      expect(variantName1, equals('UserOrStringUser'));
      expect(variantName2, equals('UserOrIntUser'));
      expect(variantName1, isNot(equals(variantName2)));
    });
  });
}
