import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/deep_object_encoder_extensions.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';

void main() {
  group('DeepObjectStringMapEncoder', () {
    group('explode parameter validation', () {
      test('throws when explode is false', () {
        expect(
          () => {
            'color': 'red',
          }.toDeepObject('filter', explode: false, allowEmpty: true),
          throwsA(isA<EncodingException>()),
        );
      });

      test('works when explode is true', () {
        final result = {
          'color': 'red',
        }.toDeepObject('filter', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'filter[color]', value: 'red'),
        ]);
      });
    });

    group('basic encoding', () {
      test('encodes a simple map with paramName prefix', () {
        final result = {
          'color': 'red',
          'size': 'large',
        }.toDeepObject('filter', explode: true, allowEmpty: true);

        expect(result, hasLength(2));
        expect(result, contains((name: 'filter[color]', value: 'red')));
        expect(result, contains((name: 'filter[size]', value: 'large')));
      });

      test('encodes a single entry map', () {
        final result = {
          'name': 'John',
        }.toDeepObject('user', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'user[name]', value: 'John'),
        ]);
      });

      test('encodes map with multiple entries', () {
        final result = {
          'name': 'Alice',
          'age': '30',
          'city': 'NYC',
        }.toDeepObject('person', explode: true, allowEmpty: true);

        expect(result, hasLength(3));
        expect(result, contains((name: 'person[name]', value: 'Alice')));
        expect(result, contains((name: 'person[age]', value: '30')));
        expect(result, contains((name: 'person[city]', value: 'NYC')));
      });
    });

    group('URL encoding', () {
      test('URL-encodes keys with special characters', () {
        final result = {
          'first name': 'John',
          'email@address': 'test',
        }.toDeepObject('params', explode: true, allowEmpty: true);

        expect(result, hasLength(2));
        expect(result, contains((name: 'params[first%20name]', value: 'John')));
        expect(
          result,
          contains((name: 'params[email%40address]', value: 'test')),
        );
      });

      test('URL-encodes values with special characters', () {
        final result = {
          'name': 'John Doe',
          'email': 'test@example.com',
          'url': 'https://example.com/path?query=value',
        }.toDeepObject('params', explode: true, allowEmpty: true);

        expect(result, hasLength(3));
        expect(result, contains((name: 'params[name]', value: 'John%20Doe')));
        expect(
          result,
          contains((name: 'params[email]', value: 'test%40example.com')),
        );
        expect(
          result,
          contains(
            (
              name: 'params[url]',
              value: 'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
            ),
          ),
        );
      });

      test('handles already encoded values when alreadyEncoded=true', () {
        final result = {
          'email': 'test%40example.com',
          'name': 'John%20Doe',
        }.toDeepObject(
          'params',
          explode: true,
          allowEmpty: true,
          alreadyEncoded: true,
        );

        expect(result, hasLength(2));
        expect(
          result,
          contains((name: 'params[email]', value: 'test%40example.com')),
        );
        expect(result, contains((name: 'params[name]', value: 'John%20Doe')));
      });

      test('double-encodes values when alreadyEncoded=false', () {
        final result = {
          'email': 'test%40example.com',
        }.toDeepObject(
          'params',
          explode: true,
          allowEmpty: true,
        );

        expect(result, [
          (name: 'params[email]', value: 'test%2540example.com'),
        ]);
      });

      test('handles unicode characters', () {
        final result = {
          'name': 'José',
          'city': 'São Paulo',
        }.toDeepObject('person', explode: true, allowEmpty: true);

        expect(result, hasLength(2));
        expect(result, contains((name: 'person[name]', value: 'Jos%C3%A9')));
        expect(
          result,
          contains((name: 'person[city]', value: 'S%C3%A3o%20Paulo')),
        );
      });

      test('handles emoji in values', () {
        final result = {
          'message': 'Hello 😀',
        }.toDeepObject('data', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'data[message]', value: 'Hello%20%F0%9F%98%80'),
        ]);
      });
    });

    group('empty values', () {
      test('handles empty map when allowEmpty=true', () {
        final result = <String, String>{}.toDeepObject(
          'filter',
          explode: true,
          allowEmpty: true,
        );

        expect(result, isEmpty);
      });

      test(
        'throws EmptyValueException when empty map and allowEmpty=false',
        () {
          expect(
            () => <String, String>{}.toDeepObject(
              'filter',
              explode: true,
              allowEmpty: false,
            ),
            throwsA(isA<EmptyValueException>()),
          );
        },
      );

      test('handles empty string values when allowEmpty=true', () {
        final result = {
          'name': '',
          'email': 'test@example.com',
        }.toDeepObject('params', explode: true, allowEmpty: true);

        expect(result, hasLength(2));
        expect(result, contains((name: 'params[name]', value: '')));
        expect(
          result,
          contains((name: 'params[email]', value: 'test%40example.com')),
        );
      });

      test('handles map with all empty string values', () {
        final result = {
          'field1': '',
          'field2': '',
        }.toDeepObject('params', explode: true, allowEmpty: true);

        expect(result, hasLength(2));
        expect(result, contains((name: 'params[field1]', value: '')));
        expect(result, contains((name: 'params[field2]', value: '')));
      });
    });

    group('parameter name handling', () {
      test('works with simple parameter names', () {
        final result = {
          'key': 'value',
        }.toDeepObject('param', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'param[key]', value: 'value'),
        ]);
      });

      test('works with parameter names containing underscores', () {
        final result = {
          'key': 'value',
        }.toDeepObject('my_param', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'my_param[key]', value: 'value'),
        ]);
      });

      test('works with parameter names containing numbers', () {
        final result = {
          'key': 'value',
        }.toDeepObject('param123', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'param123[key]', value: 'value'),
        ]);
      });

      test('works with camelCase parameter names', () {
        final result = {
          'key': 'value',
        }.toDeepObject('myParam', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'myParam[key]', value: 'value'),
        ]);
      });
    });

    group('special cases', () {
      test('handles boolean-like string values', () {
        final result = {
          'active': 'true',
          'premium': 'false',
        }.toDeepObject('flags', explode: true, allowEmpty: true);

        expect(result, hasLength(2));
        expect(result, contains((name: 'flags[active]', value: 'true')));
        expect(result, contains((name: 'flags[premium]', value: 'false')));
      });

      test('handles numeric string values', () {
        final result = {
          'count': '42',
          'price': '19.99',
        }.toDeepObject('data', explode: true, allowEmpty: true);

        expect(result, hasLength(2));
        expect(result, contains((name: 'data[count]', value: '42')));
        expect(result, contains((name: 'data[price]', value: '19.99')));
      });

      test('handles null-like string values', () {
        final result = {
          'value1': 'null',
          'value2': 'undefined',
        }.toDeepObject('params', explode: true, allowEmpty: true);

        expect(result, hasLength(2));
        expect(result, contains((name: 'params[value1]', value: 'null')));
        expect(result, contains((name: 'params[value2]', value: 'undefined')));
      });

      test('handles very long values', () {
        final longValue = 'a' * 1000;
        final result = {
          'data': longValue,
        }.toDeepObject('params', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'params[data]', value: 'a' * 1000),
        ]);
      });

      test('handles map with many entries', () {
        final largeMap = <String, String>{};
        for (var i = 0; i < 100; i++) {
          largeMap['key$i'] = 'value$i';
        }

        final result = largeMap.toDeepObject(
          'params',
          explode: true,
          allowEmpty: true,
        );

        expect(result, hasLength(100));
        for (var i = 0; i < 100; i++) {
          expect(result, contains((name: 'params[key$i]', value: 'value$i')));
        }
      });
    });

    group('consistency', () {
      test('produces consistent results for same input', () {
        final map = {'z': '1', 'a': '2', 'm': '3'};

        final result1 = map.toDeepObject(
          'params',
          explode: true,
          allowEmpty: true,
        );
        final result2 = map.toDeepObject(
          'params',
          explode: true,
          allowEmpty: true,
        );

        expect(result1, result2);
      });

      test('order is deterministic based on map iteration', () {
        final map = {'a': '1', 'b': '2', 'c': '3'};
        final result = map.toDeepObject(
          'params',
          explode: true,
          allowEmpty: true,
        );

        expect(result, hasLength(3));
        expect(result[0], (name: 'params[a]', value: '1'));
        expect(result[1], (name: 'params[b]', value: '2'));
        expect(result[2], (name: 'params[c]', value: '3'));
      });
    });

    group('edge cases', () {
      test('handles keys with square brackets in them', () {
        final result = {
          'key[0]': 'value',
        }.toDeepObject('params', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'params[key%5B0%5D]', value: 'value'),
        ]);
      });

      test('handles keys with equals signs', () {
        final result = {
          'key=name': 'value',
        }.toDeepObject('params', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'params[key%3Dname]', value: 'value'),
        ]);
      });

      test('handles keys with ampersands', () {
        final result = {
          'key&name': 'value',
        }.toDeepObject('params', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'params[key%26name]', value: 'value'),
        ]);
      });

      test('handles values with equals signs', () {
        final result = {
          'equation': 'x=y',
        }.toDeepObject('params', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'params[equation]', value: 'x%3Dy'),
        ]);
      });

      test('handles values with ampersands', () {
        final result = {
          'query': 'a&b',
        }.toDeepObject('params', explode: true, allowEmpty: true);

        expect(result, [
          (name: 'params[query]', value: 'a%26b'),
        ]);
      });
    });
  });
}
