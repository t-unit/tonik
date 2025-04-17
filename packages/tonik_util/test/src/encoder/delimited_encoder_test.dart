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
    });
  });
}
