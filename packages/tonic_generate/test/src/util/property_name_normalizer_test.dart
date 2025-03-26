import 'package:test/test.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/property_name_normalizer.dart';

void main() {
  test('normalizeAll removes leading underscores', () {
    final result = normalizeAll([
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

  test('normalizeAll handles empty or underscore-only strings', () {
    final result = normalizeAll([
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

  test('normalizeAll preserves numbers', () {
    final result = normalizeAll([
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

  test('normalizeAll makes duplicate names unique', () {
    final result = normalizeAll([
      createProperty('user_name'),
      createProperty('userName'),
      createProperty('UserName'),
      createProperty('USER_NAME'),
    ]);

    expect(result.map((r) => r.normalizedName).toList(), [
      'userName',
      'userName2',
      'userName3',
      'userName4',
    ]);
  });

  test('normalizeAll handles Dart keywords', () {
    final result = normalizeAll([
      createProperty('class'),
      createProperty('void'),
      createProperty('switch'),
      createProperty('class_name'),
      createProperty('void_method'),
      createProperty('switch_case'),
      createProperty('Class'),
      createProperty('VOID'),
      createProperty('Switch123'),
    ]);

    expect(result.map((r) => r.normalizedName).toList(), [
      r'$class',
      r'$void',
      r'$switch',
      'className',
      'voidMethod',
      'switchCase',
      r'$class2',
      r'$void2',
      'switch123',
    ]);
  });

  group('normalizeEnumValues', () {
    test('handles string values', () {
      final result = normalizeEnumValues([
        'class',
        'void',
        'switch',
        'class_name',
        'void_method',
        'switch_case',
        'Class',
        'VOID',
        'Switch123',
      ]);

      expect(result.map((r) => r.normalizedName).toList(), [
        r'$class',
        r'$void',
        r'$switch',
        'className',
        'voidMethod',
        'switchCase',
        r'$class2',
        r'$void2',
        'switch123',
      ]);
    });

    test('handles integer values', () {
      final result = normalizeEnumValues([
        '1',
        '2',
        '3',
        '123',
        '456',
      ]);

      expect(result.map((r) => r.normalizedName).toList(), [
        'one',
        'two',
        'three',
        'oneHundredTwentyThree',
        'fourHundredFiftySix',
      ]);
    });

    test('handles mixed string and integer values', () {
      final result = normalizeEnumValues([
        '1',
        'active',
        '2',
        'inactive',
        '404',
      ]);

      expect(result.map((r) => r.normalizedName).toList(), [
        'one',
        'active',
        'two',
        'inactive',
        'fourHundredFour',
      ]);
    });

    test('handles empty or underscore-only values', () {
      final result = normalizeEnumValues([
        '',
        '_',
        '__',
        '___',
      ]);

      expect(result.map((r) => r.normalizedName).toList(), [
        'value',
        'value2',
        'value3',
        'value4',
      ]);
    });

    test('makes duplicate names unique', () {
      final result = normalizeEnumValues([
        '1',
        'one',
        'ONE',
        'One',
      ]);

      expect(result.map((r) => r.normalizedName).toList(), [
        'one',
        'one2',
        'one3',
        'one4',
      ]);
    });
  });

  test('preserves property metadata', () {
    final result = normalizeAll([
      createProperty('name', isDeprecated: true),
    ]);

    expect(result.first.property.isDeprecated, isTrue);
  });
}

Property createProperty(String name, {bool isDeprecated = false}) {
  final context = Context.initial();
  return Property(
    name: name,
    model: StringModel(context: context),
    isRequired: false,
    isNullable: true,
    isDeprecated: isDeprecated,
  );
} 
