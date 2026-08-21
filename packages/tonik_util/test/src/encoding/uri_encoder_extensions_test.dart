import 'dart:convert';

import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  group('UriEncoder', () {
    test('encodes URI values', () {
      final uri = Uri.parse('https://example.com/path?query=value');
      expect(
        uri.uriEncode(allowEmpty: true, textEncoding: utf8),
        'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
      );
    });

    test('encodes URI values with allowEmpty false', () {
      final uri = Uri.parse('https://example.com');
      expect(
        uri.uriEncode(allowEmpty: false, textEncoding: utf8),
        'https%3A%2F%2Fexample.com',
      );
    });
  });

  group('StringUriEncoder', () {
    test('encodes string values', () {
      expect(
        'hello world'.uriEncode(allowEmpty: true, textEncoding: utf8),
        'hello%20world',
      );
      expect(
        r'special!@#$%^&*()'.uriEncode(allowEmpty: true, textEncoding: utf8),
        'special!%40%23%24%25%5E%26*()',
      );
    });

    test('encodes empty string as empty regardless of allowEmpty', () {
      expect(''.uriEncode(allowEmpty: true, textEncoding: utf8), '');
      expect(''.uriEncode(allowEmpty: false, textEncoding: utf8), '');
    });

    test('encodes special characters', () {
      expect(
        'a+b=c'.uriEncode(allowEmpty: true, textEncoding: utf8),
        'a%2Bb%3Dc',
      );
      expect(
        'space here'.uriEncode(allowEmpty: true, textEncoding: utf8),
        'space%20here',
      );
      expect(
        'unicode: 你好'.uriEncode(allowEmpty: true, textEncoding: utf8),
        'unicode%3A%20%E4%BD%A0%E5%A5%BD',
      );
    });
  });

  group('IntUriEncoder', () {
    test('encodes int values', () {
      expect(42.uriEncode(allowEmpty: true, textEncoding: utf8), '42');
      expect(0.uriEncode(allowEmpty: true, textEncoding: utf8), '0');
      expect((-123).uriEncode(allowEmpty: true, textEncoding: utf8), '-123');
    });

    test('encodes int values with allowEmpty false', () {
      expect(42.uriEncode(allowEmpty: false, textEncoding: utf8), '42');
    });
  });

  group('DoubleUriEncoder', () {
    test('encodes double values', () {
      expect(3.14.uriEncode(allowEmpty: true, textEncoding: utf8), '3.14');
      expect(0.0.uriEncode(allowEmpty: true, textEncoding: utf8), '0.0');
      expect((-2.5).uriEncode(allowEmpty: true, textEncoding: utf8), '-2.5');
    });

    test('encodes double values with allowEmpty false', () {
      expect(3.14.uriEncode(allowEmpty: false, textEncoding: utf8), '3.14');
    });
  });

  group('NumUriEncoder', () {
    test('encodes num values', () {
      expect((42 as num).uriEncode(allowEmpty: true, textEncoding: utf8), '42');
      expect(
        (3.14 as num).uriEncode(allowEmpty: true, textEncoding: utf8),
        '3.14',
      );
    });

    test('percent-encodes plus in a positive exponent', () {
      const num value = 6.022e23;

      expect(
        value.uriEncode(allowEmpty: true, textEncoding: utf8),
        '6.022e%2B23',
      );
      expect(
        value.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        '6.022e%2B23',
      );
    });

    test('encodes num values with allowEmpty false', () {
      expect(
        (42 as num).uriEncode(allowEmpty: false, textEncoding: utf8),
        '42',
      );
    });
  });

  group('BoolUriEncoder', () {
    test('encodes bool values', () {
      expect(true.uriEncode(allowEmpty: true, textEncoding: utf8), 'true');
      expect(false.uriEncode(allowEmpty: true, textEncoding: utf8), 'false');
    });

    test('encodes bool values with allowEmpty false', () {
      expect(true.uriEncode(allowEmpty: false, textEncoding: utf8), 'true');
    });
  });

  group('DateTimeUriEncoder', () {
    test('encodes DateTime values', () {
      final dateTime = DateTime(2023, 12, 25, 10, 30, 45);
      final result = dateTime.uriEncode(allowEmpty: true, textEncoding: utf8);
      expect(result, contains('2023-12-25T10%3A30%3A45'));
    });

    test('encodes DateTime values with allowEmpty false', () {
      final dateTime = DateTime.utc(2023);
      final result = dateTime.uriEncode(allowEmpty: false, textEncoding: utf8);
      expect(result, contains('2023-01-01T00%3A00%3A00'));
    });

    test('encodes DateTime with timezone', () {
      final dateTime = DateTime(2023, 12, 25, 10, 30, 45);
      final result = dateTime.uriEncode(allowEmpty: true, textEncoding: utf8);
      expect(result, isA<String>());
      expect(result.length, greaterThan(0));
    });
  });

  group('BigDecimalUriEncoder', () {
    test('encodes BigDecimal values', () {
      final bigDecimal = BigDecimal.parse('123.456');
      expect(
        bigDecimal.uriEncode(allowEmpty: true, textEncoding: utf8),
        '123.456',
      );
    });

    test('percent-encodes plus in a positive exponent', () {
      final value = BigDecimal.parse('1.23E+10');

      expect(
        value.uriEncode(allowEmpty: true, textEncoding: utf8),
        '1.23e%2B10',
      );
      expect(
        value.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        '1.23e%2B10',
      );
    });

    test('encodes BigDecimal values with allowEmpty false', () {
      final bigDecimal = BigDecimal.parse('0');
      expect(bigDecimal.uriEncode(allowEmpty: false, textEncoding: utf8), '0');
    });
  });

  group('StringListUriEncoder', () {
    test('encodes list values', () {
      final list = ['hello', 'world', 'test'];
      expect(
        list.uriEncode(allowEmpty: true, textEncoding: utf8),
        'hello,world,test',
      );
    });

    test('encodes list with special characters', () {
      final list = ['hello world', 'test@example.com'];
      expect(
        list.uriEncode(allowEmpty: true, textEncoding: utf8),
        'hello%20world,test%40example.com',
      );
    });

    test('handles empty list with allowEmpty true', () {
      final list = <String>[];
      expect(list.uriEncode(allowEmpty: true, textEncoding: utf8), '');
    });

    test('throws exception for empty list with allowEmpty false', () {
      final list = <String>[];
      expect(
        () => list.uriEncode(allowEmpty: false, textEncoding: utf8),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes single item list', () {
      final list = ['single'];
      expect(list.uriEncode(allowEmpty: true, textEncoding: utf8), 'single');
    });

    test('encodes an empty item as an empty comma-joined segment', () {
      expect(['', 'a'].uriEncode(allowEmpty: true, textEncoding: utf8), ',a');
    });
  });

  group('StringMapUriEncoder', () {
    test('encodes map values', () {
      final map = {'key1': 'value1', 'key2': 'value2'};
      expect(
        map.uriEncode(allowEmpty: true, textEncoding: utf8),
        'key1,value1,key2,value2',
      );
    });

    test('encodes map with special characters', () {
      final map = {
        'hello world': 'test@example.com',
        'key': 'value with spaces',
      };
      expect(
        map.uriEncode(allowEmpty: true, textEncoding: utf8),
        'hello%20world,test%40example.com,key,value%20with%20spaces',
      );
    });

    test('handles empty map with allowEmpty true', () {
      final map = <String, String>{};
      expect(map.uriEncode(allowEmpty: true, textEncoding: utf8), '');
    });

    test('throws exception for empty map with allowEmpty false', () {
      final map = <String, String>{};
      expect(
        () => map.uriEncode(allowEmpty: false, textEncoding: utf8),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes single item map', () {
      final map = {'key': 'value'};
      expect(map.uriEncode(allowEmpty: true, textEncoding: utf8), 'key,value');
    });

    test('handles alreadyEncoded parameter', () {
      final map = {'key': 'already%20encoded'};
      expect(
        map.uriEncode(
          allowEmpty: true,
          alreadyEncoded: true,
          textEncoding: utf8,
        ),
        'key,already%20encoded',
      );
    });

    test('encodes values when alreadyEncoded is false', () {
      final map = {'key': 'not encoded'};
      expect(
        map.uriEncode(allowEmpty: true, textEncoding: utf8),
        'key,not%20encoded',
      );
    });

    test('encodes an empty value as an empty comma-joined segment', () {
      expect(
        {'k': '', 'a': 'b'}.uriEncode(allowEmpty: true, textEncoding: utf8),
        'k,,a,b',
      );
    });

    test('encodes an empty key as an empty comma-joined segment', () {
      expect(
        {'': 'v', 'a': 'b'}.uriEncode(allowEmpty: true, textEncoding: utf8),
        ',v,a,b',
      );
    });
  });

  group('allowReserved', () {
    const allReserved = r":/?#[]@!$&'()*+,;=";

    test('keeps the reserved set literal except & = +', () {
      expect(
        allReserved.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        r":/?#[]@!$%26'()*%2B,;%3D",
      );
    });

    test('still encodes space, percent, delimiters and non-ASCII', () {
      expect(
        'a b'.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a%20b',
      );
      expect(
        'a%b'.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a%25b',
      );
      expect(
        'a+b'.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a%2Bb',
      );
      expect(
        'a&b'.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a%26b',
      );
      expect(
        'a=b'.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a%3Db',
      );
      expect(
        '你好'.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        '%E4%BD%A0%E5%A5%BD',
      );
    });

    test('false is byte-identical to Uri.encodeComponent', () {
      const inputs = [allReserved, 'a b', 'a+b c', 'a%b', '你好'];
      for (final input in inputs) {
        expect(
          input.uriEncode(allowEmpty: true, textEncoding: utf8),
          Uri.encodeComponent(input),
        );
      }
    });

    test('false is byte-identical to Uri.encodeQueryComponent', () {
      const inputs = [allReserved, 'a b', 'a+b c', 'a%b', '你好'];
      for (final input in inputs) {
        expect(
          input.uriEncode(
            allowEmpty: true,
            useQueryComponent: true,
            textEncoding: utf8,
          ),
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
          textEncoding: utf8,
        ),
        'a+b',
      );
      expect(
        'a+b c'.uriEncode(
          allowEmpty: true,
          useQueryComponent: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a%2Bb+c',
      );
      expect(
        'a&b=c'.uriEncode(
          allowEmpty: true,
          useQueryComponent: true,
          allowReserved: true,
          textEncoding: utf8,
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
            textEncoding: utf8,
          ),
          'a%2520b',
        );
      },
    );

    test('a literal percent sequence is not decoded back into a bracket', () {
      expect(
        '%5B'.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        '%255B',
      );
      expect(
        'a%5Bb'.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a%255Bb',
      );
    });

    test('Uri keeps reserved chars literal under allowReserved', () {
      final uri = Uri.parse('https://x.com/p?a=1&b=2');
      expect(
        uri.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'https://x.com/p?a%3D1%26b%3D2',
      );
      expect(
        uri.uriEncode(allowEmpty: true, textEncoding: utf8),
        Uri.encodeComponent(uri.toString()),
      );
    });

    test('DateTime keeps colons literal under allowReserved', () {
      final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
      final iso = dateTime.toIso8601String();
      expect(
        dateTime.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        iso,
      );
      expect(
        dateTime.uriEncode(allowEmpty: true, textEncoding: utf8),
        Uri.encodeComponent(iso),
      );
    });

    test('binary keeps reserved chars literal under allowReserved', () {
      const value = [97, 58, 98, 32, 99]; // "a:b c"
      expect(
        value.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a:b%20c',
      );
      expect(
        value.uriEncode(allowEmpty: true, textEncoding: utf8),
        Uri.encodeComponent('a:b c'),
      );
    });

    test('double routes through the helper, encoding + in its toString', () {
      expect(
        1e21.uriEncode(
          allowEmpty: false,
          allowReserved: true,
          textEncoding: utf8,
        ),
        '1e%2B21',
      );
    });

    test('numeric and bool safe values are unchanged', () {
      expect(
        42.uriEncode(allowEmpty: true, allowReserved: true, textEncoding: utf8),
        '42',
      );
      expect(
        (3.14 as num).uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        '3.14',
      );
      expect(
        3.14.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        '3.14',
      );
      expect(
        true.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'true',
      );
      expect(
        BigDecimal.parse(
          '123.456',
        ).uriEncode(allowEmpty: true, allowReserved: true, textEncoding: utf8),
        '123.456',
      );
    });

    test('list keeps reserved chars literal but encodes & = + per item', () {
      expect(
        ['a:b', 'c&d', 'e=f', 'g+h'].uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a:b,c%26d,e%3Df,g%2Bh',
      );
    });

    test('list default is byte-identical to encodeComponent per item', () {
      const items = ['a:b', 'c&d', 'e=f', 'g+h', 'i j'];
      expect(
        items.uriEncode(allowEmpty: true, textEncoding: utf8),
        items.map(Uri.encodeComponent).join(','),
      );
    });

    test(
      'list alreadyEncoded short-circuit is identical with/without flag',
      () {
        const items = ['a:b', 'c&d'];
        final without = items.uriEncode(
          allowEmpty: true,
          alreadyEncoded: true,
          textEncoding: utf8,
        );
        final with_ = items.uriEncode(
          allowEmpty: true,
          alreadyEncoded: true,
          allowReserved: true,
          textEncoding: utf8,
        );
        expect(without, 'a:b,c&d');
        expect(with_, without);
      },
    );

    test('map keeps reserved chars literal but encodes & = + in keys and '
        'values', () {
      expect(
        {'a&b': 'c=d', 'e:f': 'g+h'}.uriEncode(
          allowEmpty: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a%26b,c%3Dd,e:f,g%2Bh',
      );
    });

    test('map default is byte-identical to encodeComponent per key/value', () {
      const map = {'a&b': 'c:d', 'e=f': 'g+h'};
      expect(
        map.uriEncode(allowEmpty: true, textEncoding: utf8),
        map.entries
            .expand(
              (e) => [Uri.encodeComponent(e.key), Uri.encodeComponent(e.value)],
            )
            .join(','),
      );
    });

    test('map alreadyEncoded short-circuit is identical with/without flag', () {
      const map = {'k': 'a:b'};
      final without = map.uriEncode(
        allowEmpty: true,
        alreadyEncoded: true,
        textEncoding: utf8,
      );
      final with_ = map.uriEncode(
        allowEmpty: true,
        alreadyEncoded: true,
        allowReserved: true,
        textEncoding: utf8,
      );
      expect(without, 'k,a:b');
      expect(with_, without);
    });

    test('list query mode renders space as + and data + as %2B per item', () {
      expect(
        ['a b', 'c+d'].uriEncode(
          allowEmpty: true,
          useQueryComponent: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a+b,c%2Bd',
      );
    });

    test('map query mode renders space as + and data + as %2B in keys and '
        'values', () {
      expect(
        {'a b': 'c+d', 'e+f': 'g h'}.uriEncode(
          allowEmpty: true,
          useQueryComponent: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a+b,c%2Bd,e%2Bf,g+h',
      );
    });

    test('map encodes reserved key while passing already-encoded value '
        'through verbatim', () {
      expect(
        {'a&b': 'c%3Ad'}.uriEncode(
          allowEmpty: true,
          alreadyEncoded: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a%26b,c%3Ad',
      );
    });
  });

  group('literal', () {
    test('string is returned byte-for-byte unchanged', () {
      expect(
        'a b%,/:&=+%2F'.uriEncode(
          allowEmpty: true,
          literal: true,
          textEncoding: utf8,
        ),
        'a b%,/:&=+%2F',
      );
    });

    test('string literal keeps unicode unchanged', () {
      expect(
        '你好'.uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        '你好',
      );
    });

    test('empty string literal is empty regardless of allowEmpty', () {
      expect(
        ''.uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        '',
      );
      expect(
        ''.uriEncode(allowEmpty: false, literal: true, textEncoding: utf8),
        '',
      );
    });

    test('DateTime keeps literal colons', () {
      final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
      expect(
        dateTime.uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        '2023-12-25T10:30:45.000Z',
      );
    });

    test('non-UTC DateTime keeps the offset colon literal', () {
      final dateTime = tz.TZDateTime(
        tz.getLocation('Asia/Kolkata'),
        2023,
        12,
        25,
        20,
        0,
        45,
      );
      expect(
        dateTime.uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        '2023-12-25T20:00:45+05:30',
      );
    });

    test('non-UTC DateTime offset colon is percent-encoded by default', () {
      final dateTime = tz.TZDateTime(
        tz.getLocation('Asia/Kolkata'),
        2023,
        12,
        25,
        20,
        0,
        45,
      );
      expect(
        dateTime.uriEncode(allowEmpty: true, textEncoding: utf8),
        '2023-12-25T20%3A00%3A45%2B05%3A30',
      );
    });

    test('Uri keeps punctuation literal', () {
      final uri = Uri.parse('https://example.com/path?query=value');
      expect(
        uri.uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        'https://example.com/path?query=value',
      );
    });

    test('Uri keeps the fragment delimiter literal', () {
      final uri = Uri.parse('https://example.com/p#frag');
      expect(
        uri.uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        'https://example.com/p#frag',
      );
    });

    test('Uri fragment delimiter is percent-encoded without literal', () {
      final uri = Uri.parse('https://example.com/p#frag');
      expect(
        uri.uriEncode(allowEmpty: true, textEncoding: utf8),
        'https%3A%2F%2Fexample.com%2Fp%23frag',
      );
    });

    test('int uses plain string form', () {
      expect(
        (-123).uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        '-123',
      );
    });

    test('double uses plain string form', () {
      expect(
        3.14.uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        '3.14',
      );
    });

    test('num uses plain string form', () {
      expect(
        (6.022e23 as num).uriEncode(
          allowEmpty: true,
          literal: true,
          textEncoding: utf8,
        ),
        '6.022e+23',
      );
    });

    test('bool uses plain string form', () {
      expect(
        true.uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        'true',
      );
    });

    test('BigDecimal uses plain string form', () {
      expect(
        BigDecimal.parse(
          '1.23E+10',
        ).uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        '1.23e+10',
      );
    });

    test('takes precedence over useQueryComponent', () {
      expect(
        'a b'.uriEncode(
          allowEmpty: true,
          literal: true,
          useQueryComponent: true,
          textEncoding: utf8,
        ),
        'a b',
      );
    });

    test('takes precedence over allowReserved', () {
      expect(
        'a&b=c'.uriEncode(
          allowEmpty: true,
          literal: true,
          allowReserved: true,
          textEncoding: utf8,
        ),
        'a&b=c',
      );
    });

    test('list joins members without encoding them', () {
      expect(
        [
          'a b',
          'c/d',
          '50%',
        ].uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        'a b,c/d,50%',
      );
    });

    test('list keeps already-percent-encoded members verbatim', () {
      expect(
        [
          '%2F',
          'plain%',
        ].uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        '%2F,plain%',
      );
    });

    test('list joins members verbatim when literal and alreadyEncoded', () {
      expect(
        ['a b', 'c/d', '%2F'].uriEncode(
          allowEmpty: true,
          literal: true,
          alreadyEncoded: true,
          textEncoding: utf8,
        ),
        'a b,c/d,%2F',
      );
    });

    test('empty list still throws when allowEmpty is false', () {
      expect(
        () => <String>[].uriEncode(
          allowEmpty: false,
          literal: true,
          textEncoding: utf8,
        ),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('empty list allowed when allowEmpty is true', () {
      expect(
        <String>[].uriEncode(
          allowEmpty: true,
          literal: true,
          textEncoding: utf8,
        ),
        '',
      );
    });

    test('map emits keys and values verbatim as k1,v1,k2,v2', () {
      expect(
        {
          'k1': 'a b',
          'k2': 'c/d',
        }.uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        'k1,a b,k2,c/d',
      );
    });

    test('map keeps percent sequences in keys and values verbatim', () {
      expect(
        {
          '50%': '%2F',
        }.uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        '50%,%2F',
      );
    });

    test('empty map still throws when allowEmpty is false', () {
      expect(
        () => <String, String>{}.uriEncode(
          allowEmpty: false,
          literal: true,
          textEncoding: utf8,
        ),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('empty map allowed when allowEmpty is true', () {
      expect(
        <String, String>{}.uriEncode(
          allowEmpty: true,
          literal: true,
          textEncoding: utf8,
        ),
        '',
      );
    });

    test('binary returns UTF-8 conversion without a URI-encoding pass', () {
      expect(
        utf8
            .encode('a b/:')
            .uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        'a b/:',
      );
    });

    test('empty binary still throws when allowEmpty is false', () {
      expect(
        () => <int>[].uriEncode(
          allowEmpty: false,
          literal: true,
          textEncoding: utf8,
        ),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('empty binary allowed when allowEmpty is true', () {
      expect(
        <int>[].uriEncode(allowEmpty: true, literal: true, textEncoding: utf8),
        '',
      );
    });

    test('base64-shaped string keeps + / = literal', () {
      expect(
        'YWI+Y2Q/ZWY='.uriEncode(
          allowEmpty: true,
          literal: true,
          textEncoding: utf8,
        ),
        'YWI+Y2Q/ZWY=',
      );
    });

    test('literal false stays byte-identical to default URI behavior', () {
      expect(
        'a b/:'.uriEncode(allowEmpty: true, textEncoding: utf8),
        'a%20b%2F%3A',
      );
      expect(42.uriEncode(allowEmpty: true, textEncoding: utf8), '42');
      final uri = Uri.parse('https://example.com');
      expect(
        uri.uriEncode(allowEmpty: true, textEncoding: utf8),
        'https%3A%2F%2Fexample.com',
      );
      expect(
        ['a b', 'c/d'].uriEncode(allowEmpty: true, textEncoding: utf8),
        'a%20b,c%2Fd',
      );
      expect(
        {'k': 'a b'}.uriEncode(allowEmpty: true, textEncoding: utf8),
        'k,a%20b',
      );
      expect(
        utf8.encode('a b/:').uriEncode(allowEmpty: true, textEncoding: utf8),
        'a%20b%2F%3A',
      );
    });

    test('percent-encodes the selected text encoding exactly once', () {
      expect(
        'café'.uriEncode(
          allowEmpty: true,
          useQueryComponent: true,
          textEncoding: latin1,
        ),
        'caf%E9',
      );
      expect(
        'café'.uriEncode(
          allowEmpty: true,
          useQueryComponent: true,
          textEncoding: utf8,
        ),
        'caf%C3%A9',
      );
    });
  });
}
