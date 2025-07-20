import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:tonik_util/src/date.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';
import 'package:tonik_util/src/decoding/simple_decoder.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
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
        // Test UTC parsing
        final utcDate = DateTime.utc(2024, 3, 14, 10, 30, 45);
        const utcString = '2024-03-14T10:30:45Z';
        final utcResult = utcString.decodeSimpleDateTime();
        expect(utcResult.isUtc, isTrue);
        expect(utcResult, utcDate);

        // Test local time parsing
        const localString = '2024-03-14T10:30:45';
        final localResult = localString.decodeSimpleDateTime();
        final expectedLocal = DateTime(2024, 3, 14, 10, 30, 45);
        expect(localResult.isUtc, isFalse);
        expect(localResult, expectedLocal);

        // Test timezone offset parsing
        const offsetString = '2024-03-14T10:30:45+05:00';
        final offsetResult = offsetString.decodeSimpleDateTime();
        expect(offsetResult, isA<tz.TZDateTime>());
        expect(offsetResult.timeZoneOffset.inHours, 5);

        // Test error cases
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
        expect('ftp://files.example.com/file.txt'.decodeSimpleUri(),
               Uri.parse('ftp://files.example.com/file.txt'));
        expect('/relative/path'.decodeSimpleUri(), Uri.parse('/relative/path'));
        expect('mailto:user@example.com'.decodeSimpleUri(),
               Uri.parse('mailto:user@example.com'));
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

    group('Escaping and percent-encoding', () {
      test('decodeSimpleString decodes percent-encoded comma', () {
        expect('foo%2Cbar'.decodeSimpleString(), 'foo,bar');
      });

      test('decodeSimpleNullableString decodes percent-encoded comma', () {
        expect('foo%2Cbar'.decodeSimpleNullableString(), 'foo,bar');
        expect(''.decodeSimpleNullableString(), isNull);
        expect((null as String?).decodeSimpleNullableString(), isNull);
      });

      test(
        'decodeSimpleStringList splits only on unescaped commas and decodes',
        () {
          expect('foo,bar%2Cbaz,,qux'.decodeSimpleStringList(), [
            'foo',
            'bar,baz',
            '',
            'qux',
          ]);
          expect('foo%2Cbar'.decodeSimpleStringList(), ['foo,bar']);
          expect(''.decodeSimpleStringList(), isEmpty);
        },
      );

      test('decodeSimpleNullableStringList splits and decodes', () {
        expect('foo,bar%2Cbaz,,qux'.decodeSimpleNullableStringList(), [
          'foo',
          'bar,baz',
          '',
          'qux',
        ]);
        expect(''.decodeSimpleNullableStringList(), isNull);
        expect((null as String?).decodeSimpleNullableStringList(), isNull);
      });

      test('decodeSimpleStringNullableList splits, decodes, and converts empty '
          'to null', () {
        expect('foo,bar%2Cbaz,,qux'.decodeSimpleStringNullableList(), [
          'foo',
          'bar,baz',
          null,
          'qux',
        ]);
        expect('foo%2Cbar'.decodeSimpleStringNullableList(), ['foo,bar']);
        expect(''.decodeSimpleStringNullableList(), isEmpty);
      });

      test(
        'decodeSimpleNullableStringNullableList splits, decodes, and converts '
        'empty to null',
        () {
          expect(
            'foo,bar%2Cbaz,,qux'.decodeSimpleNullableStringNullableList(),
            ['foo', 'bar,baz', null, 'qux'],
          );
          expect(''.decodeSimpleNullableStringNullableList(), isNull);
          expect(
            (null as String?).decodeSimpleNullableStringNullableList(),
            isNull,
          );
        },
      );
    });
  });
}
