import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/delimited_encoder.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';

void main() {
  group('DelimitedEncoder', () {
    group('with pipe delimiter', () {
      late DelimitedEncoder encoder;

      setUp(() {
        encoder = const DelimitedEncoder.piped();
      });

      test('encodes String value', () {
        expect(encoder.encode('blue', explode: false, allowEmpty: true), [
          'blue',
        ]);
      });

      test('encodes String value with special characters', () {
        expect(encoder.encode('John Doe', explode: false, allowEmpty: true), [
          'John+Doe',
        ]);
      });

      test('encodes int value', () {
        expect(encoder.encode(25, explode: false, allowEmpty: true), ['25']);
      });

      test('encodes double value', () {
        expect(encoder.encode(19.99, explode: false, allowEmpty: true), [
          '19.99',
        ]);
      });

      test('encodes boolean values', () {
        expect(encoder.encode(true, explode: false, allowEmpty: true), [
          'true',
        ]);
        expect(encoder.encode(false, explode: false, allowEmpty: true), [
          'false',
        ]);
      });

      test('encodes Uri value', () {
        final uri = Uri.parse('https://example.com/api/v1');
        expect(encoder.encode(uri, explode: false, allowEmpty: true), [
          'https://example.com/api/v1',
        ]);
      });

      test('encodes Uri value with special characters', () {
        final uri = Uri.parse('https://example.com/search?q=hello world');
        expect(encoder.encode(uri, explode: false, allowEmpty: true), [
          'https://example.com/search?q=hello%20world',
        ]);
      });

      test('encodes null value when allowEmpty is true', () {
        expect(encoder.encode(null, explode: false, allowEmpty: true), ['']);
      });

      test('throws when null value and allowEmpty is false', () {
        expect(
          () => encoder.encode(null, explode: false, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('encodes List of primitive values with explode=false', () {
        expect(
          encoder.encode(
            ['red', 'green', 'blue'],
            explode: false,
            allowEmpty: true,
          ),
          ['red|green|blue'],
        );
      });

      test('encodes List of boolean values with explode=false', () {
        expect(
          encoder.encode([true, false, true], explode: false, allowEmpty: true),
          ['true|false|true'],
        );
      });

      test('encodes List with special characters with explode=false', () {
        expect(
          encoder.encode(
            ['item 1', 'item 2'],
            explode: false,
            allowEmpty: true,
          ),
          ['item+1|item+2'],
        );
      });

      test('encodes empty List when allowEmpty is true', () {
        expect(encoder.encode(<String>[], explode: false, allowEmpty: true), [
          '',
        ]);
      });

      test('throws when empty List and allowEmpty is false', () {
        expect(
          () => encoder.encode(<String>[], explode: false, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('encodes Set of primitive values with explode=false', () {
        expect(
          encoder.encode(
            {'red', 'green', 'blue'},
            explode: false,
            allowEmpty: true,
          ),
          ['red|green|blue'],
        );
      });

      test('throws when empty Set and allowEmpty is false', () {
        expect(
          () => encoder.encode(<String>{}, explode: false, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('throws exception for Map values', () {
        expect(
          () => encoder.encode(
            {'key': 'value'},
            explode: false,
            allowEmpty: true,
          ),
          throwsA(isA<UnsupportedEncodingTypeException>()),
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

      group('with explode=true', () {
        test('encodes List with explode=true as separate values', () {
          expect(
            encoder.encode(
              ['red', 'green', 'blue'],
              explode: true,
              allowEmpty: true,
            ),
            ['red', 'green', 'blue'],
          );
        });

        test('encodes List of boolean values with explode=true', () {
          expect(
            encoder.encode(
              [true, false, true],
              explode: true,
              allowEmpty: true,
            ),
            ['true', 'false', 'true'],
          );
        });

        test('encodes List with special characters and explode=true', () {
          expect(
            encoder.encode(
              ['item 1', 'item 2'],
              explode: true,
              allowEmpty: true,
            ),
            ['item+1', 'item+2'],
          );
        });

        test('encodes empty List when allowEmpty is true', () {
          expect(encoder.encode(<String>[], explode: true, allowEmpty: true), [
            '',
          ]);
        });

        test('throws when empty List and allowEmpty is false', () {
          expect(
            () => encoder.encode(<String>[], explode: true, allowEmpty: false),
            throwsA(isA<EmptyValueException>()),
          );
        });

        test('encodes Set with explode=true as separate values', () {
          final result = encoder.encode(
            {'red', 'green', 'blue'},
            explode: true,
            allowEmpty: true,
          );
          expect(result.length, 3);
          expect(result, contains('red'));
          expect(result, contains('green'));
          expect(result, contains('blue'));
        });

        test('throws when empty Set and allowEmpty is false', () {
          expect(
            () => encoder.encode(<String>{}, explode: true, allowEmpty: false),
            throwsA(isA<EmptyValueException>()),
          );
        });

        test('primitive values with explode=true return a single value', () {
          expect(encoder.encode('blue', explode: true, allowEmpty: true), [
            'blue',
          ]);
          expect(encoder.encode(25, explode: true, allowEmpty: true), ['25']);
        });

        test('throws when empty string and allowEmpty is false', () {
          expect(
            () => encoder.encode('', explode: true, allowEmpty: false),
            throwsA(isA<EmptyValueException>()),
          );
        });
      });
    });

    group('with space delimiter', () {
      late DelimitedEncoder encoder;

      setUp(() {
        encoder = const DelimitedEncoder.spaced();
      });

      test('encodes String value', () {
        expect(encoder.encode('blue', explode: false, allowEmpty: true), [
          'blue',
        ]);
      });

      test('encodes String value with special characters', () {
        expect(encoder.encode('John Doe', explode: false, allowEmpty: true), [
          'John+Doe',
        ]);
      });

      test('encodes int value', () {
        expect(encoder.encode(25, explode: false, allowEmpty: true), ['25']);
      });

      test('encodes double value', () {
        expect(encoder.encode(19.99, explode: false, allowEmpty: true), [
          '19.99',
        ]);
      });

      test('encodes boolean values', () {
        expect(encoder.encode(true, explode: false, allowEmpty: true), [
          'true',
        ]);
        expect(encoder.encode(false, explode: false, allowEmpty: true), [
          'false',
        ]);
      });

      test('encodes Uri value', () {
        final uri = Uri.parse('https://example.com/api/v1');
        expect(encoder.encode(uri, explode: false, allowEmpty: true), [
          'https://example.com/api/v1',
        ]);
      });

      test('encodes Uri value with special characters', () {
        final uri = Uri.parse('https://example.com/search?q=hello world');
        expect(encoder.encode(uri, explode: false, allowEmpty: true), [
          'https://example.com/search?q=hello%20world',
        ]);
      });

      test('encodes null value when allowEmpty is true', () {
        expect(encoder.encode(null, explode: false, allowEmpty: true), ['']);
      });

      test('throws when null value and allowEmpty is false', () {
        expect(
          () => encoder.encode(null, explode: false, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('encodes List of primitive values with explode=false', () {
        expect(
          encoder.encode(
            ['red', 'green', 'blue'],
            explode: false,
            allowEmpty: true,
          ),
          ['red%20green%20blue'],
        );
      });

      test('encodes List of boolean values with explode=false', () {
        expect(
          encoder.encode([true, false, true], explode: false, allowEmpty: true),
          ['true%20false%20true'],
        );
      });

      test('encodes List with special characters with explode=false', () {
        expect(
          encoder.encode(
            ['item 1', 'item 2'],
            explode: false,
            allowEmpty: true,
          ),
          ['item+1%20item+2'],
        );
      });

      test('encodes empty List when allowEmpty is true', () {
        expect(encoder.encode(<String>[], explode: false, allowEmpty: true), [
          '',
        ]);
      });

      test('throws when empty List and allowEmpty is false', () {
        expect(
          () => encoder.encode(<String>[], explode: false, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('encodes Set of primitive values with explode=false', () {
        expect(
          encoder.encode(
            {'red', 'green', 'blue'},
            explode: false,
            allowEmpty: true,
          ),
          ['red%20green%20blue'],
        );
      });

      test('throws when empty Set and allowEmpty is false', () {
        expect(
          () => encoder.encode(<String>{}, explode: false, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('throws exception for Map values', () {
        expect(
          () => encoder.encode(
            {'key': 'value'},
            explode: false,
            allowEmpty: true,
          ),
          throwsA(isA<UnsupportedEncodingTypeException>()),
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

      group('with explode=true', () {
        test('encodes List with explode=true as separate values', () {
          expect(
            encoder.encode(
              ['red', 'green', 'blue'],
              explode: true,
              allowEmpty: true,
            ),
            ['red', 'green', 'blue'],
          );
        });

        test('encodes List of boolean values with explode=true', () {
          expect(
            encoder.encode(
              [true, false, true],
              explode: true,
              allowEmpty: true,
            ),
            ['true', 'false', 'true'],
          );
        });

        test('encodes List with special characters and explode=true', () {
          expect(
            encoder.encode(
              ['item 1', 'item 2'],
              explode: true,
              allowEmpty: true,
            ),
            ['item+1', 'item+2'],
          );
        });

        test('encodes empty List when allowEmpty is true', () {
          expect(encoder.encode(<String>[], explode: true, allowEmpty: true), [
            '',
          ]);
        });

        test('throws when empty List and allowEmpty is false', () {
          expect(
            () => encoder.encode(<String>[], explode: true, allowEmpty: false),
            throwsA(isA<EmptyValueException>()),
          );
        });

        test('encodes Set with explode=true as separate values', () {
          final result = encoder.encode(
            {'red', 'green', 'blue'},
            explode: true,
            allowEmpty: true,
          );
          expect(result.length, 3);
          expect(result, contains('red'));
          expect(result, contains('green'));
          expect(result, contains('blue'));
        });

        test('throws when empty Set and allowEmpty is false', () {
          expect(
            () => encoder.encode(<String>{}, explode: true, allowEmpty: false),
            throwsA(isA<EmptyValueException>()),
          );
        });

        test('primitive values with explode=true return a single value', () {
          expect(encoder.encode('blue', explode: true, allowEmpty: true), [
            'blue',
          ]);
          expect(encoder.encode(25, explode: true, allowEmpty: true), ['25']);
        });

        test('throws when empty string and allowEmpty is false', () {
          expect(
            () => encoder.encode('', explode: true, allowEmpty: false),
            throwsA(isA<EmptyValueException>()),
          );
        });
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
              ['http%3A%2F%2Fexample.com'],
            );
          });

          test('encodes forward slash (/) properly', () {
            expect(
              encoder.encode('/api/v1/users', explode: false, allowEmpty: true),
              ['%2Fapi%2Fv1%2Fusers'],
            );
          });

          test('encodes question mark (?) properly', () {
            expect(
              encoder.encode(
                'search?term=test',
                explode: false,
                allowEmpty: true,
              ),
              ['search%3Fterm%3Dtest'],
            );
          });

          test('encodes hash (#) properly', () {
            expect(
              encoder.encode('page#section1', explode: false, allowEmpty: true),
              ['page%23section1'],
            );
          });

          test('encodes square brackets ([]) properly', () {
            expect(
              encoder.encode('[2001:db8::1]', explode: false, allowEmpty: true),
              ['%5B2001%3Adb8%3A%3A1%5D'],
            );
          });

          test('encodes at symbol (@) properly', () {
            expect(
              encoder.encode(
                'user@example.com',
                explode: false,
                allowEmpty: true,
              ),
              ['user%40example.com'],
            );
          });
        });

        group('sub-delims characters', () {
          test('encodes exclamation mark (!) properly', () {
            expect(
              encoder.encode('Hello!', explode: false, allowEmpty: true),
              ['Hello%21'],
            );
          });

          test(r'encodes dollar sign ($) properly', () {
            expect(
              encoder.encode(r'$19.99', explode: false, allowEmpty: true),
              ['%2419.99'],
            );
          });

          test('encodes ampersand (&) properly', () {
            expect(
              encoder.encode(
                'Johnson & Johnson',
                explode: false,
                allowEmpty: true,
              ),
              ['Johnson+%26+Johnson'],
            );
          });

          test("encodes single quote (') properly", () {
            expect(
              encoder.encode("It's working", explode: false, allowEmpty: true),
              ['It%27s+working'],
            );
          });

          test('encodes parentheses () properly', () {
            expect(
              encoder.encode(
                '(555) 123-4567',
                explode: false,
                allowEmpty: true,
              ),
              ['%28555%29+123-4567'],
            );
          });

          test('encodes asterisk (*) properly', () {
            expect(
              encoder.encode('file*.txt', explode: false, allowEmpty: true),
              ['file%2A.txt'],
            );
          });

          test('encodes plus (+) properly', () {
            expect(
              encoder.encode('2+2=4', explode: false, allowEmpty: true),
              ['2%2B2%3D4'],
            );
          });

          test('encodes comma (,) properly', () {
            expect(
              encoder.encode(
                'apple,banana,cherry',
                explode: false,
                allowEmpty: true,
              ),
              ['apple%2Cbanana%2Ccherry'],
            );
          });

          test('encodes semicolon (;) properly', () {
            expect(
              encoder.encode('a=1;b=2', explode: false, allowEmpty: true),
              ['a%3D1%3Bb%3D2'],
            );
          });

          test('encodes equals (=) properly', () {
            expect(
              encoder.encode('x=y', explode: false, allowEmpty: true),
              ['x%3Dy'],
            );
          });
        });

        group('unreserved characters should NOT be encoded', () {
          test('does not encode letters', () {
            expect(
              encoder.encode('ABCdef', explode: false, allowEmpty: true),
              ['ABCdef'],
            );
          });

          test('does not encode digits', () {
            expect(
              encoder.encode('1234567890', explode: false, allowEmpty: true),
              ['1234567890'],
            );
          });

          test('does not encode hyphen (-)', () {
            expect(
              encoder.encode(
                '123e4567-e89b-12d3',
                explode: false,
                allowEmpty: true,
              ),
              ['123e4567-e89b-12d3'],
            );
          });

          test('does not encode period (.)', () {
            expect(
              encoder.encode('example.com', explode: false, allowEmpty: true),
              ['example.com'],
            );
          });

          test('does not encode underscore (_)', () {
            expect(
              encoder.encode('my_variable', explode: false, allowEmpty: true),
              ['my_variable'],
            );
          });

          test('does not encode tilde (~)', () {
            expect(
              encoder.encode('~%2Fdocuments', explode: false, allowEmpty: true),
              ['~%252Fdocuments'],
            );
          });
        });

        group('percent-encoding normalization', () {
          test('uses uppercase hex digits for encoding', () {
            expect(
              encoder.encode('hello world!', explode: false, allowEmpty: true),
              ['hello+world%21'],
            );
          });

          test('properly encodes non-ASCII characters', () {
            expect(
              encoder.encode('café', explode: false, allowEmpty: true),
              ['caf%C3%A9'],
            );
          });

          test('properly encodes emoji', () {
            expect(
              encoder.encode('👍', explode: false, allowEmpty: true),
              ['%F0%9F%91%8D'],
            );
          });

          test('properly encodes Chinese characters', () {
            expect(
              encoder.encode('你好', explode: false, allowEmpty: true),
              ['%E4%BD%A0%E5%A5%BD'],
            );
          });
        });
      });
    });
  });
}
