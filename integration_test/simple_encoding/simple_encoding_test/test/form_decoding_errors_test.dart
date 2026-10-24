import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('oneOf handles malformed form boolean escapes as decoding failures', () {
    expect(
      () => TwoLevelOneOf.fromForm('%zz', explode: false),
      throwsA(isA<DecodingException>()),
    );
  });

  test('oneOf handles malformed form list escapes as decoding failures', () {
    expect(
      () => HeaderListChoice.fromForm('%zz,a', explode: false),
      throwsA(isA<DecodingException>()),
    );
  });

  test('oneOf retains valid encoded boolean form decoding', () {
    expect(
      TwoLevelOneOf.fromForm('%74rue', explode: false),
      const TwoLevelOneOfBool(true),
    );
  });

  test('oneOf retains valid encoded string-list form decoding', () {
    final decoded = HeaderListChoice.fromForm(
      '100%25,%2B,hello+world',
      explode: false,
    );

    expect(decoded.toJson(), ['100%', '+', 'hello world']);
  });
}
