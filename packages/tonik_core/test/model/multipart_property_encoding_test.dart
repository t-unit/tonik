import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('MultipartPropertyEncoding', () {
    group('isStyleBased', () {
      test('is false when all style fields are null', () {
        const encoding = MultipartPropertyEncoding();
        expect(encoding.isStyleBased, isFalse);
      });

      test('is true when style is set', () {
        const encoding = MultipartPropertyEncoding(
          style: MultipartEncodingStyle.form,
        );
        expect(encoding.isStyleBased, isTrue);
      });

      test('is true when explode is set to false', () {
        const encoding = MultipartPropertyEncoding(explode: false);
        expect(encoding.isStyleBased, isTrue);
      });

      test(
        'is true when explode is set to true (default value still triggers)',
        () {
          const encoding = MultipartPropertyEncoding(explode: true);
          expect(encoding.isStyleBased, isTrue);
        },
      );

      test('is true when allowReserved is set', () {
        const encoding = MultipartPropertyEncoding(allowReserved: true);
        expect(encoding.isStyleBased, isTrue);
      });

      test(
        'is false when only contentType is set (style fields still null)',
        () {
          const encoding = MultipartPropertyEncoding(
            rawContentType: 'application/json',
          );
          expect(encoding.isStyleBased, isFalse);
        },
      );
    });

    group('equality', () {
      test('two encodings with same fields are equal', () {
        const a = MultipartPropertyEncoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
          style: MultipartEncodingStyle.form,
          explode: true,
          allowReserved: false,
        );
        const b = MultipartPropertyEncoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
          style: MultipartEncodingStyle.form,
          explode: true,
          allowReserved: false,
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('two empty encodings are equal', () {
        const a = MultipartPropertyEncoding();
        const b = MultipartPropertyEncoding();
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('encodings with different style are not equal', () {
        const a = MultipartPropertyEncoding(
          style: MultipartEncodingStyle.form,
        );
        const b = MultipartPropertyEncoding(
          style: MultipartEncodingStyle.pipeDelimited,
        );
        expect(a, isNot(b));
      });

      test('encodings with different explode are not equal', () {
        const a = MultipartPropertyEncoding(explode: true);
        const b = MultipartPropertyEncoding(explode: false);
        expect(a, isNot(b));
      });

      test('encodings with different rawContentType are not equal', () {
        const a = MultipartPropertyEncoding(
          rawContentType: 'application/json',
        );
        const b = MultipartPropertyEncoding(rawContentType: 'text/plain');
        expect(a, isNot(b));
      });

      test('encodings with different allowReserved are not equal', () {
        const a = MultipartPropertyEncoding(allowReserved: true);
        const b = MultipartPropertyEncoding(allowReserved: false);
        expect(a, isNot(b));
      });

      test('encoding is not equal to non-encoding object', () {
        const a = MultipartPropertyEncoding();
        expect(a, isNot('not an encoding'));
      });

      test('encoding is equal to itself', () {
        const a = MultipartPropertyEncoding(
          style: MultipartEncodingStyle.deepObject,
        );
        expect(a, a);
      });
    });

    group('toString', () {
      test('includes all fields', () {
        const encoding = MultipartPropertyEncoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
          style: MultipartEncodingStyle.form,
          explode: true,
          allowReserved: false,
        );
        final str = encoding.toString();
        expect(str, contains('MultipartPropertyEncoding'));
        expect(str, contains('application/json'));
        expect(str, contains('MultipartEncodingStyle.form'));
        expect(str, contains('explode: true'));
        expect(str, contains('allowReserved: false'));
      });

      test('includes null fields', () {
        const encoding = MultipartPropertyEncoding();
        final str = encoding.toString();
        expect(str, contains('contentType: null'));
        expect(str, contains('style: null'));
        expect(str, contains('explode: null'));
        expect(str, contains('allowReserved: null'));
      });
    });
  });
}
