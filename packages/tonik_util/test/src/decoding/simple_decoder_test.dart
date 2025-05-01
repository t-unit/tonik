import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
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

      test('decodes DateTime values', () {
        final date = DateTime.utc(2024, 3, 14);
        expect(date.toIso8601String().decodeSimpleDateTime(), date);
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
    });

    group('Nullable Values', () {
      test('handles empty strings and null for nullable types', () {
        expect(''.decodeSimpleNullableInt(), isNull);
        expect(''.decodeSimpleNullableDouble(), isNull);
        expect(''.decodeSimpleNullableBool(), isNull);
        expect(''.decodeSimpleNullableDateTime(), isNull);
        expect(''.decodeSimpleNullableBigDecimal(), isNull);

        expect(null.decodeSimpleNullableInt(), isNull);
        expect(null.decodeSimpleNullableDouble(), isNull);
        expect(null.decodeSimpleNullableBool(), isNull);
        expect(null.decodeSimpleNullableDateTime(), isNull);
        expect(null.decodeSimpleNullableBigDecimal(), isNull);
      });

      test('decodes non-empty strings for nullable types', () {
        expect('123'.decodeSimpleNullableInt(), 123);
        expect('3.14'.decodeSimpleNullableDouble(), 3.14);
        expect('true'.decodeSimpleNullableBool(), isTrue);
        expect(
          '2024-03-14T00:00:00.000Z'.decodeSimpleNullableDateTime(),
          DateTime.utc(2024, 3, 14),
        );
        expect(
          '3.14'.decodeSimpleNullableBigDecimal(),
          BigDecimal.parse('3.14'),
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

      test('decodes string sets', () {
        // Set<String>
        expect('a,b,c,b'.decodeSimpleStringSet(), {'a', 'b', 'c'});
        expect(''.decodeSimpleStringSet(), isEmpty);
        expect(
          () => null.decodeSimpleStringSet(),
          throwsA(isA<InvalidTypeException>()),
        );

        // Set<String>?
        expect('a,b,c,b'.decodeSimpleNullableStringSet(), {'a', 'b', 'c'});
        expect(''.decodeSimpleNullableStringSet(), null);
        expect(null.decodeSimpleNullableStringSet(), null);

        // Set<String?>
        expect('a,b,c,b'.decodeSimpleStringNullableSet(), {'a', 'b', 'c'});
        expect('a,,c,'.decodeSimpleStringNullableSet(), {'a', null, 'c'});
        expect(''.decodeSimpleStringNullableSet(), isEmpty);
        expect(
          () => null.decodeSimpleStringNullableSet(),
          throwsA(isA<InvalidTypeException>()),
        );

        // Set<String?>?
        expect('a,b,c,b'.decodeSimpleNullableStringNullableSet(), {
          'a',
          'b',
          'c',
        });
        expect('a,,c,'.decodeSimpleNullableStringNullableSet(), {
          'a',
          null,
          'c',
        });
        expect(''.decodeSimpleNullableStringNullableSet(), null);
        expect(null.decodeSimpleNullableStringNullableSet(), null);
      });
    });

    group('String', () {
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
    });

    group('Int', () {
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
  });
}
