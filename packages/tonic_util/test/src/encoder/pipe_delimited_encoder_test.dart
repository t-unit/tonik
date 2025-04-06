import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonic_util/src/encoding/delimited_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';

void main() {
  late DelimitedEncoder encoder;

  setUp(() {
    encoder = const DelimitedEncoder();
  });

  group('Pipe Delimited Encoding', () {
    test('encodes String value', () {
      expect(encoder.encodePiped('blue'), ['blue']);
    });

    test('encodes String value with special characters', () {
      expect(encoder.encodePiped('John Doe'), ['John+Doe']);
    });

    test('encodes int value', () {
      expect(encoder.encodePiped(25), ['25']);
    });

    test('encodes double value', () {
      expect(encoder.encodePiped(19.99), ['19.99']);
    });

    test('encodes BigDecimal value', () {
      final bigDecimal = BigDecimal.parse('123456789012345678901234.56789');
      expect(
        encoder.encodePiped(bigDecimal),
        ['123456789012345678901234.56789'],
      );
    });

    test('encodes boolean values', () {
      expect(encoder.encodePiped(true), ['true']);
      expect(encoder.encodePiped(false), ['false']);
    });

    test('encodes Uri value', () {
      final uri = Uri.parse('https://example.com/path?query=value');
      expect(
        encoder.encodePiped(uri),
        ['https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue'],
      );
    });

    test('encodes DateTime value', () {
      final dateTime = DateTime.utc(2023, 5, 15, 12, 30, 45);
      expect(
        encoder.encodePiped(dateTime),
        ['2023-05-15T12%3A30%3A45.000Z'],
      );
    });

    test('encodes null value', () {
      expect(encoder.encodePiped(null), ['']);
    });

    test('encodes List of primitive values with explode=false', () {
      expect(
        encoder.encodePiped(['red', 'green', 'blue']),
        ['red|green|blue'],
      );
    });

    test('encodes List of boolean values with explode=false', () {
      expect(
        encoder.encodePiped([true, false, true]),
        ['true|false|true'],
      );
    });

    test('encodes List with DateTime values with explode=false', () {
      final dateTime1 = DateTime.utc(2023, 5, 15);
      final dateTime2 = DateTime.utc(2023, 6, 20);
      expect(
        encoder.encodePiped([dateTime1, dateTime2]),
        ['2023-05-15T00%3A00%3A00.000Z|2023-06-20T00%3A00%3A00.000Z'],
      );
    });

    test('encodes List with special characters with explode=false', () {
      expect(
        encoder.encodePiped(['item 1', 'item 2']),
        ['item+1|item+2'],
      );
    });

    test('encodes empty List with explode=false', () {
      expect(encoder.encodePiped(<String>[]), ['']);
    });

    test('encodes Set of primitive values with explode=false', () {
      expect(
        encoder.encodePiped({'red', 'green', 'blue'}),
        ['red|green|blue'],
      );
    });

    test('throws exception for Map values', () {
      expect(
        () => encoder.encodePiped({'key': 'value'}),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('throws exception for complex object', () {
      final complexObject = Object();
      expect(
        () => encoder.encodePiped(complexObject),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('throws exception for nested Lists', () {
      expect(
        () => encoder.encodePiped([
          ['nested'],
        ]),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    // Tests for explode functionality
    group('with explode=true', () {
      test('encodes List with explode=true as separate values', () {
        expect(
          encoder.encodePiped(['red', 'green', 'blue'], explode: true),
          ['red', 'green', 'blue'],
        );
      });

      test('encodes List of boolean values with explode=true', () {
        expect(
          encoder.encodePiped([true, false, true], explode: true),
          ['true', 'false', 'true'],
        );
      });

      test('encodes List with DateTime values with explode=true', () {
        final dateTime1 = DateTime.utc(2023, 5, 15);
        final dateTime2 = DateTime.utc(2023, 6, 20);
        expect(
          encoder.encodePiped([dateTime1, dateTime2], explode: true),
          ['2023-05-15T00%3A00%3A00.000Z', '2023-06-20T00%3A00%3A00.000Z'],
        );
      });

      test('encodes List with special characters and explode=true', () {
        expect(
          encoder.encodePiped(['item 1', 'item 2'], explode: true),
          ['item+1', 'item+2'],
        );
      });

      test('encodes empty List with explode=true', () {
        expect(
          encoder.encodePiped(<String>[], explode: true),
          [''],
        );
      });

      test('encodes Set with explode=true as separate values', () {
        // Since a Set's iteration order is not guaranteed, we need to check
        // that all expected values are in the result, not the exact order
        final result = encoder.encodePiped({'red', 'green', 'blue'}, explode: true);
        expect(result.length, 3);
        expect(result, contains('red'));
        expect(result, contains('green'));
        expect(result, contains('blue'));
      });

      test('primitive values with explode=true return a single value', () {
        // For non-collection types, explode parameter should have no effect
        // on the number of elements returned
        expect(encoder.encodePiped('blue', explode: true), ['blue']);
        expect(encoder.encodePiped(25, explode: true), ['25']);
        expect(encoder.encodePiped(null, explode: true), ['']);
      });

      test('throws exception for Map values with explode=true', () {
        expect(
          () => encoder.encodePiped({'key': 'value'}, explode: true),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });
    });

    // Tests for object encoding (Maps)
    group('with objects', () {
      test('throws exception for simple object', () {
        expect(
          () => encoder.encodePiped({'x': 1, 'y': 2}),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for empty object', () {
        expect(
          () => encoder.encodePiped(<String, dynamic>{}),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for object with string values', () {
        expect(
          () => encoder.encodePiped({'name': 'John', 'role': 'admin'}),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for object with special characters', () {
        expect(
          () => encoder.encodePiped({
            'street': '123 Main St',
            'city': 'New York',
          }),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for object with explode=true', () {
        expect(
          () => encoder.encodePiped({'x': 1, 'y': 2}, explode: true),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for nested object', () {
        expect(
          () => encoder.encodePiped({
            'name': 'John',
            'address': {'city': 'NY'},
          }),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });
    });
  });
} 