import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';
import 'package:tonik_util/src/decoding/form_decoder.dart';

void main() {
  group('FormDecoder', () {
    group('decodeFormString', () {
      test('decodes form-encoded strings with spaces', () {
        expect('hello+world'.decodeFormString(), 'hello world');
        expect('hello%20world'.decodeFormString(), 'hello world');
      });

      test('decodes form-encoded strings with special characters', () {
        expect('test%40example.com'.decodeFormString(), 'test@example.com');
        expect(
          'key%3Dvalue%26other%3Ddata'.decodeFormString(),
          'key=value&other=data',
        );
        expect('hello%2Bworld'.decodeFormString(), 'hello+world');
      });

      test('decodes unicode characters', () {
        expect('h%C3%A9llo+w%C3%B6rld'.decodeFormString(), 'héllo wörld');
        expect('emoji+%F0%9F%98%80'.decodeFormString(), 'emoji 😀');
      });

      test('handles empty strings', () {
        expect(''.decodeFormString(), '');
      });

      test('throws InvalidTypeException for null values', () {
        expect(
          () => (null as String?).decodeFormString(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('passes context in exceptions', () {
        try {
          (null as String?).decodeFormString(context: 'TestClass.property');
          fail('Should have thrown InvalidTypeException');
        } on InvalidTypeException catch (e) {
          expect(e, isA<InvalidTypeException>());
          expect(e.context, 'TestClass.property');
        }
      });
    });

    group('decodeFormNullableString', () {
      test('decodes form-encoded strings', () {
        expect('hello+world'.decodeFormNullableString(), 'hello world');
        expect(
          'test%40example.com'.decodeFormNullableString(),
          'test@example.com',
        );
      });

      test('returns null for null or empty strings', () {
        expect((null as String?).decodeFormNullableString(), isNull);
        expect(''.decodeFormNullableString(), isNull);
      });
    });

    group('decodeFormInt', () {
      test('decodes integer strings', () {
        expect('42'.decodeFormInt(), 42);
        expect('-123'.decodeFormInt(), -123);
        expect('0'.decodeFormInt(), 0);
      });

      test('throws InvalidTypeException for invalid integers', () {
        expect(
          () => 'not_a_number'.decodeFormInt(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '3.14'.decodeFormInt(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => (null as String?).decodeFormInt(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('passes context in exceptions', () {
        try {
          'invalid'.decodeFormInt(context: 'TestClass.count');
          fail('Should have thrown InvalidTypeException');
        } on InvalidTypeException catch (e) {
          expect(e, isA<InvalidTypeException>());
          expect(e.context, 'TestClass.count');
        }
      });
    });

    group('decodeFormNullableInt', () {
      test('decodes integer strings', () {
        expect('42'.decodeFormNullableInt(), 42);
        expect('-123'.decodeFormNullableInt(), -123);
      });

      test('returns null for null or empty strings', () {
        expect((null as String?).decodeFormNullableInt(), isNull);
        expect(''.decodeFormNullableInt(), isNull);
      });

      test('throws InvalidTypeException for invalid integers', () {
        expect(
          () => 'not_a_number'.decodeFormNullableInt(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormDouble', () {
      test('decodes double strings', () {
        expect('3.14'.decodeFormDouble(), 3.14);
        expect('-2.5'.decodeFormDouble(), -2.5);
        expect('0.0'.decodeFormDouble(), 0.0);
        expect('42'.decodeFormDouble(), 42.0);
      });

      test('handles extreme values', () {
        expect('Infinity'.decodeFormDouble(), double.infinity);
        expect('-Infinity'.decodeFormDouble(), double.negativeInfinity);
        expect('NaN'.decodeFormDouble(), isNaN);
      });

      test('throws InvalidTypeException for invalid doubles', () {
        expect(
          () => 'not_a_number'.decodeFormDouble(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => (null as String?).decodeFormDouble(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormNullableDouble', () {
      test('decodes double strings', () {
        expect('3.14'.decodeFormNullableDouble(), 3.14);
        expect('-2.5'.decodeFormNullableDouble(), -2.5);
      });

      test('returns null for null or empty strings', () {
        expect((null as String?).decodeFormNullableDouble(), isNull);
        expect(''.decodeFormNullableDouble(), isNull);
      });

      test('throws InvalidTypeException for invalid doubles', () {
        expect(
          () => 'not_a_number'.decodeFormNullableDouble(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormBool', () {
      test('decodes boolean strings', () {
        expect('true'.decodeFormBool(), isTrue);
        expect('false'.decodeFormBool(), isFalse);
      });

      test('throws InvalidTypeException for invalid booleans', () {
        expect(
          () => 'True'.decodeFormBool(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => 'FALSE'.decodeFormBool(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '1'.decodeFormBool(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '0'.decodeFormBool(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => (null as String?).decodeFormBool(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormNullableBool', () {
      test('decodes boolean strings', () {
        expect('true'.decodeFormNullableBool(), isTrue);
        expect('false'.decodeFormNullableBool(), isFalse);
      });

      test('returns null for null or empty strings', () {
        expect((null as String?).decodeFormNullableBool(), isNull);
        expect(''.decodeFormNullableBool(), isNull);
      });

      test('throws InvalidTypeException for invalid booleans', () {
        expect(
          () => 'invalid'.decodeFormNullableBool(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormDateTime', () {
      test('decodes ISO 8601 DateTime strings', () {
        final dateTime = '2023-12-25T10%3A30%3A45Z'.decodeFormDateTime();
        expect(dateTime.year, 2023);
        expect(dateTime.month, 12);
        expect(dateTime.day, 25);
        expect(dateTime.hour, 10);
        expect(dateTime.minute, 30);
        expect(dateTime.second, 45);
        expect(dateTime.isUtc, isTrue);
      });

      test('decodes DateTime with timezone offset', () {
        final dateTime = '2023-06-15T14%3A30%3A00%2B02%3A00'
            .decodeFormDateTime();
        expect(dateTime.year, 2023);
        expect(dateTime.month, 6);
        expect(dateTime.day, 15);
        expect(dateTime.hour, 14);
        expect(dateTime.minute, 30);
      });

      test('throws InvalidTypeException for invalid DateTime strings', () {
        expect(
          () => 'not_a_date'.decodeFormDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => (null as String?).decodeFormDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormNullableDateTime', () {
      test('decodes DateTime strings', () {
        final dateTime = '2023-12-25T10%3A30%3A45Z'
            .decodeFormNullableDateTime();
        expect(dateTime, isNotNull);
        expect(dateTime!.year, 2023);
      });

      test('returns null for null or empty strings', () {
        expect((null as String?).decodeFormNullableDateTime(), isNull);
        expect(''.decodeFormNullableDateTime(), isNull);
      });

      test('throws InvalidTypeException for invalid DateTime strings', () {
        expect(
          () => 'invalid'.decodeFormNullableDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormBigDecimal', () {
      test('decodes BigDecimal strings', () {
        expect(
          '123.456789'.decodeFormBigDecimal(),
          BigDecimal.parse('123.456789'),
        );
        expect(
          '999999999999.123456789'.decodeFormBigDecimal(),
          BigDecimal.parse('999999999999.123456789'),
        );
        expect('0'.decodeFormBigDecimal(), BigDecimal.zero);
        expect('-42.5'.decodeFormBigDecimal(), BigDecimal.parse('-42.5'));
      });

      test('throws InvalidTypeException for invalid BigDecimal strings', () {
        expect(
          () => 'not_a_decimal'.decodeFormBigDecimal(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => (null as String?).decodeFormBigDecimal(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormNullableBigDecimal', () {
      test('decodes BigDecimal strings', () {
        expect(
          '123.456789'.decodeFormNullableBigDecimal(),
          BigDecimal.parse('123.456789'),
        );
        expect(
          '-42.5'.decodeFormNullableBigDecimal(),
          BigDecimal.parse('-42.5'),
        );
      });

      test('returns null for null or empty strings', () {
        expect((null as String?).decodeFormNullableBigDecimal(), isNull);
        expect(''.decodeFormNullableBigDecimal(), isNull);
      });

      test('throws InvalidTypeException for invalid BigDecimal strings', () {
        expect(
          () => 'invalid'.decodeFormNullableBigDecimal(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormDate', () {
      test('decodes ISO 8601 Date strings', () {
        final date = '2023-12-25'.decodeFormDate();
        expect(date.year, 2023);
        expect(date.month, 12);
        expect(date.day, 25);
      });

      test('throws InvalidTypeException for invalid Date strings', () {
        expect(
          () => 'not_a_date'.decodeFormDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2023-13-45'.decodeFormDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => (null as String?).decodeFormDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => ''.decodeFormDate(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormNullableDate', () {
      test('decodes Date strings', () {
        final date = '2023-12-25'.decodeFormNullableDate();
        expect(date, isNotNull);
        expect(date!.year, 2023);
      });

      test('returns null for null or empty strings', () {
        expect((null as String?).decodeFormNullableDate(), isNull);
        expect(''.decodeFormNullableDate(), isNull);
      });

      test('throws InvalidTypeException for invalid Date strings', () {
        expect(
          () => 'invalid'.decodeFormNullableDate(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormUri', () {
      test('decodes URI strings', () {
        final uri = 'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue'
            .decodeFormUri();
        expect(uri.scheme, 'https');
        expect(uri.host, 'example.com');
        expect(uri.path, '/path');
        expect(uri.query, 'query=value');
      });

      test('decodes simple URIs', () {
        final uri = 'https%3A%2F%2Fexample.com'.decodeFormUri();
        expect(uri.toString(), 'https://example.com');
      });

      test('throws InvalidTypeException for null input', () {
        expect(
          () => (null as String?).decodeFormUri(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormNullableUri', () {
      test('decodes URI strings', () {
        final uri = 'https%3A%2F%2Fexample.com'.decodeFormNullableUri();
        expect(uri, isNotNull);
        expect(uri!.toString(), 'https://example.com');
      });

      test('returns null for null or empty strings', () {
        expect((null as String?).decodeFormNullableUri(), isNull);
        expect(''.decodeFormNullableUri(), isNull);
      });

      test('accepts any string that Uri.parse accepts', () {
        // Uri.parse is very lenient, so we should be too
        expect('not_a_uri'.decodeFormNullableUri().toString(), 'not_a_uri');
        expect('invalid'.decodeFormNullableUri().toString(), 'invalid');
      });
    });

    group('decodeFormStringList', () {
      test('decodes comma-separated string lists', () {
        expect('red,green,blue'.decodeFormStringList(), [
          'red',
          'green',
          'blue',
        ]);
        expect('single'.decodeFormStringList(), ['single']);
      });

      test('decodes form-encoded string lists', () {
        expect('hello+world,test%40example.com'.decodeFormStringList(), [
          'hello world',
          'test@example.com',
        ]);
        expect('key%3Dvalue,other%26data'.decodeFormStringList(), [
          'key=value',
          'other&data',
        ]);
      });

      test('handles empty strings', () {
        expect(''.decodeFormStringList(), <String>[]);
      });

      test('throws InvalidTypeException for null values', () {
        expect(
          () => (null as String?).decodeFormStringList(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormNullableStringList', () {
      test('decodes string lists', () {
        expect('red,green,blue'.decodeFormNullableStringList(), [
          'red',
          'green',
          'blue',
        ]);
        expect(
          'hello+world,test%40example.com'.decodeFormNullableStringList(),
          ['hello world', 'test@example.com'],
        );
      });

      test('returns null for null or empty strings', () {
        expect((null as String?).decodeFormNullableStringList(), isNull);
        expect(''.decodeFormNullableStringList(), isNull);
      });
    });

    group('decodeFormStringNullableList', () {
      test('decodes string lists with nullable elements', () {
        expect('red,green,blue'.decodeFormStringNullableList(), [
          'red',
          'green',
          'blue',
        ]);
        expect(
          'hello+world,,test%40example.com'.decodeFormStringNullableList(),
          ['hello world', null, 'test@example.com'],
        );
      });

      test('handles empty strings', () {
        expect(''.decodeFormStringNullableList(), <String?>[]);
      });

      test('throws InvalidTypeException for null values', () {
        expect(
          () => (null as String?).decodeFormStringNullableList(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('decodeFormNullableStringNullableList', () {
      test('decodes nullable string lists with nullable elements', () {
        expect('red,green,blue'.decodeFormNullableStringNullableList(), [
          'red',
          'green',
          'blue',
        ]);
        expect(
          'hello+world,,test%40example.com'
              .decodeFormNullableStringNullableList(),
          ['hello world', null, 'test@example.com'],
        );
      });

      test('returns null for null or empty strings', () {
        expect(
          (null as String?).decodeFormNullableStringNullableList(),
          isNull,
        );
        expect(''.decodeFormNullableStringNullableList(), isNull);
      });
    });

    group('Binary', () {
      test('decodes UTF-8 string to List<int>', () {
        // Test standard UTF-8.
        const textString = 'Hello World';
        final result = textString.decodeFormBinary();
        expect(result, [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]);

        // Test UTF-8 with special characters.
        const utf8String = 'Hëllö';
        final utf8Result = utf8String.decodeFormBinary();
        expect(utf8Result, [72, 195, 171, 108, 108, 195, 182]);

        // Test empty string.
        const emptyString = '';
        final emptyResult = emptyString.decodeFormBinary();
        expect(emptyResult, <int>[]);
      });

      test('decodes nullable UTF-8 string to List<int>', () {
        const textString = 'Hello World';
        final result = textString.decodeFormNullableBinary();
        expect(result, [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]);

        expect(null.decodeFormNullableBinary(), isNull);
        expect(''.decodeFormNullableBinary(), isNull);
      });

      test('throws InvalidTypeException if value is null', () {
        expect(
          () => null.decodeFormBinary(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('includes context in error messages', () {
        try {
          null.decodeFormBinary(context: 'User.thumbnail');
          fail('Should have thrown');
        } on InvalidTypeException catch (e) {
          expect(e.context, 'User.thumbnail');
        }
      });
    });
  });
}
