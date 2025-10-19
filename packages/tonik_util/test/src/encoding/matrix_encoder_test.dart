import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

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

    test('encodes Uri value', () {
      final uri = Uri.parse('https://example.com/api/v1');
      expect(
        encoder.encode('endpoint', uri, explode: false, allowEmpty: true),
        ';endpoint=https%3A%2F%2Fexample.com%2Fapi%2Fv1',
      );
    });

    test('encodes Uri value with special characters', () {
      final uri = Uri.parse('https://example.com/search?q=hello world');
      expect(
        encoder.encode('url', uri, explode: false, allowEmpty: true),
        ';url=https%3A%2F%2Fexample.com%2Fsearch%3Fq%3Dhello%2520world',
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
              ';url=http%3A%2F%2Fexample.com',
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
              ';path=%2Fapi%2Fv1%2Fusers',
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
              ';query=search%3Fterm%3Dtest',
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
              ';fragment=page%23section1',
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
              ';ipv6=%5B2001%3Adb8%3A%3A1%5D',
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
              ';email=user%40example.com',
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
              ';exclaim=Hello!',
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
              ';price=%2419.99',
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
              ';company=Johnson%20%26%20Johnson',
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
              ";text=It's%20working",
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
              ';phone=(555)%20123-4567',
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
              ';wildcard=file*.txt',
            );
          });

          test('encodes plus (+) properly', () {
            expect(
              encoder.encode('math', '2+2=4', explode: false, allowEmpty: true),
              ';math=2%2B2%3D4',
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
              ';list=apple%2Cbanana%2Ccherry',
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
              ';params=a%3D1%3Bb%3D2',
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
              ';equation=x%3Dy',
            );
          });
        });

        group('percent-encoding normalization', () {
          test('properly encodes non-ASCII characters', () {
            expect(
              encoder.encode(
                'unicode',
                'café',
                explode: false,
                allowEmpty: true,
              ),
              ';unicode=caf%C3%A9',
            );
          });

          test('properly encodes emoji', () {
            expect(
              encoder.encode('emoji', '👍', explode: false, allowEmpty: true),
              ';emoji=%F0%9F%91%8D',
            );
          });

          test('properly encodes Chinese characters', () {
            expect(
              encoder.encode('chinese', '你好', explode: false, allowEmpty: true),
              ';chinese=%E4%BD%A0%E5%A5%BD',
            );
          });
        });
      });
    });
  });
}
