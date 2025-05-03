import 'package:big_decimal/big_decimal.dart';
import 'package:test/test.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';
import 'package:tonik_util/src/decoding/json_decoder.dart';

void main() {
  group('JsonDecoder', () {
    group('DateTime', () {
      test('decodes DateTime values', () {
        final date = DateTime.utc(2024, 3, 14);
        expect(date.toIso8601String().decodeJsonDateTime(), date);
        expect(
          () => 123.decodeJsonDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
        expect(
          () => null.decodeJsonDateTime(),
          throwsA(isA<InvalidTypeException>()),
        );
      });

      test('decodes nullable DateTime values', () {
        final date = DateTime.utc(2024, 3, 14);
        expect(date.toIso8601String().decodeJsonNullableDateTime(), date);
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
  });
}
