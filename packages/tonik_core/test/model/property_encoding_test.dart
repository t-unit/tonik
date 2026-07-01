import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('PropertyEncoding', () {
    group('isStyleBased', () {
      test('is false when all style fields are null', () {
        const encoding = PropertyEncoding();
        expect(encoding.isStyleBased, isFalse);
      });

      test('is true when style is set', () {
        const encoding = PropertyEncoding(
          style: EncodingStyle.form,
        );
        expect(encoding.isStyleBased, isTrue);
      });

      test('is true when explode is set to false', () {
        const encoding = PropertyEncoding(explode: false);
        expect(encoding.isStyleBased, isTrue);
      });

      test(
        'is true when explode is set to true (default value still triggers)',
        () {
          const encoding = PropertyEncoding(explode: true);
          expect(encoding.isStyleBased, isTrue);
        },
      );

      test('is true when allowReserved is set', () {
        const encoding = PropertyEncoding(allowReserved: true);
        expect(encoding.isStyleBased, isTrue);
      });

      test(
        'is false when only contentType is set (style fields still null)',
        () {
          const encoding = PropertyEncoding(
            rawContentType: 'application/json',
          );
          expect(encoding.isStyleBased, isFalse);
        },
      );
    });

    group('equality', () {
      test('two encodings with same fields are equal', () {
        const a = PropertyEncoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
          style: EncodingStyle.form,
          explode: true,
          allowReserved: false,
        );
        const b = PropertyEncoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
          style: EncodingStyle.form,
          explode: true,
          allowReserved: false,
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('two empty encodings are equal', () {
        const a = PropertyEncoding();
        const b = PropertyEncoding();
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('encodings with different style are not equal', () {
        const a = PropertyEncoding(
          style: EncodingStyle.form,
        );
        const b = PropertyEncoding(
          style: EncodingStyle.pipeDelimited,
        );
        expect(a, isNot(b));
      });

      test('encodings with different explode are not equal', () {
        const a = PropertyEncoding(explode: true);
        const b = PropertyEncoding(explode: false);
        expect(a, isNot(b));
      });

      test('encodings with different rawContentType are not equal', () {
        const a = PropertyEncoding(
          rawContentType: 'application/json',
        );
        const b = PropertyEncoding(rawContentType: 'text/plain');
        expect(a, isNot(b));
      });

      test('encodings with different allowReserved are not equal', () {
        const a = PropertyEncoding(allowReserved: true);
        const b = PropertyEncoding(allowReserved: false);
        expect(a, isNot(b));
      });

      test('encoding is not equal to non-encoding object', () {
        const a = PropertyEncoding();
        expect(a, isNot('not an encoding'));
      });

      test('encoding is equal to itself', () {
        const a = PropertyEncoding(
          style: EncodingStyle.deepObject,
        );
        expect(a, a);
      });
    });

    group('toString', () {
      test('includes all fields', () {
        const encoding = PropertyEncoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
          style: EncodingStyle.form,
          explode: true,
          allowReserved: false,
        );
        final str = encoding.toString();
        expect(str, contains('PropertyEncoding'));
        expect(str, contains('application/json'));
        expect(str, contains('EncodingStyle.form'));
        expect(str, contains('explode: true'));
        expect(str, contains('allowReserved: false'));
      });

      test('includes null fields', () {
        const encoding = PropertyEncoding();
        final str = encoding.toString();
        expect(str, contains('contentType: null'));
        expect(str, contains('style: null'));
        expect(str, contains('explode: null'));
        expect(str, contains('allowReserved: null'));
      });
    });
  });
}
