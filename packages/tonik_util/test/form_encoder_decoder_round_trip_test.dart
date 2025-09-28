import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/decoding/form_decoder.dart';
import 'package:tonik_util/src/encoding/form_encoder_extensions.dart';

/// Tests to verify that form encoding and decoding are perfect inverses.
/// These tests ensure data integrity through encode/decode cycles.
void main() {
  group('Form Encoder/Decoder Round-Trip Compatibility', () {
    group('String round-trip', () {
      test('simple strings', () {
        const original = 'hello world';
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormString();
        expect(decoded, original);
      });

      test('strings with special characters', () {
        const original = 'test@example.com';
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormString();
        expect(decoded, original);
      });

      test('strings with mixed special characters', () {
        const original = 'hello world @test+data&more=stuff';
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormString();
        expect(decoded, original);
      });

      test('unicode strings', () {
        const original = 'héllo wörld 😀';
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormString();
        expect(decoded, original);
      });

      test('empty strings', () {
        const original = '';
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormString();
        expect(decoded, original);
      });

      test('very long strings', () {
        final original = 'a' * 1000 + r' test @#$%^&*()';
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormString();
        expect(decoded, original);
      });
    });

    group('Integer round-trip', () {
      test('positive integers', () {
        const original = 42;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormInt();
        expect(decoded, original);
      });

      test('negative integers', () {
        const original = -123;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormInt();
        expect(decoded, original);
      });

      test('zero', () {
        const original = 0;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormInt();
        expect(decoded, original);
      });

      test('large integers', () {
        const original = 9223372036854775807; // max int64
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormInt();
        expect(decoded, original);
      });
    });

    group('Double round-trip', () {
      test('positive doubles', () {
        const original = 3.14159;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormDouble();
        expect(decoded, original);
      });

      test('negative doubles', () {
        const original = -2.71828;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormDouble();
        expect(decoded, original);
      });

      test('zero double', () {
        const original = 0.0;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormDouble();
        expect(decoded, original);
      });

      test('extreme double values', () {
        const values = [
          double.infinity,
          double.negativeInfinity,
          double.maxFinite,
          double.minPositive,
        ];

        for (final original in values) {
          final encoded = original.toForm(explode: false, allowEmpty: true);
          final decoded = encoded.decodeFormDouble();
          expect(decoded, original, reason: 'Failed for value: $original');
        }
      });

      test('NaN handling', () {
        const original = double.nan;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormDouble();
        expect(decoded, isNaN);
      });
    });

    group('Boolean round-trip', () {
      test('true value', () {
        const original = true;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormBool();
        expect(decoded, original);
      });

      test('false value', () {
        const original = false;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormBool();
        expect(decoded, original);
      });
    });

    group('BigDecimal round-trip', () {
      test('simple decimal', () {
        final original = BigDecimal.parse('123.456789');
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormBigDecimal();
        expect(decoded, original);
      });

      test('large decimal', () {
        final original = BigDecimal.parse('999999999999.123456789012345');
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormBigDecimal();
        expect(decoded, original);
      });

      test('zero decimal', () {
        final original = BigDecimal.zero;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormBigDecimal();
        expect(decoded, original);
      });

      test('negative decimal', () {
        final original = BigDecimal.parse('-42.5');
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormBigDecimal();
        expect(decoded, original);
      });

      test('very precise decimal', () {
        final original = BigDecimal.parse('0.000000000000000000000001');
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormBigDecimal();
        expect(decoded, original);
      });
    });

    group('URI round-trip', () {
      test('simple URI', () {
        final original = Uri.parse('https://example.com');
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormUri();
        expect(decoded, original);
      });

      test('complex URI with query parameters', () {
        final original = Uri.parse(
          'https://example.com/path?query=value&other=data',
        );
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormUri();
        expect(decoded, original);
      });

      test('URI with special characters', () {
        final original = Uri.parse(
          'https://example.com/path with spaces?query=value@test',
        );
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormUri();
        expect(decoded, original);
      });

      test('URI with fragment', () {
        final original = Uri.parse('https://example.com/path#fragment');
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormUri();
        expect(decoded, original);
      });
    });

    group('String List round-trip', () {
      test('simple string list', () {
        const original = ['red', 'green', 'blue'];
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormStringList();
        expect(decoded, original);
      });

      test('string list with special characters', () {
        const original = [
          'hello world',
          'test@example.com',
          'key=value&other=data',
        ];
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormStringList();
        expect(decoded, original);
      });

      test('string list with unicode', () {
        const original = ['héllo wörld', 'emoji 😀', 'unicode ñ'];
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormStringList();
        expect(decoded, original);
      });

      test('single item list', () {
        const original = ['single'];
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormStringList();
        expect(decoded, original);
      });

      test('empty list', () {
        const original = <String>[];
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormStringList();
        expect(decoded, original);
      });

      test('list with empty strings', () {
        const original = ['', 'middle', ''];
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormStringList();
        expect(decoded, original);
      });
    });

    group('String Map round-trip (explode=false)', () {
      test('simple string map', () {
        const original = {'name': 'John', 'age': '25'};
        final encoded = original.toForm(explode: false, allowEmpty: true);

        // For explode=false, we expect comma-separated key,value pairs
        // We can't directly round-trip maps through string decoding since
        // the decoder doesn't have a decodeFormMap method yet
        // This test verifies the encoding format is correct
        final parts = encoded.split(',');
        expect(parts.length, 4);
        expect(parts, containsAll(['name', 'John', 'age', '25']));
      });

      test('map with special characters', () {
        const original = {'key=name': 'value&data', 'other+key': 'more data'};
        final encoded = original.toForm(explode: false, allowEmpty: true);

        // Verify that values are properly encoded (keys are not encoded in
        // explode=false)
        expect(encoded, contains('key=name'));
        expect(encoded, contains('value%26data'));
        expect(encoded, contains('other+key'));
        expect(encoded, contains('more+data'));
      });
    });

    group('String Map round-trip (explode=true)', () {
      test('simple string map exploded', () {
        const original = {'name': 'John', 'age': '25'};
        final encoded = original.toForm(explode: true, allowEmpty: true);

        // For explode=true, we expect key=value pairs separated by &
        expect(encoded, contains('name=John'));
        expect(encoded, contains('age=25'));
        expect(encoded, contains('&'));
      });

      test('map with special characters exploded', () {
        const original = {'key name': 'value@data', 'other+key': 'more&data'};
        final encoded = original.toForm(explode: true, allowEmpty: true);

        // Verify proper encoding in exploded format
        expect(encoded, contains('key+name=value%40data'));
        expect(encoded, contains('other%2Bkey=more%26data'));
        expect(encoded, contains('&'));
      });
    });

    group('Nullable types round-trip', () {
      test('nullable string with value', () {
        const original = 'test value';
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormNullableString();
        expect(decoded, original);
      });

      test('nullable int with value', () {
        const original = 42;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormNullableInt();
        expect(decoded, original);
      });

      test('nullable bool with value', () {
        const original = true;
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormNullableBool();
        expect(decoded, original);
      });

      test('nullable list with value', () {
        const original = ['test', 'data'];
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormNullableStringList();
        expect(decoded, original);
      });
    });

    group('Edge cases and stress tests', () {
      test('strings with all ASCII special characters', () {
        const original = r'''!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~''';
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormString();
        expect(decoded, original);
      });

      test('mixed data types in string list', () {
        const original = ['42', 'true', '3.14', 'hello world'];
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormStringList();
        expect(decoded, original);
      });

      test('very large string list', () {
        final original = List.generate(100, (i) => 'item_$i with spaces');
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormStringList();
        expect(decoded, original);
      });

      test('string with only special characters', () {
        const original = r'@#$%^&*()+={}[]|\:";' "'" '<>?,./';
        final encoded = original.toForm(explode: false, allowEmpty: true);
        final decoded = encoded.decodeFormString();
        expect(decoded, original);
      });
    });

    group('Data integrity verification', () {
      test('no data loss in encoding/decoding cycle', () {
        final testCases = [
          'simple',
          'hello world',
          'test@example.com',
          'key=value&other=data',
          'unicode: héllo wörld 😀',
          r'special: @#$%^&*()',
          '',
          'a' * 1000,
        ];

        for (final original in testCases) {
          final encoded = original.toForm(explode: false, allowEmpty: true);
          final decoded = encoded.decodeFormString();
          expect(decoded, original, reason: 'Failed for: "$original"');
          expect(
            decoded.length,
            original.length,
            reason: 'Length mismatch for: "$original"',
          );
        }
      });

      test('encoding is reversible for all supported types', () {
        // String
        const stringVal = 'test value';
        expect(
          stringVal.toForm(explode: false, allowEmpty: true).decodeFormString(),
          stringVal,
        );

        // Int
        const intVal = 42;
        expect(
          intVal.toForm(explode: false, allowEmpty: true).decodeFormInt(),
          intVal,
        );

        // Double
        const doubleVal = 3.14;
        expect(
          doubleVal.toForm(explode: false, allowEmpty: true).decodeFormDouble(),
          doubleVal,
        );

        // Bool
        const boolVal = true;
        expect(
          boolVal.toForm(explode: false, allowEmpty: true).decodeFormBool(),
          boolVal,
        );

        // BigDecimal
        final bigDecimalVal = BigDecimal.parse('123.456');
        expect(
          bigDecimalVal
              .toForm(explode: false, allowEmpty: true)
              .decodeFormBigDecimal(),
          bigDecimalVal,
        );

        // URI
        final uriVal = Uri.parse('https://example.com');
        expect(
          uriVal.toForm(explode: false, allowEmpty: true).decodeFormUri(),
          uriVal,
        );

        // List
        const listVal = ['a', 'b', 'c'];
        expect(
          listVal
              .toForm(explode: false, allowEmpty: true)
              .decodeFormStringList(),
          listVal,
        );
      });
    });
  });
}
