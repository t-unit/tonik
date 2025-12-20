import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/form_encoder_extensions.dart';

void main() {
  group('FormUriEncoder', () {
    test('encodes Uri values with URL encoding', () {
      final uri = Uri.parse('https://example.com/path?query=value');
      expect(
        uri.toForm(explode: false, allowEmpty: true),
        'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
      );
      expect(
        uri.toForm(explode: true, allowEmpty: true),
        'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
      );
    });

    test('handles special characters in URI', () {
      final uri = Uri.parse('https://example.com/path with spaces');
      expect(
        uri.toForm(explode: false, allowEmpty: true),
        'https%3A%2F%2Fexample.com%2Fpath%2520with%2520spaces',
      );
    });
  });

  group('FormStringEncoder', () {
    test('encodes string values with URL encoding', () {
      expect(
        'hello world'.toForm(explode: false, allowEmpty: true),
        'hello%20world',
      );
      expect(
        'test@example.com'.toForm(explode: true, allowEmpty: true),
        'test%40example.com',
      );
    });

    test('handles empty strings based on allowEmpty', () {
      expect(
        ''.toForm(explode: false, allowEmpty: true),
        '',
      );
      expect(
        () => ''.toForm(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes special characters', () {
      expect(
        'key=value&other=data'.toForm(explode: false, allowEmpty: true),
        'key%3Dvalue%26other%3Ddata',
      );
      expect(
        'hello+world'.toForm(explode: false, allowEmpty: true),
        'hello%2Bworld',
      );
    });
  });

  group('FormIntEncoder', () {
    test('encodes integer values as strings', () {
      expect(42.toForm(explode: false, allowEmpty: true), '42');
      expect((-123).toForm(explode: true, allowEmpty: true), '-123');
      expect(0.toForm(explode: false, allowEmpty: false), '0');
    });
  });

  group('FormDoubleEncoder', () {
    test('encodes double values as URL-encoded strings', () {
      expect(3.14.toForm(explode: false, allowEmpty: true), '3.14');
      expect((-2.5).toForm(explode: true, allowEmpty: true), '-2.5');
      expect(0.0.toForm(explode: false, allowEmpty: false), '0.0');
    });

    test('handles scientific notation', () {
      expect(1.23e-4.toForm(explode: false, allowEmpty: true), '0.000123');
      expect(1.23e10.toForm(explode: false, allowEmpty: true), '12300000000.0');
    });
  });

  group('FormNumEncoder', () {
    test('encodes num values as strings', () {
      const num intValue = 42;
      const num doubleValue = 3.14;

      expect(intValue.toForm(explode: false, allowEmpty: true), '42');
      expect(doubleValue.toForm(explode: true, allowEmpty: true), '3.14');
    });
  });

  group('FormBoolEncoder', () {
    test('encodes boolean values as strings', () {
      expect(true.toForm(explode: false, allowEmpty: true), 'true');
      expect(false.toForm(explode: true, allowEmpty: true), 'false');
      expect(true.toForm(explode: false, allowEmpty: false), 'true');
    });
  });

  group('FormDateTimeEncoder', () {
    test('encodes DateTime values as URL-encoded ISO strings', () {
      final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
      final encoded = dateTime.toForm(explode: false, allowEmpty: true);

      // Should be URL-encoded ISO string
      expect(encoded, contains('2023-12-25T10%3A30%3A45'));
      expect(encoded, contains('Z'));
    });

    test('handles different DateTime formats', () {
      final localDateTime = DateTime(2023, 6, 15, 14, 30);
      final encoded = localDateTime.toForm(explode: true, allowEmpty: true);

      expect(encoded, isNotEmpty);
      expect(encoded, contains('2023-06-15T14%3A30%3A'));
    });
  });

  group('FormBigDecimalEncoder', () {
    test('encodes BigDecimal values as strings', () {
      final decimal = BigDecimal.parse('123.456789');
      expect(
        decimal.toForm(explode: false, allowEmpty: true),
        '123.456789',
      );

      final largeDecimal = BigDecimal.parse('999999999999.123456789');
      expect(
        largeDecimal.toForm(explode: true, allowEmpty: true),
        '999999999999.123456789',
      );
    });

    test('handles zero and negative values', () {
      expect(
        BigDecimal.zero.toForm(explode: false, allowEmpty: true),
        '0',
      );
      expect(
        BigDecimal.parse('-42.5').toForm(explode: false, allowEmpty: true),
        '-42.5',
      );
    });
  });

  group('FormStringListEncoder', () {
    test('encodes lists with explode=false as comma-separated', () {
      expect(
        ['red', 'green', 'blue'].toForm(explode: false, allowEmpty: true),
        'red,green,blue',
      );
      expect(
        [
          'hello world',
          'test@example.com',
        ].toForm(explode: false, allowEmpty: true),
        'hello%20world,test%40example.com',
      );
    });

    test(
      'encodes lists with explode=true as comma-separated (parameter level '
      'handles repetition)',
      () {
        // Note: According to OpenAPI spec, explode=true for arrays means the
        // parameter name is repeated for each value, but at the value level we
        // still use commas
        expect(
          ['red', 'green', 'blue'].toForm(explode: true, allowEmpty: true),
          'red,green,blue',
        );
        expect(
          [
            'hello world',
            'test@example.com',
          ].toForm(explode: true, allowEmpty: true),
          'hello%20world,test%40example.com',
        );
      },
    );

    test('handles empty lists based on allowEmpty', () {
      expect(
        <String>[].toForm(explode: false, allowEmpty: true),
        '',
      );
      expect(
        <String>[].toForm(explode: true, allowEmpty: true),
        '',
      );
      expect(
        () => <String>[].toForm(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
      expect(
        () => <String>[].toForm(explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('handles single item lists', () {
      expect(
        ['single'].toForm(explode: false, allowEmpty: true),
        'single',
      );
      expect(
        ['single'].toForm(explode: true, allowEmpty: true),
        'single',
      );
    });

    test('URL-encodes special characters in list items', () {
      expect(
        ['key=value', 'other&data'].toForm(explode: false, allowEmpty: true),
        'key%3Dvalue,other%26data',
      );
      expect(
        ['key=value', 'other&data'].toForm(explode: true, allowEmpty: true),
        'key%3Dvalue,other%26data',
      );
    });
  });

  group('FormStringMapEncoder', () {
    test(
      'encodes maps with explode=false as comma-separated key,value pairs',
      () {
        expect(
          {
            'name': 'John',
            'age': '25',
          }.toForm(explode: false, allowEmpty: true),
          'name,John,age,25',
        );
        expect(
          {
            'key': 'hello world',
            'other': 'test@example.com',
          }.toForm(explode: false, allowEmpty: true),
          'key,hello%20world,other,test%40example.com',
        );
      },
    );

    test(
      'encodes maps with explode=true as ampersand-separated key=value pairs',
      () {
        expect(
          {'name': 'John', 'age': '25'}.toForm(explode: true, allowEmpty: true),
          'name=John&age=25',
        );
        expect(
          {
            'key': 'hello world',
            'other': 'test@example.com',
          }.toForm(explode: true, allowEmpty: true),
          'key=hello%20world&other=test%40example.com',
        );
      },
    );

    test('handles empty maps based on allowEmpty', () {
      expect(
        <String, String>{}.toForm(explode: false, allowEmpty: true),
        '',
      );
      expect(
        <String, String>{}.toForm(explode: true, allowEmpty: true),
        '',
      );
      expect(
        () => <String, String>{}.toForm(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
      expect(
        () => <String, String>{}.toForm(explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('handles single entry maps', () {
      expect(
        {'key': 'value'}.toForm(explode: false, allowEmpty: true),
        'key,value',
      );
      expect(
        {'key': 'value'}.toForm(explode: true, allowEmpty: true),
        'key=value',
      );
    });

    test('URL-encodes special characters in keys and values', () {
      expect(
        {
          'key=name': 'value&data',
          'other+key': 'more data',
        }.toForm(explode: false, allowEmpty: true),
        'key=name,value%26data,other+key,more%20data',
      );
      expect(
        {
          'key=name': 'value&data',
          'other+key': 'more data',
        }.toForm(explode: true, allowEmpty: true),
        'key%3Dname=value%26data&other%2Bkey=more%20data',
      );
    });

    test('handles already encoded values when alreadyEncoded=true', () {
      expect(
        {
          'email': 'albert%40example.com',
          'name': 'John%20Doe',
        }.toForm(explode: false, allowEmpty: true, alreadyEncoded: true),
        'email,albert%40example.com,name,John%20Doe',
      );
      expect(
        {
          'email': 'albert%40example.com',
          'name': 'John%20Doe',
        }.toForm(explode: true, allowEmpty: true, alreadyEncoded: true),
        'email=albert%40example.com&name=John%20Doe',
      );
    });

    test('maintains consistent key ordering', () {
      final map = {'z': '1', 'a': '2', 'm': '3'};
      final result1 = map.toForm(explode: false, allowEmpty: true);
      final result2 = map.toForm(explode: false, allowEmpty: true);

      // Results should be consistent (though order may vary by implementation)
      expect(result1, result2);
      expect(result1, contains('z,1'));
      expect(result1, contains('a,2'));
      expect(result1, contains('m,3'));
    });
  });

  group('Form encoding edge cases', () {
    test('handles null-like string values', () {
      expect('null'.toForm(explode: false, allowEmpty: true), 'null');
      expect('undefined'.toForm(explode: false, allowEmpty: true), 'undefined');
    });

    test('handles unicode characters', () {
      expect(
        'héllo wörld'.toForm(explode: false, allowEmpty: true),
        'h%C3%A9llo%20w%C3%B6rld',
      );
      expect(
        ['emoji 😀', 'unicode ñ'].toForm(explode: false, allowEmpty: true),
        'emoji%20%F0%9F%98%80,unicode%20%C3%B1',
      );
    });

    test('handles very long strings', () {
      final longString = 'a' * 1000;
      final encoded = longString.toForm(explode: false, allowEmpty: true);
      expect(
        encoded,
        'a' * 1000,
      ); // No special chars, so no encoding needed
    });

    test('handles extreme numeric values', () {
      expect(
        double.infinity.toForm(explode: false, allowEmpty: true),
        'Infinity',
      );
      expect(
        double.negativeInfinity.toForm(explode: false, allowEmpty: true),
        '-Infinity',
      );
      expect(double.nan.toForm(explode: false, allowEmpty: true), 'NaN');
    });
  });

  group('FormBinaryEncoder', () {
    test('encodes List<int> to UTF-8 string with URL encoding', () {
      const value = [72, 101, 108, 108, 111]; // "Hello"
      expect(
        value.toForm(explode: false, allowEmpty: true),
        'Hello',
      );
    });

    test('encodes empty List<int>', () {
      const value = <int>[];
      expect(
        value.toForm(explode: false, allowEmpty: true),
        '',
      );
    });

    test('encodes List<int> with special characters', () {
      const value = [72, 195, 171, 108, 108, 195, 182]; // "Hëllö"
      expect(
        value.toForm(explode: false, allowEmpty: true),
        'H%C3%ABll%C3%B6',
      );
    });

    test('throws EmptyValueException when empty and allowEmpty=false', () {
      const value = <int>[];
      expect(
        () => value.toForm(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('explode parameter has no effect', () {
      const value = [72, 101, 108, 108, 111];
      expect(
        value.toForm(explode: true, allowEmpty: true),
        value.toForm(explode: false, allowEmpty: true),
      );
    });
  });
}
