import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/label_encoder.dart';

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

    test('encodes Uri value', () {
      final uri = Uri.parse('https://example.com/api/v1');
      expect(
        encoder.encode(uri, explode: false, allowEmpty: true),
        '.https%3A%2F%2Fexample.com%2Fapi%2Fv1',
      );
    });

    test('encodes Uri value with special characters', () {
      final uri = Uri.parse('https://example.com/search?q=hello world');
      expect(
        encoder.encode(uri, explode: false, allowEmpty: true),
        '.https%3A%2F%2Fexample.com%2Fsearch%3Fq%3Dhello%2520world',
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

      group('RFC 3986 reserved character encoding', () {
        group('gen-delims characters', () {
          test('encodes colon (:) properly', () {
            expect(
              encoder.encode(
                'http://example.com',
                explode: false,
                allowEmpty: true,
              ),
              '.http%3A%2F%2Fexample.com',
            );
          });

          test('encodes forward slash (/) properly', () {
            expect(
              encoder.encode('/api/v1/users', explode: false, allowEmpty: true),
              '.%2Fapi%2Fv1%2Fusers',
            );
          });

          test('encodes question mark (?) properly', () {
            expect(
              encoder.encode(
                'search?term=test',
                explode: false,
                allowEmpty: true,
              ),
              '.search%3Fterm%3Dtest',
            );
          });

          test('encodes hash (#) properly', () {
            expect(
              encoder.encode('page#section1', explode: false, allowEmpty: true),
              '.page%23section1',
            );
          });

          test('encodes square brackets ([]) properly', () {
            expect(
              encoder.encode('[2001:db8::1]', explode: false, allowEmpty: true),
              '.%5B2001%3Adb8%3A%3A1%5D',
            );
          });

          test('encodes at symbol (@) properly', () {
            expect(
              encoder.encode(
                'user@example.com',
                explode: false,
                allowEmpty: true,
              ),
              '.user%40example.com',
            );
          });
        });

        group('sub-delims characters', () {
          test('encodes exclamation mark (!) properly', () {
            expect(
              encoder.encode('Hello!', explode: false, allowEmpty: true),
              '.Hello!',
            );
          });

          test(r'encodes dollar sign ($) properly', () {
            expect(
              encoder.encode(r'$19.99', explode: false, allowEmpty: true),
              '.%2419.99',
            );
          });

          test('encodes ampersand (&) properly', () {
            expect(
              encoder.encode(
                'Johnson & Johnson',
                explode: false,
                allowEmpty: true,
              ),
              '.Johnson%20%26%20Johnson',
            );
          });

          test("encodes single quote (') properly", () {
            expect(
              encoder.encode("It's working", explode: false, allowEmpty: true),
              ".It's%20working",
            );
          });

          test('encodes parentheses () properly', () {
            expect(
              encoder.encode(
                '(555) 123-4567',
                explode: false,
                allowEmpty: true,
              ),
              '.(555)%20123-4567',
            );
          });

          test('encodes asterisk (*) properly', () {
            expect(
              encoder.encode('file*.txt', explode: false, allowEmpty: true),
              '.file*.txt',
            );
          });

          test('encodes plus (+) properly', () {
            expect(
              encoder.encode('2+2=4', explode: false, allowEmpty: true),
              '.2%2B2%3D4',
            );
          });

          test('encodes comma (,) properly', () {
            expect(
              encoder.encode(
                'apple,banana,cherry',
                explode: false,
                allowEmpty: true,
              ),
              '.apple%2Cbanana%2Ccherry',
            );
          });

          test('encodes semicolon (;) properly', () {
            expect(
              encoder.encode('a=1;b=2', explode: false, allowEmpty: true),
              '.a%3D1%3Bb%3D2',
            );
          });

          test('encodes equals (=) properly', () {
            expect(
              encoder.encode('x=y', explode: false, allowEmpty: true),
              '.x%3Dy',
            );
          });
        });

        group('percent-encoding normalization', () {
          test('properly encodes non-ASCII characters', () {
            expect(
              encoder.encode('café', explode: false, allowEmpty: true),
              '.caf%C3%A9',
            );
          });

          test('properly encodes emoji', () {
            expect(
              encoder.encode('👍', explode: false, allowEmpty: true),
              '.%F0%9F%91%8D',
            );
          });

          test('properly encodes Chinese characters', () {
            expect(
              encoder.encode('你好', explode: false, allowEmpty: true),
              '.%E4%BD%A0%E5%A5%BD',
            );
          });
        });
      });
    });
  });
}
