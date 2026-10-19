import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';

void main() {
  group('FieldEncoding', () {
    group('equality', () {
      test('two encodings with same fields are equal', () {
        const a = FieldEncoding(
          allowReserved: true,
          style: EncodingStyle.form,
          explode: true,
        );
        const b = FieldEncoding(
          allowReserved: true,
          style: EncodingStyle.form,
          explode: true,
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('encodings with different allowReserved are not equal', () {
        const a = FieldEncoding(
          allowReserved: true,
          style: null,
          explode: null,
        );
        const b = FieldEncoding(
          allowReserved: false,
          style: null,
          explode: null,
        );
        expect(a, isNot(b));
      });

      test('encodings with different style are not equal', () {
        const a = FieldEncoding(
          allowReserved: false,
          style: EncodingStyle.form,
          explode: null,
        );
        const b = FieldEncoding(
          allowReserved: false,
          style: EncodingStyle.pipeDelimited,
          explode: null,
        );
        expect(a, isNot(b));
      });

      test('encodings with different explode are not equal', () {
        const a = FieldEncoding(
          allowReserved: false,
          style: null,
          explode: true,
        );
        const b = FieldEncoding(
          allowReserved: false,
          style: null,
          explode: false,
        );
        expect(a, isNot(b));
      });

      test('encoding is not equal to non-encoding object', () {
        const a = FieldEncoding(
          allowReserved: false,
          style: null,
          explode: null,
        );
        expect(a, isNot('not an encoding'));
      });

      test('encoding is equal to itself', () {
        const a = FieldEncoding(
          allowReserved: true,
          style: EncodingStyle.deepObject,
          explode: null,
        );
        expect(a, a);
      });
    });

    group('toString', () {
      test('includes all fields', () {
        const encoding = FieldEncoding(
          allowReserved: true,
          style: EncodingStyle.form,
          explode: false,
        );
        final str = encoding.toString();
        expect(str, contains('FieldEncoding'));
        expect(str, contains('allowReserved: true'));
        expect(str, contains('EncodingStyle.form'));
        expect(str, contains('explode: false'));
      });
    });
  });

  group('PartEncoding', () {
    test('quoted semicolon does not declare a multipart boundary', () {
      const encoding = PartEncoding(
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data; profile="x;boundary=inner"',
        headers: null,
        style: null,
        explode: null,
        allowReserved: null,
        wireContentType: null,
        textEncoding: TextEncoding.utf8,
      );

      expect(encoding.requiresWireContentType, isTrue);
    });

    test('nonempty declared multipart boundary is sufficient', () {
      const encoding = PartEncoding(
        contentType: ContentType.multipart,
        rawContentType: 'multipart/form-data; profile="x;y"; boundary=inner',
        headers: null,
        style: null,
        explode: null,
        allowReserved: null,
        wireContentType: null,
        textEncoding: TextEncoding.utf8,
      );

      expect(encoding.requiresWireContentType, isFalse);
    });

    test('opaque multipart mixed requires a caller boundary', () {
      const encoding = PartEncoding(
        contentType: ContentType.bytes,
        rawContentType: 'multipart/mixed',
        headers: null,
        style: null,
        explode: null,
        allowReserved: null,
        wireContentType: null,
        textEncoding: TextEncoding.utf8,
      );

      expect(encoding.requiresWireContentType, isTrue);
    });

    test(
      'opaque multipart mixed with a declared boundary needs no caller type',
      () {
        const encoding = PartEncoding(
          contentType: ContentType.bytes,
          rawContentType: 'multipart/mixed; boundary=inner',
          headers: null,
          style: null,
          explode: null,
          allowReserved: null,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        );

        expect(encoding.requiresWireContentType, isFalse);
      },
    );

    group('isStyleBased', () {
      test('is false when all style fields are null', () {
        const encoding = PartEncoding(
          contentType: null,
          rawContentType: null,
          headers: null,
          style: null,
          explode: null,
          allowReserved: null,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        );
        expect(encoding.isStyleBased, isFalse);
      });

      test('is true when style is set', () {
        const encoding = PartEncoding(
          contentType: null,
          rawContentType: null,
          headers: null,
          style: EncodingStyle.form,
          explode: null,
          allowReserved: null,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        );
        expect(encoding.isStyleBased, isTrue);
      });

      test('is true when explode is set to false', () {
        const encoding = PartEncoding(
          contentType: null,
          rawContentType: null,
          headers: null,
          style: null,
          explode: false,
          allowReserved: null,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        );
        expect(encoding.isStyleBased, isTrue);
      });

      test('does not use allowReserved as an effective style setting', () {
        const encoding = PartEncoding(
          contentType: null,
          rawContentType: null,
          headers: null,
          style: null,
          explode: null,
          allowReserved: true,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        );
        expect(encoding.isStyleBased, isFalse);
      });

      test(
        'is false when only contentType is set (style fields still null)',
        () {
          const encoding = PartEncoding(
            contentType: null,
            rawContentType: 'application/json',
            headers: null,
            style: null,
            explode: null,
            allowReserved: null,
            wireContentType: null,
            textEncoding: TextEncoding.utf8,
          );
          expect(encoding.isStyleBased, isFalse);
        },
      );
    });

    group('equality', () {
      test('two encodings with same fields are equal', () {
        const a = PartEncoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
          headers: null,
          style: EncodingStyle.form,
          explode: true,
          allowReserved: false,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        );
        const b = PartEncoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
          headers: null,
          style: EncodingStyle.form,
          explode: true,
          allowReserved: false,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('encodings with different rawContentType are not equal', () {
        const a = PartEncoding(
          contentType: null,
          rawContentType: 'application/json',
          headers: null,
          style: null,
          explode: null,
          allowReserved: null,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        );
        const b = PartEncoding(
          contentType: null,
          rawContentType: 'text/plain',
          headers: null,
          style: null,
          explode: null,
          allowReserved: null,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        );
        expect(a, isNot(b));
      });

      test('encoding is not equal to non-encoding object', () {
        const a = PartEncoding(
          contentType: null,
          rawContentType: null,
          headers: null,
          style: null,
          explode: null,
          allowReserved: null,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        );
        expect(a, isNot('not an encoding'));
      });
    });

    group('toString', () {
      test('includes all fields', () {
        const encoding = PartEncoding(
          contentType: ContentType.json,
          rawContentType: 'application/json',
          headers: null,
          style: EncodingStyle.form,
          explode: true,
          allowReserved: false,
          wireContentType: null,
          textEncoding: TextEncoding.utf8,
        );
        final str = encoding.toString();
        expect(str, contains('PartEncoding'));
        expect(str, contains('application/json'));
        expect(str, contains('EncodingStyle.form'));
        expect(str, contains('explode: true'));
        expect(str, contains('allowReserved: false'));
      });
    });
  });
}
