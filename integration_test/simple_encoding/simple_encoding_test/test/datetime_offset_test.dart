import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('JSON encoding normalizes offset seconds and preserves the instant', () {
    final instant = DateTime.utc(1900, 1, 1, 11, 50, 39);
    final timestamp = OffsetDateTime.from(
      instant,
      offset: const Duration(minutes: 9, seconds: 21),
    );

    final json = TimestampMixin(createdAt: timestamp).toJson();

    expect(json, {'created_at': '1900-01-01T12:00:39+00:10'});
    expect(
      TimestampMixin.fromJson(json).createdAt.isAtSameMomentAs(instant),
      isTrue,
    );
  });
}
