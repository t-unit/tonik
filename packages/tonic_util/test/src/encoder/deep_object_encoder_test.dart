import 'package:test/test.dart';
import 'package:tonic_util/src/encoding/deep_object_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';
import 'package:tonic_util/src/encoding/parameter_entry.dart';

void main() {
  const encoder = DeepObjectEncoder();

  group('DeepObjectEncoder', () {
    test('encodes a simple object', () {
      final result = encoder.encode('filter', {
        'color': 'red',
        'size': 'large',
      }, allowEmpty: true);

      expect(result, [
        (name: 'filter[color]', value: 'red'),
        (name: 'filter[size]', value: 'large'),
      ]);
    });

    test('encodes boolean properties', () {
      final result = encoder.encode('filter', {
        'active': true,
        'premium': false,
      }, allowEmpty: true);

      expect(result, [
        (name: 'filter[active]', value: 'true'),
        (name: 'filter[premium]', value: 'false'),
      ]);
    });

    test('encodes an object with a null value', () {
      final result = encoder.encode('filter', {
        'color': null,
        'size': 'large',
      }, allowEmpty: true);

      expect(result, [
        (name: 'filter[color]', value: ''),
        (name: 'filter[size]', value: 'large'),
      ]);
    });

    test('encodes an empty object', () {
      final result = encoder.encode(
        'filter',
        <String, dynamic>{},
        allowEmpty: true,
      );

      expect(result, [(name: 'filter', value: '')]);
    });

    test('encodes nested objects', () {
      final result = encoder.encode('filter', {
        'product': {'color': 'blue', 'size': 'medium'},
      }, allowEmpty: true);

      expect(result, [
        (name: 'filter[product][color]', value: 'blue'),
        (name: 'filter[product][size]', value: 'medium'),
      ]);
    });

    test('encodes deeply nested objects', () {
      final result = encoder.encode('filter', {
        'product': {
          'attributes': {'color': 'blue', 'size': 'medium'},
        },
      }, allowEmpty: true);

      expect(result, [
        (name: 'filter[product][attributes][color]', value: 'blue'),
        (name: 'filter[product][attributes][size]', value: 'medium'),
      ]);
    });

    test('throws for objects containing arrays', () {
      expect(
        () => encoder.encode('filter', {
          'colors': ['red', 'blue', 'green'],
        }, allowEmpty: true),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('throws for objects containing empty arrays', () {
      expect(
        () =>
            encoder.encode('filter', {'colors': <String>[]}, allowEmpty: true),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('throws for objects containing sets', () {
      expect(
        () => encoder.encode('filter', {
          'sizes': {'small', 'medium', 'large'},
        }, allowEmpty: true),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('encodes a complex object with various types', () {
      final result = encoder.encode('params', {
        'name': 'John',
        'age': 30,
        'active': true,
        'address': {'street': '123 Main St', 'city': 'New York'},
      }, allowEmpty: true);

      expect(result, [
        (name: 'params[name]', value: 'John'),
        (name: 'params[age]', value: '30'),
        (name: 'params[active]', value: 'true'),
        (name: 'params[address][street]', value: '123+Main+St'),
        (name: 'params[address][city]', value: 'New+York'),
      ]);
    });

    test('throws UnsupportedEncodingTypeException if value is not a Map', () {
      expect(
        () => encoder.encode('param', 'string value', allowEmpty: true),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );

      expect(
        () => encoder.encode('param', 42, allowEmpty: true),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );

      expect(
        () => encoder.encode('param', [1, 2, 3], allowEmpty: true),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test(
      'throws UnsupportedEncodingTypeException for unsupported types in Map',
      () {
        final objectWithFunction = {'callback': () => 'hello'};

        expect(
          () => encoder.encode('param', objectWithFunction, allowEmpty: true),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      },
    );

    test(
      'throws UnsupportedEncodingTypeException for nested unsupported types',
      () {
        final nestedObject = {
          'outer': {
            'inner': {'unsupported': RegExp(r'\d+')},
          },
        };

        expect(
          () => encoder.encode('param', nestedObject, allowEmpty: true),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      },
    );

    test('throws UnsupportedEncodingTypeException for nested arrays', () {
      // Object with nested arrays
      final objectWithNestedArrays = {
        'user': {
          'hobbies': ['reading', 'swimming'],
        },
      };

      expect(
        () => encoder.encode('param', objectWithNestedArrays, allowEmpty: true),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    group('allowEmpty parameter', () {
      test('allows empty values when allowEmpty is true', () {
        final result = encoder.encode('filter', {
          'emptyString': '',
          'emptyMap': <String, dynamic>{},
          'normalValue': 'test',
        }, allowEmpty: true);

        expect(result, [
          (name: 'filter[emptyString]', value: ''),
          (name: 'filter[emptyMap]', value: ''),
          (name: 'filter[normalValue]', value: 'test'),
        ]);
      });

      test('throws when allowEmpty is false and value is empty string', () {
        expect(
          () => encoder.encode('filter', {
            'emptyString': '',
            'normalValue': 'test',
          }, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('throws when allowEmpty is false and map is empty', () {
        expect(
          () =>
              encoder.encode('filter', <String, dynamic>{}, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('throws when allowEmpty is false and nested map is empty', () {
        expect(
          () => encoder.encode('filter', {
            'nested': <String, dynamic>{},
            'normalValue': 'test',
          }, allowEmpty: false),
          throwsA(isA<EmptyValueException>()),
        );
      });

      test('throws when allowEmpty is false and value is empty list', () {
        expect(
          () =>
              encoder.encode('filter', {'list': <String>[]}, allowEmpty: false),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('throws when allowEmpty is false and value is empty set', () {
        expect(
          () =>
              encoder.encode('filter', {'set': <String>{}}, allowEmpty: false),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      });

      test('allows non-empty values when allowEmpty is false', () {
        final result = encoder.encode('filter', {
          'string': 'value',
          'nested': {'inner': 'value'},
        }, allowEmpty: false);

        expect(result, [
          (name: 'filter[string]', value: 'value'),
          (name: 'filter[nested][inner]', value: 'value'),
        ]);
      });
    });
  });
}
