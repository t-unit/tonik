import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('JSON encoding preserves offset seconds and the instant', () {
    final instant = DateTime.utc(1900, 1, 1, 11, 50, 39);
    final timestamp = OffsetDateTime.from(
      instant,
      offset: const Duration(minutes: 9, seconds: 21),
    );

    final json = TimestampMixin(createdAt: timestamp).toJson();

    expect(json, {'created_at': '1900-01-01T12:00:00+00:09:21'});
    expect(
      TimestampMixin.fromJson(json).createdAt.timeZoneOffset,
      const Duration(minutes: 9, seconds: 21),
    );
    expect(
      TimestampMixin.fromJson(json).createdAt.isAtSameMomentAs(instant),
      isTrue,
    );
  });

  test(
    'JSON decoding preserves negative offset seconds and clock fractions',
    () {
      final model = TimestampMixin.fromJson(const {
        'created_at': '2023-12-31T23:59:39.123456-00:00:21',
      });

      expect(model.createdAt.timeZoneOffset, const Duration(seconds: -21));
      expect(
        model.createdAt.toUtc(),
        DateTime.utc(2024, 1, 1, 0, 0, 0, 123, 456),
      );
      expect(model.toJson(), {
        'created_at': '2023-12-31T23:59:39.123456-00:00:21',
      });
    },
  );
}
