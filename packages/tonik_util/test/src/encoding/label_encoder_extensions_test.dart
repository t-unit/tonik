import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/label_encoder_extensions.dart';

void main() {
  group('LabelStringEncoder', () {
    test('encodes String value', () {
      expect('blue'.toLabel(explode: false, allowEmpty: true), '.blue');
    });

    test('encodes String value with special characters', () {
      expect(
        'John Doe'.toLabel(explode: false, allowEmpty: true),
        '.John%20Doe',
      );
    });

    test('encodes empty String when allowEmpty is true', () {
      expect(''.toLabel(explode: false, allowEmpty: true), '.');
    });

    test('throws exception for empty String when allowEmpty is false', () {
      expect(
        () => ''.toLabel(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('explode parameter has no effect on primitives', () {
      expect('blue'.toLabel(explode: true, allowEmpty: true), '.blue');
    });
  });

  group('LabelIntEncoder', () {
    test('encodes int value', () {
      expect(25.toLabel(explode: false, allowEmpty: true), '.25');
    });

    test('explode parameter has no effect on primitives', () {
      expect(25.toLabel(explode: true, allowEmpty: true), '.25');
    });
  });

  group('LabelDoubleEncoder', () {
    test('encodes double value', () {
      expect(19.99.toLabel(explode: false, allowEmpty: true), '.19.99');
    });

    test('explode parameter has no effect on primitives', () {
      expect(19.99.toLabel(explode: true, allowEmpty: true), '.19.99');
    });
  });

  group('LabelNumEncoder', () {
    test('encodes num value', () {
      const num value = 42;
      expect(value.toLabel(explode: false, allowEmpty: true), '.42');
    });

    test('explode parameter has no effect on primitives', () {
      const num value = 42;
      expect(value.toLabel(explode: true, allowEmpty: true), '.42');
    });
  });

  group('LabelBoolEncoder', () {
    test('encodes boolean values', () {
      expect(true.toLabel(explode: false, allowEmpty: true), '.true');
      expect(false.toLabel(explode: false, allowEmpty: true), '.false');
    });

    test('explode parameter has no effect on primitives', () {
      expect(true.toLabel(explode: true, allowEmpty: true), '.true');
      expect(false.toLabel(explode: true, allowEmpty: true), '.false');
    });
  });

  group('LabelUriEncoder', () {
    test('encodes Uri value', () {
      final uri = Uri.parse('https://example.com/api/v1');
      expect(
        uri.toLabel(explode: false, allowEmpty: true),
        '.https%3A%2F%2Fexample.com%2Fapi%2Fv1',
      );
    });

    test('encodes Uri value with special characters', () {
      final uri = Uri.parse('https://example.com/search?q=hello world');
      expect(
        uri.toLabel(explode: false, allowEmpty: true),
        '.https%3A%2F%2Fexample.com%2Fsearch%3Fq%3Dhello%2520world',
      );
    });

    test('explode parameter has no effect on primitives', () {
      final uri = Uri.parse('https://example.com/api/v1');
      expect(
        uri.toLabel(explode: true, allowEmpty: true),
        '.https%3A%2F%2Fexample.com%2Fapi%2Fv1',
      );
    });
  });

  group('LabelDateTimeEncoder', () {
    test('encodes DateTime value', () {
      final dateTime = DateTime.utc(2023, 1, 15, 10, 30, 45);
      expect(
        dateTime.toLabel(explode: false, allowEmpty: true),
        '.2023-01-15T10%3A30%3A45.000Z',
      );
    });

    test('explode parameter has no effect on primitives', () {
      final dateTime = DateTime.utc(2023, 1, 15, 10, 30, 45);
      expect(
        dateTime.toLabel(explode: true, allowEmpty: true),
        '.2023-01-15T10%3A30%3A45.000Z',
      );
    });
  });

  group('LabelBigDecimalEncoder', () {
    test('encodes BigDecimal value', () {
      final decimal = BigDecimal.parse('123.456');
      expect(
        decimal.toLabel(explode: false, allowEmpty: true),
        '.123.456',
      );
    });

    test('explode parameter has no effect on primitives', () {
      final decimal = BigDecimal.parse('123.456');
      expect(
        decimal.toLabel(explode: true, allowEmpty: true),
        '.123.456',
      );
    });
  });

  group('LabelStringListEncoder', () {
    test('encodes List of primitive values with explode=false', () {
      expect(
        ['red', 'green', 'blue'].toLabel(explode: false, allowEmpty: true),
        '.red,green,blue',
      );
    });

    test('encodes List with special characters and explode=false', () {
      expect(
        ['item 1', 'item 2'].toLabel(explode: false, allowEmpty: true),
        '.item%201,item%202',
      );
    });

    test('encodes List with explode=true', () {
      expect(
        ['red', 'green', 'blue'].toLabel(explode: true, allowEmpty: true),
        '.red.green.blue',
      );
    });

    test('encodes List with special characters and explode=true', () {
      expect(
        ['item 1', 'item 2'].toLabel(explode: true, allowEmpty: true),
        '.item%201.item%202',
      );
    });

    test('encodes empty List when allowEmpty is true', () {
      expect(
        <String>[].toLabel(explode: false, allowEmpty: true),
        '.',
      );
    });

    test('encodes empty List with explode=true when allowEmpty is true', () {
      expect(
        <String>[].toLabel(explode: true, allowEmpty: true),
        '.',
      );
    });

    test('throws exception for empty List when allowEmpty is false', () {
      expect(
        () => <String>[].toLabel(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test(
      'throws exception for empty List with explode=true '
      'when allowEmpty is false',
      () {
        expect(
          () => <String>[].toLabel(explode: true, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      },
    );
  });

  group('LabelStringMapEncoder', () {
    test('encodes object with explode=false', () {
      expect(
        {'x': '1', 'y': '2'}.toLabel(explode: false, allowEmpty: true),
        '.x,1,y,2',
      );
    });

    test('encodes object with string values and explode=false', () {
      expect(
        {'name': 'John', 'role': 'admin'}.toLabel(
          explode: false,
          allowEmpty: true,
        ),
        '.name,John,role,admin',
      );
    });

    test('encodes object with special characters and explode=false', () {
      expect(
        {'street': '123 Main St', 'city': 'New York'}.toLabel(
          explode: false,
          allowEmpty: true,
        ),
        '.street,123%20Main%20St,city,New%20York',
      );
    });

    test('encodes object with explode=true', () {
      expect(
        {'x': '1', 'y': '2'}.toLabel(explode: true, allowEmpty: true),
        '.x=1.y=2',
      );
    });

    test('encodes object with special characters and explode=true', () {
      expect(
        {'street': '123 Main St', 'city': 'New York'}.toLabel(
          explode: true,
          allowEmpty: true,
        ),
        '.street=123%20Main%20St.city=New%20York',
      );
    });

    test('encodes empty object when allowEmpty is true', () {
      expect(
        <String, String>{}.toLabel(explode: false, allowEmpty: true),
        '.',
      );
    });

    test('encodes empty object with explode=true when allowEmpty is true', () {
      expect(
        <String, String>{}.toLabel(explode: true, allowEmpty: true),
        '.',
      );
    });

    test('throws exception for empty object when allowEmpty is false', () {
      expect(
        () => <String, String>{}.toLabel(explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test(
      'throws exception for empty object with explode=true '
      'when allowEmpty is false',
      () {
        expect(
          () => <String, String>{}.toLabel(explode: true, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      },
    );
  });

  group('RFC 3986 reserved character encoding', () {
    group('gen-delims characters', () {
      test('encodes colon (:) properly', () {
        expect(
          'http://example.com'.toLabel(explode: false, allowEmpty: true),
          '.http%3A%2F%2Fexample.com',
        );
      });

      test('encodes forward slash (/) properly', () {
        expect(
          '/api/v1/users'.toLabel(explode: false, allowEmpty: true),
          '.%2Fapi%2Fv1%2Fusers',
        );
      });

      test('encodes question mark (?) properly', () {
        expect(
          'search?term=test'.toLabel(explode: false, allowEmpty: true),
          '.search%3Fterm%3Dtest',
        );
      });

      test('encodes hash (#) properly', () {
        expect(
          'page#section1'.toLabel(explode: false, allowEmpty: true),
          '.page%23section1',
        );
      });

      test('encodes square brackets ([]) properly', () {
        expect(
          '[2001:db8::1]'.toLabel(explode: false, allowEmpty: true),
          '.%5B2001%3Adb8%3A%3A1%5D',
        );
      });

      test('encodes at symbol (@) properly', () {
        expect(
          'user@example.com'.toLabel(explode: false, allowEmpty: true),
          '.user%40example.com',
        );
      });
    });

    group('sub-delims characters', () {
      test('encodes exclamation mark (!) properly', () {
        expect(
          'Hello!'.toLabel(explode: false, allowEmpty: true),
          '.Hello!',
        );
      });

      test(r'encodes dollar sign ($) properly', () {
        expect(
          r'$19.99'.toLabel(explode: false, allowEmpty: true),
          '.%2419.99',
        );
      });

      test('encodes ampersand (&) properly', () {
        expect(
          'Johnson & Johnson'.toLabel(explode: false, allowEmpty: true),
          '.Johnson%20%26%20Johnson',
        );
      });

      test("encodes single quote (') properly", () {
        expect(
          "It's working".toLabel(explode: false, allowEmpty: true),
          ".It's%20working",
        );
      });

      test('encodes parentheses () properly', () {
        expect(
          '(555) 123-4567'.toLabel(explode: false, allowEmpty: true),
          '.(555)%20123-4567',
        );
      });

      test('encodes asterisk (*) properly', () {
        expect(
          'file*.txt'.toLabel(explode: false, allowEmpty: true),
          '.file*.txt',
        );
      });

      test('encodes plus (+) properly', () {
        expect(
          '2+2=4'.toLabel(explode: false, allowEmpty: true),
          '.2%2B2%3D4',
        );
      });

      test('encodes comma (,) properly', () {
        expect(
          'apple,banana,cherry'.toLabel(explode: false, allowEmpty: true),
          '.apple%2Cbanana%2Ccherry',
        );
      });

      test('encodes semicolon (;) properly', () {
        expect(
          'a=1;b=2'.toLabel(explode: false, allowEmpty: true),
          '.a%3D1%3Bb%3D2',
        );
      });

      test('encodes equals (=) properly', () {
        expect(
          'x=y'.toLabel(explode: false, allowEmpty: true),
          '.x%3Dy',
        );
      });
    });

    group('percent-encoding normalization', () {
      test('properly encodes non-ASCII characters', () {
        expect(
          'café'.toLabel(explode: false, allowEmpty: true),
          '.caf%C3%A9',
        );
      });

      test('properly encodes emoji', () {
        expect(
          '👍'.toLabel(explode: false, allowEmpty: true),
          '.%F0%9F%91%8D',
        );
      });

      test('properly encodes Chinese characters', () {
        expect(
          '你好'.toLabel(explode: false, allowEmpty: true),
          '.%E4%BD%A0%E5%A5%BD',
        );
      });
    });
  });

  group('LabelStringMapEncoder alreadyEncoded parameter', () {
    test('alreadyEncoded=true prevents double encoding with explode=true', () {
      final map = {'key': 'hello%20world'};
      expect(
        map.toLabel(explode: true, allowEmpty: true, alreadyEncoded: true),
        '.key=hello%20world',
      );
    });

    test('alreadyEncoded=false encodes values with explode=true', () {
      final map = {'key': 'hello world'};
      expect(
        map.toLabel(explode: true, allowEmpty: true),
        '.key=hello%20world',
      );
    });

    test('alreadyEncoded=true prevents double encoding with explode=false', () {
      final map = {'key': 'hello%20world'};
      expect(
        map.toLabel(explode: false, allowEmpty: true, alreadyEncoded: true),
        '.key,hello%20world',
      );
    });

    test('alreadyEncoded=false encodes values with explode=false', () {
      final map = {'key': 'hello world'};
      expect(
        map.toLabel(explode: false, allowEmpty: true),
        '.key,hello%20world',
      );
    });

    test('alreadyEncoded parameter defaults to false', () {
      final map = {'key': 'hello world'};
      expect(
        map.toLabel(explode: false, allowEmpty: true),
        '.key,hello%20world',
      );
    });

    test('alreadyEncoded=true with mixed encoded and unencoded values', () {
      final map = {'x': '1%2B2', 'y': '3%2B4'};
      expect(
        map.toLabel(explode: false, allowEmpty: true, alreadyEncoded: true),
        '.x,1%2B2,y,3%2B4',
      );
    });

    test('alreadyEncoded=true with special characters in keys', () {
      final map = {'name': 'John%20Doe', 'role': 'admin%26user'};
      expect(
        map.toLabel(explode: true, allowEmpty: true, alreadyEncoded: true),
        '.name=John%20Doe.role=admin%26user',
      );
    });

    test('alreadyEncoded=true with empty values', () {
      final map = {'key1': '', 'key2': ''};
      expect(
        map.toLabel(explode: false, allowEmpty: true, alreadyEncoded: true),
        '.key1,,key2,',
      );
    });

    test('alreadyEncoded=true with Unicode characters', () {
      final map = {'greeting': '%E4%BD%A0%E5%A5%BD'};
      expect(
        map.toLabel(explode: true, allowEmpty: true, alreadyEncoded: true),
        '.greeting=%E4%BD%A0%E5%A5%BD',
      );
    });
  });
}
