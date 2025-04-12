import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';
import 'package:tonic_util/src/encoding/label_encoder.dart';

void main() {
  late LabelEncoder encoder;

  setUp(() {
    encoder = const LabelEncoder();
  });

  group('LabelEncoder', () {
    test('encodes String value', () {
      expect(encoder.encode('blue', explode: false, allowEmpty: true), '.blue');
    });

    test('encodes String value with special characters', () {
      expect(
        encoder.encode('John Doe', explode: false, allowEmpty: true),
        '.John%20Doe',
      );
    });

    test('encodes int value', () {
      expect(encoder.encode(25, explode: false, allowEmpty: true), '.25');
    });

    test('encodes double value', () {
      expect(encoder.encode(19.99, explode: false, allowEmpty: true), '.19.99');
    });

    test('encodes boolean values', () {
      expect(encoder.encode(true, explode: false, allowEmpty: true), '.true');
      expect(encoder.encode(false, explode: false, allowEmpty: true), '.false');
    });

    test('encodes BigDecimal value', () {
      final bigDecimal = BigDecimal.parse('123456789012345678901234.56789');
      expect(
        encoder.encode(bigDecimal, explode: false, allowEmpty: true),
        '.123456789012345678901234.56789',
      );
    });

    test('encodes Uri value', () {
      final uri = Uri.parse('https://example.com/path?query=value');
      expect(
        encoder.encode(uri, explode: false, allowEmpty: true),
        '.https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
      );
    });

    test('encodes null value', () {
      expect(encoder.encode(null, explode: false, allowEmpty: true), '.');
    });

    test('encodes List of primitive values', () {
      expect(
        encoder.encode(
          ['red', 'green', 'blue'],
          explode: false,
          allowEmpty: true,
        ),
        '.red,green,blue',
      );
    });

    test('encodes List with special characters', () {
      expect(
        encoder.encode(['item 1', 'item 2'], explode: false, allowEmpty: true),
        '.item%201,item%202',
      );
    });

    test('encodes empty List', () {
      expect(encoder.encode(<String>[], explode: false, allowEmpty: true), '.');
    });

    test('encodes Set of primitive values', () {
      expect(
        encoder.encode(
          {'red', 'green', 'blue'},
          explode: false,
          allowEmpty: true,
        ),
        '.red,green,blue',
      );
    });

    test('supports Map<String, dynamic> values', () {
      expect(
        encoder.encode({'key': 'value'}, explode: false, allowEmpty: true),
        '.key,value',
      );
    });

    test('throws exception for complex object', () {
      final complexObject = Object();
      expect(
        () => encoder.encode(complexObject, explode: false, allowEmpty: true),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('throws exception for nested Lists', () {
      expect(
        () => encoder.encode(
          [
            ['nested'],
          ],
          explode: false,
          allowEmpty: true,
        ),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    // Tests for explode functionality
    group('with explode=true', () {
      test('encodes List with explode=true', () {
        expect(
          encoder.encode(
            ['red', 'green', 'blue'],
            explode: true,
            allowEmpty: true,
          ),
          '.red.green.blue',
        );
      });

      test('encodes List with special characters and explode=true', () {
        expect(
          encoder.encode(['item 1', 'item 2'], explode: true, allowEmpty: true),
          '.item%201.item%202',
        );
      });

      test('encodes empty List with explode=true', () {
        expect(
          encoder.encode(<String>[], explode: true, allowEmpty: true),
          '.', // Empty list with explode should result in a dot
        );
      });

      test('encodes Set with explode=true', () {
        expect(
          encoder.encode(
            {'red', 'green', 'blue'},
            explode: true,
            allowEmpty: true,
          ),
          '.red.green.blue',
        );
      });

      test('primitive values are encoded the same with explode=true', () {
        // For non-collection types, explode parameter should have no effect
        expect(
          encoder.encode('blue', explode: true, allowEmpty: true),
          '.blue',
        );
        expect(encoder.encode(25, explode: true, allowEmpty: true), '.25');
        expect(encoder.encode(null, explode: true, allowEmpty: true), '.');
      });
    });

    // Tests for object encoding (Maps)
    group('with objects', () {
      test('encodes object', () {
        expect(
          encoder.encode({'x': 1, 'y': 2}, explode: false, allowEmpty: true),
          '.x,1,y,2',
        );
      });

      test('encodes empty object', () {
        expect(
          encoder.encode(<String, dynamic>{}, explode: false, allowEmpty: true),
          '.',
        );
      });

      test('encodes object with string values', () {
        expect(
          encoder.encode(
            {'name': 'John', 'role': 'admin'},
            explode: false,
            allowEmpty: true,
          ),
          '.name,John,role,admin',
        );
      });

      test('encodes object with special characters', () {
        expect(
          encoder.encode(
            {'street': '123 Main St', 'city': 'New York'},
            explode: false,
            allowEmpty: true,
          ),
          '.street,123%20Main%20St,city,New%20York',
        );
      });

      test('encodes object with explode=true', () {
        expect(
          encoder.encode({'x': 1, 'y': 2}, explode: true, allowEmpty: true),
          '.x=1.y=2',
        );
      });

      test('throws exception for nested object', () {
        expect(
          () => encoder.encode(
            {
              'name': 'John',
              'address': {'city': 'NY'},
            },
            explode: false,
            allowEmpty: true,
          ),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });
    });
  });
}
