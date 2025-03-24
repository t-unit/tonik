import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/tonic_generate.dart';

void main() {
  group('PropertyNameNormalizer', () {
    late PropertyNameNormalizer normalizer;
    late Context context;

    setUp(() {
      normalizer = PropertyNameNormalizer();
      context = Context.initial();
    });

    Property createProperty(String name) => Property(
          name: name,
          model: StringModel(context: context),
          isRequired: false,
          isNullable: true,
          isDeprecated: false,
        );

    group('normalizeAll', () {
      test('handles empty list', () {
        expect(normalizer.normalizeAll([]), isEmpty);
      });

      test('converts snake_case to camelCase', () {
        final result = normalizer.normalizeAll([
          createProperty('user_name'),
          createProperty('first_name'),
          createProperty('postal_code_prefix'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'userName',
          'firstName',
          'postalCodePrefix',
        ]);
      });

      test('handles kebab-case', () {
        final result = normalizer.normalizeAll([
          createProperty('user-name'),
          createProperty('first-name'),
          createProperty('postal-code-prefix'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'userName',
          'firstName',
          'postalCodePrefix',
        ]);
      });

      test('handles mixed cases', () {
        final result = normalizer.normalizeAll([
          createProperty('UserName'),
          createProperty('firstName'),
          createProperty('PostalCodePrefix'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'userName',
          'firstName',
          'postalCodePrefix',
        ]);
      });

      test('removes leading underscores', () {
        final result = normalizer.normalizeAll([
          createProperty('_name'),
          createProperty('__name'),
          createProperty('___name'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'name',
          'name2',
          'name3',
        ]);
      });

      test('handles empty or underscore-only strings', () {
        final result = normalizer.normalizeAll([
          createProperty(''),
          createProperty('_'),
          createProperty('__'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'field',
          'field2',
          'field3',
        ]);
      });

      test('preserves numbers', () {
        final result = normalizer.normalizeAll([
          createProperty('user123'),
          createProperty('user_123'),
          createProperty('user_id_123'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'user123',
          'user1232',
          'userId123',
        ]);
      });

      test('handles spaces', () {
        final result = normalizer.normalizeAll([
          createProperty('user name'),
          createProperty('first name'),
          createProperty('postal code prefix'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'userName',
          'firstName',
          'postalCodePrefix',
        ]);
      });

      test('removes special characters', () {
        final result = normalizer.normalizeAll([
          createProperty('user!name'),
          createProperty('first@name'),
          createProperty(r'postal#code\$prefix'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'username',
          'firstname',
          'postalcodeprefix',
        ]);
      });

      test('handles mixed separators', () {
        final result = normalizer.normalizeAll([
          createProperty('user_name-prefix'),
          createProperty('first-name_suffix'),
          createProperty('postal-code_prefix'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'userNamePrefix',
          'firstNameSuffix',
          'postalCodePrefix',
        ]);
      });

      test('preserves acronyms in camelCase', () {
        final result = normalizer.normalizeAll([
          createProperty('user_id'),
          createProperty('user_url'),
          createProperty('api_key'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'userId',
          'userUrl',
          'apiKey',
        ]);
      });

      test('handles already camelCase input', () {
        final result = normalizer.normalizeAll([
          createProperty('userName'),
          createProperty('firstName'),
          createProperty('postalCodePrefix'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'userName',
          'firstName',
          'postalCodePrefix',
        ]);
      });

      test('makes duplicate names unique', () {
        final result = normalizer.normalizeAll([
          createProperty('user_name'),
          createProperty('userName'),
          createProperty('User_Name'),
          createProperty('USER_NAME'),
        ]);

        expect(result.map((r) => r.normalizedName).toList(), [
          'userName',
          'userName2',
          'userName3',
          'userName4',
        ]);
        expect(result.map((r) => r.property.name).toList(), [
          'user_name',
          'userName',
          'User_Name',
          'USER_NAME',
        ]);
      });

      test('preserves property attributes', () {
        final property = Property(
          name: 'user_name',
          model: StringModel(context: context),
          isRequired: true,
          isNullable: false,
          isDeprecated: true,
        );

        final result = normalizer.normalizeAll([property]);

        expect(result.length, 1);
        expect(result.first.normalizedName, 'userName');
        expect(result.first.property.name, 'user_name');
        expect(result.first.property.isRequired, isTrue);
        expect(result.first.property.isNullable, isFalse);
        expect(result.first.property.isDeprecated, isTrue);
      });
    });
  });
} 
