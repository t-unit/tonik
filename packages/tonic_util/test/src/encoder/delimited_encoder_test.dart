import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonic_util/src/encoding/delimited_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';

void main() {
  group('DelimitedEncoder', () {

    group('with pipe delimiter', () {
      late DelimitedEncoder encoder;

      setUp(() {
        encoder = const DelimitedEncoder.piped();
      });

      test('encodes String value', () {
        expect(encoder.encode('blue'), ['blue']);
      });

      test('encodes String value with special characters', () {
        expect(encoder.encode('John Doe'), ['John+Doe']);
      });

      test('encodes int value', () {
        expect(encoder.encode(25), ['25']);
      });

      test('encodes double value', () {
        expect(encoder.encode(19.99), ['19.99']);
      });

      test('encodes BigDecimal value', () {
        final bigDecimal = BigDecimal.parse('123456789012345678901234.56789');
        expect(encoder.encode(bigDecimal), ['123456789012345678901234.56789']);
      });

      test('encodes boolean values', () {
        expect(encoder.encode(true), ['true']);
        expect(encoder.encode(false), ['false']);
      });

      test('encodes Uri value', () {
        final uri = Uri.parse('https://example.com/path?query=value');
        expect(encoder.encode(uri), [
          'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
        ]);
      });

      test('encodes null value', () {
        expect(encoder.encode(null), ['']);
      });

      test('encodes List of primitive values with explode=false', () {
        expect(encoder.encode(['red', 'green', 'blue']), ['red|green|blue']);
      });

      test('encodes List of boolean values with explode=false', () {
        expect(encoder.encode([true, false, true]), ['true|false|true']);
      });

      test('encodes List with special characters with explode=false', () {
        expect(encoder.encode(['item 1', 'item 2']), ['item+1|item+2']);
      });

      test('encodes empty List with explode=false', () {
        expect(encoder.encode(<String>[]), ['']);
      });

      test('encodes Set of primitive values with explode=false', () {
        expect(encoder.encode({'red', 'green', 'blue'}), ['red|green|blue']);
      });

      test('throws exception for Map values', () {
        expect(
          () => encoder.encode({'key': 'value'}),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for complex object', () {
        final complexObject = Object();
        expect(
          () => encoder.encode(complexObject),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for nested Lists', () {
        expect(
          () => encoder.encode([
            ['nested'],
          ]),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      group('with explode=true', () {
        test('encodes List with explode=true as separate values', () {
          expect(encoder.encode(['red', 'green', 'blue'], explode: true), [
            'red',
            'green',
            'blue',
          ]);
        });

        test('encodes List of boolean values with explode=true', () {
          expect(encoder.encode([true, false, true], explode: true), [
            'true',
            'false',
            'true',
          ]);
        });

        test('encodes List with special characters and explode=true', () {
          expect(encoder.encode(['item 1', 'item 2'], explode: true), [
            'item+1',
            'item+2',
          ]);
        });

        test('encodes empty List with explode=true', () {
          expect(encoder.encode(<String>[], explode: true), ['']);
        });

        test('encodes Set with explode=true as separate values', () {
          final result = encoder.encode({
            'red',
            'green',
            'blue',
          }, explode: true,);
          expect(result.length, 3);
          expect(result, contains('red'));
          expect(result, contains('green'));
          expect(result, contains('blue'));
        });

        test('primitive values with explode=true return a single value', () {
          expect(encoder.encode('blue', explode: true), ['blue']);
          expect(encoder.encode(25, explode: true), ['25']);
          expect(encoder.encode(null, explode: true), ['']);
        });
      });
    });

    group('with space delimiter', () {
      late DelimitedEncoder encoder;

      setUp(() {
        encoder = const DelimitedEncoder.spaced();
      });

      test('encodes String value', () {
        expect(encoder.encode('blue'), ['blue']);
      });

      test('encodes String value with special characters', () {
        expect(encoder.encode('John Doe'), ['John+Doe']);
      });

      test('encodes int value', () {
        expect(encoder.encode(25), ['25']);
      });

      test('encodes double value', () {
        expect(encoder.encode(19.99), ['19.99']);
      });

      test('encodes BigDecimal value', () {
        final bigDecimal = BigDecimal.parse('123456789012345678901234.56789');
        expect(encoder.encode(bigDecimal), ['123456789012345678901234.56789']);
      });

      test('encodes boolean values', () {
        expect(encoder.encode(true), ['true']);
        expect(encoder.encode(false), ['false']);
      });

      test('encodes Uri value', () {
        final uri = Uri.parse('https://example.com/path?query=value');
        expect(encoder.encode(uri), [
          'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
        ]);
      });

      test('encodes null value', () {
        expect(encoder.encode(null), ['']);
      });

      test('encodes List of primitive values with explode=false', () {
        expect(encoder.encode(['red', 'green', 'blue']), [
          'red%20green%20blue',
        ]);
      });

      test('encodes List of boolean values with explode=false', () {
        expect(encoder.encode([true, false, true]), ['true%20false%20true']);
      });

      test('encodes List with special characters with explode=false', () {
        expect(encoder.encode(['item 1', 'item 2']), ['item+1%20item+2']);
      });

      test('encodes empty List with explode=false', () {
        expect(encoder.encode(<String>[]), ['']);
      });

      test('encodes Set of primitive values with explode=false', () {
        expect(encoder.encode({'red', 'green', 'blue'}), [
          'red%20green%20blue',
        ]);
      });

      test('throws exception for Map values', () {
        expect(
          () => encoder.encode({'key': 'value'}),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for complex object', () {
        final complexObject = Object();
        expect(
          () => encoder.encode(complexObject),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws exception for nested Lists', () {
        expect(
          () => encoder.encode([
            ['nested'],
          ]),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      group('with explode=true', () {
        test('encodes List with explode=true as separate values', () {
          expect(encoder.encode(['red', 'green', 'blue'], explode: true), [
            'red',
            'green',
            'blue',
          ]);
        });

        test('encodes List of boolean values with explode=true', () {
          expect(encoder.encode([true, false, true], explode: true), [
            'true',
            'false',
            'true',
          ]);
        });

        test('encodes List with special characters and explode=true', () {
          expect(encoder.encode(['item 1', 'item 2'], explode: true), [
            'item+1',
            'item+2',
          ]);
        });

        test('encodes empty List with explode=true', () {
          expect(encoder.encode(<String>[], explode: true), ['']);
        });

        test('encodes Set with explode=true as separate values', () {
          final result = encoder.encode({
            'red',
            'green',
            'blue',
          }, explode: true,);
          expect(result.length, 3);
          expect(result, contains('red'));
          expect(result, contains('green'));
          expect(result, contains('blue'));
        });

        test('primitive values with explode=true return a single value', () {
          expect(encoder.encode('blue', explode: true), ['blue']);
          expect(encoder.encode(25, explode: true), ['25']);
          expect(encoder.encode(null, explode: true), ['']);
        });
      });
    });
  });
}
