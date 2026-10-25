import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:tonik_util/src/decoding/simple_decoder.dart';
import 'package:tonik_util/src/encoding/datetime_extension.dart';
import 'package:tonik_util/src/offset_date_time.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  group('DateTimeEncodingExtension', () {
    group('toTimeZonedIso8601String', () {
      test('encodes UTC DateTime correctly', () {
        final utcDateTime = DateTime.utc(2023, 12, 25, 15, 30, 45, 123);
        final result = utcDateTime.toTimeZonedIso8601String();

        expect(result, utcDateTime.toIso8601String());
        expect(result, '2023-12-25T15:30:45.123Z');
      });

      test('preserves Dart year formatting in UTC', () {
        expect(
          DateTime.utc(-5).toTimeZonedIso8601String(),
          '-0005-01-01T00:00:00.000Z',
        );
        expect(
          DateTime.utc(10000).toTimeZonedIso8601String(),
          '+010000-01-01T00:00:00.000Z',
        );
      });
    });

    group('timezone handling', () {
      test('rounds a positive offset up without changing the instant', () {
        final instant = DateTime.utc(1900, 1, 1, 11, 50, 39);
        final dateTime = OffsetDateTime.from(
          instant,
          offset: const Duration(minutes: 9, seconds: 21),
        );

        final encoded = dateTime.toTimeZonedIso8601String();

        expect(encoded, '1900-01-01T12:00:39+00:10');
        expect(DateTime.parse(encoded).isAtSameMomentAs(instant), isTrue);
      });

      test('rounds a negative offset up without changing the instant', () {
        final instant = DateTime.utc(1900, 1, 1, 12, 9, 21);
        final dateTime = OffsetDateTime.from(
          instant,
          offset: const Duration(minutes: -9, seconds: -21),
        );

        final encoded = dateTime.toTimeZonedIso8601String();

        expect(encoded, '1900-01-01T12:00:21-00:09');
        expect(DateTime.parse(encoded).isAtSameMomentAs(instant), isTrue);
      });

      test('preserves microseconds when normalization crosses a year', () {
        final instant = DateTime.utc(2023, 12, 31, 23, 59, 30, 123, 456);
        final dateTime = OffsetDateTime.from(
          instant,
          offset: const Duration(microseconds: 1),
        );

        final encoded = dateTime.toTimeZonedIso8601String();

        expect(encoded, '2024-01-01T00:00:30.123456+00:01');
        expect(DateTime.parse(encoded).isAtSameMomentAs(instant), isTrue);
      });

      test('rounds a negative sub-minute offset to UTC', () {
        final instant = DateTime.utc(2024, 1, 1, 0, 0, 0, 123, 456);
        final dateTime = OffsetDateTime.from(
          instant,
          offset: const Duration(microseconds: -1),
        );

        final encoded = dateTime.toTimeZonedIso8601String();

        expect(encoded, '2024-01-01T00:00:00.123456Z');
        expect(DateTime.parse(encoded).isAtSameMomentAs(instant), isTrue);
      });

      test('uses UTC when rounding would exceed the RFC 3339 offset range', () {
        final instant = DateTime.utc(2024, 1, 1, 0, 0, 0, 123, 456);
        final dateTime = OffsetDateTime.from(
          instant,
          offset: const Duration(hours: 23, minutes: 59, seconds: 1),
        );

        final encoded = dateTime.toTimeZonedIso8601String();

        expect(encoded, '2024-01-01T00:00:00.123456Z');
        expect(DateTime.parse(encoded).isAtSameMomentAs(instant), isTrue);
      });

      test('pads an offset datetime year and permits decoding it again', () {
        final dateTime = OffsetDateTime.parse('0099-01-01T12:00:00+02:00');

        final encoded = dateTime.toTimeZonedIso8601String();

        expect(encoded, '0099-01-01T12:00:00+02:00');
        expect(encoded.decodeSimpleDateTime().year, 99);
      });

      test('pads a local DateTime year and permits decoding it again', () {
        final dateTime = DateTime(500, 1, 1, 12);
        final encoded = dateTime.toTimeZonedIso8601String();

        expect(encoded.startsWith('0500-01-01T'), isTrue);
        expect(DateTime.parse(encoded).isAtSameMomentAs(dateTime), isTrue);
        expect(encoded.decodeSimpleDateTime().year, 500);
      });

      test('uses Dart year formatting with an offset', () {
        final negativeYear = OffsetDateTime.from(
          DateTime.utc(-5, 1, 1, 10),
          offset: const Duration(hours: 2),
        );
        final expandedNegativeYear = OffsetDateTime.from(
          DateTime.utc(-10000, 1, 1, 10),
          offset: const Duration(hours: 2),
        );
        final expandedYear = OffsetDateTime.from(
          DateTime.utc(10000, 1, 1, 10),
          offset: const Duration(hours: 2),
        );

        expect(
          negativeYear.toTimeZonedIso8601String(),
          '-0005-01-01T12:00:00+02:00',
        );
        expect(
          expandedNegativeYear.toTimeZonedIso8601String(),
          '-010000-01-01T12:00:00+02:00',
        );
        expect(
          expandedYear.toTimeZonedIso8601String(),
          '+010000-01-01T12:00:00+02:00',
        );
      });

      test('encodes in EST (UTC-5:00)', () {
        final estLocation = tz.getLocation('America/New_York');
        final estDateTime = tz.TZDateTime(
          estLocation,
          2023,
          12,
          25,
          15,
          30,
          45,
        );

        final result = estDateTime.toTimeZonedIso8601String();

        expect(result, '2023-12-25T15:30:45-05:00');
      });

      test('encodes in PST (UTC-8:00)', () {
        final pstLocation = tz.getLocation('America/Los_Angeles');
        final pstDateTime = tz.TZDateTime(
          pstLocation,
          2023,
          12,
          25,
          18,
          30,
          45,
        );

        final result = pstDateTime.toTimeZonedIso8601String();

        expect(result, '2023-12-25T18:30:45-08:00');
      });

      test('encodes in IST (UTC+5:30)', () {
        final istLocation = tz.getLocation('Asia/Kolkata');
        final istDateTime = tz.TZDateTime(istLocation, 2023, 12, 25, 20, 0, 45);

        final result = istDateTime.toTimeZonedIso8601String();

        expect(result, '2023-12-25T20:00:45+05:30');
      });

      test('encodes in CET (UTC+1:00)', () {
        final cetLocation = tz.getLocation('Europe/Paris');
        final cetDateTime = tz.TZDateTime(
          cetLocation,
          2023,
          12,
          25,
          16,
          30,
          45,
        );

        final result = cetDateTime.toTimeZonedIso8601String();

        expect(result, '2023-12-25T16:30:45+01:00');
      });

      test('encodes in GMT (UTC+0:00)', () {
        final gmtLocation = tz.getLocation('Europe/London');
        final gmtDateTime = tz.TZDateTime(
          gmtLocation,
          2023,
          12,
          25,
          15,
          30,
          45,
        );

        final result = gmtDateTime.toTimeZonedIso8601String();

        expect(result, '2023-12-25T15:30:45+00:00');
      });

      test('encodes with milliseconds in timezone', () {
        final estLocation = tz.getLocation('America/New_York');
        final estDateTime = tz.TZDateTime(
          estLocation,
          2023,
          12,
          25,
          15,
          30,
          45,
          123,
        );

        final result = estDateTime.toTimeZonedIso8601String();

        expect(result, '2023-12-25T15:30:45.123-05:00');
      });

      test('encodes with microseconds in timezone', () {
        final pstLocation = tz.getLocation('America/Los_Angeles');
        final pstDateTime = tz.TZDateTime(
          pstLocation,
          2023,
          12,
          25,
          18,
          30,
          45,
          123,
          456,
        );

        final result = pstDateTime.toTimeZonedIso8601String();

        expect(result, '2023-12-25T18:30:45.123456-08:00');
      });

      test('encodes with only microseconds (no milliseconds) in timezone', () {
        final estLocation = tz.getLocation('America/New_York');
        final estDateTime = tz.TZDateTime(
          estLocation,
          2023,
          1,
          1,
          12,
          0,
          0,
          0, // milliseconds = 0
          456, // microseconds = 456
        );

        final result = estDateTime.toTimeZonedIso8601String();

        // Must include decimal point before fractional digits
        expect(result, '2023-01-01T12:00:00.000456-05:00');
      });

      test('encodes in JST (UTC+9:00)', () {
        final jstLocation = tz.getLocation('Asia/Tokyo');
        final jstDateTime = tz.TZDateTime(jstLocation, 2009, 6, 30, 18, 30);

        final result = jstDateTime.toTimeZonedIso8601String();

        expect(result, '2009-06-30T18:30:00+09:00');
      });
    });
  });
}
