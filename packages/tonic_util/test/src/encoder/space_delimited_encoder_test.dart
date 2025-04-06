import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonic_util/src/encoding/delimited_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';

void main() {
  late DelimitedEncoder encoder;

  setUp(() {
    encoder = const DelimitedEncoder();
  });

  group('Space Delimited Encoding', () {
    test('encodes String value', () {
      expect(encoder.encodeSpaced('blue'), ['blue']);
    });

    test('encodes String value with special characters', () {
      expect(encoder.encodeSpaced('John Doe'), ['John+Doe']);
    });

    test('encodes int value', () {
      expect(encoder.encodeSpaced(25), ['25']);
    });

    test('encodes double value', () {
      expect(encoder.encodeSpaced(19.99), ['19.99']);
    });

    test('encodes BigDecimal value', () {
      final bigDecimal = BigDecimal.parse('123456789012345678901234.56789');
      expect(
        encoder.encodeSpaced(bigDecimal),
        ['123456789012345678901234.56789'],
      );
    });

    test('encodes boolean values', () {
      expect(encoder.encodeSpaced(true), ['true']);
      expect(encoder.encodeSpaced(false), ['false']);
    });

    test('encodes Uri value', () {
      final uri = Uri.parse('https://example.com/path?query=value');
      expect(
        encoder.encodeSpaced(uri),
        ['https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue'],
      );
    });

    test('encodes null value', () {
      expect(encoder.encodeSpaced(null), ['']);
    });

    test('encodes List of primitive values with explode=false', () {
      expect(
        encoder.encodeSpaced(['red', 'green', 'blue']),
        ['red%20green%20blue'],
      );
    });

    test('encodes List of boolean values with explode=false', () {
      expect(
        encoder.encodeSpaced([true, false, true]),
        ['true%20false%20true'],
      );
    });

    test('encodes List with special characters with explode=false', () {
      expect(
        encoder.encodeSpaced(['item 1', 'item 2']),
        ['item+1%20item+2'],
      );
    });

    test('encodes empty List with explode=false', () {
      expect(encoder.encodeSpaced(<String>[]), ['']);
    });

    test('encodes Set of primitive values with explode=false', () {
      expect(
        encoder.encodeSpaced({'red', 'green', 'blue'}),
        ['red%20green%20blue'],
      );
    });

    test('throws exception for Map values', () {
      expect(
        () => encoder.encodeSpaced({'key': 'value'}),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('throws exception for complex object', () {
      final complexObject = Object();
      expect(
        () => encoder.encodeSpaced(complexObject),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('throws exception for nested Lists', () {
      expect(
        () => encoder.encodeSpaced([
          ['nested'],
        ]),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    // Tests for explode functionality
    group('with explode=true', () {
      test('encodes List with explode=true as separate values', () {
        expect(
          encoder.encodeSpaced(['red', 'green', 'blue'], explode: true),
          ['red', 'green', 'blue'],
        );
      });

      test('encodes List of boolean values with explode=true', () {
        expect(
          encoder.encodeSpaced([true, false, true], explode: true),
          ['true', 'false', 'true'],
        );
      });

      test('encodes List with special characters and explode=true', () {
        expect(
          encoder.encodeSpaced(['item 1', 'item 2'], explode: true),
          ['item+1', 'item+2'],
        );
      });

      test('encodes empty List with explode=true', () {
        expect(
          encoder.encodeSpaced(<String>[], explode: true),
          [''],
        );
      });

      test('encodes Set with explode=true as separate values', () {
        // Since a Set's iteration order is not guaranteed, we need to check
        // that all expected values are in the result, not the exact order
        final result = encoder.encodeSpaced({'red', 'green', 'blue'}, explode: true);
        expect(result.length, 3);
        expect(result, contains('red'));
        expect(result, contains('green'));
        expect(result, contains('blue'));
      });

      test('primitive values with explode=true return a single value', () {
        // For non-collection types, explode parameter should have no effect
        // on the number of elements returned
        expect(encoder.encodeSpaced('blue', explode: true), ['blue']);
        expect(encoder.encodeSpaced(25, explode: true), ['25']);
        expect(encoder.encodeSpaced(null, explode: true), ['']);
      });

      test('throws exception for Map values with explode=true', () {
        expect(
          () => encoder.encodeSpaced({'key': 'value'}, explode: true),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });
    });

    // Tests for object encoding (Maps)
    group('with objects', () {
      test('throws exception for simple object', () {
        expect(
          () => encoder.encodeSpaced({'x': 1, 'y': 2}),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for empty object', () {
        expect(
          () => encoder.encodeSpaced(<String, dynamic>{}),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for object with string values', () {
        expect(
          () => encoder.encodeSpaced({'name': 'John', 'role': 'admin'}),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for object with special characters', () {
        expect(
          () => encoder.encodeSpaced({
            'street': '123 Main St',
            'city': 'New York',
          }),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for object with explode=true', () {
        expect(
          () => encoder.encodeSpaced({'x': 1, 'y': 2}, explode: true),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for nested object', () {
        expect(
          () => encoder.encodeSpaced({
            'name': 'John',
            'address': {'city': 'NY'},
          }),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });
    });
  });
} 