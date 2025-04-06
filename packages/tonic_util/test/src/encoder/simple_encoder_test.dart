import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';
import 'package:tonic_util/src/encoding/simple_encoder.dart';

void main() {
  late SimpleEncoder encoder;

  setUp(() {
    encoder = const SimpleEncoder();
  });

  group('SimpleEncoder', () {
    test('encodes String value', () {
      expect(encoder.encode('blue'), 'blue');
    });

    test('encodes String value with special characters', () {
      expect(encoder.encode('John Doe'), 'John%20Doe');
    });

    test('encodes int value', () {
      expect(encoder.encode(25), '25');
    });

    test('encodes double value', () {
      expect(encoder.encode(19.99), '19.99');
    });

    test('encodes boolean values', () {
      expect(encoder.encode(true), 'true');
      expect(encoder.encode(false), 'false');
    });

    test('encodes BigDecimal value', () {
      final bigDecimal = BigDecimal.parse('123456789012345678901234.56789');
      expect(
        encoder.encode(bigDecimal),
        '123456789012345678901234.56789',
      );
    });

    test('encodes Uri value', () {
      final uri = Uri.parse('https://example.com/path?query=value');
      expect(
        encoder.encode(uri),
        'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
      );
    });

    test('encodes null value', () {
      expect(encoder.encode(null), '');
    });

    test('encodes List of primitive values', () {
      expect(
        encoder.encode(['red', 'green', 'blue']),
        'red,green,blue',
      );
    });

    test('encodes List with special characters', () {
      expect(
        encoder.encode(['item 1', 'item 2']),
        'item%201,item%202',
      );
    });

    test('encodes empty List', () {
      expect(encoder.encode(<String>[]), '');
    });

    test('encodes Set of primitive values', () {
      expect(
        encoder.encode({'red', 'green', 'blue'}),
        'red,green,blue',
      );
    });

    test('supports Map<String, dynamic> values', () {
      expect(encoder.encode({'key': 'value'}), 'key,value');
    });

    test('throws exception for complex object', () {
      final complexObject = Object();
      expect(
        () => encoder.encode(complexObject),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('throws exception for nested Lists', () {
      expect(
        () => encoder.encode([
          ['nested'],
        ]),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    // Tests for explode functionality
    group('with explode=true', () {
      test('encodes List with explode=true', () {
        expect(
          encoder.encode(['red', 'green', 'blue'], explode: true),
          'red,green,blue', // Same as explode=false for SimpleEncoder
        );
      });

      test('encodes List with special characters and explode=true', () {
        expect(
          encoder.encode(['item 1', 'item 2'], explode: true),
          'item%201,item%202',
        );
      });

      test('encodes empty List with explode=true', () {
        expect(
          encoder.encode(<String>[], explode: true),
          '',
        );
      });

      test('encodes Set with explode=true', () {
        expect(
          encoder.encode({'red', 'green', 'blue'}, explode: true),
          'red,green,blue',
        );
      });

      test('primitive values are encoded the same with explode=true', () {
        // For non-collection types, explode parameter should have no effect
        expect(encoder.encode('blue', explode: true), 'blue');
        expect(encoder.encode(25, explode: true), '25');
        expect(encoder.encode(null, explode: true), '');
      });
    });

    // Tests for object encoding (Maps)
    group('with objects', () {
      test('encodes object', () {
        expect(encoder.encode({'x': 1, 'y': 2}), 'x,1,y,2');
      });

      test('encodes empty object', () {
        expect(encoder.encode(<String, dynamic>{}), '');
      });

      test('encodes object with string values', () {
        expect(
          encoder.encode({'name': 'John', 'role': 'admin'}),
          'name,John,role,admin',
        );
      });

      test('encodes object with special characters', () {
        expect(
          encoder.encode({
            'street': '123 Main St',
            'city': 'New York',
          }),
          'street,123%20Main%20St,city,New%20York',
        );
      });

      test('encodes object with explode=true', () {
        expect(
          encoder.encode({'x': 1, 'y': 2}, explode: true),
          'x=1,y=2',
        );
      });

      test('throws exception for nested object', () {
        expect(
          () => encoder.encode({
            'name': 'John',
            'address': {'city': 'NY'},
          }),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });
    });
  });
} 
