import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/any_encoding.dart';
import 'package:tonik_util/src/encoding/encodable.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';

/// A test class implementing ParameterEncodable.
class TestEncodableModel implements ParameterEncodable {
  const TestEncodableModel({required this.name, required this.value});

  final String name;
  final int value;

  @override
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) {
    if (explode) {
      return ';name=$name;value=$value';
    }
    return ';$paramName=name,$name,value,$value';
  }

  @override
  String toLabel({required bool explode, required bool allowEmpty}) {
    if (explode) {
      return '.name=$name.value=$value';
    }
    return '.name.$name.value.$value';
  }

  @override
  String toSimple({required bool explode, required bool allowEmpty}) {
    if (explode) {
      return 'name=$name,value=$value';
    }
    return 'name,$name,value,$value';
  }

  @override
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) {
    if (explode) {
      return 'name=$name&value=$value';
    }
    return 'name,$name,value,$value';
  }

  @override
  List<ParameterEntry> toDeepObject(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) {
    return [
      (name: '$paramName[name]', value: name),
      (name: '$paramName[value]', value: value.toString()),
    ];
  }

  @override
  Object? toJson() => {'name': name, 'value': value};
}

void main() {
  group('encodeAnyToMatrix', () {
    group('ParameterEncodable', () {
      test('encodes with explode=true', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        expect(
          encodeAnyToMatrix(model, 'obj', explode: true, allowEmpty: false),
          ';name=test;value=42',
        );
      });

      test('encodes with explode=false', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        expect(
          encodeAnyToMatrix(model, 'obj', explode: false, allowEmpty: false),
          ';obj=name,test,value,42',
        );
      });
    });

    group('String', () {
      test('encodes string with allowEmpty=true', () {
        expect(
          encodeAnyToMatrix(
            'hello world',
            'name',
            explode: true,
            allowEmpty: true,
          ),
          ';name=hello%20world',
        );
      });

      test('encodes string with allowEmpty=false', () {
        expect(
          encodeAnyToMatrix(
            'hello world',
            'name',
            explode: false,
            allowEmpty: false,
          ),
          ';name=hello%20world',
        );
      });

      test('encodes special characters', () {
        expect(
          encodeAnyToMatrix(
            'hello & world',
            'name',
            explode: true,
            allowEmpty: true,
          ),
          ';name=hello%20%26%20world',
        );
      });
    });

    group('int', () {
      test('encodes positive int', () {
        expect(
          encodeAnyToMatrix(42, 'count', explode: true, allowEmpty: true),
          ';count=42',
        );
      });

      test('encodes zero', () {
        expect(
          encodeAnyToMatrix(0, 'count', explode: true, allowEmpty: true),
          ';count=0',
        );
      });

      test('encodes negative int', () {
        expect(
          encodeAnyToMatrix(-42, 'count', explode: true, allowEmpty: true),
          ';count=-42',
        );
      });
    });

    group('double', () {
      test('encodes positive double', () {
        expect(
          encodeAnyToMatrix(3.14, 'pi', explode: true, allowEmpty: true),
          ';pi=3.14',
        );
      });

      test('encodes zero double', () {
        expect(
          encodeAnyToMatrix(0.0, 'value', explode: true, allowEmpty: true),
          ';value=0.0',
        );
      });

      test('encodes negative double', () {
        expect(
          encodeAnyToMatrix(-3.14, 'pi', explode: true, allowEmpty: true),
          ';pi=-3.14',
        );
      });
    });

    group('bool', () {
      test('encodes true', () {
        expect(
          encodeAnyToMatrix(true, 'flag', explode: true, allowEmpty: true),
          ';flag=true',
        );
      });

      test('encodes false', () {
        expect(
          encodeAnyToMatrix(false, 'flag', explode: true, allowEmpty: true),
          ';flag=false',
        );
      });
    });

    group('DateTime', () {
      test('encodes DateTime', () {
        final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
        final result = encodeAnyToMatrix(
          dateTime,
          'date',
          explode: true,
          allowEmpty: true,
        );
        expect(result, startsWith(';date='));
        expect(result, contains('2023-12-25T10%3A30%3A45'));
      });
    });

    group('Uri', () {
      test('encodes Uri', () {
        final uri = Uri.parse('https://example.com/path');
        expect(
          encodeAnyToMatrix(uri, 'url', explode: true, allowEmpty: true),
          ';url=https%3A%2F%2Fexample.com%2Fpath',
        );
      });
    });

    group('BigDecimal', () {
      test('encodes BigDecimal', () {
        final decimal = BigDecimal.parse('123.456');
        expect(
          encodeAnyToMatrix(
            decimal,
            'amount',
            explode: true,
            allowEmpty: true,
          ),
          ';amount=123.456',
        );
      });

      test('encodes zero BigDecimal', () {
        expect(
          encodeAnyToMatrix(
            BigDecimal.zero,
            'amount',
            explode: true,
            allowEmpty: true,
          ),
          ';amount=0',
        );
      });
    });

    group('null handling', () {
      test('encodes null with allowEmpty=true', () {
        expect(
          encodeAnyToMatrix(null, 'param', explode: false, allowEmpty: true),
          ';param',
        );
      });

      test('encodes null with allowEmpty=false', () {
        expect(
          encodeAnyToMatrix(null, 'param', explode: false, allowEmpty: false),
          '',
        );
      });
    });

    group('unsupported types', () {
      test('throws for unsupported type', () {
        expect(
          () => encodeAnyToMatrix(
            Object(),
            'param',
            explode: false,
            allowEmpty: false,
          ),
          throwsA(isA<EncodingException>()),
        );
      });

      test('throws for List (not directly supported)', () {
        expect(
          () => encodeAnyToMatrix(
            ['a', 'b'],
            'param',
            explode: false,
            allowEmpty: false,
          ),
          throwsA(isA<EncodingException>()),
        );
      });
    });
  });

  group('encodeAnyToLabel', () {
    group('ParameterEncodable', () {
      test('encodes with explode=true', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        expect(
          encodeAnyToLabel(model, explode: true, allowEmpty: false),
          '.name=test.value=42',
        );
      });

      test('encodes with explode=false', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        expect(
          encodeAnyToLabel(model, explode: false, allowEmpty: false),
          '.name.test.value.42',
        );
      });
    });

    group('String', () {
      test('encodes String value', () {
        expect(
          encodeAnyToLabel('blue', explode: false, allowEmpty: true),
          '.blue',
        );
      });

      test('encodes String value with special characters', () {
        expect(
          encodeAnyToLabel('John Doe', explode: false, allowEmpty: true),
          '.John%20Doe',
        );
      });
    });

    group('int', () {
      test('encodes int value', () {
        expect(encodeAnyToLabel(25, explode: false, allowEmpty: true), '.25');
      });
    });

    group('double', () {
      test('encodes double value', () {
        expect(
          encodeAnyToLabel(19.99, explode: false, allowEmpty: true),
          '.19.99',
        );
      });
    });

    group('bool', () {
      test('encodes true', () {
        expect(
          encodeAnyToLabel(true, explode: false, allowEmpty: true),
          '.true',
        );
      });

      test('encodes false', () {
        expect(
          encodeAnyToLabel(false, explode: false, allowEmpty: true),
          '.false',
        );
      });
    });

    group('DateTime', () {
      test('encodes DateTime value', () {
        final dateTime = DateTime.utc(2023, 1, 15, 10, 30, 45);
        expect(
          encodeAnyToLabel(dateTime, explode: false, allowEmpty: true),
          '.2023-01-15T10%3A30%3A45.000Z',
        );
      });
    });

    group('Uri', () {
      test('encodes Uri value', () {
        final uri = Uri.parse('https://example.com/api/v1');
        expect(
          encodeAnyToLabel(uri, explode: false, allowEmpty: true),
          '.https%3A%2F%2Fexample.com%2Fapi%2Fv1',
        );
      });
    });

    group('BigDecimal', () {
      test('encodes BigDecimal value', () {
        final decimal = BigDecimal.parse('123.456');
        expect(
          encodeAnyToLabel(decimal, explode: false, allowEmpty: true),
          '.123.456',
        );
      });
    });

    group('null handling', () {
      test('encodes null with allowEmpty=true', () {
        expect(encodeAnyToLabel(null, explode: false, allowEmpty: true), '.');
      });

      test('encodes null with allowEmpty=false', () {
        expect(encodeAnyToLabel(null, explode: false, allowEmpty: false), '');
      });
    });

    group('RFC 3986 reserved character encoding', () {
      test('encodes colon (:) properly', () {
        expect(
          encodeAnyToLabel(
            'http://example.com',
            explode: false,
            allowEmpty: true,
          ),
          '.http%3A%2F%2Fexample.com',
        );
      });

      test('encodes ampersand (&) properly', () {
        expect(
          encodeAnyToLabel(
            'Johnson & Johnson',
            explode: false,
            allowEmpty: true,
          ),
          '.Johnson%20%26%20Johnson',
        );
      });

      test('properly encodes non-ASCII characters (café)', () {
        expect(
          encodeAnyToLabel('café', explode: false, allowEmpty: true),
          '.caf%C3%A9',
        );
      });

      test('properly encodes emoji', () {
        expect(
          encodeAnyToLabel('👍', explode: false, allowEmpty: true),
          '.%F0%9F%91%8D',
        );
      });

      test('properly encodes Chinese characters', () {
        expect(
          encodeAnyToLabel('你好', explode: false, allowEmpty: true),
          '.%E4%BD%A0%E5%A5%BD',
        );
      });
    });

    group('unsupported types', () {
      test('throws for unsupported type', () {
        expect(
          () => encodeAnyToLabel(Object(), explode: false, allowEmpty: false),
          throwsA(isA<EncodingException>()),
        );
      });
    });
  });

  group('encodeAnyToSimple', () {
    group('ParameterEncodable', () {
      test('encodes with explode=true', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        expect(
          encodeAnyToSimple(model, explode: true, allowEmpty: false),
          'name=test,value=42',
        );
      });

      test('encodes with explode=false', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        expect(
          encodeAnyToSimple(model, explode: false, allowEmpty: false),
          'name,test,value,42',
        );
      });
    });

    group('String', () {
      test('encodes string value', () {
        expect(
          encodeAnyToSimple('blue', explode: false, allowEmpty: true),
          'blue',
        );
      });

      test('encodes string with special characters', () {
        expect(
          encodeAnyToSimple('John Doe', explode: false, allowEmpty: true),
          'John%20Doe',
        );
      });
    });

    group('int', () {
      test('encodes int value', () {
        expect(encodeAnyToSimple(42, explode: false, allowEmpty: true), '42');
      });

      test('encodes negative int', () {
        expect(
          encodeAnyToSimple(-123, explode: true, allowEmpty: true),
          '-123',
        );
      });
    });

    group('double', () {
      test('encodes double values', () {
        expect(
          encodeAnyToSimple(3.14, explode: false, allowEmpty: true),
          '3.14',
        );
      });

      test('encodes negative double', () {
        expect(
          encodeAnyToSimple(-2.5, explode: true, allowEmpty: true),
          '-2.5',
        );
      });
    });

    group('bool', () {
      test('encodes true', () {
        expect(
          encodeAnyToSimple(true, explode: false, allowEmpty: true),
          'true',
        );
      });

      test('encodes false', () {
        expect(
          encodeAnyToSimple(false, explode: true, allowEmpty: true),
          'false',
        );
      });
    });

    group('DateTime', () {
      test('encodes DateTime', () {
        final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
        final encoded = encodeAnyToSimple(
          dateTime,
          explode: false,
          allowEmpty: true,
        );
        expect(encoded, contains('2023-12-25T10%3A30%3A45'));
      });
    });

    group('Uri', () {
      test('encodes HTTPS Uri', () {
        final uri = Uri.parse('https://example.com/path?query=value');
        expect(
          encodeAnyToSimple(uri, explode: false, allowEmpty: true),
          'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
        );
      });

      test('encodes Uri with special characters', () {
        final uri = Uri.parse(
          'https://example.com/path with spaces?key=value&other=data',
        );
        expect(
          encodeAnyToSimple(uri, explode: false, allowEmpty: true),
          'https%3A%2F%2Fexample.com%2Fpath%2520with%2520spaces'
          '%3Fkey%3Dvalue%26other%3Ddata',
        );
      });
    });

    group('BigDecimal', () {
      test('encodes BigDecimal', () {
        final decimal = BigDecimal.parse('123.456789');
        expect(
          encodeAnyToSimple(decimal, explode: false, allowEmpty: true),
          '123.456789',
        );
      });
    });

    group('null handling', () {
      test('encodes null with allowEmpty=true', () {
        expect(encodeAnyToSimple(null, explode: false, allowEmpty: true), '');
      });

      test('throws for null with allowEmpty=false', () {
        expect(
          () => encodeAnyToSimple(null, explode: false, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });
    });

    group('unsupported types', () {
      test('throws for unsupported type', () {
        expect(
          () => encodeAnyToSimple(Object(), explode: false, allowEmpty: false),
          throwsA(isA<EncodingException>()),
        );
      });
    });
  });

  group('encodeAnyToForm', () {
    group('ParameterEncodable', () {
      test('encodes with explode=true', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        expect(
          encodeAnyToForm(model, explode: true, allowEmpty: false),
          'name=test&value=42',
        );
      });

      test('encodes with explode=false', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        expect(
          encodeAnyToForm(model, explode: false, allowEmpty: false),
          'name,test,value,42',
        );
      });
    });

    group('String', () {
      test('encodes string values with URL encoding', () {
        expect(
          encodeAnyToForm('hello world', explode: false, allowEmpty: true),
          'hello%20world',
        );
      });

      test('encodes special characters', () {
        expect(
          encodeAnyToForm(
            'key=value&other=data',
            explode: false,
            allowEmpty: true,
          ),
          'key%3Dvalue%26other%3Ddata',
        );
      });

      test('encodes plus sign', () {
        expect(
          encodeAnyToForm('hello+world', explode: false, allowEmpty: true),
          'hello%2Bworld',
        );
      });
    });

    group('int', () {
      test('encodes integer values', () {
        expect(encodeAnyToForm(42, explode: false, allowEmpty: true), '42');
        expect(encodeAnyToForm(-123, explode: true, allowEmpty: true), '-123');
        expect(encodeAnyToForm(0, explode: false, allowEmpty: false), '0');
      });
    });

    group('double', () {
      test('encodes double values', () {
        expect(encodeAnyToForm(3.14, explode: false, allowEmpty: true), '3.14');
        expect(encodeAnyToForm(-2.5, explode: true, allowEmpty: true), '-2.5');
        expect(encodeAnyToForm(0.0, explode: false, allowEmpty: false), '0.0');
      });
    });

    group('bool', () {
      test('encodes boolean values', () {
        expect(encodeAnyToForm(true, explode: false, allowEmpty: true), 'true');
        expect(
          encodeAnyToForm(false, explode: true, allowEmpty: true),
          'false',
        );
      });
    });

    group('DateTime', () {
      test('encodes DateTime as URL-encoded ISO string', () {
        final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
        final encoded = encodeAnyToForm(
          dateTime,
          explode: false,
          allowEmpty: true,
        );
        expect(encoded, contains('2023-12-25T10%3A30%3A45'));
        expect(encoded, contains('Z'));
      });
    });

    group('Uri', () {
      test('encodes Uri values with URL encoding', () {
        final uri = Uri.parse('https://example.com/path?query=value');
        expect(
          encodeAnyToForm(uri, explode: false, allowEmpty: true),
          'https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue',
        );
      });
    });

    group('BigDecimal', () {
      test('encodes BigDecimal values', () {
        final decimal = BigDecimal.parse('123.456789');
        expect(
          encodeAnyToForm(decimal, explode: false, allowEmpty: true),
          '123.456789',
        );
      });

      test('handles zero and negative values', () {
        expect(
          encodeAnyToForm(BigDecimal.zero, explode: false, allowEmpty: true),
          '0',
        );
        expect(
          encodeAnyToForm(
            BigDecimal.parse('-42.5'),
            explode: false,
            allowEmpty: true,
          ),
          '-42.5',
        );
      });
    });

    group('null handling', () {
      test('encodes null with allowEmpty=true', () {
        expect(encodeAnyToForm(null, explode: false, allowEmpty: true), '');
      });

      test('throws for null with allowEmpty=false', () {
        expect(
          () => encodeAnyToForm(null, explode: false, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });
    });

    group('unsupported types', () {
      test('throws for unsupported type', () {
        expect(
          () => encodeAnyToForm(Object(), explode: false, allowEmpty: false),
          throwsA(isA<EncodingException>()),
        );
      });
    });
  });

  group('encodeAnyToDeepObject', () {
    group('ParameterEncodable', () {
      test('encodes ParameterEncodable instance', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        final result = encodeAnyToDeepObject(
          model,
          'obj',
          explode: true,
          allowEmpty: false,
        );
        expect(result, hasLength(2));
        expect(result[0], (name: 'obj[name]', value: 'test'));
        expect(result[1], (name: 'obj[value]', value: '42'));
      });
    });

    group('Map<String, String>', () {
      test('encodes a simple map with paramName prefix', () {
        final result = encodeAnyToDeepObject(
          {'color': 'red', 'size': 'large'},
          'filter',
          explode: true,
          allowEmpty: true,
        );

        expect(result, hasLength(2));
        expect(result, contains((name: 'filter[color]', value: 'red')));
        expect(result, contains((name: 'filter[size]', value: 'large')));
      });

      test('URL-encodes keys with special characters', () {
        final result = encodeAnyToDeepObject(
          {'first name': 'John', 'email@address': 'test'},
          'params',
          explode: true,
          allowEmpty: true,
        );

        expect(result, hasLength(2));
        expect(result, contains((name: 'params[first%20name]', value: 'John')));
        expect(
          result,
          contains((name: 'params[email%40address]', value: 'test')),
        );
      });

      test('URL-encodes values with special characters', () {
        final result = encodeAnyToDeepObject(
          {
            'name': 'John Doe',
            'email': 'test@example.com',
            'url': 'https://example.com/path?query=value',
          },
          'params',
          explode: true,
          allowEmpty: true,
        );

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

      test('handles unicode characters', () {
        final result = encodeAnyToDeepObject(
          {'name': 'José', 'city': 'São Paulo'},
          'person',
          explode: true,
          allowEmpty: true,
        );

        expect(result, hasLength(2));
        expect(result, contains((name: 'person[name]', value: 'Jos%C3%A9')));
        expect(
          result,
          contains((name: 'person[city]', value: 'S%C3%A3o%20Paulo')),
        );
      });

      test('handles emoji in values', () {
        final result = encodeAnyToDeepObject(
          {'message': 'Hello 😀'},
          'data',
          explode: true,
          allowEmpty: true,
        );

        expect(result, [
          (name: 'data[message]', value: 'Hello%20%F0%9F%98%80'),
        ]);
      });

      test('handles empty map when allowEmpty=true', () {
        final result = encodeAnyToDeepObject(
          <String, String>{},
          'filter',
          explode: true,
          allowEmpty: true,
        );

        expect(result, isEmpty);
      });

      test('handles keys with square brackets', () {
        final result = encodeAnyToDeepObject(
          {'key[0]': 'value'},
          'params',
          explode: true,
          allowEmpty: true,
        );

        expect(result, [
          (name: 'params[key%5B0%5D]', value: 'value'),
        ]);
      });

      test('handles keys with equals signs', () {
        final result = encodeAnyToDeepObject(
          {'key=name': 'value'},
          'params',
          explode: true,
          allowEmpty: true,
        );

        expect(result, [
          (name: 'params[key%3Dname]', value: 'value'),
        ]);
      });

      test('handles keys with ampersands', () {
        final result = encodeAnyToDeepObject(
          {'key&name': 'value'},
          'params',
          explode: true,
          allowEmpty: true,
        );

        expect(result, [
          (name: 'params[key%26name]', value: 'value'),
        ]);
      });
    });

    group('null handling', () {
      test('encodes null with allowEmpty=true', () {
        expect(
          encodeAnyToDeepObject(null, 'obj', explode: true, allowEmpty: true),
          isEmpty,
        );
      });

      test('throws for null with allowEmpty=false', () {
        expect(
          () => encodeAnyToDeepObject(
            null,
            'obj',
            explode: true,
            allowEmpty: false,
          ),
          throwsA(isA<EmptyValueException>()),
        );
      });
    });

    group('unsupported types', () {
      test('throws for primitive types (String)', () {
        expect(
          () => encodeAnyToDeepObject(
            'hello',
            'obj',
            explode: true,
            allowEmpty: false,
          ),
          throwsA(isA<EncodingException>()),
        );
      });

      test('throws for primitive types (int)', () {
        expect(
          () => encodeAnyToDeepObject(
            42,
            'obj',
            explode: true,
            allowEmpty: false,
          ),
          throwsA(isA<EncodingException>()),
        );
      });

      test('throws for unsupported object type', () {
        expect(
          () => encodeAnyToDeepObject(
            Object(),
            'obj',
            explode: true,
            allowEmpty: false,
          ),
          throwsA(isA<EncodingException>()),
        );
      });
    });
  });

  group('encodeAnyToJson', () {
    group('JsonEncodable', () {
      test('encodes JsonEncodable instance', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        expect(
          encodeAnyToJson(model),
          {'name': 'test', 'value': 42},
        );
      });
    });

    group('JSON primitives pass-through', () {
      test('passes through null', () {
        expect(encodeAnyToJson(null), isNull);
      });

      test('passes through String', () {
        expect(encodeAnyToJson('hello'), 'hello');
      });

      test('passes through int', () {
        expect(encodeAnyToJson(42), 42);
      });

      test('passes through double', () {
        expect(encodeAnyToJson(3.14), 3.14);
      });

      test('passes through bool', () {
        expect(encodeAnyToJson(true), true);
        expect(encodeAnyToJson(false), false);
      });
    });

    group('DateTime', () {
      test('converts DateTime to ISO8601 string', () {
        final dt = DateTime.utc(2024, 1, 15, 10, 30);
        expect(encodeAnyToJson(dt), '2024-01-15T10:30:00.000Z');
      });
    });

    group('recursive encoding', () {
      test('recursively encodes List', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        final list = [1, 'hello', model];
        expect(
          encodeAnyToJson(list),
          [
            1,
            'hello',
            {'name': 'test', 'value': 42},
          ],
        );
      });

      test('recursively encodes nested Lists', () {
        final nested = [
          [1, 2],
          [3, 4],
        ];
        expect(
          encodeAnyToJson(nested),
          [
            [1, 2],
            [3, 4],
          ],
        );
      });

      test('recursively encodes Map', () {
        const model = TestEncodableModel(name: 'test', value: 42);
        final map = {'num': 1, 'str': 'hello', 'obj': model};
        expect(
          encodeAnyToJson(map),
          {
            'num': 1,
            'str': 'hello',
            'obj': {'name': 'test', 'value': 42},
          },
        );
      });

      test('recursively encodes nested Maps', () {
        final nested = {
          'outer': {'inner': 'value'},
        };
        expect(
          encodeAnyToJson(nested),
          {
            'outer': {'inner': 'value'},
          },
        );
      });

      test('recursively encodes mixed nested structures', () {
        const model = TestEncodableModel(name: 'nested', value: 99);
        final complex = {
          'items': [
            {'id': 1},
            model,
          ],
          'metadata': {'count': 2},
        };
        expect(
          encodeAnyToJson(complex),
          {
            'items': [
              {'id': 1},
              {'name': 'nested', 'value': 99},
            ],
            'metadata': {'count': 2},
          },
        );
      });

      test('handles DateTime in nested structures', () {
        final dt = DateTime.utc(2024, 1, 15, 10, 30);
        final map = {
          'timestamp': dt,
          'items': [dt],
        };
        expect(
          encodeAnyToJson(map),
          {
            'timestamp': '2024-01-15T10:30:00.000Z',
            'items': ['2024-01-15T10:30:00.000Z'],
          },
        );
      });
    });

    group('unsupported types', () {
      test('throws for unsupported type', () {
        expect(
          () => encodeAnyToJson(Object()),
          throwsA(isA<EncodingException>()),
        );
      });

      test('throws for unsupported type in List', () {
        expect(
          () => encodeAnyToJson([Object()]),
          throwsA(isA<EncodingException>()),
        );
      });

      test('throws for unsupported type in Map value', () {
        expect(
          () => encodeAnyToJson({'key': Object()}),
          throwsA(isA<EncodingException>()),
        );
      });
    });
  });
}
