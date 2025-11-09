import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/simple_encoder_extensions.dart';

void main() {
  group('SimpleUriEncoder', () {
    test('encodes HTTPS Uri', () {
      final value = Uri.parse('https://example.com/path?query=value');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
      );
    });

    test('encodes file Uri', () {
      final value = Uri.parse('file:///path/to/file.txt');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'file%3A%2F%2F%2Fpath%2Fto%2Ffile.txt',
      );
    });

    test('encodes relative path Uri', () {
      final value = Uri.parse('/relative/path');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '%2Frelative%2Fpath',
      );
    });

    test('encodes mailto Uri', () {
      final value = Uri.parse('mailto:user@example.com');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'mailto%3Auser%40example.com',
      );
    });

    test('encodes Uri with special characters', () {
      final value = Uri.parse(
        'https://example.com/path with spaces?key=value&other=data',
      );
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'https%3A%2F%2Fexample.com%2Fpath%2520with%2520spaces'
        '%3Fkey%3Dvalue%26other%3Ddata',
      );
    });

    test('encodes Uri with fragment', () {
      final value = Uri.parse('https://example.com/page#section1');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'https%3A%2F%2Fexample.com%2Fpage%23section1',
      );
    });

    test('encodes Uri with port', () {
      final value = Uri.parse('https://example.com:8080/api/v1');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'https%3A%2F%2Fexample.com%3A8080%2Fapi%2Fv1',
      );
    });

    test('encodes Uri with authentication', () {
      final value = Uri.parse('https://user:pass@example.com/secure');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'https%3A%2F%2Fuser%3Apass%40example.com%2Fsecure',
      );
    });

    test('encodes custom scheme Uri', () {
      final value = Uri.parse('custom-app://action?param=value');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'custom-app%3A%2F%2Faction%3Fparam%3Dvalue',
      );
    });

    test('encodes empty path Uri', () {
      final value = Uri.parse('https://example.com');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'https%3A%2F%2Fexample.com',
      );
    });

    test('explode parameter has no effect on Uri encoding', () {
      final value = Uri.parse('https://example.com/test');
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });

    test('allowEmpty parameter has no effect on Uri values', () {
      final value = Uri.parse('https://example.com/test');
      expect(
        value.toSimple(explode: false, allowEmpty: false),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });

    group('Uri path encoding edge cases', () {
      test('encodes Uri with encoded characters in path', () {
        final value = Uri.parse('https://example.com/path%20with%20spaces');
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'https%3A%2F%2Fexample.com%2Fpath%2520with%2520spaces',
        );
      });

      test('encodes Uri with Unicode characters', () {
        final value = Uri.parse('https://example.com/café');
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'https%3A%2F%2Fexample.com%2Fcaf%25C3%25A9',
        );
      });

      test('encodes Uri with emoji', () {
        final value = Uri.parse('https://example.com/👍');
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'https%3A%2F%2Fexample.com%2F%25F0%259F%2591%258D',
        );
      });
    });

    group('Uri query parameter edge cases', () {
      test('encodes Uri with multiple query parameters', () {
        final value = Uri.parse(
          'https://api.example.com/search?q=dart&page=1&size=10',
        );
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'https%3A%2F%2Fapi.example.com%2Fsearch'
          '%3Fq%3Ddart%26page%3D1%26size%3D10',
        );
      });

      test('encodes Uri with empty query parameter values', () {
        final value = Uri.parse('https://example.com/search?q=&empty');
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'https%3A%2F%2Fexample.com%2Fsearch%3Fq%3D%26empty',
        );
      });

      test('encodes Uri with encoded query parameters', () {
        final value = Uri.parse('https://example.com/search?q=hello%20world');
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'https%3A%2F%2Fexample.com%2Fsearch%3Fq%3Dhello%2520world',
        );
      });
    });
  });

  group('SimpleStringEncoder', () {
    test('encodes string value', () {
      const value = 'blue';
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'blue',
      );
    });

    test('encodes string with special characters', () {
      const value = 'John Doe';
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'John%20Doe',
      );
    });

    test('encodes empty string with allowEmpty=true', () {
      const value = '';
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '',
      );
    });

    test('explode parameter has no effect on string encoding', () {
      const value = 'test';
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });

    group('RFC 3986 reserved character encoding', () {
      group('gen-delims characters', () {
        test('encodes colon (:) properly', () {
          const value = 'http://example.com';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            'http%3A%2F%2Fexample.com',
          );
        });

        test('encodes forward slash (/) properly', () {
          const value = '/api/v1/users';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            '%2Fapi%2Fv1%2Fusers',
          );
        });

        test('encodes question mark (?) properly', () {
          const value = 'search?term=test';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            'search%3Fterm%3Dtest',
          );
        });

        test('encodes hash (#) properly', () {
          const value = 'page#section1';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            'page%23section1',
          );
        });

        test('encodes square brackets ([]) properly', () {
          const value = '[2001:db8::1]';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            '%5B2001%3Adb8%3A%3A1%5D',
          );
        });

        test('encodes at symbol (@) properly', () {
          const value = 'user@example.com';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            'user%40example.com',
          );
        });
      });

      group('sub-delims characters', () {
        test('encodes exclamation mark (!) properly', () {
          const value = 'Hello!';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            'Hello!',
          );
        });

        test(r'encodes dollar sign ($) properly', () {
          const value = r'$19.99';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            '%2419.99',
          );
        });

        test('encodes ampersand (&) properly', () {
          const value = 'Johnson & Johnson';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            'Johnson%20%26%20Johnson',
          );
        });

        test("encodes single quote (') properly", () {
          const value = "It's working";
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            "It's%20working",
          );
        });

        test('encodes parentheses () properly', () {
          const value = '(555) 123-4567';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            '(555)%20123-4567',
          );
        });

        test('encodes asterisk (*) properly', () {
          const value = 'file*.txt';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            'file*.txt',
          );
        });

        test('encodes plus (+) properly', () {
          const value = '2+2=4';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            '2%2B2%3D4',
          );
        });

        test('encodes comma (,) properly', () {
          const value = 'apple,banana,cherry';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            'apple%2Cbanana%2Ccherry',
          );
        });

        test('encodes semicolon (;) properly', () {
          const value = 'a=1;b=2';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            'a%3D1%3Bb%3D2',
          );
        });

        test('encodes equals (=) properly', () {
          const value = 'x=y';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            'x%3Dy',
          );
        });
      });

      group('percent-encoding normalization', () {
        test('properly encodes non-ASCII characters', () {
          const value = 'café';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            'caf%C3%A9',
          );
        });

        test('properly encodes emoji', () {
          const value = '👍';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            '%F0%9F%91%8D',
          );
        });

        test('properly encodes Chinese characters', () {
          const value = '你好';
          expect(
            value.toSimple(explode: false, allowEmpty: true),
            '%E4%BD%A0%E5%A5%BD',
          );
        });
      });
    });

    group('allowEmpty parameter behavior', () {
      test('empty string should throw with allowEmpty=false', () {
        const value = '';
        expect(
          () => value.toSimple(explode: false, allowEmpty: false),
          throwsException,
        );
      });

      test('non-empty string ignores allowEmpty parameter', () {
        const value = 'test';
        expect(
          value.toSimple(explode: false, allowEmpty: false),
          value.toSimple(explode: false, allowEmpty: true),
        );
      });
    });
  });

  group('SimpleIntEncoder', () {
    test('encodes int value', () {
      const value = 25;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '25',
      );
    });

    test('encodes negative int value', () {
      const value = -42;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '-42',
      );
    });

    test('encodes zero', () {
      const value = 0;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '0',
      );
    });

    test('encodes maximum int value', () {
      const value = 9223372036854775807; // max int64
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '9223372036854775807',
      );
    });

    test('encodes minimum int value', () {
      const value = -9223372036854775808; // min int64
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '-9223372036854775808',
      );
    });

    test('explode parameter has no effect on int encoding', () {
      const value = 123;
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });

    test('allowEmpty parameter has no effect on non-zero int', () {
      const value = 42;
      expect(
        value.toSimple(explode: false, allowEmpty: false),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });
  });

  group('SimpleDoubleEncoder', () {
    test('encodes double value', () {
      const value = 19.99;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '19.99',
      );
    });

    test('encodes negative double value', () {
      const value = -3.14;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '-3.14',
      );
    });

    test('encodes zero double', () {
      const value = 0.0;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '0.0',
      );
    });

    test('encodes very small double value', () {
      const value = 0.0000001;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '1e-7',
      );
    });

    test('encodes very large double value', () {
      const value = 1.7976931348623157e+308; // close to max double
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '1.7976931348623157e%2B308',
      );
    });

    test('encodes double with many decimal places', () {
      const value = 3.141592653589793;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '3.141592653589793',
      );
    });

    test('encodes negative zero double', () {
      const value = -0.0;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '-0.0',
      );
    });

    test('explode parameter has no effect on double encoding', () {
      const value = 42.5;
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });

    test('allowEmpty parameter has no effect on non-zero double', () {
      const value = 3.14;
      expect(
        value.toSimple(explode: false, allowEmpty: false),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });
  });

  group('SimpleNumEncoder', () {
    test('encodes num value (int)', () {
      const num value = 25;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '25',
      );
    });

    test('encodes num value (double)', () {
      const num value = 19.99;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '19.99',
      );
    });

    test('explode parameter has no effect on num encoding', () {
      const num value = 123.45;
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });
  });

  group('SimpleBoolEncoder', () {
    test('encodes true value', () {
      const value = true;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'true',
      );
    });

    test('encodes false value', () {
      const value = false;
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'false',
      );
    });

    test('explode parameter has no effect on bool encoding', () {
      const value = true;
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });

    test('explode parameter has no effect on false bool encoding', () {
      const value = false;
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });

    test('allowEmpty parameter has no effect on bool values', () {
      const valueTrue = true;
      const valueFalse = false;
      expect(
        valueTrue.toSimple(explode: false, allowEmpty: false),
        valueTrue.toSimple(explode: false, allowEmpty: true),
      );
      expect(
        valueFalse.toSimple(explode: false, allowEmpty: false),
        valueFalse.toSimple(explode: false, allowEmpty: true),
      );
    });
  });

  group('SimpleDateTimeEncoder', () {
    test('encodes UTC DateTime value', () {
      final value = DateTime.utc(2023, 12, 25, 10, 30);
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '2023-12-25T10%3A30%3A00.000Z',
      );
    });

    test('encodes local DateTime with timezone', () {
      final value = DateTime(2023, 12, 25, 10, 30);
      final result = value.toSimple(explode: false, allowEmpty: true);
      // Should contain encoded timezone offset
      expect(result, contains('2023-12-25T10%3A30%3A00'));
      // Should contain either positive or negative timezone offset
      expect(result, anyOf(contains('%2B'), contains('%2D')));
    });

    test('encodes DateTime at Unix epoch', () {
      final value = DateTime.utc(1970);
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '1970-01-01T00%3A00%3A00.000Z',
      );
    });

    test('encodes DateTime with microseconds', () {
      final value = DateTime.utc(2023, 12, 25, 10, 30, 0, 123, 456);
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '2023-12-25T10%3A30%3A00.123456Z',
      );
    });

    test('encodes DateTime far in the future', () {
      final value = DateTime.utc(2099, 12, 31, 23, 59, 59);
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '2099-12-31T23%3A59%3A59.000Z',
      );
    });

    test('explode parameter has no effect on DateTime encoding', () {
      final value = DateTime.utc(2023);
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });

    test('allowEmpty parameter has no effect on DateTime values', () {
      final value = DateTime.utc(2023, 6, 15, 12);
      expect(
        value.toSimple(explode: false, allowEmpty: false),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });
  });

  group('SimpleBigDecimalEncoder', () {
    test('encodes BigDecimal value using extension', () {
      final value = BigDecimal.parse('123.456789');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '123.456789',
      );
    });

    test('encodes negative BigDecimal value using extension', () {
      final value = BigDecimal.parse('-999.001');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '-999.001',
      );
    });

    test('encodes zero BigDecimal using extension', () {
      final value = BigDecimal.parse('0');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '0',
      );
    });

    test('encodes very large BigDecimal value using extension', () {
      final value = BigDecimal.parse('99999999999999999999999999999.99999999');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '99999999999999999999999999999.99999999',
      );
    });

    test('encodes very small BigDecimal value using extension', () {
      final value = BigDecimal.parse('0.00000000000000000001');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        value.toString(), // May be in scientific notation
      );
    });

    test('encodes BigDecimal with many decimal places using extension', () {
      final value = BigDecimal.parse('3.1415926535897932384626433832795');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '3.1415926535897932384626433832795',
      );
    });

    test('encodes BigDecimal in scientific notation input using extension', () {
      final value = BigDecimal.parse('1.23E+10');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        value.toString(),
      );
    });

    test('explode parameter has no effect on BigDecimal encoding', () {
      final value = BigDecimal.parse('42.123');
      expect(
        value.toSimple(explode: true, allowEmpty: true),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });

    test('allowEmpty parameter has no effect on BigDecimal values', () {
      final value = BigDecimal.parse('3.14159');
      expect(
        value.toSimple(explode: false, allowEmpty: false),
        value.toSimple(explode: false, allowEmpty: true),
      );
    });
  });

  group('SimpleStringListEncoder', () {
    test('encodes List of primitive values', () {
      const value = ['red', 'green', 'blue'];
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'red,green,blue',
      );
    });

    test('encodes List with special characters', () {
      const value = ['item 1', 'item 2'];
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'item%201,item%202',
      );
    });

    test('encodes empty List', () {
      const value = <String>[];
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        '',
      );
    });

    test('encodes single item List', () {
      const value = ['single'];
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'single',
      );
    });

    test('encodes List with RFC 3986 characters', () {
      const value = ['hello world', 'test@example.com', 'path/to/file'];
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'hello%20world,test%40example.com,path%2Fto%2Ffile',
      );
    });

    test('encodes List with empty strings', () {
      const value = ['', 'middle', ''];
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        ',middle,',
      );
    });

    test('encodes List with Unicode characters', () {
      const value = ['café', '你好', '👍'];
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'caf%C3%A9,%E4%BD%A0%E5%A5%BD,%F0%9F%91%8D',
      );
    });

    test('encodes List with comma-containing strings', () {
      const value = ['apple,banana', 'cherry,date'];
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        'apple%2Cbanana,cherry%2Cdate',
      );
    });

    group('with explode=true', () {
      test('encodes List with explode=true', () {
        const value = ['red', 'green', 'blue'];
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          'red,green,blue',
        );
      });

      test('encodes List with special characters and explode=true', () {
        const value = ['item 1', 'item 2'];
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          'item%201,item%202',
        );
      });

      test('encodes empty List with explode=true', () {
        const value = <String>[];
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          '',
        );
      });

      test('encodes single item List with explode=true', () {
        const value = ['single'];
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          'single',
        );
      });
    });

    group('allowEmpty parameter behavior', () {
      test('empty List should throw with allowEmpty=false', () {
        const value = <String>[];
        expect(
          () => value.toSimple(explode: false, allowEmpty: false),
          throwsException,
        );
      });

      test('non-empty List ignores allowEmpty parameter', () {
        const value = ['test'];
        expect(
          value.toSimple(explode: false, allowEmpty: false),
          value.toSimple(explode: false, allowEmpty: true),
        );
      });

      test(
        'empty List with explode=true should throw with allowEmpty=false',
        () {
          const value = <String>[];
          expect(
            () => value.toSimple(explode: true, allowEmpty: false),
            throwsException,
          );
        },
      );
    });

    test('very large List encoding', () {
      final value = List.generate(100, (i) => 'item$i');
      final expected = List.generate(100, (i) => 'item$i').join(',');
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        expected,
      );
    });

    test('List with all empty strings', () {
      const value = ['', '', ''];
      expect(
        value.toSimple(explode: false, allowEmpty: true),
        ',,',
      );
    });
  });

  group('SimpleStringMapEncoder', () {
    group('with explode=true', () {
      test('encodes Map with key=value pairs', () {
        const value = {'color': 'blue', 'size': 'large'};
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          'color=blue,size=large',
        );
      });

      test('encodes Map with special characters in keys and values', () {
        const value = {
          'user name': 'John Doe',
          'email@domain': 'test@example.com',
        };
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          'user%20name=John%20Doe,email%40domain=test%40example.com',
        );
      });

      test('encodes empty Map', () {
        const value = <String, String>{};
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          '',
        );
      });

      test('encodes single entry Map', () {
        const value = {'key': 'value'};
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          'key=value',
        );
      });

      test('encodes Map with empty keys and values', () {
        const value = {'': 'empty_key', 'empty_value': ''};
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          '=empty_key,empty_value=',
        );
      });

      test('encodes Map with RFC 3986 reserved characters', () {
        const value = {
          'path/to/resource': 'value@example.com',
          'query?param': 'result#section',
        };
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          'path%2Fto%2Fresource=value%40example.com,'
          'query%3Fparam=result%23section',
        );
      });

      test('encodes Map with Unicode characters', () {
        const value = {'café': '你好', 'emoji': '👍'};
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          'caf%C3%A9=%E4%BD%A0%E5%A5%BD,emoji=%F0%9F%91%8D',
        );
      });

      test('encodes Map with equals signs and commas in values', () {
        const value = {'formula': 'x=y+z', 'list': 'apple,banana,cherry'};
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          'formula=x%3Dy%2Bz,list=apple%2Cbanana%2Ccherry',
        );
      });
    });

    group('with explode=false', () {
      test('encodes Map with comma-separated key,value pairs', () {
        const value = {'color': 'blue', 'size': 'large'};
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'color,blue,size,large',
        );
      });

      test('encodes Map with special characters in keys and values', () {
        const value = {
          'user name': 'John Doe',
          'email@domain': 'test@example.com',
        };
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'user%20name,John%20Doe,email%40domain,test%40example.com',
        );
      });

      test('encodes empty Map', () {
        const value = <String, String>{};
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          '',
        );
      });

      test('encodes single entry Map', () {
        const value = {'key': 'value'};
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'key,value',
        );
      });

      test('encodes Map with empty keys and values', () {
        const value = {'': 'empty_key', 'empty_value': ''};
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          ',empty_key,empty_value,',
        );
      });

      test('encodes Map with RFC 3986 reserved characters', () {
        const value = {
          'path/to/resource': 'value@example.com',
          'query?param': 'result#section',
        };
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'path%2Fto%2Fresource,value%40example.com,'
          'query%3Fparam,result%23section',
        );
      });

      test('encodes Map with Unicode characters', () {
        const value = {'café': '你好', 'emoji': '👍'};
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'caf%C3%A9,%E4%BD%A0%E5%A5%BD,emoji,%F0%9F%91%8D',
        );
      });

      test('encodes Map with commas in keys and values', () {
        const value = {'a,b': 'x,y', 'c,d': 'z,w'};
        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'a%2Cb,x%2Cy,c%2Cd,z%2Cw',
        );
      });
    });

    group('allowEmpty parameter behavior', () {
      test('empty Map should throw with allowEmpty=false', () {
        const value = <String, String>{};
        expect(
          () => value.toSimple(explode: false, allowEmpty: false),
          throwsException,
        );
      });

      test(
        'empty Map with explode=true should throw with allowEmpty=false',
        () {
          const value = <String, String>{};
          expect(
            () => value.toSimple(explode: true, allowEmpty: false),
            throwsException,
          );
        },
      );

      test('non-empty Map ignores allowEmpty parameter with explode=false', () {
        const value = {'test': 'value'};
        expect(
          value.toSimple(explode: false, allowEmpty: false),
          value.toSimple(explode: false, allowEmpty: true),
        );
      });

      test('non-empty Map ignores allowEmpty parameter with explode=true', () {
        const value = {'test': 'value'};
        expect(
          value.toSimple(explode: true, allowEmpty: false),
          value.toSimple(explode: true, allowEmpty: true),
        );
      });
    });

    group('complex scenarios', () {
      test('encodes large Map with many entries', () {
        final value = <String, String>{};
        for (var i = 0; i < 50; i++) {
          value['key$i'] = 'value$i';
        }

        final resultExplode = value.toSimple(explode: true, allowEmpty: true);
        final resultNoExplode = value.toSimple(
          explode: false,
          allowEmpty: true,
        );

        // Check that both formats contain all entries
        for (var i = 0; i < 50; i++) {
          expect(resultExplode, contains('key$i'));
          expect(resultExplode, contains('value$i'));
          expect(resultNoExplode, contains('key$i'));
          expect(resultNoExplode, contains('value$i'));
        }

        // Check format differences
        if (value.isNotEmpty) {
          expect(resultExplode, contains('='));
          expect(resultNoExplode, isNot(contains('=')));
        }
      });

      test('encodes Map with AllOf property merge scenario', () {
        const value = {'id': '123', 'offset': '10', 'index': '5'};

        expect(
          value.toSimple(explode: true, allowEmpty: true),
          'id=123,offset=10,index=5',
        );

        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'id,123,offset,10,index,5',
        );
      });

      test('encodes Map with values containing delimiter characters', () {
        const value = {
          'equation': 'a=b,c=d',
          'list': 'x,y,z',
          'pair': 'key=value',
        };

        expect(
          value.toSimple(explode: true, allowEmpty: true),
          'equation=a%3Db%2Cc%3Dd,list=x%2Cy%2Cz,pair=key%3Dvalue',
        );

        expect(
          value.toSimple(explode: false, allowEmpty: true),
          'equation,a%3Db%2Cc%3Dd,list,x%2Cy%2Cz,pair,key%3Dvalue',
        );
      });

      test('maintains consistent key ordering for same Map', () {
        const value = {'z': '3', 'a': '1', 'm': '2'};

        final result1 = value.toSimple(explode: true, allowEmpty: true);
        final result2 = value.toSimple(explode: true, allowEmpty: true);
        final result3 = value.toSimple(explode: false, allowEmpty: true);
        final result4 = value.toSimple(explode: false, allowEmpty: true);

        // Results should be consistent for the same parameters
        expect(result1, equals(result2));
        expect(result3, equals(result4));
      });
    });

    group('alreadyEncoded parameter behavior', () {
      test(
        'alreadyEncoded=true prevents double encoding with explode=true',
        () {
          const value = {'email': 'user%40example.com', 'name': 'John%20Doe'};
          expect(
            value.toSimple(
              explode: true,
              allowEmpty: true,
              alreadyEncoded: true,
            ),
            'email=user%40example.com,name=John%20Doe',
          );
        },
      );

      test(
        'alreadyEncoded=true prevents double encoding with explode=false',
        () {
          const value = {'email': 'user%40example.com', 'name': 'John%20Doe'};
          expect(
            value.toSimple(
              explode: false,
              allowEmpty: true,
              alreadyEncoded: true,
            ),
            'email,user%40example.com,name,John%20Doe',
          );
        },
      );

      test('alreadyEncoded=false encodes values normally', () {
        const value = {'email': 'user@example.com', 'name': 'John Doe'};
        expect(
          value.toSimple(
            explode: true,
            allowEmpty: true,
          ),
          'email=user%40example.com,name=John%20Doe',
        );
      });

      test(
        'alreadyEncoded=false encodes values normally with explode=false',
        () {
          const value = {'email': 'user@example.com', 'name': 'John Doe'};
          expect(
            value.toSimple(
              explode: false,
              allowEmpty: true,
            ),
            'email,user%40example.com,name,John%20Doe',
          );
        },
      );

      test('alreadyEncoded parameter defaults to false', () {
        const value = {'email': 'user@example.com', 'name': 'John Doe'};
        expect(
          value.toSimple(explode: true, allowEmpty: true),
          value.toSimple(
            explode: true,
            allowEmpty: true,
          ),
        );
      });

      test('alreadyEncoded=true with mixed encoded and unencoded values', () {
        const value = {
          'encoded': 'user%40example.com',
          'unencoded': 'user@example.com',
        };
        expect(
          value.toSimple(
            explode: true,
            allowEmpty: true,
            alreadyEncoded: true,
          ),
          'encoded=user%40example.com,unencoded=user@example.com',
        );
      });

      test('alreadyEncoded=true with special characters in keys', () {
        const value = {
          'user name': 'John%20Doe',
          'email@domain': 'test%40example.com',
        };
        expect(
          value.toSimple(
            explode: true,
            allowEmpty: true,
            alreadyEncoded: true,
          ),
          'user%20name=John%20Doe,email%40domain=test%40example.com',
        );
      });

      test('alreadyEncoded=true with empty values', () {
        const value = {'key1': '', 'key2': 'value'};
        expect(
          value.toSimple(
            explode: true,
            allowEmpty: true,
            alreadyEncoded: true,
          ),
          'key1=,key2=value',
        );
      });

      test('alreadyEncoded=true with Unicode characters', () {
        const value = {'café': '你好', 'emoji': '👍'};
        expect(
          value.toSimple(
            explode: true,
            allowEmpty: true,
            alreadyEncoded: true,
          ),
          'caf%C3%A9=你好,emoji=👍',
        );
      });
    });
  });
}
