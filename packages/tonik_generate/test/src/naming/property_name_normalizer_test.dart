import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';

void main() {
  test('normalizeAll removes leading underscores', () {
    final result = normalizeProperties([
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
    final result = normalizeProperties([
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
    final result = normalizeProperties([
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
    final result = normalizeProperties([
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
    final result = normalizeProperties([
      createProperty('class'),
      createProperty('void'),
      createProperty('switch'),
      createProperty('class_name'),
      createProperty('void_method'),
      createProperty('switch_case'),
      createProperty('Class'),
      createProperty('VOID'),
      createProperty('Switch123'),
      createProperty('fromJson'),
      createProperty('toJson'),
      createProperty('copyWith'),
      createProperty('toString'),
      createProperty('hashCode'),
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
      r'$fromJson',
      r'$toJson',
      r'$copyWith',
      r'$toString',
      r'$hashCode',
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
      final result = normalizeEnumValues(['1', '2', '3', '123', '456']);

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
      final result = normalizeEnumValues(['', '_', '__', '___']);

      expect(result.map((r) => r.normalizedName).toList(), [
        'value',
        'value2',
        'value3',
        'value4',
      ]);
    });

    test('makes duplicate names unique', () {
      final result = normalizeEnumValues(['1', 'one', 'ONE', 'One']);

      expect(result.map((r) => r.normalizedName).toList(), [
        'one',
        'one2',
        'one3',
        'one4',
      ]);
    });
  });

  test('handles special characters', () {
    final result = normalizeEnumValues([
      'class',
      r'$class',
      'class2',
      'if',
      r'$if',
      'if2',
    ]);

    expect(result.map((r) => r.normalizedName).toList(), [
      r'$class',
      r'$class2',
      'class2',
      r'$if',
      r'$if2',
      'if2',
    ]);
  });

  test('preserves property metadata', () {
    final result = normalizeProperties([
      createProperty('name', isDeprecated: true),
    ]);

    expect(result.first.property.isDeprecated, isTrue);
  });

  group('nameOverride support', () {
    test('uses nameOverride when set', () {
      final prop = createProperty('user_profile')..nameOverride = 'customName';

      final result = normalizeProperties([prop]);

      expect(result.first.normalizedName, 'customName');
      expect(result.first.property.name, 'user_profile');
    });

    test('sanitizes nameOverride value', () {
      final prop = createProperty('user')..nameOverride = 'my-custom_name';

      final result = normalizeProperties([prop]);

      expect(result.first.normalizedName, 'myCustomName');
    });

    test('makes nameOverride unique when duplicate', () {
      final prop1 = createProperty('field1')..nameOverride = 'value';

      final prop2 = createProperty('field2')..nameOverride = 'value';

      final result = normalizeProperties([prop1, prop2]);

      expect(result[0].normalizedName, 'value');
      expect(result[1].normalizedName, 'value2');
    });

    test('falls back to generated name when nameOverride is null', () {
      final prop = createProperty('user_name');

      final result = normalizeProperties([prop]);

      expect(result.first.normalizedName, 'userName');
    });

    test('original property name unchanged for JSON serialization', () {
      final prop = createProperty('_id')..nameOverride = 'identifier';

      final result = normalizeProperties([prop]);

      expect(result.first.normalizedName, 'identifier');
      expect(
        result.first.property.name,
        '_id',
        reason: 'Original name should be preserved for JSON keys',
      );
    });

    test('nameOverride mixes with generated names uniquely', () {
      final prop1 = createProperty('user');
      final prop2 = createProperty('profile')..nameOverride = 'user';

      final result = normalizeProperties([prop1, prop2]);

      expect(result[0].normalizedName, 'user');
      expect(result[1].normalizedName, 'user2');
    });
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
