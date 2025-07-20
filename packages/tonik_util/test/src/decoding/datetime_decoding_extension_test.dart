import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:tonik_util/src/decoding/datetime_decoding_extension.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  group('DateTimeParsingExtension', () {
    group('parseWithTimeZone', () {
      group('UTC parsing', () {
        test('parses UTC datetime with Z suffix', () {
          const input = '2023-12-25T15:30:45Z';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.isUtc, isTrue);
          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset, Duration.zero);
        });

        test('parses UTC datetime with milliseconds', () {
          const input = '2023-12-25T15:30:45.123Z';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.isUtc, isTrue);
          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 123);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset, Duration.zero);
        });

        test('parses UTC datetime with microseconds', () {
          const input = '2023-12-25T15:30:45.123456Z';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.isUtc, isTrue);
          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 123);
          expect(result.microsecond, 456);
          expect(result.timeZoneOffset, Duration.zero);
        });

        test('parses UTC datetime at midnight', () {
          const input = '2023-12-25T00:00:00Z';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.isUtc, isTrue);
          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 0);
          expect(result.minute, 0);
          expect(result.second, 0);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset, Duration.zero);
        });

        test('parses UTC datetime at end of day', () {
          const input = '2023-12-25T23:59:59Z';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.isUtc, isTrue);
          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 23);
          expect(result.minute, 59);
          expect(result.second, 59);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset, Duration.zero);
        });
      });

      group('local time parsing (no timezone info)', () {
        test('parses datetime without timezone as local time', () {
          const input = '2023-12-25T15:30:45';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);
          final expected = DateTime(2023, 12, 25, 15, 30, 45);

          expect(result.isUtc, isFalse);
          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset, expected.timeZoneOffset);
        });

        test('parses datetime with milliseconds as local time', () {
          const input = '2023-12-25T15:30:45.123';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);
          final expected = DateTime(2023, 12, 25, 15, 30, 45, 123);

          expect(result.isUtc, isFalse);
          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 123);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset, expected.timeZoneOffset);
        });

        test('parses datetime with microseconds as local time', () {
          const input = '2023-12-25T15:30:45.123456';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);
          final expected = DateTime(2023, 12, 25, 15, 30, 45, 123, 456);

          expect(result.isUtc, isFalse);
          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 123);
          expect(result.microsecond, 456);
          expect(result.timeZoneOffset, expected.timeZoneOffset);
        });

        test('parses date-only format as local midnight', () {
          const input = '2023-12-25';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);
          final expected = DateTime(2023, 12, 25);

          expect(result.isUtc, isFalse);
          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 0);
          expect(result.minute, 0);
          expect(result.second, 0);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset, expected.timeZoneOffset);
        });
      });

      group('timezone offset parsing', () {
        test('parses positive timezone offset (+05:00)', () {
          const input = '2023-12-25T15:30:45+05:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset.inHours, 5);
        });

        test('parses negative timezone offset (-08:00)', () {
          const input = '2023-12-25T15:30:45-08:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset.inHours, -8);
        });

        test('parses timezone offset with 30-minute offset (+05:30)', () {
          const input = '2023-12-25T15:30:45+05:30';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset.inMinutes, 330); // 5.5 hours
        });

        test('parses timezone offset with 45-minute offset (+05:45)', () {
          const input = '2023-12-25T15:30:45+05:45';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset.inMinutes, 345); // 5.75 hours
        });

        test('parses timezone offset with milliseconds', () {
          const input = '2023-12-25T15:30:45.123+05:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 123);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset.inHours, 5);
        });

        test('parses timezone offset with microseconds', () {
          const input = '2023-12-25T15:30:45.123456+05:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 123);
          expect(result.microsecond, 456);
          expect(result.timeZoneOffset.inHours, 5);
        });

        test('parses compact timezone offset format (+0500)', () {
          const input = '2023-12-25T15:30:45+0500';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset.inHours, 5);
        });

        test('parses compact negative timezone offset format (-0800)', () {
          const input = '2023-12-25T15:30:45-0800';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset.inHours, -8);
        });
      });

      group('timezone location matching', () {
        test('maps common European timezone offset to CET', () {
          const input = '2023-12-25T15:30:45+01:00'; // CET (winter time)
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.timeZoneName, 'CET');
          expect(result.timeZoneOffset.inHours, 1);
        });

        test('maps summer time European offset to CEST', () {
          const input = '2023-07-25T15:30:45+02:00'; // CEST (summer time)
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.timeZoneName, 'CEST');
          expect(result.timeZoneOffset.inHours, 2);
        });

        test('maps US Eastern timezone offset to EST', () {
          const input = '2023-12-25T15:30:45-05:00'; // EST (winter time)
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.timeZoneName, 'EST');
          expect(result.timeZoneOffset.inHours, -5);
        });

        test('maps US Eastern summer time offset to EDT', () {
          const input = '2023-07-25T15:30:45-04:00'; // EDT (summer time)
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.timeZoneName, 'EDT');
          expect(result.timeZoneOffset.inHours, -4);
        });

        test('maps India Standard Time offset to IST', () {
          const input = '2023-12-25T15:30:45+05:30';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);
          expect(result.timeZoneName, 'IST');
          expect(result.timeZoneOffset.inMinutes, 330); // 5.5 hours
        });

        test('maps Japan Standard Time offset to JST', () {
          const input = '2023-12-25T15:30:45+09:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.timeZoneName, 'JST');
          expect(result.timeZoneOffset.inHours, 9);
        });

        test(
          'handles unusual timezone offset by falling back to UTC',
          () {
            const input = '2023-12-25T15:30:45+03:17'; // Unusual offset
            final result = DateTimeParsingExtension.parseWithTimeZone(input);

            // For unusual offsets, falls back to UTC due to 
            // timezone package limitations
            expect(result.timeZoneOffset.inMinutes, 0); // UTC
            expect(result.timeZoneName, 'UTC');
            
            // But the parsed time should still be correctly converted
            // Original: 15:30:45+03:17 should convert to UTC time
            expect(result.year, 2023);
            expect(result.month, 12);
            expect(result.day, 25);
            expect(result.hour, 12); // 15:30 - 3:17 = 12:13
            expect(result.minute, 13);
            expect(result.second, 45);
          },
        );
      });

      group('edge cases', () {
        test('parses leap year date (UTC)', () {
          const input = '2024-02-29T12:00:00Z';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2024);
          expect(result.month, 2);
          expect(result.day, 29);
        });

        test('parses leap year date (local)', () {
          const input = '2024-02-29T12:00:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2024);
          expect(result.month, 2);
          expect(result.day, 29);
        });

        test('parses leap year date (timezone offset)', () {
          const input = '2024-02-29T12:00:00+03:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2024);
          expect(result.month, 2);
          expect(result.day, 29);
        });

        test('parses year boundaries correctly (UTC)', () {
          const input = '2023-12-31T23:59:59Z';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 31);
        });

        test('parses year boundaries correctly (local)', () {
          const input = '2023-12-31T23:59:59';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 31);
        });

        test('parses year boundaries correctly (timezone offset)', () {
          const input = '2023-12-31T23:59:59-05:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 31);
        });

        test('parses new year correctly (UTC)', () {
          const input = '2024-01-01T00:00:00Z';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2024);
          expect(result.month, 1);
          expect(result.day, 1);
        });

        test('parses new year correctly (local)', () {
          const input = '2024-01-01T00:00:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2024);
          expect(result.month, 1);
          expect(result.day, 1);
        });

        test('parses new year correctly (timezone offset)', () {
          const input = '2024-01-01T00:00:00+09:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2024);
          expect(result.month, 1);
          expect(result.day, 1);
        });

        test('handles single digit milliseconds (UTC)', () {
          const input = '2023-12-25T15:30:45.1Z';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.millisecond, 100);
        });

        test('handles single digit milliseconds (local)', () {
          const input = '2023-12-25T15:30:45.1';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.millisecond, 100);
        });

        test('handles single digit milliseconds (timezone offset)', () {
          const input = '2023-12-25T15:30:45.1+02:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.millisecond, 100);
        });

        test('handles two digit milliseconds (UTC)', () {
          const input = '2023-12-25T15:30:45.12Z';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.millisecond, 120);
        });

        test('handles two digit milliseconds (local)', () {
          const input = '2023-12-25T15:30:45.12';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.millisecond, 120);
        });

        test('handles two digit milliseconds (timezone offset)', () {
          const input = '2023-12-25T15:30:45.12-07:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.millisecond, 120);
        });
      });

      group('error handling', () {
        test('throws InvalidFormatException for invalid format', () {
          const input = 'invalid-date-format';
          expect(
            () => DateTimeParsingExtension.parseWithTimeZone(input),
            throwsA(isA<InvalidFormatException>()),
          );
        });

        test('throws InvalidFormatException for incomplete date', () {
          const input = '2023-12';
          expect(
            () => DateTimeParsingExtension.parseWithTimeZone(input),
            throwsA(isA<InvalidFormatException>()),
          );
        });
      });

      group('RFC3339 compliance', () {
        test('parses full RFC3339 format with T separator', () {
          const input = '2023-12-25T15:30:45.123456+05:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 123);
          expect(result.microsecond, 456);
          expect(result.timeZoneOffset.inHours, 5);
        });

        test('parses RFC3339 format with space separator', () {
          const input = '2023-12-25 15:30:45.123+05:00';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 123);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset.inHours, 5);
        });

        test('parses minimum required RFC3339 format', () {
          const input = '2023-12-25T15:30:45Z';
          final result = DateTimeParsingExtension.parseWithTimeZone(input);

          expect(result.isUtc, isTrue);
          expect(result.year, 2023);
          expect(result.month, 12);
          expect(result.day, 25);
          expect(result.hour, 15);
          expect(result.minute, 30);
          expect(result.second, 45);
          expect(result.millisecond, 0);
          expect(result.microsecond, 0);
          expect(result.timeZoneOffset, Duration.zero);
        });
      });
    });
  });
}
