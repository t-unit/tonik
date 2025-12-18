import 'package:petstore_api/petstore_api.dart' as base;
import 'package:petstore_overrides_api/petstore_overrides_api.dart'
    as overrides;
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('OrderStatusModel unknown/encoding', () {
    test(
      'overrides: unknown string maps to reservedForFutureUse via fromJson',
      () {
        final res = overrides.OrderStatusModel.fromJson('something_unknown');
        expect(res, overrides.OrderStatusModel.reservedForFutureUse);
      },
    );

    test('overrides: non-string input throws JsonDecodingException', () {
      expect(
        () => overrides.OrderStatusModel.fromJson(123),
        throwsA(isA<JsonDecodingException>()),
      );
    });

    test(
      'overrides: toJson throws EncodingException for reservedForFutureUse',
      () {
        expect(
          () => overrides.OrderStatusModel.reservedForFutureUse.toJson(),
          throwsA(isA<EncodingException>()),
        );
      },
    );

    test(
      'overrides: toSimple throws EncodingException for reservedForFutureUse',
      () {
        expect(
          () => overrides.OrderStatusModel.reservedForFutureUse.toSimple(
            explode: false,
            allowEmpty: false,
          ),
          throwsA(isA<EncodingException>()),
        );
      },
    );

    test('overrides: fromSimple with unknown returns reservedForFutureUse', () {
      final res = overrides.OrderStatusModel.fromSimple(
        'unknown',
        explode: false,
      );
      expect(res, overrides.OrderStatusModel.reservedForFutureUse);
    });

    test('base: unknown string does NOT map to reservedForFutureUse', () {
      // The original petstore_api should reject unknown enum values
      expect(
        () => base.OrderStatusModel.fromJson('something_unknown'),
        throwsA(isA<JsonDecodingException>()),
      );
    });

    test('base: enum values do not include reservedForFutureUse rawValue', () {
      final hasReserved = base.OrderStatusModel.values.any(
        (e) => e.rawValue == 'reservedForFutureUse',
      );
      expect(hasReserved, isFalse);
    });
  });
}
