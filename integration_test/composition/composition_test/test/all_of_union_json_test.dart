import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('allOf round-trips a string selected by anyOf', () {
    final value = AllOfUnionDisplayName.fromJson('Ada');
    expect(value.toJson(), 'Ada');
  });

  test('allOf round-trips an object selected by anyOf', () {
    final value = AllOfUnionDisplayName.fromJson(const {'text': 'Ada'});
    expect(value.toJson(), {'text': 'Ada'});
  });

  test('allOf round-trips an array selected by oneOf', () {
    final value = AllOfUnionTags.fromJson(const ['blue', 'black']);
    expect(value.toJson(), ['blue', 'black']);
  });

  test('allOf round-trips matching nested scalar unions', () {
    final value = AllOfMatchingUnions.fromJson('Ada');
    expect(value.toJson(), 'Ada');
  });

  test('allOf rejects inconsistent nested scalar unions', () {
    final value = AllOfMatchingUnions(
      allOfUnionDisplayName: AllOfUnionDisplayName.fromJson('Ada'),
      allOfUnionTags: AllOfUnionTags.fromJson('Grace'),
    );
    expect(value.toJson, throwsA(isA<EncodingException>()));
  });

  test('allOf rejects mixed nested scalar and object unions', () {
    final value = AllOfMatchingUnions(
      allOfUnionDisplayName: AllOfUnionDisplayName.fromJson(const {
        'text': 'Ada',
      }),
      allOfUnionTags: AllOfUnionTags.fromJson('Ada'),
    );
    expect(value.toJson, throwsA(isA<EncodingException>()));
  });

  test('allOf rejects mixed nested array and object unions', () {
    final value = AllOfMatchingUnions(
      allOfUnionDisplayName: AllOfUnionDisplayName.fromJson(const {
        'text': 'Ada',
      }),
      allOfUnionTags: AllOfUnionTags.fromJson(const ['Ada']),
    );
    expect(value.toJson, throwsA(isA<EncodingException>()));
  });
  test('allOf rejects object extras accompanying a scalar union', () {
    final value = AllOfUnionWithExtras(
      allOfUnionDisplayName: AllOfUnionDisplayName.fromJson('Ada'),
      additionalProperties: const {'nickname': 'A'},
    );
    expect(value.toJson, throwsA(isA<EncodingException>()));
  });
}
