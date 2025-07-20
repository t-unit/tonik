import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/form_encoder.dart';

void main() {
  late FormEncoder encoder;

  setUp(() {
    encoder = const FormEncoder();
  });

  group('FormEncoder', () {
    test('encodes String value', () {
      expect(
        encoder.encode('color', 'blue', explode: false, allowEmpty: true),
        [(name: 'color', value: 'blue')],
      );
    });

    test('encodes String value with special characters', () {
      expect(
        encoder.encode('name', 'John Doe', explode: false, allowEmpty: true),
        [(name: 'name', value: 'John+Doe')],
      );
    });

    test('encodes int value', () {
      expect(encoder.encode('age', 25, explode: false, allowEmpty: true), [
        (name: 'age', value: '25'),
      ]);
    });

    test('encodes double value', () {
      expect(encoder.encode('price', 19.99, explode: false, allowEmpty: true), [
        (name: 'price', value: '19.99'),
      ]);
    });

    test('encodes boolean values', () {
      expect(encoder.encode('active', true, explode: false, allowEmpty: true), [
        (name: 'active', value: 'true'),
      ]);
      expect(
        encoder.encode('active', false, explode: false, allowEmpty: true),
        [(name: 'active', value: 'false')],
      );
    });

    test('encodes Uri value', () {
      final uri = Uri.parse('https://example.com/api/v1');
      expect(
        encoder.encode('endpoint', uri, explode: false, allowEmpty: true),
        [(name: 'endpoint', value: 'https://example.com/api/v1')],
      );
    });

    test('encodes Uri value with special characters', () {
      final uri = Uri.parse('https://example.com/search?q=hello world');
      expect(
        encoder.encode('url', uri, explode: false, allowEmpty: true),
        [(name: 'url', value: 'https://example.com/search?q=hello%20world')],
      );
    });

    group('empty value handling', () {
      test('encodes null value when allowEmpty is true', () {
        expect(
          encoder.encode('param', null, explode: false, allowEmpty: true),
          [(name: 'param', value: '')],
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
        expect(encoder.encode('param', '', explode: false, allowEmpty: true), [
          (name: 'param', value: ''),
        ]);
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
          [(name: 'param', value: '')],
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
          [(name: 'param', value: '')],
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
          [(name: 'param', value: '')],
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
        [(name: 'colors', value: 'red,green,blue')],
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
        [(name: 'items', value: 'item+1,item+2')],
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
        [(name: 'colors', value: 'red,green,blue')],
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
        [(name: 'param', value: 'key,value')],
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
          [
            (name: 'colors', value: 'red'),
            (name: 'colors', value: 'green'),
            (name: 'colors', value: 'blue'),
          ],
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
          [(name: 'items', value: 'item+1'), (name: 'items', value: 'item+2')],
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
          [
            (name: 'colors', value: 'red'),
            (name: 'colors', value: 'green'),
            (name: 'colors', value: 'blue'),
          ],
        );
      });

      test('primitive values are encoded the same with explode=true', () {
        expect(
          encoder.encode('color', 'blue', explode: true, allowEmpty: true),
          [(name: 'color', value: 'blue')],
        );
        expect(encoder.encode('age', 25, explode: true, allowEmpty: true), [
          (name: 'age', value: '25'),
        ]);
      });

      test('encodes Map with explode=true', () {
        expect(
          encoder.encode(
            'user',
            {'role': 'admin', 'firstName': 'Alex'},
            explode: true,
            allowEmpty: true,
          ),
          [(name: 'role', value: 'admin'), (name: 'firstName', value: 'Alex')],
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
          [(name: 'point', value: 'x,1,y,2')],
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
          [(name: 'user', value: 'name,John,role,admin')],
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
          [(name: 'address', value: 'street,123+Main+St,city,New+York')],
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
          [(name: 'role', value: 'admin'), (name: 'firstName', value: 'Alex')],
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

      group('RFC 3986 reserved character encoding', () {
        group('gen-delims characters', () {
          test('encodes colon (:) properly', () {
            expect(
              encoder.encode(
                'url',
                'http://example.com',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'url', value: 'http%3A%2F%2Fexample.com')],
            );
          });

          test('encodes forward slash (/) properly', () {
            expect(
              encoder.encode(
                'path',
                '/api/v1/users',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'path', value: '%2Fapi%2Fv1%2Fusers')],
            );
          });

          test('encodes question mark (?) properly', () {
            expect(
              encoder.encode(
                'query',
                'search?term=test',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'query', value: 'search%3Fterm%3Dtest')],
            );
          });

          test('encodes hash (#) properly', () {
            expect(
              encoder.encode(
                'fragment',
                'page#section1',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'fragment', value: 'page%23section1')],
            );
          });

          test('encodes square brackets ([]) properly', () {
            expect(
              encoder.encode(
                'ipv6',
                '[2001:db8::1]',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'ipv6', value: '%5B2001%3Adb8%3A%3A1%5D')],
            );
          });

          test('encodes at symbol (@) properly', () {
            expect(
              encoder.encode(
                'email',
                'user@example.com',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'email', value: 'user%40example.com')],
            );
          });
        });

        group('sub-delims characters', () {
          test('encodes exclamation mark (!) properly', () {
            expect(
              encoder.encode(
                'exclaim',
                'Hello!',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'exclaim', value: 'Hello%21')],
            );
          });

          test(r'encodes dollar sign ($) properly', () {
            expect(
              encoder.encode(
                'price',
                r'$19.99',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'price', value: '%2419.99')],
            );
          });

          test('encodes ampersand (&) properly', () {
            expect(
              encoder.encode(
                'company',
                'Johnson & Johnson',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'company', value: 'Johnson+%26+Johnson')],
            );
          });

          test("encodes single quote (') properly", () {
            expect(
              encoder.encode(
                'text',
                "It's working",
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'text', value: 'It%27s+working')],
            );
          });

          test('encodes parentheses () properly', () {
            expect(
              encoder.encode(
                'phone',
                '(555) 123-4567',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'phone', value: '%28555%29+123-4567')],
            );
          });

          test('encodes asterisk (*) properly', () {
            expect(
              encoder.encode(
                'wildcard',
                'file*.txt',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'wildcard', value: 'file%2A.txt')],
            );
          });

          test('encodes plus (+) properly', () {
            expect(
              encoder.encode('math', '2+2=4', explode: false, allowEmpty: true),
              [(name: 'math', value: '2%2B2%3D4')],
            );
          });

          test('encodes comma (,) properly', () {
            expect(
              encoder.encode(
                'list',
                'apple,banana,cherry',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'list', value: 'apple%2Cbanana%2Ccherry')],
            );
          });

          test('encodes semicolon (;) properly', () {
            expect(
              encoder.encode(
                'params',
                'a=1;b=2',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'params', value: 'a%3D1%3Bb%3D2')],
            );
          });

          test('encodes equals (=) properly', () {
            expect(
              encoder.encode(
                'equation',
                'x=y',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'equation', value: 'x%3Dy')],
            );
          });
        });

        group('unreserved characters should NOT be encoded', () {
          test('does not encode letters', () {
            expect(
              encoder.encode(
                'text',
                'ABCdef',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'text', value: 'ABCdef')],
            );
          });

          test('does not encode digits', () {
            expect(
              encoder.encode(
                'numbers',
                '1234567890',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'numbers', value: '1234567890')],
            );
          });

          test('does not encode hyphen (-)', () {
            expect(
              encoder.encode(
                'uuid',
                '123e4567-e89b-12d3',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'uuid', value: '123e4567-e89b-12d3')],
            );
          });

          test('does not encode period (.)', () {
            expect(
              encoder.encode(
                'domain',
                'example.com',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'domain', value: 'example.com')],
            );
          });

          test('does not encode underscore (_)', () {
            expect(
              encoder.encode(
                'var',
                'my_variable',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'var', value: 'my_variable')],
            );
          });

          test('does not encode tilde (~)', () {
            expect(
              encoder.encode(
                'path',
                '~/documents',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'path', value: '~%2Fdocuments')],
            );
          });
        });

        group('percent-encoding normalization', () {
          test('uses uppercase hex digits for encoding', () {
            expect(
              encoder.encode(
                'special',
                'hello world!',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'special', value: 'hello+world%21')],
            );
          });

          test('properly encodes non-ASCII characters', () {
            expect(
              encoder.encode(
                'unicode',
                'café',
                explode: false,
                allowEmpty: true,
              ),
              [(name: 'unicode', value: 'caf%C3%A9')],
            );
          });

          test('properly encodes emoji', () {
            expect(
              encoder.encode('emoji', '👍', explode: false, allowEmpty: true),
              [(name: 'emoji', value: '%F0%9F%91%8D')],
            );
          });

          test('properly encodes Chinese characters', () {
            expect(
              encoder.encode('chinese', '你好', explode: false, allowEmpty: true),
              [(name: 'chinese', value: '%E4%BD%A0%E5%A5%BD')],
            );
          });
        });
      });
    });
  });
}
