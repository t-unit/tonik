import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/matrix_encoder_extensions.dart';

void main() {
  group('MatrixUriEncoder', () {
    test('encodes Uri with allowEmpty=true', () {
      final uri = Uri.parse('https://example.com/path');
      expect(
        uri.toMatrix('url', allowEmpty: true, explode: true),
        ';url=https%3A%2F%2Fexample.com%2Fpath',
      );
    });

    test('encodes Uri with allowEmpty=false', () {
      final uri = Uri.parse('https://example.com/path');
      expect(
        uri.toMatrix('url', allowEmpty: false, explode: true),
        ';url=https%3A%2F%2Fexample.com%2Fpath',
      );
    });
  });

  group('MatrixStringEncoder', () {
    test('encodes string with allowEmpty=true', () {
      expect(
        'hello world'.toMatrix('name', allowEmpty: true, explode: true),
        ';name=hello%20world',
      );
    });

    test('encodes string with allowEmpty=false', () {
      expect(
        'hello world'.toMatrix('name', allowEmpty: false, explode: true),
        ';name=hello%20world',
      );
    });

    test('encodes empty string with allowEmpty=true', () {
      expect(''.toMatrix('name', allowEmpty: true, explode: true), ';name=');
    });

    test('encodes empty string with allowEmpty=false', () {
      expect(
        () => ''.toMatrix('name', allowEmpty: false, explode: true),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes special characters', () {
      expect(
        'hello & world'.toMatrix('name', allowEmpty: true, explode: true),
        ';name=hello%20%26%20world',
      );
    });
  });

  group('MatrixIntEncoder', () {
    test('encodes int with allowEmpty=true', () {
      expect(
        42.toMatrix('count', allowEmpty: true, explode: true),
        ';count=42',
      );
    });

    test('encodes int with allowEmpty=false', () {
      expect(
        42.toMatrix('count', allowEmpty: false, explode: true),
        ';count=42',
      );
    });

    test('encodes zero', () {
      expect(0.toMatrix('count', allowEmpty: true, explode: true), ';count=0');
    });

    test('encodes negative int', () {
      expect(
        (-42).toMatrix('count', allowEmpty: true, explode: true),
        ';count=-42',
      );
    });
  });

  group('MatrixDoubleEncoder', () {
    test('encodes double with allowEmpty=true', () {
      expect(3.14.toMatrix('pi', allowEmpty: true, explode: true), ';pi=3.14');
    });

    test('encodes double with allowEmpty=false', () {
      expect(3.14.toMatrix('pi', allowEmpty: false, explode: true), ';pi=3.14');
    });

    test('encodes zero double', () {
      expect(
        0.0.toMatrix('value', allowEmpty: true, explode: true),
        ';value=0.0',
      );
    });

    test('encodes negative double', () {
      expect(
        (-3.14).toMatrix('pi', allowEmpty: true, explode: true),
        ';pi=-3.14',
      );
    });
  });

  group('MatrixNumEncoder', () {
    test('encodes num with allowEmpty=true', () {
      expect(
        (42 as num).toMatrix('count', allowEmpty: true, explode: true),
        ';count=42',
      );
    });

    test('encodes num with allowEmpty=false', () {
      expect(
        (42 as num).toMatrix('count', allowEmpty: false, explode: true),
        ';count=42',
      );
    });
  });

  group('MatrixBoolEncoder', () {
    test('encodes true with allowEmpty=true', () {
      expect(
        true.toMatrix('flag', allowEmpty: true, explode: true),
        ';flag=true',
      );
    });

    test('encodes false with allowEmpty=true', () {
      expect(
        false.toMatrix('flag', allowEmpty: true, explode: true),
        ';flag=false',
      );
    });

    test('encodes bool with allowEmpty=false', () {
      expect(
        true.toMatrix('flag', allowEmpty: false, explode: true),
        ';flag=true',
      );
    });
  });

  group('MatrixDateTimeEncoder', () {
    test('encodes DateTime with allowEmpty=true', () {
      final dateTime = DateTime(2023, 12, 25, 10, 30, 45);
      final result = dateTime.toMatrix('date', allowEmpty: true, explode: true);
      expect(result, startsWith(';date='));
      expect(result, contains('2023-12-25T10%3A30%3A45'));
    });

    test('encodes DateTime with allowEmpty=false', () {
      final dateTime = DateTime(2023, 12, 25, 10, 30, 45);
      final result = dateTime.toMatrix(
        'date',
        allowEmpty: false,
        explode: true,
      );
      expect(result, startsWith(';date='));
      expect(result, contains('2023-12-25T10%3A30%3A45'));
    });
  });

  group('MatrixBigDecimalEncoder', () {
    test('encodes BigDecimal with allowEmpty=true', () {
      final bigDecimal = BigDecimal.parse('123.456');
      expect(
        bigDecimal.toMatrix('amount', allowEmpty: true, explode: true),
        ';amount=123.456',
      );
    });

    test('encodes BigDecimal with allowEmpty=false', () {
      final bigDecimal = BigDecimal.parse('123.456');
      expect(
        bigDecimal.toMatrix('amount', allowEmpty: false, explode: true),
        ';amount=123.456',
      );
    });

    test('encodes zero BigDecimal', () {
      final bigDecimal = BigDecimal.zero;
      expect(
        bigDecimal.toMatrix('amount', allowEmpty: true, explode: true),
        ';amount=0',
      );
    });
  });

  group('MatrixStringListEncoder', () {
    test('encodes list with explode=false and allowEmpty=true', () {
      final list = ['red', 'green', 'blue'];
      expect(
        list.toMatrix('colors', explode: false, allowEmpty: true),
        ';colors=red,green,blue',
      );
    });

    test('encodes list with explode=false and allowEmpty=false', () {
      final list = ['red', 'green', 'blue'];
      expect(
        list.toMatrix('colors', explode: false, allowEmpty: false),
        ';colors=red,green,blue',
      );
    });

    test('encodes list with explode=true and allowEmpty=true', () {
      final list = ['red', 'green', 'blue'];
      expect(
        list.toMatrix('colors', explode: true, allowEmpty: true),
        ';colors=red;colors=green;colors=blue',
      );
    });

    test('encodes list with explode=true and allowEmpty=false', () {
      final list = ['red', 'green', 'blue'];
      expect(
        list.toMatrix('colors', explode: true, allowEmpty: false),
        ';colors=red;colors=green;colors=blue',
      );
    });

    test('encodes empty list with explode=false and allowEmpty=true', () {
      final list = <String>[];
      expect(
        list.toMatrix('colors', explode: false, allowEmpty: true),
        ';colors',
      );
    });

    test('encodes empty list with explode=false and allowEmpty=false', () {
      final list = <String>[];
      expect(
        () => list.toMatrix('colors', explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes empty list with explode=true and allowEmpty=true', () {
      final list = <String>[];
      expect(
        list.toMatrix('colors', explode: true, allowEmpty: true),
        ';colors',
      );
    });

    test('encodes empty list with explode=true and allowEmpty=false', () {
      final list = <String>[];
      expect(
        () => list.toMatrix('colors', explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes list with special characters and explode=true', () {
      final list = ['hello & world', 'test,value'];
      expect(
        list.toMatrix('items', explode: true, allowEmpty: true),
        ';items=hello%20%26%20world;items=test%2Cvalue',
      );
    });

    test('encodes single item list with explode=true', () {
      final list = ['single'];
      expect(
        list.toMatrix('item', explode: true, allowEmpty: true),
        ';item=single',
      );
    });
  });

  group('MatrixStringMapEncoder', () {
    test('encodes map with explode=false and allowEmpty=true', () {
      final map = {'x': '1', 'y': '2'};
      expect(
        map.toMatrix('point', explode: false, allowEmpty: true),
        ';point=x,1,y,2',
      );
    });

    test('encodes map with explode=false and allowEmpty=false', () {
      final map = {'x': '1', 'y': '2'};
      expect(
        map.toMatrix('point', explode: false, allowEmpty: false),
        ';point=x,1,y,2',
      );
    });

    test('encodes map with explode=true and allowEmpty=true', () {
      final map = {'x': '1', 'y': '2'};
      expect(
        map.toMatrix('point', explode: true, allowEmpty: true),
        ';x=1;y=2',
      );
    });

    test('encodes map with explode=true and allowEmpty=false', () {
      final map = {'x': '1', 'y': '2'};
      expect(
        map.toMatrix('point', explode: true, allowEmpty: false),
        ';x=1;y=2',
      );
    });

    test('encodes empty map with explode=false and allowEmpty=true', () {
      final map = <String, String>{};
      expect(map.toMatrix('point', explode: false, allowEmpty: true), ';point');
    });

    test('encodes empty map with explode=false and allowEmpty=false', () {
      final map = <String, String>{};
      expect(
        () => map.toMatrix('point', explode: false, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes empty map with explode=true and allowEmpty=true', () {
      final map = <String, String>{};
      expect(map.toMatrix('point', explode: true, allowEmpty: true), ';point');
    });

    test('encodes empty map with explode=true and allowEmpty=false', () {
      final map = <String, String>{};
      expect(
        () => map.toMatrix('point', explode: true, allowEmpty: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes map with special characters and explode=true', () {
      final map = {'key & name': 'value,test', 'other': 'normal'};
      expect(
        map.toMatrix('data', explode: true, allowEmpty: true),
        ';key%20%26%20name=value%2Ctest;other=normal',
      );
    });

    test('encodes map with alreadyEncoded=true and explode=false', () {
      final map = {'x': '1%2C2', 'y': '3%2C4'};
      expect(
        map.toMatrix(
          'point',
          explode: false,
          allowEmpty: true,
          alreadyEncoded: true,
        ),
        ';point=x,1%2C2,y,3%2C4',
      );
    });

    test('encodes map with alreadyEncoded=true and explode=true', () {
      final map = {'x': '1%2C2', 'y': '3%2C4'};
      expect(
        map.toMatrix(
          'point',
          explode: true,
          allowEmpty: true,
          alreadyEncoded: true,
        ),
        ';x=1%2C2;y=3%2C4',
      );
    });

    test('encodes single key map with explode=true', () {
      final map = {'single': 'value'};
      expect(
        map.toMatrix('item', explode: true, allowEmpty: true),
        ';single=value',
      );
    });
  });

  group('MatrixBinaryEncoder', () {
    test('encodes List<int> with parameter name', () {
      const value = [72, 101, 108, 108, 111]; // "Hello"
      expect(
        value.toMatrix('data', allowEmpty: true, explode: false),
        ';data=Hello',
      );
    });

    test('encodes empty List<int> when allowEmpty=true', () {
      const value = <int>[];
      expect(
        value.toMatrix('data', allowEmpty: true, explode: false),
        ';data=',
      );
    });

    test('throws EmptyValueException when empty and allowEmpty=false', () {
      const value = <int>[];
      expect(
        () => value.toMatrix('data', allowEmpty: false, explode: false),
        throwsA(isA<EmptyValueException>()),
      );
    });

    test('encodes List<int> with special characters', () {
      const value = [72, 195, 171, 108, 108, 195, 182]; // "Hëllö"
      expect(
        value.toMatrix('text', allowEmpty: true, explode: false),
        ';text=H%C3%ABll%C3%B6',
      );
    });

    test('explode parameter has no effect', () {
      const value = [72, 101, 108, 108, 111];
      expect(
        value.toMatrix('data', allowEmpty: true, explode: true),
        value.toMatrix('data', allowEmpty: true, explode: false),
      );
    });
  });
}
