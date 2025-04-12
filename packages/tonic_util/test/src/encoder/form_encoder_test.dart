import 'package:test/test.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';
import 'package:tonic_util/src/encoding/form_encoder.dart';

void main() {
  late FormEncoder encoder;

  setUp(() {
    encoder = const FormEncoder();
  });

  group('FormEncoder', () {
    test('encodes String value', () {
      expect(
        encoder.encode('color', 'blue', explode: false, allowEmpty: true),
        {'color': 'blue'},
      );
    });

    test('encodes String value with special characters', () {
      expect(
        encoder.encode('name', 'John Doe', explode: false, allowEmpty: true),
        {'name': 'John+Doe'},
      );
    });

    test('encodes int value', () {
      expect(encoder.encode('age', 25, explode: false, allowEmpty: true), {
        'age': '25',
      });
    });

    test('encodes double value', () {
      expect(encoder.encode('price', 19.99, explode: false, allowEmpty: true), {
        'price': '19.99',
      });
    });

    test('encodes boolean values', () {
      expect(encoder.encode('active', true, explode: false, allowEmpty: true), {
        'active': 'true',
      });
      expect(
        encoder.encode('active', false, explode: false, allowEmpty: true),
        {'active': 'false'},
      );
    });

    group('empty value handling', () {
      test('encodes null value when allowEmpty is true', () {
        expect(
          encoder.encode('param', null, explode: false, allowEmpty: true),
          {'param': ''},
        );
      });

      test('throws when null value and allowEmpty is false', () {
        expect(
          () =>
              encoder.encode('param', null, explode: false, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('throws when empty string and allowEmpty is false', () {
        expect(
          () => encoder.encode('param', '', explode: false, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('encodes empty string when allowEmpty is true', () {
        expect(encoder.encode('param', '', explode: false, allowEmpty: true), {
          'param': '',
        });
      });

      test('throws when empty List and allowEmpty is false', () {
        expect(
          () => encoder.encode(
            'param',
            <String>[],
            explode: false,
            allowEmpty: false,
          ),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('encodes empty List when allowEmpty is true', () {
        expect(
          encoder.encode('param', <String>[], explode: false, allowEmpty: true),
          {'param': ''},
        );
      });

      test('throws when empty Set and allowEmpty is false', () {
        expect(
          () => encoder.encode(
            'param',
            <String>{},
            explode: false,
            allowEmpty: false,
          ),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('encodes empty Set when allowEmpty is true', () {
        expect(
          encoder.encode('param', <String>{}, explode: false, allowEmpty: true),
          {'param': ''},
        );
      });

      test('throws when empty Map and allowEmpty is false', () {
        expect(
          () => encoder.encode(
            'param',
            <String, dynamic>{},
            explode: false,
            allowEmpty: false,
          ),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('encodes empty Map when allowEmpty is true', () {
        expect(
          encoder.encode(
            'param',
            <String, dynamic>{},
            explode: false,
            allowEmpty: true,
          ),
          {'param': ''},
        );
      });
    });

    test('encodes List of primitive values', () {
      expect(
        encoder.encode(
          'colors',
          ['red', 'green', 'blue'],
          explode: false,
          allowEmpty: true,
        ),
        {'colors': 'red,green,blue'},
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
        {'items': 'item+1,item+2'},
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
        {'colors': 'red,green,blue'},
      );
    });

    test('supports Map<String, dynamic> values', () {
      expect(
        encoder.encode(
          'param',
          {'key': 'value'},
          explode: false,
          allowEmpty: true,
        ),
        {'param': 'key,value'},
      );
    });

    test('throws exception for complex object', () {
      final complexObject = Object();
      expect(
        () => encoder.encode(
          'param',
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
          'param',
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
          {
            'colors': ['red', 'green', 'blue'],
          },
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
          {
            'items': ['item+1', 'item+2'],
          },
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
          {
            'colors': ['red', 'green', 'blue'],
          },
        );
      });

      test('primitive values are encoded the same with explode=true', () {
        expect(
          encoder.encode('color', 'blue', explode: true, allowEmpty: true),
          {'color': 'blue'},
        );
        expect(encoder.encode('age', 25, explode: true, allowEmpty: true), {
          'age': '25',
        });
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
          {'point': 'x,1,y,2'},
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
          {'user': 'name,John,role,admin'},
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
          {'address': 'street,123+Main+St,city,New+York'},
        );
      });

      test('encodes object with explode=true', () {
        expect(
          encoder.encode(
            'user',
            {'role': 'admin', 'firstName': 'Alex'},
            explode: true,
            allowEmpty: true,
          ),
          {'role': 'admin', 'firstName': 'Alex'},
        );
      });

      test('throws exception for nested object', () {
        expect(
          () => encoder.encode(
            'user',
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
