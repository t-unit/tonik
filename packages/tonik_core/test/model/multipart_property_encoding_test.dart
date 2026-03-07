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
  });
}
