import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

void main() {
  group('UriEncoder', () {
    test('encodes URI values', () {
      final uri = Uri.parse('https://example.com/path?query=value');
      expect(
        uri.uriEncode(allowEmpty: true),
        'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
      );
    });

    test('encodes URI values with allowEmpty false', () {
      final uri = Uri.parse('https://example.com');
      expect(uri.uriEncode(allowEmpty: false), 'https%3A%2F%2Fexample.com');
    });
  });

  group('StringUriEncoder', () {
    test('encodes string values', () {
      expect('hello world'.uriEncode(allowEmpty: true), 'hello%20world');
      expect(
        r'special!@#$%^&*()'.uriEncode(allowEmpty: true),
        'special!%40%23%24%25%5E%26*()',
      );
    });

    test('handles empty strings with allowEmpty true', () {
      expect(''.uriEncode(allowEmpty: true), '');
    });

    test('throws exception for empty strings with allowEmpty false', () {
      expect(
        () => ''.uriEncode(allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes special characters', () {
      expect('a+b=c'.uriEncode(allowEmpty: true), 'a%2Bb%3Dc');
      expect('space here'.uriEncode(allowEmpty: true), 'space%20here');
      expect(
        'unicode: 你好'.uriEncode(allowEmpty: true),
        'unicode%3A%20%E4%BD%A0%E5%A5%BD',
      );
    });
  });

  group('IntUriEncoder', () {
    test('encodes int values', () {
      expect(42.uriEncode(allowEmpty: true), '42');
      expect(0.uriEncode(allowEmpty: true), '0');
      expect((-123).uriEncode(allowEmpty: true), '-123');
    });

    test('encodes int values with allowEmpty false', () {
      expect(42.uriEncode(allowEmpty: false), '42');
    });
  });

  group('DoubleUriEncoder', () {
    test('encodes double values', () {
      expect(3.14.uriEncode(allowEmpty: true), '3.14');
      expect(0.0.uriEncode(allowEmpty: true), '0.0');
      expect((-2.5).uriEncode(allowEmpty: true), '-2.5');
    });

    test('encodes double values with allowEmpty false', () {
      expect(3.14.uriEncode(allowEmpty: false), '3.14');
    });
  });

  group('NumUriEncoder', () {
    test('encodes num values', () {
      expect((42 as num).uriEncode(allowEmpty: true), '42');
      expect((3.14 as num).uriEncode(allowEmpty: true), '3.14');
    });

    test('encodes num values with allowEmpty false', () {
      expect((42 as num).uriEncode(allowEmpty: false), '42');
    });
  });

  group('BoolUriEncoder', () {
    test('encodes bool values', () {
      expect(true.uriEncode(allowEmpty: true), 'true');
      expect(false.uriEncode(allowEmpty: true), 'false');
    });

    test('encodes bool values with allowEmpty false', () {
      expect(true.uriEncode(allowEmpty: false), 'true');
    });
  });

  group('DateTimeUriEncoder', () {
    test('encodes DateTime values', () {
      final dateTime = DateTime(2023, 12, 25, 10, 30, 45);
      final result = dateTime.uriEncode(allowEmpty: true);
      expect(result, contains('2023-12-25T10%3A30%3A45'));
    });

    test('encodes DateTime values with allowEmpty false', () {
      final dateTime = DateTime.utc(2023);
      final result = dateTime.uriEncode(allowEmpty: false);
      expect(result, contains('2023-01-01T00%3A00%3A00'));
    });

    test('encodes DateTime with timezone', () {
      final dateTime = DateTime(2023, 12, 25, 10, 30, 45);
      final result = dateTime.uriEncode(allowEmpty: true);
      expect(result, isA<String>());
      expect(result.length, greaterThan(0));
    });
  });

  group('BigDecimalUriEncoder', () {
    test('encodes BigDecimal values', () {
      final bigDecimal = BigDecimal.parse('123.456');
      expect(bigDecimal.uriEncode(allowEmpty: true), '123.456');
    });

    test('encodes BigDecimal values with allowEmpty false', () {
      final bigDecimal = BigDecimal.parse('0');
      expect(bigDecimal.uriEncode(allowEmpty: false), '0');
    });
  });

  group('StringListUriEncoder', () {
    test('encodes list values', () {
      final list = ['hello', 'world', 'test'];
      expect(list.uriEncode(allowEmpty: true), 'hello,world,test');
    });

    test('encodes list with special characters', () {
      final list = ['hello world', 'test@example.com'];
      expect(
        list.uriEncode(allowEmpty: true),
        'hello%20world,test%40example.com',
      );
    });

    test('handles empty list with allowEmpty true', () {
      final list = <String>[];
      expect(list.uriEncode(allowEmpty: true), '');
    });

    test('throws exception for empty list with allowEmpty false', () {
      final list = <String>[];
      expect(
        () => list.uriEncode(allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes single item list', () {
      final list = ['single'];
      expect(list.uriEncode(allowEmpty: true), 'single');
    });
  });

  group('StringMapUriEncoder', () {
    test('encodes map values', () {
      final map = {'key1': 'value1', 'key2': 'value2'};
      expect(map.uriEncode(allowEmpty: true), 'key1,value1,key2,value2');
    });

    test('encodes map with special characters', () {
      final map = {
        'hello world': 'test@example.com',
        'key': 'value with spaces',
      };
      expect(
        map.uriEncode(allowEmpty: true),
        'hello%20world,test%40example.com,key,value%20with%20spaces',
      );
    });

    test('handles empty map with allowEmpty true', () {
      final map = <String, String>{};
      expect(map.uriEncode(allowEmpty: true), '');
    });

    test('throws exception for empty map with allowEmpty false', () {
      final map = <String, String>{};
      expect(
        () => map.uriEncode(allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes single item map', () {
      final map = {'key': 'value'};
      expect(map.uriEncode(allowEmpty: true), 'key,value');
    });

    test('handles alreadyEncoded parameter', () {
      final map = {'key': 'already%20encoded'};
      expect(
        map.uriEncode(allowEmpty: true, alreadyEncoded: true),
        'key,already%20encoded',
      );
    });

    test('encodes values when alreadyEncoded is false', () {
      final map = {'key': 'not encoded'};
      expect(
        map.uriEncode(allowEmpty: true),
        'key,not%20encoded',
      );
    });
  });
}
