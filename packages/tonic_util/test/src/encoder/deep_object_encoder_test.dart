import 'package:test/test.dart';
import 'package:tonic_util/src/encoding/deep_object_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';

void main() {
  const encoder = DeepObjectEncoder();

  group('DeepObjectEncoder', () {
    test('encodes a simple object', () {
      final result = encoder.encode('filter', {
        'color': 'red',
        'size': 'large',
      });

      expect(result, {'filter[color]': 'red', 'filter[size]': 'large'});
    });

    test('encodes boolean properties', () {
      final result = encoder.encode('filter', {
        'active': true,
        'premium': false,
      });

      expect(result, {'filter[active]': 'true', 'filter[premium]': 'false'});
    });

    test('encodes an object with a null value', () {
      final result = encoder.encode('filter', {'color': null, 'size': 'large'});

      expect(result, {'filter[color]': '', 'filter[size]': 'large'});
    });

    test('encodes an empty object', () {
      final result = encoder.encode('filter', <String, dynamic>{});

      expect(result, isEmpty);
    });

    test('encodes nested objects', () {
      final result = encoder.encode('filter', {
        'product': {'color': 'blue', 'size': 'medium'},
      });

      expect(result, {
        'filter[product][color]': 'blue',
        'filter[product][size]': 'medium',
      });
    });

    test('encodes deeply nested objects', () {
      final result = encoder.encode('filter', {
        'product': {
          'attributes': {'color': 'blue', 'size': 'medium'},
        },
      });

      expect(result, {
        'filter[product][attributes][color]': 'blue',
        'filter[product][attributes][size]': 'medium',
      });
    });

    test('throws for objects containing arrays', () {
      expect(
        () => encoder.encode('filter', {
          'colors': ['red', 'blue', 'green'],
        }),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('throws for objects containing empty arrays', () {
      expect(
        () => encoder.encode('filter', {'colors': <String>[]}),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('throws for objects containing sets', () {
      expect(
        () => encoder.encode('filter', {
          'sizes': {'small', 'medium', 'large'},
        }),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test('encodes a complex object with various types', () {
      final result = encoder.encode('params', {
        'name': 'John',
        'age': 30,
        'active': true,
        'address': {'street': '123 Main St', 'city': 'New York'},
      });

      expect(result, {
        'params[name]': 'John',
        'params[age]': '30',
        'params[active]': 'true',
        'params[address][street]': '123+Main+St',
        'params[address][city]': 'New+York',
      });
    });

    test('encodes DateTime values correctly', () {
      final dateTime = DateTime.utc(2023, 5, 15, 12, 30, 45);

      final result = encoder.encode('filter', {'date': dateTime});

      expect(result, {'filter[date]': '2023-05-15T12:30:45.000Z'});
    });

    test('encodes nested DateTime values correctly', () {
      final startDate = DateTime.utc(2023, 5, 15);
      final endDate = DateTime.utc(2023, 6, 20);

      final result = encoder.encode('filter', {
        'range': {'start': startDate, 'end': endDate},
      });

      expect(result, {
        'filter[range][start]': '2023-05-15T00:00:00.000Z',
        'filter[range][end]': '2023-06-20T00:00:00.000Z',
      });
    });

    test('throws UnsupportedEncodingTypeException if value is not a Map', () {
      expect(
        () => encoder.encode('param', 'string value'),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );

      expect(
        () => encoder.encode('param', 42),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );

      expect(
        () => encoder.encode('param', [1, 2, 3]),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });

    test(
      'throws UnsupportedEncodingTypeException for unsupported types in Map',
      () {
        // Object with a function value
        final objectWithFunction = {'callback': () => 'hello'};

        expect(
          () => encoder.encode('param', objectWithFunction),
          throwsA(isA<UnsupportedEncodingTypeException>()),
        );
      },
    );

    test(
      'throws UnsupportedEncodingTypeException for nested unsupported types',
      () {
        // Nested map with an unsupported type
        final nestedObject = {
          'outer': {
            'inner': {'unsupported': RegExp(r'\d+')},
          },
        };

        expect(
          () => encoder.encode('param', nestedObject),
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
        () => encoder.encode('param', objectWithNestedArrays),
        throwsA(isA<UnsupportedEncodingTypeException>()),
      );
    });
  });
}
