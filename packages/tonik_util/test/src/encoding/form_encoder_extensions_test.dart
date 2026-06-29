import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/form_encoder_extensions.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';

void main() {
  group('FormUriEncoder', () {
    test('encodes Uri values as a single entry with URL encoding', () {
      final uri = Uri.parse('https://example.com/path?query=value');
      expect(
        uri.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[
          (
            name: 'p',
            value: 'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
          ),
        ],
      );
      expect(
        uri.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[
          (
            name: 'p',
            value: 'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
          ),
        ],
      );
    });

    test('handles special characters in URI', () {
      final uri = Uri.parse('https://example.com/path with spaces');
      expect(
        uri.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[
          (
            name: 'p',
            value: 'https%3A%2F%2Fexample.com%2Fpath%2520with%2520spaces',
          ),
        ],
      );
    });
  });

  group('FormStringEncoder', () {
    test('encodes string values as a single entry with URL encoding', () {
      expect(
        'hello world'.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'hello%20world')],
      );
      expect(
        'test@example.com'.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'test%40example.com')],
      );
    });

    test('handles empty strings based on allowEmpty', () {
      expect(
        ''.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '')],
      );
      expect(
        () => ''.toForm('p', explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes special characters', () {
      expect(
        'key=value&other=data'.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[
          (name: 'p', value: 'key%3Dvalue%26other%3Ddata'),
        ],
      );
      expect(
        'hello+world'.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'hello%2Bworld')],
      );
    });
  });

  group('FormIntEncoder', () {
    test('encodes integer values as a single entry', () {
      expect(
        42.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '42')],
      );
      expect(
        (-123).toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '-123')],
      );
      expect(
        0.toForm('p', explode: false, allowEmpty: false),
        const <ParameterEntry>[(name: 'p', value: '0')],
      );
    });
  });

  group('FormDoubleEncoder', () {
    test('encodes double values as a single entry', () {
      expect(
        3.14.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '3.14')],
      );
      expect(
        (-2.5).toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '-2.5')],
      );
      expect(
        0.0.toForm('p', explode: false, allowEmpty: false),
        const <ParameterEntry>[(name: 'p', value: '0.0')],
      );
    });

    test('handles scientific notation', () {
      expect(
        1.23e-4.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '0.000123')],
      );
      expect(
        1.23e10.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '12300000000.0')],
      );
    });
  });

  group('FormNumEncoder', () {
    test('encodes num values as a single entry', () {
      const num intValue = 42;
      const num doubleValue = 3.14;

      expect(
        intValue.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '42')],
      );
      expect(
        doubleValue.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '3.14')],
      );
    });
  });

  group('FormBoolEncoder', () {
    test('encodes boolean values as a single entry', () {
      expect(
        true.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'true')],
      );
      expect(
        false.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'false')],
      );
    });
  });

  group('FormDateTimeEncoder', () {
    test('encodes DateTime values as a single URL-encoded ISO entry', () {
      final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
      final encoded = dateTime.toForm('p', explode: false, allowEmpty: true);

      expect(encoded, hasLength(1));
      expect(encoded.single.name, 'p');
      expect(encoded.single.value, contains('2023-12-25T10%3A30%3A45'));
      expect(encoded.single.value, contains('Z'));
    });
  });

  group('FormBigDecimalEncoder', () {
    test('encodes BigDecimal values as a single entry', () {
      final decimal = BigDecimal.parse('123.456789');
      expect(
        decimal.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '123.456789')],
      );
    });

    test('handles zero and negative values', () {
      expect(
        BigDecimal.zero.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '0')],
      );
      expect(
        BigDecimal.parse('-42.5').toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '-42.5')],
      );
    });
  });

  group('FormStringListEncoder', () {
    test('explode=false joins items into a single comma-separated entry', () {
      expect(
        ['red', 'green', 'blue'].toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'red,green,blue')],
      );
      expect(
        [
          'hello world',
          'test@example.com',
        ].toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[
          (name: 'p', value: 'hello%20world,test%40example.com'),
        ],
      );
    });

    test('explode=true emits one entry per item, all named paramName', () {
      expect(
        ['red', 'green', 'blue'].toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[
          (name: 'p', value: 'red'),
          (name: 'p', value: 'green'),
          (name: 'p', value: 'blue'),
        ],
      );
      expect(
        [
          'hello world',
          'test@example.com',
        ].toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[
          (name: 'p', value: 'hello%20world'),
          (name: 'p', value: 'test%40example.com'),
        ],
      );
    });

    test('empty list with explode=false yields a single empty-value entry', () {
      expect(
        <String>[].toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '')],
      );
    });

    test('empty list with explode=true yields no entries', () {
      expect(
        <String>[].toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[],
      );
    });

    test('empty list throws when allowEmpty=false', () {
      expect(
        () => <String>[].toForm('p', explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
      expect(
        () => <String>[].toForm('p', explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('URL-encodes special characters in list items', () {
      expect(
        [
          'key=value',
          'other&data',
        ].toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'key%3Dvalue,other%26data')],
      );
      expect(
        [
          'key=value',
          'other&data',
        ].toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[
          (name: 'p', value: 'key%3Dvalue'),
          (name: 'p', value: 'other%26data'),
        ],
      );
    });
  });

  group('FormStringMapEncoder', () {
    test('explode=false yields a single comma-separated key,value entry', () {
      expect(
        {
          'name': 'John',
          'age': '25',
        }.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'name,John,age,25')],
      );
      expect(
        {
          'key': 'hello world',
          'other': 'test@example.com',
        }.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[
          (name: 'p', value: 'key,hello%20world,other,test%40example.com'),
        ],
      );
    });

    test('explode=true emits one entry per property keyed by the bare key', () {
      expect(
        {
          'name': 'John',
          'age': '25',
        }.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[
          (name: 'name', value: 'John'),
          (name: 'age', value: '25'),
        ],
      );
      expect(
        {
          'key': 'hello world',
          'other': 'test@example.com',
        }.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[
          (name: 'key', value: 'hello%20world'),
          (name: 'other', value: 'test%40example.com'),
        ],
      );
    });

    test('empty map with explode=false yields a single empty-value entry', () {
      expect(
        <String, String>{}.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '')],
      );
    });

    test('empty map with explode=true yields no entries', () {
      expect(
        <String, String>{}.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[],
      );
    });

    test('empty map throws when allowEmpty=false', () {
      expect(
        () => <String, String>{}.toForm('p', explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
      expect(
        () => <String, String>{}.toForm('p', explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('URL-encodes keys and values for explode=true', () {
      expect(
        {
          'key=name': 'value&data',
          'other+key': 'more data',
        }.toForm('p', explode: true, allowEmpty: true),
        const <ParameterEntry>[
          (name: 'key%3Dname', value: 'value%26data'),
          (name: 'other%2Bkey', value: 'more%20data'),
        ],
      );
    });

    test('does not re-encode values when alreadyEncoded=true', () {
      expect(
        {
          'email': 'albert%40example.com',
          'name': 'John%20Doe',
        }.toForm('p', explode: false, allowEmpty: true, alreadyEncoded: true),
        const <ParameterEntry>[
          (name: 'p', value: 'email,albert%40example.com,name,John%20Doe'),
        ],
      );
      expect(
        {
          'email': 'albert%40example.com',
          'name': 'John%20Doe',
        }.toForm('p', explode: true, allowEmpty: true, alreadyEncoded: true),
        const <ParameterEntry>[
          (name: 'email', value: 'albert%40example.com'),
          (name: 'name', value: 'John%20Doe'),
        ],
      );
    });
  });

  group('FormBinaryEncoder', () {
    test('encodes List<int> to a single UTF-8 URL-encoded entry', () {
      const value = [72, 101, 108, 108, 111]; // "Hello"
      expect(
        value.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'Hello')],
      );
    });

    test('encodes empty List<int> as a single empty-value entry', () {
      const value = <int>[];
      expect(
        value.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: '')],
      );
    });

    test('encodes List<int> with special characters', () {
      const value = [72, 195, 171, 108, 108, 195, 182]; // "Hëllö"
      expect(
        value.toForm('p', explode: false, allowEmpty: true),
        const <ParameterEntry>[(name: 'p', value: 'H%C3%ABll%C3%B6')],
      );
    });

    test('throws EmptyValueException when empty and allowEmpty=false', () {
      const value = <int>[];
      expect(
        () => value.toForm('p', explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });
  });

  group('useQueryComponent parameter', () {
    test(
      'FormStringEncoder encodes spaces as + when useQueryComponent=true',
      () {
        expect(
          'hello world'.toForm(
            'p',
            explode: false,
            allowEmpty: true,
            useQueryComponent: true,
          ),
          const <ParameterEntry>[(name: 'p', value: 'hello+world')],
        );
      },
    );

    test(
      'FormStringEncoder distinguishes literal + (%2B) from space (+) when '
      'useQueryComponent=true',
      () {
        expect(
          'a+b c'.toForm(
            'p',
            explode: false,
            allowEmpty: true,
            useQueryComponent: true,
          ),
          const <ParameterEntry>[(name: 'p', value: 'a%2Bb+c')],
        );
      },
    );

    test('FormStringListEncoder encodes items with + (explode=true)', () {
      expect(
        ['hello world', 'foo bar'].toForm(
          'p',
          explode: true,
          allowEmpty: true,
          useQueryComponent: true,
        ),
        const <ParameterEntry>[
          (name: 'p', value: 'hello+world'),
          (name: 'p', value: 'foo+bar'),
        ],
      );
    });

    test('FormStringMapEncoder encodes values with + (explode=true)', () {
      expect(
        {'name': 'John Doe', 'city': 'New York'}.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          useQueryComponent: true,
        ),
        const <ParameterEntry>[
          (name: 'name', value: 'John+Doe'),
          (name: 'city', value: 'New+York'),
        ],
      );
    });

    test(
      'FormBinaryEncoder encodes spaces with + when useQueryComponent=true',
      () {
        const value = [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100];
        expect(
          value.toForm(
            'p',
            explode: false,
            allowEmpty: true,
            useQueryComponent: true,
          ),
          const <ParameterEntry>[(name: 'p', value: 'Hello+World')],
        );
      },
    );
  });

  group('allowReserved parameter', () {
    const allReserved = r":/?#[]@!$&'()*+,;=";

    test('FormStringEncoder keeps reserved chars literal', () {
      expect(
        allReserved.toForm(
          'p',
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        ),
        const <ParameterEntry>[
          (name: 'p', value: r":/?#%5B%5D@!$%26'()*%2B,;%3D"),
        ],
      );
    });

    test('FormStringEncoder default is byte-identical to encodeComponent', () {
      expect(
        allReserved.toForm('p', explode: false, allowEmpty: true),
        <ParameterEntry>[(name: 'p', value: Uri.encodeComponent(allReserved))],
      );
    });

    test('FormStringEncoder composes with useQueryComponent', () {
      expect(
        'a+b c'.toForm(
          'p',
          explode: false,
          allowEmpty: true,
          useQueryComponent: true,
          allowReserved: true,
        ),
        const <ParameterEntry>[(name: 'p', value: 'a%2Bb+c')],
      );
    });

    test('FormUriEncoder threads allowReserved into uriEncode', () {
      final uri = Uri.parse('https://x.com/p?a=1&b=2');
      expect(
        uri.toForm(
          'p',
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        ),
        const <ParameterEntry>[
          (name: 'p', value: 'https://x.com/p?a%3D1%26b%3D2'),
        ],
      );
    });

    test('FormDateTimeEncoder threads allowReserved into uriEncode', () {
      final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
      expect(
        dateTime.toForm(
          'p',
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        ),
        <ParameterEntry>[(name: 'p', value: dateTime.toIso8601String())],
      );
    });

    test('FormBinaryEncoder threads allowReserved into uriEncode', () {
      const value = [97, 58, 98, 32, 99]; // "a:b c"
      expect(
        value.toForm(
          'p',
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        ),
        const <ParameterEntry>[(name: 'p', value: 'a:b%20c')],
      );
    });

    test('numeric and bool encoders accept the flag as a no-op', () {
      expect(
        42.toForm('p', explode: false, allowEmpty: true, allowReserved: true),
        const <ParameterEntry>[(name: 'p', value: '42')],
      );
      expect(
        3.14.toForm('p', explode: false, allowEmpty: true, allowReserved: true),
        const <ParameterEntry>[(name: 'p', value: '3.14')],
      );
      const num numValue = 3.14;
      expect(
        numValue.toForm(
          'p',
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        ),
        const <ParameterEntry>[(name: 'p', value: '3.14')],
      );
      expect(
        true.toForm('p', explode: false, allowEmpty: true, allowReserved: true),
        const <ParameterEntry>[(name: 'p', value: 'true')],
      );
      expect(
        BigDecimal.parse('123.456').toForm(
          'p',
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        ),
        const <ParameterEntry>[(name: 'p', value: '123.456')],
      );
    });

    test('list explode=false keeps reserved literal, encodes & = + per '
        'item', () {
      expect(
        ['a:b', 'c&d', 'e=f', 'g+h'].toForm(
          'p',
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        ),
        const <ParameterEntry>[(name: 'p', value: 'a:b,c%26d,e%3Df,g%2Bh')],
      );
    });

    test('list explode=true keeps reserved literal, encodes & = + per '
        'item', () {
      expect(
        ['a:b', 'c&d', 'e=f', 'g+h'].toForm(
          'p',
          explode: true,
          allowEmpty: true,
          allowReserved: true,
        ),
        const <ParameterEntry>[
          (name: 'p', value: 'a:b'),
          (name: 'p', value: 'c%26d'),
          (name: 'p', value: 'e%3Df'),
          (name: 'p', value: 'g%2Bh'),
        ],
      );
    });

    test('list default is byte-identical to encodeComponent', () {
      const items = ['a:b', 'c&d', 'e=f', 'g+h'];
      expect(
        items.toForm('p', explode: false, allowEmpty: true),
        <ParameterEntry>[
          (name: 'p', value: items.map(Uri.encodeComponent).join(',')),
        ],
      );
      expect(
        items.toForm('p', explode: true, allowEmpty: true),
        <ParameterEntry>[
          for (final item in items)
            (name: 'p', value: Uri.encodeComponent(item)),
        ],
      );
    });

    test('list alreadyEncoded short-circuit is identical with/without '
        'flag', () {
      const items = ['a:b', 'c&d'];
      final without = items.toForm(
        'p',
        explode: true,
        allowEmpty: true,
        alreadyEncoded: true,
      );
      final with_ = items.toForm(
        'p',
        explode: true,
        allowEmpty: true,
        alreadyEncoded: true,
        allowReserved: true,
      );
      expect(without, const <ParameterEntry>[
        (name: 'p', value: 'a:b'),
        (name: 'p', value: 'c&d'),
      ]);
      expect(with_, without);
    });

    test('map explode=true keeps reserved literal, encodes & = + in keys and '
        'values', () {
      expect(
        {'a&b': 'c:d', 'e:f': 'g=h'}.toForm(
          'p',
          explode: true,
          allowEmpty: true,
          allowReserved: true,
        ),
        const <ParameterEntry>[
          (name: 'a%26b', value: 'c:d'),
          (name: 'e:f', value: 'g%3Dh'),
        ],
      );
    });

    test('map explode=false keeps reserved literal in values, keys '
        'untouched', () {
      expect(
        {'a:b': 'c=d'}.toForm(
          'p',
          explode: false,
          allowEmpty: true,
          allowReserved: true,
        ),
        const <ParameterEntry>[(name: 'p', value: 'a:b,c%3Dd')],
      );
    });

    test('map default is byte-identical to encodeComponent', () {
      const map = {'a&b': 'c:d', 'e=f': 'g+h'};
      expect(
        map.toForm('p', explode: true, allowEmpty: true),
        <ParameterEntry>[
          for (final e in map.entries)
            (
              name: Uri.encodeComponent(e.key),
              value: Uri.encodeComponent(e.value),
            ),
        ],
      );
    });

    test('map alreadyEncoded short-circuit is identical with/without flag', () {
      const map = {'k': 'a:b'};
      final without = map.toForm(
        'p',
        explode: true,
        allowEmpty: true,
        alreadyEncoded: true,
      );
      final with_ = map.toForm(
        'p',
        explode: true,
        allowEmpty: true,
        alreadyEncoded: true,
        allowReserved: true,
      );
      expect(without, const <ParameterEntry>[(name: 'k', value: 'a:b')]);
      expect(with_, without);
    });
  });
}
