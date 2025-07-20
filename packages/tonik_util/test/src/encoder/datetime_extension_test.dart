import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:tonik_util/src/encoding/datetime_extension.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  group('DateTimeEncodingExtension', () {
    group('toTimeZonedIso8601String', () {
      test('encodes UTC DateTime correctly', () {
        final utcDateTime = DateTime.utc(2023, 12, 25, 15, 30, 45, 123);
        final result = utcDateTime.toTimeZonedIso8601String();
        
        // Should match toIso8601String for UTC dates
        expect(result, utcDateTime.toIso8601String());
        expect(result, '2023-12-25T15:30:45.123Z');
      });
    });

    group('timezone handling', () {
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
        
        // Should include EST timezone offset (-05:00)
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
        
        // Should include PST timezone offset (-08:00)
        expect(result, '2023-12-25T18:30:45-08:00');
      });

      test('encodes in IST (UTC+5:30)', () {
        final istLocation = tz.getLocation('Asia/Kolkata');
        final istDateTime = tz.TZDateTime(
          istLocation, 
          2023, 
          12, 
          25, 
          20, 
          0, 
          45,
        );
        
        final result = istDateTime.toTimeZonedIso8601String();
        
        // Should include IST timezone offset (+05:30)
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
        
        // Should include CET timezone offset (+01:00)
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
        
        // Should include GMT timezone offset (+00:00)
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
        
        // Should include EST timezone offset (-05:00) and milliseconds
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
        
        // Should include PST timezone offset (-08:00) and microseconds
        expect(result, '2023-12-25T18:30:45.123456-08:00');
      });

      test('encodes in JST (UTC+9:00)', () {
        final jstLocation = tz.getLocation('Asia/Tokyo');
        final jstDateTime = tz.TZDateTime(jstLocation, 2009, 6, 30, 18, 30);
        
        final result = jstDateTime.toTimeZonedIso8601String();
        
        // Should include JST timezone offset (+09:00)
        expect(result, '2009-06-30T18:30:00+09:00');
      });
    });
  });
} 
