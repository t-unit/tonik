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

  group('allowReserved', () {
    const allReserved = r":/?#[]@!$&'()*+,;=";

    test('keeps the reserved set literal except & = + and [ ]', () {
      expect(
        allReserved.uriEncode(allowEmpty: true, allowReserved: true),
        r":/?#%5B%5D@!$%26'()*%2B,;%3D",
      );
    });

    test('still encodes space, percent, delimiters and non-ASCII', () {
      expect('a b'.uriEncode(allowEmpty: true, allowReserved: true), 'a%20b');
      expect('a%b'.uriEncode(allowEmpty: true, allowReserved: true), 'a%25b');
      expect('a+b'.uriEncode(allowEmpty: true, allowReserved: true), 'a%2Bb');
      expect('a&b'.uriEncode(allowEmpty: true, allowReserved: true), 'a%26b');
      expect('a=b'.uriEncode(allowEmpty: true, allowReserved: true), 'a%3Db');
      expect(
        '你好'.uriEncode(allowEmpty: true, allowReserved: true),
        '%E4%BD%A0%E5%A5%BD',
      );
    });

    test('false is byte-identical to Uri.encodeComponent', () {
      const inputs = [allReserved, 'a b', 'a+b c', 'a%b', '你好'];
      for (final input in inputs) {
        expect(
          input.uriEncode(allowEmpty: true),
          Uri.encodeComponent(input),
        );
      }
    });

    test('false is byte-identical to Uri.encodeQueryComponent', () {
      const inputs = [allReserved, 'a b', 'a+b c', 'a%b', '你好'];
      for (final input in inputs) {
        expect(
          input.uriEncode(allowEmpty: true, useQueryComponent: true),
          Uri.encodeQueryComponent(input),
        );
      }
    });

    test('composes with useQueryComponent rendering space as +', () {
      expect(
        'a b'.uriEncode(
          allowEmpty: true,
          useQueryComponent: true,
          allowReserved: true,
        ),
        'a+b',
      );
      expect(
        'a+b c'.uriEncode(
          allowEmpty: true,
          useQueryComponent: true,
          allowReserved: true,
        ),
        'a%2Bb+c',
      );
      expect(
        'a&b=c'.uriEncode(
          allowEmpty: true,
          useQueryComponent: true,
          allowReserved: true,
        ),
        'a%26b%3Dc',
      );
    });

    test(
      'query mode escapes a literal percent so %20-looking input is not '
      'collapsed to a space',
      () {
        expect(
          'a%20b'.uriEncode(
            allowEmpty: true,
            useQueryComponent: true,
            allowReserved: true,
          ),
          'a%2520b',
        );
      },
    );

    test('Uri keeps reserved chars literal under allowReserved', () {
      final uri = Uri.parse('https://x.com/p?a=1&b=2');
      expect(
        uri.uriEncode(allowEmpty: true, allowReserved: true),
        'https://x.com/p?a%3D1%26b%3D2',
      );
      expect(
        uri.uriEncode(allowEmpty: true),
        Uri.encodeComponent(uri.toString()),
      );
    });

    test('DateTime keeps colons literal under allowReserved', () {
      final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
      final iso = dateTime.toIso8601String();
      expect(
        dateTime.uriEncode(allowEmpty: true, allowReserved: true),
        iso,
      );
      expect(
        dateTime.uriEncode(allowEmpty: true),
        Uri.encodeComponent(iso),
      );
    });

    test('binary keeps reserved chars literal under allowReserved', () {
      const value = [97, 58, 98, 32, 99]; // "a:b c"
      expect(
        value.uriEncode(allowEmpty: true, allowReserved: true),
        'a:b%20c',
      );
      expect(
        value.uriEncode(allowEmpty: true),
        Uri.encodeComponent('a:b c'),
      );
    });

    test('double routes through the helper, encoding + in its toString', () {
      expect(
        1e21.uriEncode(allowEmpty: false, allowReserved: true),
        '1e%2B21',
      );
    });

    test('numeric and bool types accept the flag as a no-op', () {
      expect(42.uriEncode(allowEmpty: true, allowReserved: true), '42');
      expect(
        (3.14 as num).uriEncode(allowEmpty: true, allowReserved: true),
        '3.14',
      );
      expect(3.14.uriEncode(allowEmpty: true, allowReserved: true), '3.14');
      expect(true.uriEncode(allowEmpty: true, allowReserved: true), 'true');
      expect(
        BigDecimal.parse('123.456')
            .uriEncode(allowEmpty: true, allowReserved: true),
        '123.456',
      );
    });
  });
}
