import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('preserves raw scalar strings', () {
    final result = encodeAnyValueToPropertyValue('a,b', allowEmpty: true);
    expect((result as ScalarPropertyValue).value, 'a,b');
  });

  test('preserves array element boundaries and scalar encodings', () {
    final result = encodeAnyValueToPropertyValue([
      'a,b',
      42,
      true,
      null,
    ], allowEmpty: true);
    expect((result as ArrayPropertyValue).values, ['a,b', '42', 'true', '']);
  });

  test('preserves empty arrays', () {
    final result = encodeAnyValueToPropertyValue([], allowEmpty: true);
    expect((result as ArrayPropertyValue).values, isEmpty);
  });

  test('rejects null when empty values are disabled', () {
    expect(
      () => encodeAnyValueToPropertyValue(null, allowEmpty: false),
      throwsA(isA<EmptyValueException>()),
    );
  });

  test('rejects nested objects', () {
    expect(
      () => encodeAnyValueToPropertyValue({'name': 'Ada'}, allowEmpty: true),
      throwsA(isA<EncodingException>()),
    );
  });

  test('rejects nested arrays', () {
    expect(
      () => encodeAnyValueToPropertyValue([
        ['blue'],
      ], allowEmpty: true),
      throwsA(isA<EncodingException>()),
    );
  });
}
