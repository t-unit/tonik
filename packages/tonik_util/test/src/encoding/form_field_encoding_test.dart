import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/form_field_encoding.dart';

void main() {
  group('FormFieldEncoding', () {
    test('allowReserved defaults to false and explode to null', () {
      const encoding = FormFieldEncoding();
      expect(encoding.allowReserved, isFalse);
      expect(encoding.explode, isNull);
    });

    group('equality', () {
      test('two encodings with the same fields are equal', () {
        const a = FormFieldEncoding(allowReserved: true, explode: false);
        const b = FormFieldEncoding(allowReserved: true, explode: false);
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('encodings with different allowReserved are not equal', () {
        const a = FormFieldEncoding(allowReserved: true);
        const b = FormFieldEncoding();
        expect(a, isNot(b));
      });

      test('encodings with different explode are not equal', () {
        const a = FormFieldEncoding(explode: true);
        const b = FormFieldEncoding(explode: false);
        expect(a, isNot(b));
      });
    });
  });
}
