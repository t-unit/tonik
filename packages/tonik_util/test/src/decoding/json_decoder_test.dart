import 'dart:convert';

import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/date.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';
import 'package:tonik_util/src/decoding/json_decoder.dart';

void main() {
  group('JsonDecoder', () {
    group('DateTime', () {
      test('decodes DateTime values with timezone awareness', () {
        // Test UTC parsing
        const utcString = '2024-03-14T10:30:45Z';
        final utcResult = utcString.decodeJsonDateTime();
        expect(utcResult.year, 2024);
        expect(utcResult.month, 3);
        expect(utcResult.day, 14);
        expect(utcResult.hour, 10);
        expect(utcResult.minute, 30);
        expect(utcResult.second, 45);
        expect(utcResult.timeZoneOffset, Duration.zero);

        // Test local time parsing (no timezone offset)
        const localString = '2024-03-14T10:30:45';
        final localResult = localString.decodeJsonDateTime();
        expect(localResult.year, 2024);
        expect(localResult.month, 3);
        expect(localResult.day, 14);
        expect(localResult.hour, 10);
        expect(localResult.minute, 30);
        expect(localResult.second, 45);
        // Local datetime uses system timezone
        // should match same date in local timezone
        final expectedLocalTime = DateTime(2024, 3, 14, 10, 30, 45);
        expect(localResult.timeZoneOffset, expectedLocalTime.timeZoneOffset);

        // Test timezone offset parsing
        const offsetString = '2024-03-14T10:30:45+05:00';
        final offsetResult = offsetString.decodeJsonDateTime();
        expect(offsetResult.year, 2024);
        expect(offsetResult.month, 3);
        expect(offsetResult.day, 14);
        expect(offsetResult.hour, 10);
        expect(offsetResult.minute, 30);
        expect(offsetResult.second, 45);
        expect(offsetResult.timeZoneOffset.inHours, 5);
        expect(offsetResult.timeZoneOffset.inMinutes, 5 * 60);

        // Test negative timezone offset
        const negativeOffsetString = '2024-03-14T10:30:45-08:00';
        final negativeOffsetResult = negativeOffsetString.decodeJsonDateTime();
        expect(negativeOffsetResult.year, 2024);
        expect(negativeOffsetResult.month, 3);
        expect(negativeOffsetResult.day, 14);
        expect(negativeOffsetResult.hour, 10);
        expect(negativeOffsetResult.minute, 30);
        expect(negativeOffsetResult.second, 45);
        expect(negativeOffsetResult.timeZoneOffset.inHours, -8);
        expect(negativeOffsetResult.timeZoneOffset.inMinutes, -8 * 60);

        // Test error cases
        expect(
          () => 123.decodeJsonDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeJsonDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes nullable DateTime values with timezone awareness', () {
        final result = '2024-03-14T10:30:45Z'.decodeJsonNullableDateTime();
        expect(result, isNotNull);
        expect(result!.year, 2024);
        expect(result.month, 3);
        expect(result.day, 14);
        expect(result.hour, 10);
        expect(result.minute, 30);
        expect(result.second, 45);
        expect(result.timeZoneOffset, Duration.zero);

        expect(null.decodeJsonNullableDateTime(), isNull);
        expect(''.decodeJsonNullableDateTime(), isNull);
        expect(
          () => 123.decodeJsonNullableDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('BigDecimal', () {
      test('decodes BigDecimal values', () {
        expect('3.14'.decodeJsonBigDecimal(), BigDecimal.parse('3.14'));
        expect('-0.5'.decodeJsonBigDecimal(), BigDecimal.parse('-0.5'));
        expect(
          () => 123.decodeJsonBigDecimal(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeJsonBigDecimal(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes nullable BigDecimal values', () {
        expect('3.14'.decodeJsonNullableBigDecimal(), BigDecimal.parse('3.14'));
        expect('-0.5'.decodeJsonNullableBigDecimal(), BigDecimal.parse('-0.5'));
        expect(null.decodeJsonNullableDateTime(), isNull);
        expect(''.decodeJsonNullableBigDecimal(), isNull);
        expect(
          () => 123.decodeJsonNullableBigDecimal(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('String', () {
      test('decodes String values', () {
        expect('hello'.decodeJsonString(), 'hello');
        expect(
          () => 123.decodeJsonString(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeJsonString(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes nullable String values', () {
        expect('hello'.decodeJsonNullableString(), 'hello');
        expect(null.decodeJsonNullableString(), isNull);
        expect(''.decodeJsonNullableString(), '');
        expect(
          () => 123.decodeJsonNullableString(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('int', () {
      test('decodes int values', () {
        expect(42.decodeJsonInt(), 42);
        expect((-7).decodeJsonInt(), -7);
        expect(
          () => 'foo'.decodeJsonInt(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeJsonInt(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes nullable int values', () {
        expect(42.decodeJsonNullableInt(), 42);
        expect((-7).decodeJsonNullableInt(), -7);
        expect(null.decodeJsonNullableInt(), isNull);
        expect(
          () => 'foo'.decodeJsonNullableInt(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('num', () {
      test('decodes num values', () {
        expect(42.decodeJsonNum(), 42);
        expect((-7.5).decodeJsonNum(), -7.5);
        expect(3.14.decodeJsonNum(), 3.14);
        expect(
          () => 'foo'.decodeJsonNum(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeJsonNum(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes nullable num values', () {
        expect(42.decodeJsonNullableNum(), 42);
        expect((-7.5).decodeJsonNullableNum(), -7.5);
        expect(3.14.decodeJsonNullableNum(), 3.14);
        expect(null.decodeJsonNullableNum(), isNull);
        expect(
          () => 'foo'.decodeJsonNullableNum(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('double', () {
      test('decodes double values', () {
        expect(3.14.decodeJsonDouble(), 3.14);
        expect((-0.5).decodeJsonDouble(), -0.5);
        expect(
          () => 'foo'.decodeJsonDouble(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeJsonDouble(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes nullable double values', () {
        expect(3.14.decodeJsonNullableDouble(), 3.14);
        expect((-0.5).decodeJsonNullableDouble(), -0.5);
        expect(null.decodeJsonNullableDouble(), isNull);
        expect(
          () => 'foo'.decodeJsonNullableDouble(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('bool', () {
      test('decodeJsonBool decodes a valid bool', () {
        expect(true.decodeJsonBool(), isTrue);
        expect(false.decodeJsonBool(), isFalse);
      });

      test('decodeJsonBool throws on null', () {
        expect(
          () => null.decodeJsonBool(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodeJsonBool throws on non-bool', () {
        expect(
          () => 'true'.decodeJsonBool(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodeJsonNullableBool decodes a valid bool', () {
        expect(true.decodeJsonNullableBool(), isTrue);
        expect(false.decodeJsonNullableBool(), isFalse);
      });

      test('decodeJsonNullableBool returns null on null', () {
        expect(null.decodeJsonNullableBool(), isNull);
      });

      test('decodeJsonNullableBool throws on non-bool', () {
        expect(
          () => 'true'.decodeJsonNullableBool(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('Date', () {
      test('decodes Date values', () {
        final date = Date(2024, 3, 15);
        expect('2024-03-15'.decodeJsonDate(), date);
        expect(
          () => 123.decodeJsonDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeJsonDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2024-00-15'.decodeJsonDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2024-13-15'.decodeJsonDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2024-03-00'.decodeJsonDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2024-03-32'.decodeJsonDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2024-02-30'.decodeJsonDate(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes nullable Date values', () {
        final date = Date(2024, 3, 15);
        expect('2024-03-15'.decodeJsonNullableDate(), date);
        expect(null.decodeJsonNullableDate(), isNull);
        expect(
          () => ''.decodeJsonNullableDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => 123.decodeJsonNullableDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2024-00-15'.decodeJsonNullableDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2024-13-15'.decodeJsonNullableDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2024-03-00'.decodeJsonNullableDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2024-03-32'.decodeJsonNullableDate(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => '2024-02-30'.decodeJsonNullableDate(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });

    group('Uri', () {
      test('decodes Uri values', () {
        final uri = Uri.parse('https://example.com');
        expect('https://example.com'.decodeJsonUri(), uri);
        expect(
          'ftp://files.example.com/file.txt'.decodeJsonUri(),
          Uri.parse('ftp://files.example.com/file.txt'),
        );
        expect('/relative/path'.decodeJsonUri(), Uri.parse('/relative/path'));
        expect(
          'mailto:user@example.com'.decodeJsonUri(),
          Uri.parse('mailto:user@example.com'),
        );
        expect(
          () => 123.decodeJsonUri(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeJsonUri(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes nullable Uri values', () {
        final uri = Uri.parse('https://example.com');
        expect('https://example.com'.decodeJsonNullableUri(), uri);
        expect(
          '/api/v1/users'.decodeJsonNullableUri(),
          Uri.parse('/api/v1/users'),
        );
        expect(null.decodeJsonNullableUri(), isNull);
        expect(''.decodeJsonNullableUri(), Uri.parse(''));
        expect(
          () => 123.decodeJsonNullableUri(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('handles invalid URI strings', () {
        expect(
          () => ':::invalid:::'.decodeJsonUri(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => ':::invalid:::'.decodeJsonNullableUri(),
          throwsA(isA<InvalidTypeException>()),
        );
      });
    });
  });

  group('List', () {
    test('decodes int lists', () {
      final json = jsonDecode('[1,2,3]') as Object?;
      expect(json.decodeJsonList<int>(), [1, 2, 3]);
    });

    test('decodes string lists', () {
      final json = jsonDecode('["foo","bar"]') as Object?;
      expect(json.decodeJsonList<String>(), ['foo', 'bar']);
    });

    test('throws if the list is not a list', () {
      final json = jsonDecode('{"foo":"bar"}') as Object?;
      expect(
        () => json.decodeJsonList<int>(),
        throwsA(isA<InvalidTypeException>()),
      );
    });

    test('throws if the list is not a list of the expected type', () {
      final json = jsonDecode('[1,2,3]') as Object?;
      expect(
        () => json.decodeJsonList<String>(),
        throwsA(isA<InvalidTypeException>()),
      );
    });

    test('throws if the list is null', () {
      final json = jsonDecode('null') as Object?;
      expect(
        () => json.decodeJsonList<int>(),
        throwsA(isA<InvalidTypeException>()),
      );
    });

    test('decodes nested lists', () {
      final json = jsonDecode('[[1,2],[3,4]]') as Object?;
      expect(json.decodeJsonList<List<Object?>>(), [
        [1, 2],
        [3, 4],
      ]);
    });

    test('decodes nullable lists', () {
      final json = jsonDecode('null') as Object?;
      expect(json.decodeJsonNullableList<int>(), isNull);
    });
  });

  group('decodeMap', () {
    test('decodes valid map', () {
      final map = {'key': 'value'};
      expect(map.decodeMap(), map);
    });

    test('throws on null', () {
      expect(() => null.decodeMap(), throwsA(isA<InvalidTypeException>()));
    });

    test('throws on non-map', () {
      expect(
        () => 'not a map'.decodeMap(),
        throwsA(isA<InvalidTypeException>()),
      );
    });

    test('includes context in error message', () {
      expect(
        () => null.decodeMap(context: 'test context'),
        throwsA(isA<InvalidTypeException>()),
      );
    });
  });

  group('Binary', () {
    test('decodes UTF-8 string to List<int>', () {
      // Test standard UTF-8.
      const textString = 'Hello World';
      final result = textString.decodeJsonBinary();
      expect(result, [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]);

      // Test UTF-8 with special characters.
      const utf8String = 'Hëllö';
      final utf8Result = utf8String.decodeJsonBinary();
      expect(utf8Result, [72, 195, 171, 108, 108, 195, 182]);

      // Test empty string.
      const emptyString = '';
      final emptyResult = emptyString.decodeJsonBinary();
      expect(emptyResult, <int>[]);
    });

    test('decodes nullable UTF-8 string to List<int>', () {
      const textString = 'Hello World';
      final result = textString.decodeJsonNullableBinary();
      expect(result, [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]);

      expect(null.decodeJsonNullableBinary(), isNull);
      expect(''.decodeJsonNullableBinary(), <int>[]);
    });

    test('handles malformed UTF-8 gracefully', () {
      // String with escape sequences that might represent binary data.
      const stringWithEscapes = 'test\u0000data';
      final result = stringWithEscapes.decodeJsonBinary();
      expect(result, isNotEmpty);
    });

    test('throws InvalidTypeException if value is null', () {
      expect(
        () => null.decodeJsonBinary(),
        throwsA(isA<InvalidTypeException>()),
      );
    });

    test('throws InvalidTypeException if value is not a string', () {
      expect(
        () => 123.decodeJsonBinary(),
        throwsA(isA<InvalidTypeException>()),
      );
      expect(
        () => [1, 2, 3].decodeJsonBinary(),
        throwsA(isA<InvalidTypeException>()),
      );
    });

    test('includes context in error messages', () {
      try {
        null.decodeJsonBinary(context: 'User.thumbnail');
        fail('Should have thrown');
      } on InvalidTypeException catch (e) {
        expect(e.context, 'User.thumbnail');
      }

      try {
        123.decodeJsonBinary(context: 'Request.data');
        fail('Should have thrown');
      } on InvalidTypeException catch (e) {
        expect(e.context, 'Request.data');
      }
    });
  });
}
