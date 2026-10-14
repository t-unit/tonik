import 'package:adversarial_strings_api/adversarial_strings_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('newline-prefixed property preserves its exact JSON key', () {
    const value = ObjectWithNewlineProp(k: 'declared');
    final json = value.toJson()! as Map<String, Object?>;

    expect(json, {'\nk': 'declared'});
    expect(json.keys.single.codeUnits, [10, 107]);
  });

  test('decoding separates the declared key from a similar additional key', () {
    final value = ObjectWithNewlineProp.fromJson(const {
      '\nk': 'declared',
      'k': 'additional',
    });

    expect(value.k, 'declared');
    expect(value.additionalProperties, {'k': 'additional'});
    expect(value.toJson(), {'\nk': 'declared', 'k': 'additional'});
  });

  test('encoding permits a key without the declared leading newline', () {
    const value = ObjectWithNewlineProp(
      k: 'declared',
      additionalProperties: {'k': 'additional'},
    );

    expect(value.toJson(), {'\nk': 'declared', 'k': 'additional'});
  });

  test('encoding rejects a collision with the full declared key', () {
    const value = ObjectWithNewlineProp(
      k: 'declared',
      additionalProperties: {'\nk': 'shadow'},
    );

    expect(value.toJson, throwsA(isA<EncodingException>()));
  });
}
