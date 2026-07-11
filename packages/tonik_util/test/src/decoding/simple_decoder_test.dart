import 'dart:convert';

import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/date.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';
import 'package:tonik_util/src/decoding/simple_decoder.dart';

void main() {
  group('SimpleDecoder', () {
    group('Simple Values', () {
      test('decodes integer values', () {
        expect('123'.decodeSimpleInt(), 123);
        expect('-17'.decodeSimpleInt(), -17);
        expect(
          () => 'abc'.decodeSimpleInt(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeSimpleInt(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes double values', () {
        expect('3.14'.decodeSimpleDouble(), 3.14);
        expect('-0.5'.decodeSimpleDouble(), -0.5);
        expect(
          () => 'abc'.decodeSimpleDouble(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeSimpleDouble(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes boolean values', () {
        expect('true'.decodeSimpleBool(), isTrue);
        expect('false'.decodeSimpleBool(), isFalse);
        expect(
          () => 'yes'.decodeSimpleBool(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeSimpleBool(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes DateTime values with timezone awareness', () {
        const utcString = '2024-03-14T10:30:45Z';
        final utcResult = utcString.decodeSimpleDateTime();
        expect(utcResult.year, 2024);
        expect(utcResult.month, 3);
        expect(utcResult.day, 14);
        expect(utcResult.hour, 10);
        expect(utcResult.minute, 30);
        expect(utcResult.second, 45);
        expect(utcResult.timeZoneOffset, Duration.zero);

        const localString = '2024-03-14T10:30:45';
        final localResult = localString.decodeSimpleDateTime();
        expect(localResult.year, 2024);
        expect(localResult.month, 3);
        expect(localResult.day, 14);
        expect(localResult.hour, 10);
        expect(localResult.minute, 30);
        expect(localResult.second, 45);
        final expectedLocalTime = DateTime(2024, 3, 14, 10, 30, 45);
        expect(localResult.timeZoneOffset, expectedLocalTime.timeZoneOffset);

        const offsetString = '2024-03-14T10:30:45+05:00';
        final offsetResult = offsetString.decodeSimpleDateTime();
        expect(offsetResult.year, 2024);
        expect(offsetResult.month, 3);
        expect(offsetResult.day, 14);
        expect(offsetResult.hour, 10);
        expect(offsetResult.minute, 30);
        expect(offsetResult.second, 45);
        expect(offsetResult.timeZoneOffset.inHours, 5);
        expect(offsetResult.timeZoneOffset.inMinutes, 5 * 60);

        const negativeOffsetString = '2024-03-14T10:30:45-08:00';
        final negativeOffsetResult = negativeOffsetString
            .decodeSimpleDateTime();
        expect(negativeOffsetResult.year, 2024);
        expect(negativeOffsetResult.month, 3);
        expect(negativeOffsetResult.day, 14);
        expect(negativeOffsetResult.hour, 10);
        expect(negativeOffsetResult.minute, 30);
        expect(negativeOffsetResult.second, 45);
        expect(negativeOffsetResult.timeZoneOffset.inHours, -8);
        expect(negativeOffsetResult.timeZoneOffset.inMinutes, -8 * 60);

        expect(
          () => 'not-a-date'.decodeSimpleDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeSimpleDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes BigDecimal values', () {
        expect('3.14'.decodeSimpleBigDecimal(), BigDecimal.parse('3.14'));
        expect('-0.5'.decodeSimpleBigDecimal(), BigDecimal.parse('-0.5'));
        expect(
          () => 'abcdefghijklmnopqrstuvwxyz'.decodeSimpleBigDecimal(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeSimpleBigDecimal(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes Date values', () {
        final date = Date(2024, 3, 15);
        expect('2024-03-15'.decodeSimpleDate(), date);
        expect(
          () => 'not-a-date'.decodeSimpleDate(),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => null.decodeSimpleDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2024-00-15'.decodeSimpleDate(),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => '2024-13-15'.decodeSimpleDate(),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => '2024-03-00'.decodeSimpleDate(),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => '2024-03-32'.decodeSimpleDate(),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => '2024-02-30'.decodeSimpleDate(),
          throwsA(isA<FormatException>()),
        );
      });

      test('decodes Uri values', () {
        final uri = Uri.parse('https://example.com');
        expect('https://example.com'.decodeSimpleUri(), uri);
        expect(
          'ftp://files.example.com/file.txt'.decodeSimpleUri(),
          Uri.parse('ftp://files.example.com/file.txt'),
        );
        expect('/relative/path'.decodeSimpleUri(), Uri.parse('/relative/path'));
        expect(
          'mailto:user@example.com'.decodeSimpleUri(),
          Uri.parse('mailto:user@example.com'),
        );
        expect(
          () => null.decodeSimpleUri(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('handles URI parsing errors', () {
        expect(
          () => ':::invalid:::'.decodeSimpleUri(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('Nullable Values', () {
      test('handles empty strings and null for nullable types', () {
        expect(''.decodeSimpleNullableInt(), isNull);
        expect(''.decodeSimpleNullableDouble(), isNull);
        expect(''.decodeSimpleNullableBool(), isNull);
        expect(''.decodeSimpleNullableDateTime(), isNull);
        expect(''.decodeSimpleNullableBigDecimal(), isNull);
        expect(''.decodeSimpleNullableDate(), isNull);
        expect(''.decodeSimpleNullableUri(), isNull);

        expect(null.decodeSimpleNullableInt(), isNull);
        expect(null.decodeSimpleNullableDouble(), isNull);
        expect(null.decodeSimpleNullableBool(), isNull);
        expect(null.decodeSimpleNullableDateTime(), isNull);
        expect(null.decodeSimpleNullableBigDecimal(), isNull);
        expect(null.decodeSimpleNullableDate(), isNull);
        expect(null.decodeSimpleNullableUri(), isNull);
      });

      test('decodes non-empty strings for nullable types', () {
        expect('123'.decodeSimpleNullableInt(), 123);
        expect('3.14'.decodeSimpleNullableDouble(), 3.14);
        expect('true'.decodeSimpleNullableBool(), isTrue);
        expect(
          '2024-03-14T10:30:45Z'.decodeSimpleNullableDateTime(),
          DateTime.utc(2024, 3, 14, 10, 30, 45),
        );
        expect(
          '3.14'.decodeSimpleNullableBigDecimal(),
          BigDecimal.parse('3.14'),
        );
        expect(
          '2024-03-15'.decodeSimpleNullableDate(),
          Date(2024, 3, 15),
        );
        expect(
          'https://example.com'.decodeSimpleNullableUri(),
          Uri.parse('https://example.com'),
        );
      });
    });

    group('Empty string handling', () {
      test('throws on empty string for scalar types', () {
        expect(
          () => ''.decodeSimpleInt(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => ''.decodeSimpleDouble(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => ''.decodeSimpleBool(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => ''.decodeSimpleDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => ''.decodeSimpleBigDecimal(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => ''.decodeSimpleDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => ''.decodeSimpleUri(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('Collections', () {
      test('decodes string lists', () {
        // List<String>
        expect('a,b,c'.decodeSimpleStringList(), ['a', 'b', 'c']);
        expect(''.decodeSimpleStringList(), isEmpty);
        expect(
          () => null.decodeSimpleStringList(),
          throwsA(isA<InvalidTypeException>()),
        );

        // List<String>?
        expect('a,b,c'.decodeSimpleNullableStringList(), ['a', 'b', 'c']);
        expect(''.decodeSimpleNullableStringList(), null);
        expect(null.decodeSimpleNullableStringList(), null);

        // List<String?>
        expect('a,b,c'.decodeSimpleStringNullableList(), ['a', 'b', 'c']);
        expect('a,,c'.decodeSimpleStringNullableList(), ['a', null, 'c']);
        expect(''.decodeSimpleStringNullableList(), isEmpty);
        expect(
          () => null.decodeSimpleStringNullableList(),
          throwsA(isA<InvalidTypeException>()),
        );

        // List<String?>?
        expect('a,b,c'.decodeSimpleNullableStringNullableList(), [
          'a',
          'b',
          'c',
        ]);
        expect('a,,c'.decodeSimpleNullableStringNullableList(), [
          'a',
          null,
          'c',
        ]);
        expect(''.decodeSimpleNullableStringNullableList(), null);
        expect(null.decodeSimpleNullableStringNullableList(), null);
      });

      test('decodes string values', () {
        expect('test'.decodeSimpleString(), 'test');
        expect(
          () => null.decodeSimpleString(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes nullable string values', () {
        expect('test'.decodeSimpleNullableString(), 'test');
        expect(null.decodeSimpleNullableString(), isNull);
        expect(''.decodeSimpleNullableString(), isNull);
      });

      test('decodes integer values', () {
        expect('42'.decodeSimpleInt(), 42);
        expect(
          () => 'not a number'.decodeSimpleInt(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeSimpleInt(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes nullable integer values', () {
        expect('42'.decodeSimpleNullableInt(), 42);
        expect(null.decodeSimpleNullableInt(), isNull);
        expect(''.decodeSimpleNullableInt(), isNull);
        expect(
          () => 'not a number'.decodeSimpleNullableInt(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('Literal percent handling', () {
      test('decodeSimpleString returns percent signs literally', () {
        expect('50%'.decodeSimpleString(), '50%');
        expect('75%2Fdone'.decodeSimpleString(), '75%2Fdone');
        expect('a%20b'.decodeSimpleString(), 'a%20b');
        expect('foo%2Cbar'.decodeSimpleString(), 'foo%2Cbar');
        expect('%ZZ'.decodeSimpleString(), '%ZZ');
        expect('trailing%'.decodeSimpleString(), 'trailing%');
      });

      test('decodeSimpleNullableString returns percent signs literally', () {
        expect('50%'.decodeSimpleNullableString(), '50%');
        expect('foo%2Cbar'.decodeSimpleNullableString(), 'foo%2Cbar');
        expect('%ZZ'.decodeSimpleNullableString(), '%ZZ');
        expect(''.decodeSimpleNullableString(), isNull);
        expect((null as String?).decodeSimpleNullableString(), isNull);
      });

      test('decodeSimpleStringList splits on commas and keeps members raw', () {
        expect('a%2Cb,c'.decodeSimpleStringList(), ['a%2Cb', 'c']);
        expect('foo,bar%2Cbaz,,qux'.decodeSimpleStringList(), [
          'foo',
          'bar%2Cbaz',
          '',
          'qux',
        ]);
        expect('foo%2Cbar'.decodeSimpleStringList(), ['foo%2Cbar']);
        expect(''.decodeSimpleStringList(), isEmpty);
      });

      test('decodeSimpleNullableStringList keeps members raw', () {
        expect('a%2Cb,c'.decodeSimpleNullableStringList(), ['a%2Cb', 'c']);
        expect('foo,bar%2Cbaz,,qux'.decodeSimpleNullableStringList(), [
          'foo',
          'bar%2Cbaz',
          '',
          'qux',
        ]);
        expect(''.decodeSimpleNullableStringList(), isNull);
        expect((null as String?).decodeSimpleNullableStringList(), isNull);
      });

      test('decodeSimpleStringNullableList keeps members raw and empty to null',
          () {
        expect('foo,bar%2Cbaz,,qux'.decodeSimpleStringNullableList(), [
          'foo',
          'bar%2Cbaz',
          null,
          'qux',
        ]);
        expect('foo%2Cbar'.decodeSimpleStringNullableList(), ['foo%2Cbar']);
        expect(''.decodeSimpleStringNullableList(), isEmpty);
      });

      test('decodeSimpleNullableStringNullableList keeps members raw', () {
        expect(
          'foo,bar%2Cbaz,,qux'.decodeSimpleNullableStringNullableList(),
          ['foo', 'bar%2Cbaz', null, 'qux'],
        );
        expect(''.decodeSimpleNullableStringNullableList(), isNull);
        expect(
          (null as String?).decodeSimpleNullableStringNullableList(),
          isNull,
        );
      });

      test('decodeSimpleDateTime does not percent-decode before parsing', () {
        expect(
          () => '2023-12-25T10%3A30%3A00.000Z'.decodeSimpleDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodeSimpleUri does not percent-decode before parsing', () {
        expect(
          'https://example.com/a%20b'.decodeSimpleUri(),
          Uri.parse('https://example.com/a%20b'),
        );
      });

      test('decodeSimpleDouble does not percent-decode before parsing', () {
        expect(
          () => '1.5%2B0'.decodeSimpleDouble(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('Binary', () {
      test('decodes UTF-8 string to List<int>', () {
        const textString = 'Hello World';
        final result = textString.decodeSimpleBinary();
        expect(result, [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]);

        const utf8String = 'Hëllö';
        final utf8Result = utf8String.decodeSimpleBinary();
        expect(utf8Result, [72, 195, 171, 108, 108, 195, 182]);

        const emptyString = '';
        final emptyResult = emptyString.decodeSimpleBinary();
        expect(emptyResult, <int>[]);
      });

      test('decodes nullable UTF-8 string to List<int>', () {
        const textString = 'Hello World';
        final result = textString.decodeSimpleNullableBinary();
        expect(result, [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]);

        expect(null.decodeSimpleNullableBinary(), isNull);
        expect(''.decodeSimpleNullableBinary(), isNull);
      });

      test('throws InvalidTypeException if value is null', () {
        expect(
          () => null.decodeSimpleBinary(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('includes context in error messages', () {
        try {
          null.decodeSimpleBinary(context: 'User.thumbnail');
          fail('Should have thrown');
        } on InvalidTypeException catch (e) {
          expect(e.context, 'User.thumbnail');
        }
      });
    });

    group('decodeSimpleBase64', () {
      test('decodes base64 string to List<int>', () {
        // "Hello" in base64 is "SGVsbG8="
        const base64String = 'SGVsbG8=';
        final result = base64String.decodeSimpleBase64();
        expect(result, [72, 101, 108, 108, 111]);
      });

      test('decodes empty base64 string to empty list', () {
        const emptyBase64 = '';
        final result = emptyBase64.decodeSimpleBase64();
        expect(result, <int>[]);
      });

      test('round-trips with base64 encoding', () {
        final original = [1, 2, 3, 4, 5];
        final encoded = base64.encode(original);
        final decoded = encoded.decodeSimpleBase64();
        expect(decoded, original);
      });

      test('decodes standard base64 with padding directly', () {
        const encoded = '3q2+7w==';
        final result = encoded.decodeSimpleBase64();
        expect(result, [0xDE, 0xAD, 0xBE, 0xEF]);
      });

      test('decodes standard base64 with forward slashes directly', () {
        const encoded = '//8=';
        final result = encoded.decodeSimpleBase64();
        expect(result, [0xFF, 0xFF]);
      });

      test('throws InvalidTypeException if value is null', () {
        expect(
          () => null.decodeSimpleBase64(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('throws InvalidTypeException for non-base64 content', () {
        expect(
          () => 'not base64!'.decodeSimpleBase64(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('throws InvalidTypeException for percent-encoded base64', () {
        expect(
          () => '3q2%2B7w%3D%3D'.decodeSimpleBase64(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('includes context in error messages', () {
        try {
          null.decodeSimpleBase64(context: 'User.avatar');
          fail('Should have thrown');
        } on InvalidTypeException catch (e) {
          expect(e.context, 'User.avatar');
        }
      });
    });

    group('decodeSimpleNullableBase64', () {
      test('decodes base64 string to List<int>', () {
        const base64String = 'SGVsbG8=';
        final result = base64String.decodeSimpleNullableBase64();
        expect(result, [72, 101, 108, 108, 111]);
      });

      test('returns null for null value', () {
        final result = null.decodeSimpleNullableBase64();
        expect(result, isNull);
      });

      test('returns null for empty string', () {
        final result = ''.decodeSimpleNullableBase64();
        expect(result, isNull);
      });
    });
  });
}
