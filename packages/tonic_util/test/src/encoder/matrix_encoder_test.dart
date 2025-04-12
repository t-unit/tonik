import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonic_util/tonic_util.dart';

void main() {
  late MatrixEncoder encoder;

  setUp(() {
    encoder = const MatrixEncoder();
  });

  group('MatrixEncoder', () {
    test('encodes String value', () {
      expect(
        encoder.encode('color', 'blue', explode: false, allowEmpty: true),
        ';color=blue',
      );
    });

    test('encodes String value with special characters', () {
      expect(
        encoder.encode('name', 'John Doe', explode: false, allowEmpty: true),
        ';name=John%20Doe',
      );
    });

    test('encodes int value', () {
      expect(
        encoder.encode('age', 25, explode: false, allowEmpty: true),
        ';age=25',
      );
    });

    test('encodes double value', () {
      expect(
        encoder.encode('price', 19.99, explode: false, allowEmpty: true),
        ';price=19.99',
      );
    });

    test('encodes boolean values', () {
      expect(
        encoder.encode('active', true, explode: false, allowEmpty: true),
        ';active=true',
      );
      expect(
        encoder.encode('premium', false, explode: false, allowEmpty: true),
        ';premium=false',
      );
    });

    test('encodes BigDecimal value', () {
      final bigDecimal = BigDecimal.parse('123456789012345678901234.56789');
      expect(
        encoder.encode('amount', bigDecimal, explode: false, allowEmpty: true),
        ';amount=123456789012345678901234.56789',
      );
    });

    test('encodes Uri value', () {
      final uri = Uri.parse('https://example.com/path?query=value');
      expect(
        encoder.encode('url', uri, explode: false, allowEmpty: true),
        ';url=https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
      );
    });

    test('encodes null value', () {
      expect(
        encoder.encode('nullValue', null, explode: false, allowEmpty: true),
        ';nullValue',
      );
    });

    test('encodes List of primitive values', () {
      expect(
        encoder.encode(
          'colors',
          ['red', 'green', 'blue'],
          explode: false,
          allowEmpty: true,
        ),
        ';colors=red,green,blue',
      );
    });

    test('encodes List with special characters', () {
      expect(
        encoder.encode(
          'items',
          ['item 1', 'item 2'],
          explode: false,
          allowEmpty: true,
        ),
        ';items=item%201,item%202',
      );
    });

    test('encodes empty List', () {
      expect(
        encoder.encode(
          'emptyList',
          <String>[],
          explode: false,
          allowEmpty: true,
        ),
        ';emptyList',
      );
    });

    test('encodes Set of primitive values', () {
      expect(
        encoder.encode(
          'colors',
          {'red', 'green', 'blue'},
          explode: false,
          allowEmpty: true,
        ),
        ';colors=red,green,blue',
      );
    });

    test('supports Map<String, dynamic> values', () {
      expect(
        encoder.encode(
          'map',
          {'key': 'value'},
          explode: false,
          allowEmpty: true,
        ),
        ';map=key,value',
      );
    });

    test('throws exception for complex object', () {
      final complexObject = Object();
      expect(
        () => encoder.encode(
          'complex',
          complexObject,
          explode: false,
          allowEmpty: true,
        ),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('throws exception for nested Lists', () {
      expect(
        () => encoder.encode(
          'nestedList',
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
            'colors',
            ['red', 'green', 'blue'],
            explode: true,
            allowEmpty: true,
          ),
          ';colors=red;colors=green;colors=blue',
        );
      });

      test('encodes List with special characters and explode=true', () {
        expect(
          encoder.encode(
            'items',
            ['item 1', 'item 2'],
            explode: true,
            allowEmpty: true,
          ),
          ';items=item%201;items=item%202',
        );
      });

      test('encodes empty List with explode=true', () {
        expect(
          encoder.encode(
            'emptyList',
            <String>[],
            explode: true,
            allowEmpty: true,
          ),
          ';emptyList',
        );
      });

      test('encodes Set with explode=true', () {
        expect(
          encoder.encode(
            'colors',
            {'red', 'green', 'blue'},
            explode: true,
            allowEmpty: true,
          ),
          ';colors=red;colors=green;colors=blue',
        );
      });

      test('primitive values are encoded the same with explode=true', () {
        // For non-collection types, explode parameter should have no effect
        expect(
          encoder.encode('color', 'blue', explode: true, allowEmpty: true),
          ';color=blue',
        );
        expect(
          encoder.encode('age', 25, explode: true, allowEmpty: true),
          ';age=25',
        );
        expect(
          encoder.encode('nullValue', null, explode: true, allowEmpty: true),
          ';nullValue',
        );
      });
    });

    // Tests for object encoding (Maps)
    group('with objects', () {
      test('encodes object', () {
        expect(
          encoder.encode(
            'point',
            {'x': 1, 'y': 2},
            explode: false,
            allowEmpty: true,
          ),
          ';point=x,1,y,2',
        );
      });

      test('encodes empty object', () {
        expect(
          encoder.encode(
            'obj',
            <String, dynamic>{},
            explode: false,
            allowEmpty: true,
          ),
          ';obj=',
        );
      });

      test('encodes object with string values', () {
        expect(
          encoder.encode(
            'user',
            {'name': 'John', 'role': 'admin'},
            explode: false,
            allowEmpty: true,
          ),
          ';user=name,John,role,admin',
        );
      });

      test('encodes object with special characters', () {
        expect(
          encoder.encode(
            'address',
            {'street': '123 Main St', 'city': 'New York'},
            explode: false,
            allowEmpty: true,
          ),
          ';address=street,123%20Main%20St,city,New%20York',
        );
      });

      test('encodes object with explode=true', () {
        expect(
          encoder.encode(
            'point',
            {'x': 1, 'y': 2},
            explode: true,
            allowEmpty: true,
          ),
          ';point.x=1;point.y=2',
        );
      });

      test('throws exception for nested object', () {
        expect(
          () => encoder.encode(
            'person',
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
