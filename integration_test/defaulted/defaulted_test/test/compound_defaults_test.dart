import 'package:defaulted_api/defaulted_api.dart';
import 'package:defaulted_api/src/operation/get_compound_defaults.dart';
import 'package:test/test.dart';

void main() {
  test('allOf defaults apply to missing properties', () {
    final value = AllOfDefaults.fromJson(const <String, Object?>{});

    expect(value.single?.toJson(), 3);
    expect(value.multiple?.toJson(), 3);
    expect(value.aliased?.toJson(), 3);
    expect(value.aliasOverride?.toJson(), 2);
    expect(value.overridden?.toJson(), 0);
    expect(value.inline?.toJson(), 3);
    expect(value.nullable?.toJson(), 3);
    expect(value.zero?.toJson(), 0);
    expect(value.disabled?.toJson(), isFalse);
    expect(value.nullDefault, isNull);
    expect(value.noDefault, isNull);
  });

  test('oneOf defaults apply to missing properties', () {
    final value = OneOfDefaults.fromJson(const <String, Object?>{});

    expect(value.single?.toJson(), 3);
    expect(value.multiple?.toJson(), 3);
    expect(value.aliased?.toJson(), 3);
    expect(value.aliasOverride?.toJson(), 2);
    expect(value.overridden?.toJson(), 0);
    expect(value.inline?.toJson(), 3);
    expect(value.nullable?.toJson(), 3);
    expect(value.zero?.toJson(), 0);
    expect(value.disabled?.toJson(), isFalse);
    expect(value.nullDefault, isNull);
    expect(value.noDefault, isNull);
  });

  test('anyOf defaults apply to missing properties', () {
    final value = AnyOfDefaults.fromJson(const <String, Object?>{});

    expect(value.single?.toJson(), 3);
    expect(value.multiple?.toJson(), 3);
    expect(value.aliased?.toJson(), 3);
    expect(value.aliasOverride?.toJson(), 2);
    expect(value.overridden?.toJson(), 0);
    expect(value.inline?.toJson(), 3);
    expect(value.nullable?.toJson(), 3);
    expect(value.zero?.toJson(), 0);
    expect(value.disabled?.toJson(), isFalse);
    expect(value.nullDefault, isNull);
    expect(value.noDefault, isNull);
  });

  test('supplied values override compound defaults', () {
    final allOf = AllOfDefaults.fromJson(const {'single': 9, 'disabled': true});
    final oneOf = OneOfDefaults.fromJson(const {'multiple': 9, 'aliased': 8});
    final anyOf = AnyOfDefaults.fromJson(const {'overridden': 9, 'zero': 8});

    expect(allOf.single?.toJson(), 9);
    expect(allOf.disabled?.toJson(), isTrue);
    expect(oneOf.multiple?.toJson(), 9);
    expect(oneOf.aliased?.toJson(), 8);
    expect(anyOf.overridden?.toJson(), 9);
    expect(anyOf.zero?.toJson(), 8);
  });

  test('explicit null wins over nullable compound defaults', () {
    final allOf = AllOfDefaults.fromJson(const {'nullable': null});
    final oneOf = OneOfDefaults.fromJson(const {'nullable': null});
    final anyOf = AnyOfDefaults.fromJson(const {'nullable': null});

    expect(allOf.nullable, isNull);
    expect(oneOf.nullable, isNull);
    expect(anyOf.nullable, isNull);
  });

  test('null schema defaults leave explicit null unchanged', () {
    final allOf = AllOfDefaults.fromJson(const {'nullDefault': null});
    final oneOf = OneOfDefaults.fromJson(const {'nullDefault': null});
    final anyOf = AnyOfDefaults.fromJson(const {'nullDefault': null});

    expect(allOf.nullDefault, isNull);
    expect(oneOf.nullDefault, isNull);
    expect(anyOf.nullDefault, isNull);
  });

  test('properties without defaults accept supplied values', () {
    final allOf = AllOfDefaults.fromJson(const {
      'nullDefault': 4,
      'noDefault': 5,
    });
    final oneOf = OneOfDefaults.fromJson(const {
      'nullDefault': 4,
      'noDefault': 5,
    });
    final anyOf = AnyOfDefaults.fromJson(const {
      'nullDefault': 4,
      'noDefault': 5,
    });

    expect(allOf.nullDefault?.toJson(), 4);
    expect(allOf.noDefault?.toJson(), 5);
    expect(oneOf.nullDefault?.toJson(), 4);
    expect(oneOf.noDefault?.toJson(), 5);
    expect(anyOf.nullDefault?.toJson(), 4);
    expect(anyOf.noDefault?.toJson(), 5);
  });

  test('compound defaults survive a JSON round-trip', () {
    final allOf = AllOfDefaults.fromJson(const <String, Object?>{});
    final oneOf = OneOfDefaults.fromJson(const <String, Object?>{});
    final anyOf = AnyOfDefaults.fromJson(const <String, Object?>{});

    expect(AllOfDefaults.fromJson(allOf.toJson()), allOf);
    expect(OneOfDefaults.fromJson(oneOf.toJson()), oneOf);
    expect(AnyOfDefaults.fromJson(anyOf.toJson()), anyOf);
  });

  test('compound defaults are public computed getters', () {
    expect(AllOfDefaults.singleDefault.toJson(), 3);
    expect(OneOfDefaults.multipleDefault.toJson(), 3);
    expect(AnyOfDefaults.aliasedDefault.toJson(), 3);
    expect(
      identical(AllOfDefaults.singleDefault, AllOfDefaults.singleDefault),
      isFalse,
    );
  });

  test('operation parameters expose referenced compound defaults', () {
    expect(GetCompoundDefaults.retriesDefault.toJson(), 3);
    expect(GetCompoundDefaults.choiceDefault.toJson(), 3);
    expect(GetCompoundDefaults.combinationDefault.toJson(), 3);
    expect(GetCompoundDefaults.enabledDefault.toJson(), isFalse);
  });
}
