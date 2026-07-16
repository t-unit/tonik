import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('constructor', () {
    test('should create OffsetDateTime with explicit timezone name', () {
      final dateTime = DateTime(2023, 1, 15, 12, 30, 45);
      const offset = Duration(hours: 5, minutes: 30);
      const timeZoneName = 'Asia/Kolkata';
      final offsetDateTime = OffsetDateTime.from(
        dateTime,
        offset: offset,
        timeZoneName: timeZoneName,
      );
      expect(offsetDateTime.offset, offset);
      expect(offsetDateTime.timeZoneName, timeZoneName);
      expect(offsetDateTime.year, 2023);
      expect(offsetDateTime.month, 1);
      expect(offsetDateTime.day, 15);
      expect(offsetDateTime.hour, 12);
      expect(offsetDateTime.minute, 30);
      expect(offsetDateTime.second, 45);
    });

    test('should auto-generate timezone name when not provided', () {
      final dateTime = DateTime(2023, 1, 15, 12);
      const offset = Duration(hours: 5, minutes: 30);
      final offsetDateTime = OffsetDateTime.from(dateTime, offset: offset);
      expect(offsetDateTime.timeZoneName, 'UTC+05:30');
    });

    test('should use UTC for zero offset', () {
      final dateTime = DateTime.utc(2023, 1, 15, 12);
      final offsetDateTime = OffsetDateTime.from(
        dateTime,
        offset: Duration.zero,
      );
      expect(offsetDateTime.timeZoneName, 'UTC');
      expect(offsetDateTime.isUtc, isTrue);
    });

    test('should not use host DST rules when applying a fixed offset', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2025, 3, 29, 17),
        offset: const Duration(hours: -10),
      );

      expect(
        offsetDateTime.microsecondsSinceEpoch,
        DateTime.utc(2025, 3, 30, 3).microsecondsSinceEpoch,
      );
      expect(
        offsetDateTime.toTimeZonedIso8601String(),
        '2025-03-29T17:00:00-10:00',
      );
    });
  });

  group('timezone name generation', () {
    test('should generate UTC for zero offset', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12),
        offset: Duration.zero,
      );
      expect(offsetDateTime.timeZoneName, 'UTC');
    });

    test('should generate positive offset names', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 17),
        offset: const Duration(hours: 5, minutes: 30),
      );
      expect(offsetDateTime.timeZoneName, 'UTC+05:30');
    });

    test('should generate negative offset names', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 4),
        offset: const Duration(hours: -8),
      );
      expect(offsetDateTime.timeZoneName, 'UTC-08:00');
    });

    test('should generate names for unusual offsets', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 4),
        offset: const Duration(hours: 9, minutes: 45),
      );
      expect(offsetDateTime.timeZoneName, 'UTC+09:45');
    });

    test('should generate names for negative offsets with minutes', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 4),
        offset: const Duration(hours: -3, minutes: -30),
      );
      expect(offsetDateTime.timeZoneName, 'UTC-03:30');
    });

    test('should override auto-generated name when explicit name provided', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 17),
        offset: const Duration(hours: 5, minutes: 30),
        timeZoneName: 'Asia/Kolkata',
      );
      expect(offsetDateTime.timeZoneName, 'Asia/Kolkata');
    });
  });

  group('toLocal()', () {
    test('should convert to local system time', () {
      final utcTime = DateTime.utc(2023, 1, 15, 12);
      final offsetDateTime = OffsetDateTime.from(
        utcTime,
        offset: Duration.zero,
        timeZoneName: 'UTC',
      );
      final localDateTime = offsetDateTime.toLocal();
      expect(localDateTime.isUtc, isFalse);
      expect(
        localDateTime.microsecondsSinceEpoch,
        offsetDateTime.microsecondsSinceEpoch,
      );
    });

    test('should preserve exact moment in time when converting to local', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 17, 30, 45),
        offset: const Duration(hours: 2),
      );
      final localDateTime = offsetDateTime.toLocal();
      expect(localDateTime.isUtc, isFalse);
      expect(
        localDateTime.microsecondsSinceEpoch,
        offsetDateTime.microsecondsSinceEpoch,
      );
    });
  });

  group('toUtc()', () {
    test('should convert to UTC when offset is not zero', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 17, 30),
        offset: const Duration(hours: 5, minutes: 30),
      );
      final utcDateTime = offsetDateTime.toUtc();
      expect(utcDateTime.isUtc, isTrue);
      expect(utcDateTime.timeZoneName, 'UTC');
      expect(utcDateTime.offset, Duration.zero);
      expect(
        utcDateTime.microsecondsSinceEpoch,
        offsetDateTime.microsecondsSinceEpoch,
      );
    });

    test('should return same instance for UTC offset', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12),
        offset: Duration.zero,
      );
      final utcDateTime = offsetDateTime.toUtc();
      expect(identical(utcDateTime, offsetDateTime), isTrue);
    });
  });

  group('date and time components', () {
    test('should return correct local date components', () {
      // UTC midnight plus this offset lands at 05:30 local time.
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2023, 6, 15),
        offset: const Duration(hours: 5, minutes: 30),
      );
      expect(offsetDateTime.year, 2023);
      expect(offsetDateTime.month, 6);
      expect(offsetDateTime.day, 15);
      expect(offsetDateTime.hour, 5);
      expect(offsetDateTime.minute, 30);
      expect(offsetDateTime.second, 0);
      expect(offsetDateTime.millisecond, 0);
      expect(offsetDateTime.microsecond, 0);
    });

    test('should handle day boundary crossing', () {
      // UTC 23:00 plus this offset crosses into the next local day.
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2023, 6, 15, 23),
        offset: const Duration(hours: 2),
      );
      expect(offsetDateTime.year, 2023);
      expect(offsetDateTime.month, 6);
      expect(offsetDateTime.day, 16);
      expect(offsetDateTime.hour, 1);
    });

    test('should return correct weekday', () {
      // June 15, 2023 is a Thursday.
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 6, 15, 12),
        offset: const Duration(hours: 2),
      );
      expect(offsetDateTime.weekday, 4);
    });
  });

  group('epoch time methods', () {
    test('should return correct milliseconds since epoch', () {
      final baseDateTime = DateTime.utc(2023, 1, 1, 12);
      final offsetDateTime = OffsetDateTime.from(
        baseDateTime,
        offset: const Duration(hours: 5),
      );
      // The epoch time should match the input UTC time.
      expect(
        offsetDateTime.millisecondsSinceEpoch,
        baseDateTime.millisecondsSinceEpoch,
      );
    });

    test('should return correct microseconds since epoch', () {
      final baseDateTime = DateTime.utc(2023, 1, 1, 12);
      final offsetDateTime = OffsetDateTime.from(
        baseDateTime,
        offset: const Duration(hours: 5),
      );
      // The epoch time should match the input UTC time.
      expect(
        offsetDateTime.microsecondsSinceEpoch,
        baseDateTime.microsecondsSinceEpoch,
      );
    });
  });

  group('arithmetic operations', () {
    test('should add duration correctly', () {
      // Use UTC to avoid system timezone-dependent expectations.
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 7),
        offset: const Duration(hours: 5),
      );
      final result = offsetDateTime.add(const Duration(hours: 2));

      expect(result.hour, 14);
      expect(result.offset, offsetDateTime.offset);
      expect(result.timeZoneName, offsetDateTime.timeZoneName);
    });

    test('should subtract duration correctly', () {
      // Use UTC to avoid system timezone-dependent expectations.
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 7),
        offset: const Duration(hours: 5),
      );
      final result = offsetDateTime.subtract(const Duration(hours: 2));

      expect(result.hour, 10);
      expect(result.offset, offsetDateTime.offset);
      expect(result.timeZoneName, offsetDateTime.timeZoneName);
    });

    test('should calculate difference between OffsetDateTime instances', () {
      // Both inputs represent the same UTC moment.
      final offsetDateTime1 = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12),
        offset: Duration.zero,
      );
      final offsetDateTime2 = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12),
        offset: const Duration(hours: 5),
      );
      final difference = offsetDateTime2.difference(offsetDateTime1);
      expect(difference, Duration.zero);
    });

    test('should calculate difference with regular DateTime', () {
      // Both inputs represent the same UTC moment.
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12),
        offset: const Duration(hours: 5),
      );
      final regularDateTime = DateTime.utc(2023, 1, 15, 12);
      final difference = offsetDateTime.difference(regularDateTime);
      expect(difference, Duration.zero);
    });
  });

  group('comparison methods', () {
    late OffsetDateTime offsetDateTime1;
    late OffsetDateTime offsetDateTime2;
    late OffsetDateTime offsetDateTime3;

    setUp(() {
      // The first two values represent 2023-01-15 12:00 UTC.
      offsetDateTime1 = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12),
        offset: Duration.zero,
      );
      offsetDateTime2 = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12),
        offset: const Duration(hours: 5),
      );
      offsetDateTime3 = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 13),
        offset: Duration.zero,
      );
    });

    test('should correctly identify same moments', () {
      expect(offsetDateTime1.isAtSameMomentAs(offsetDateTime2), isTrue);
      expect(offsetDateTime1.isAtSameMomentAs(offsetDateTime3), isFalse);
    });

    test('should correctly compare before', () {
      expect(offsetDateTime1.isBefore(offsetDateTime3), isTrue);
      expect(offsetDateTime3.isBefore(offsetDateTime1), isFalse);
      expect(offsetDateTime1.isBefore(offsetDateTime2), isFalse);
    });

    test('should correctly compare after', () {
      expect(offsetDateTime3.isAfter(offsetDateTime1), isTrue);
      expect(offsetDateTime1.isAfter(offsetDateTime3), isFalse);
      expect(offsetDateTime1.isAfter(offsetDateTime2), isFalse);
    });

    test('should correctly compare with compareTo', () {
      expect(offsetDateTime1.compareTo(offsetDateTime2), 0);
      expect(offsetDateTime1.compareTo(offsetDateTime3), lessThan(0));
      expect(offsetDateTime3.compareTo(offsetDateTime1), greaterThan(0));
    });
  });

  group('equality and hashCode', () {
    test('should be equal when representing same UTC moment', () {
      // Both inputs represent the same UTC moment.
      final offsetDateTime1 = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12),
        offset: Duration.zero,
      );
      final offsetDateTime2 = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12),
        offset: const Duration(hours: 5),
      );
      expect(offsetDateTime1 == offsetDateTime2, isTrue);
      expect(offsetDateTime1.hashCode, offsetDateTime2.hashCode);
    });

    test('should not be equal when representing different UTC moments', () {
      final offsetDateTime1 = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12),
        offset: Duration.zero,
      );
      final offsetDateTime2 = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 13),
        offset: Duration.zero,
      );
      expect(offsetDateTime1 == offsetDateTime2, isFalse);
    });

    test('should be identical to itself', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12),
        offset: Duration.zero,
      );
      expect(offsetDateTime == offsetDateTime, isTrue);
      expect(identical(offsetDateTime, offsetDateTime), isTrue);
    });

    test('should be equal to regular DateTime at same moment '
        '(OffsetDateTime == DateTime)', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2021),
        offset: Duration.zero,
      );
      final regularDateTime = DateTime.utc(2021);

      expect(offsetDateTime == regularDateTime, isTrue);
    });

    test('should be equal to regular DateTime at same moment '
        '(DateTime == OffsetDateTime)', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2021),
        offset: Duration.zero,
      );
      final regularDateTime = DateTime.utc(2021);

      expect(regularDateTime == offsetDateTime, isTrue);
    });

    test('should have symmetric equality with regular DateTime', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2021),
        offset: Duration.zero,
      );
      final regularDateTime = DateTime.utc(2021);

      expect(
        offsetDateTime == regularDateTime,
        regularDateTime == offsetDateTime,
      );
    });

    test('should work correctly in DeepCollectionEquality '
        'for lists with DateTime', () {
      final offsetDateTimeList = [
        OffsetDateTime.parse('2021-01-01T00:00:00.000Z'),
        OffsetDateTime.parse('2021-01-02T00:00:00.000Z'),
      ];
      final regularDateTimeList = [
        DateTime.utc(2021),
        DateTime.utc(2021, 1, 2),
      ];

      const deepEquals = DeepCollectionEquality();
      expect(
        deepEquals.equals(offsetDateTimeList, regularDateTimeList),
        isTrue,
      );
      expect(
        deepEquals.equals(regularDateTimeList, offsetDateTimeList),
        isTrue,
      );
    });
  });

  group('timeZoneOffset property', () {
    test('should return the offset', () {
      const offset = Duration(hours: 5, minutes: 30);
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 12),
        offset: offset,
      );
      expect(offsetDateTime.timeZoneOffset, offset);
    });
  });

  group('string representation', () {
    test('should format UTC time with Z suffix', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2023, 1, 15, 12, 30, 45, 123),
        offset: Duration.zero,
      );
      final isoString = offsetDateTime.toIso8601String();
      final toString = offsetDateTime.toString();
      expect(isoString, '2023-01-15T12:30:45.123Z');
      expect(toString, '2023-01-15 12:30:45.123Z');
    });

    test('should format offset time with offset suffix', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 12, 30, 45, 123),
        offset: const Duration(hours: 5, minutes: 30),
      );
      final isoString = offsetDateTime.toIso8601String();
      final toString = offsetDateTime.toString();
      expect(isoString, '2023-01-15T12:30:45.123+05:30');
      expect(toString, '2023-01-15 12:30:45.123+05:30');
    });

    test('should format negative offset correctly', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 12, 30, 45, 123),
        offset: const Duration(hours: -8),
      );
      final isoString = offsetDateTime.toIso8601String();
      expect(isoString, '2023-01-15T12:30:45.123-08:00');
    });

    test('should handle microseconds in string representation', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 12, 30, 45, 123, 456),
        offset: const Duration(hours: 2),
      );
      final isoString = offsetDateTime.toIso8601String();
      expect(isoString, '2023-01-15T12:30:45.123456+02:00');
    });
  });

  group('edge cases', () {
    test('should handle maximum positive offset', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 12),
        offset: const Duration(hours: 14),
      );
      expect(offsetDateTime.timeZoneName, 'UTC+14:00');
    });

    test('should handle maximum negative offset', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 12),
        offset: const Duration(hours: -12),
      );
      expect(offsetDateTime.timeZoneName, 'UTC-12:00');
    });

    test('should handle leap year dates', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2024, 2, 29, 12), // Leap year
        offset: const Duration(hours: 3),
      );
      expect(offsetDateTime.year, 2024);
      expect(offsetDateTime.month, 2);
      expect(offsetDateTime.day, 29);
    });

    test('should handle year boundary crossing', () {
      // New Year's Eve UTC plus this offset lands on New Year's Day locally.
      final offsetDateTime = OffsetDateTime.from(
        DateTime.utc(2023, 12, 31, 23),
        offset: const Duration(hours: 2),
      );
      expect(offsetDateTime.year, 2024);
      expect(offsetDateTime.month, 1);
      expect(offsetDateTime.day, 1);
      expect(offsetDateTime.hour, 1);
    });

    test('should handle minute-level offsets', () {
      final offsetDateTime = OffsetDateTime.from(
        DateTime(2023, 1, 15, 12),
        offset: const Duration(minutes: 30),
      );
      expect(offsetDateTime.timeZoneName, 'UTC+00:30');
    });
  });

  group('OffsetDateTime.parse', () {
    group('UTC parsing', () {
      test('should parse UTC datetime with Z suffix', () {
        const input = '2023-12-25T15:30:45Z';
        final result = OffsetDateTime.parse(input);
        expect(result, isA<OffsetDateTime>());
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
        expect(result.timeZoneName, 'UTC');
      });

      test('should parse UTC datetime with milliseconds', () {
        const input = '2023-12-25T15:30:45.123Z';
        final result = OffsetDateTime.parse(input);
        expect(result, isA<OffsetDateTime>());
        expect(result.isUtc, isTrue);
        expect(result.year, 2023);
        expect(result.month, 12);
        expect(result.day, 25);
        expect(result.hour, 15);
        expect(result.minute, 30);
        expect(result.second, 45);
        expect(result.millisecond, 123);
        expect(result.microsecond, 0);
        expect(result.timeZoneName, 'UTC');
      });

      test('should parse compact basic form with lowercase t separator', () {
        final lower = OffsetDateTime.parse('20240115t103000Z');
        final upper = OffsetDateTime.parse('20240115T103000Z');

        expect(lower.isUtc, isTrue);
        expect(lower.isAtSameMomentAs(upper), isTrue);
        expect(lower.millisecondsSinceEpoch, upper.millisecondsSinceEpoch);
      });

      test('should accept lowercase t separator with fractional seconds', () {
        final lower = OffsetDateTime.parse('2024-01-15t10:30:00.123Z');
        final upper = OffsetDateTime.parse('2024-01-15T10:30:00.123Z');

        expect(lower.isUtc, isTrue);
        expect(lower.millisecond, 123);
        expect(lower.isAtSameMomentAs(upper), isTrue);
        expect(lower.millisecondsSinceEpoch, upper.millisecondsSinceEpoch);
      });

      test('should parse UTC datetime with microseconds', () {
        const input = '2023-12-25T15:30:45.123456Z';
        final result = OffsetDateTime.parse(input);
        expect(result, isA<OffsetDateTime>());
        expect(result.isUtc, isTrue);
        expect(result.year, 2023);
        expect(result.month, 12);
        expect(result.day, 25);
        expect(result.hour, 15);
        expect(result.minute, 30);
        expect(result.second, 45);
        expect(result.millisecond, 123);
        expect(result.microsecond, 456);
        expect(result.timeZoneName, 'UTC');
      });

      test('should accept lowercase t separator with Z suffix as UTC', () {
        final lower = OffsetDateTime.parse('2024-01-15t10:30:00Z');
        final upper = OffsetDateTime.parse('2024-01-15T10:30:00Z');

        expect(lower.isUtc, isTrue);
        expect(lower.isAtSameMomentAs(upper), isTrue);
        expect(lower.millisecondsSinceEpoch, upper.millisecondsSinceEpoch);
      });

      test('should accept lowercase t with lowercase z suffix as UTC', () {
        final lower = OffsetDateTime.parse('2024-01-15t10:30:00z');
        final upper = OffsetDateTime.parse('2024-01-15T10:30:00Z');

        expect(lower.isUtc, isTrue);
        expect(lower.timeZoneOffset, Duration.zero);
        expect(lower.isAtSameMomentAs(upper), isTrue);
        expect(lower.millisecondsSinceEpoch, upper.millisecondsSinceEpoch);
      });

      test('should accept uppercase T with lowercase z suffix as UTC', () {
        final result = OffsetDateTime.parse('2024-01-15T10:30:00z');
        final upper = OffsetDateTime.parse('2024-01-15T10:30:00Z');

        expect(result.isUtc, isTrue);
        expect(result.isAtSameMomentAs(upper), isTrue);
      });
    });

    group('local datetime parsing', () {
      test('should parse local datetime without timezone', () {
        const input = '2023-12-25T15:30:45';
        final result = OffsetDateTime.parse(input);

        expect(result, isA<OffsetDateTime>());
        expect(result.year, 2023);
        expect(result.month, 12);
        expect(result.day, 25);
        expect(result.hour, 15);
        expect(result.minute, 30);
        expect(result.second, 45);

        // Local datetimes inherit the system timezone offset.
        final expectedLocalTime = DateTime.parse(input);
        expect(result.timeZoneOffset, expectedLocalTime.timeZoneOffset);
      });

      test('should parse local datetime with space separator', () {
        const input = '2023-12-25 15:30:45';
        final result = OffsetDateTime.parse(input);

        expect(result, isA<OffsetDateTime>());
        expect(result.year, 2023);
        expect(result.month, 12);
        expect(result.day, 25);
        expect(result.hour, 15);
        expect(result.minute, 30);
        expect(result.second, 45);

        // Local datetimes inherit the system timezone offset.
        final expectedLocalTime = DateTime.parse(input);
        expect(result.timeZoneOffset, expectedLocalTime.timeZoneOffset);
      });

      test('should parse local datetime with milliseconds', () {
        const input = '2023-12-25T15:30:45.789';
        final result = OffsetDateTime.parse(input);

        expect(result, isA<OffsetDateTime>());
        expect(result.year, 2023);
        expect(result.month, 12);
        expect(result.day, 25);
        expect(result.hour, 15);
        expect(result.minute, 30);
        expect(result.second, 45);
        expect(result.millisecond, 789);

        // Local datetimes inherit the system timezone offset.
        final expectedLocalTime = DateTime.parse(input);
        expect(result.timeZoneOffset, expectedLocalTime.timeZoneOffset);
      });

      test('should accept lowercase t separator without timezone', () {
        final result = OffsetDateTime.parse('2024-01-15t10:30:00');
        final upper = OffsetDateTime.parse('2024-01-15T10:30:00');

        expect(result.year, 2024);
        expect(result.month, 1);
        expect(result.day, 15);
        expect(result.hour, 10);
        expect(result.minute, 30);
        expect(result.second, 0);

        final expectedLocalTime = DateTime.parse('2024-01-15T10:30:00');
        expect(result.timeZoneOffset, expectedLocalTime.timeZoneOffset);
        expect(result.isAtSameMomentAs(upper), isTrue);
      });
    });

    group('timezone offset parsing', () {
      test('should parse positive timezone offset with colon', () {
        const input = '2023-12-25T15:30:45+05:30';
        final result = OffsetDateTime.parse(input);
        expect(result, isA<OffsetDateTime>());
        expect(result.timeZoneName, 'UTC+05:30');
        expect(result.timeZoneOffset.inMinutes, 330); // 5.5 hours
        expect(result.year, 2023);
        expect(result.month, 12);
        expect(result.day, 25);
        expect(result.hour, 15);
        expect(result.minute, 30);
        expect(result.second, 45);
      });

      test('should parse negative timezone offset with colon', () {
        const input = '2023-12-25T15:30:45-03:15';
        final result = OffsetDateTime.parse(input);
        expect(result, isA<OffsetDateTime>());
        expect(result.timeZoneName, 'UTC-03:15');
        expect(result.timeZoneOffset.inMinutes, -195); // -3.25 hours
      });

      test('should parse timezone offset without colon', () {
        const input = '2023-12-25T15:30:45+0800';
        final result = OffsetDateTime.parse(input);
        expect(result, isA<OffsetDateTime>());
        expect(result.timeZoneName, 'UTC+08:00');
        expect(result.timeZoneOffset.inHours, 8);
      });

      test('should parse zero timezone offset', () {
        const input = '2023-12-25T15:30:45+00:00';
        final result = OffsetDateTime.parse(input);
        expect(result, isA<OffsetDateTime>());
        expect(result.timeZoneName, 'UTC');
        expect(result.timeZoneOffset.inMinutes, 0);
      });

      test('should parse datetime with offset and milliseconds', () {
        const input = '2023-12-25T15:30:45.123+02:00';
        final result = OffsetDateTime.parse(input);
        expect(result, isA<OffsetDateTime>());
        expect(result.timeZoneName, 'UTC+02:00');
        expect(result.timeZoneOffset.inHours, 2);
        expect(result.millisecond, 123);
      });

      test('should parse datetime with offset and microseconds', () {
        const input = '2023-12-25T15:30:45.123456-07:00';
        final result = OffsetDateTime.parse(input);
        expect(result, isA<OffsetDateTime>());
        expect(result.timeZoneName, 'UTC-07:00');
        expect(result.timeZoneOffset.inHours, -7);
        expect(result.millisecond, 123);
        expect(result.microsecond, 456);
      });

      test('should preserve the instant when crossing host DST', () {
        const input = '2025-03-29T17:00:00-10:00';
        final result = OffsetDateTime.parse(input);

        expect(
          result.microsecondsSinceEpoch,
          DateTime.utc(2025, 3, 30, 3).microsecondsSinceEpoch,
        );
        expect(result.timeZoneOffset, const Duration(hours: -10));
        expect(result.toTimeZonedIso8601String(), input);
      });

      test('should accept lowercase t separator with offset and colon', () {
        final lower = OffsetDateTime.parse('2024-01-15t10:30:00+05:30');
        final upper = OffsetDateTime.parse('2024-01-15T10:30:00+05:30');

        expect(lower.timeZoneName, 'UTC+05:30');
        expect(lower.timeZoneOffset.inMinutes, 330);
        expect(lower.hour, 10);
        expect(lower.minute, 30);
        expect(lower.isAtSameMomentAs(upper), isTrue);
        expect(lower.millisecondsSinceEpoch, upper.millisecondsSinceEpoch);
      });

      test('should accept lowercase t separator with offset without colon', () {
        final lower = OffsetDateTime.parse('2024-01-15t10:30:00+0530');
        final upper = OffsetDateTime.parse('2024-01-15T10:30:00+0530');

        expect(lower.timeZoneName, 'UTC+05:30');
        expect(lower.timeZoneOffset.inMinutes, 330);
        expect(lower.hour, 10);
        expect(lower.minute, 30);
        expect(lower.isAtSameMomentAs(upper), isTrue);
        expect(lower.millisecondsSinceEpoch, upper.millisecondsSinceEpoch);
      });
    });

    group('error handling', () {
      test('should throw InvalidFormatException for empty string', () {
        expect(
          () => OffsetDateTime.parse(''),
          throwsA(isA<InvalidFormatException>()),
        );
      });

      test('should throw InvalidFormatException for invalid format', () {
        expect(
          () => OffsetDateTime.parse('not-a-date'),
          throwsA(isA<InvalidFormatException>()),
        );
      });

      test(
        'should throw InvalidFormatException for invalid timezone offset',
        () {
          expect(
            () => OffsetDateTime.parse('2023-12-25T15:30:45+25:00'),
            // Invalid hour.
            throwsA(isA<InvalidFormatException>()),
          );
        },
      );

      test(
        'should throw InvalidFormatException for invalid timezone format',
        () {
          expect(
            () => OffsetDateTime.parse('2023-12-25T15:30:45+5:30'),
            // Missing leading zero.
            throwsA(isA<InvalidFormatException>()),
          );
        },
      );

      test('should throw InvalidFormatException for invalid minutes', () {
        expect(
          () => OffsetDateTime.parse('2023-12-25T15:30:45+05:60'),
          // Invalid minutes.
          throwsA(isA<InvalidFormatException>()),
        );
      });

      test('should throw InvalidFormatException for malformed datetime '
          'with valid timezone offset', () {
        expect(
          () => OffsetDateTime.parse('garbage+05:30'),
          throwsA(isA<InvalidFormatException>()),
        );
      });

      test('should throw InvalidFormatException for malformed time part '
          'with compact timezone offset', () {
        expect(
          () => OffsetDateTime.parse('2024-01-15txx:30:00+0530'),
          throwsA(isA<InvalidFormatException>()),
        );
      });

      test('should report the original input for malformed input '
          'containing a space', () {
        expect(
          () => OffsetDateTime.parse('not a date'),
          throwsA(
            isA<InvalidFormatException>().having(
              (e) => e.value,
              'value',
              'not a date',
            ),
          ),
        );
      });

      test('should report the original input for malformed input '
          'containing a digit-flanked lowercase t', () {
        expect(
          () => OffsetDateTime.parse('12t34'),
          throwsA(
            isA<InvalidFormatException>().having(
              (e) => e.value,
              'value',
              '12t34',
            ),
          ),
        );
      });

      test('should report the original input for malformed input '
          'with a valid timezone offset', () {
        expect(
          () => OffsetDateTime.parse('not a date+05:30'),
          throwsA(
            isA<InvalidFormatException>().having(
              (e) => e.value,
              'value',
              'not a date+05:30',
            ),
          ),
        );
      });
    });
  });

  group('OffsetDateTime.parse local timezone behavior', () {
    test('should preserve local timezone for strings '
        'without timezone info', () {
      const localString = '2024-03-14T10:30:45';
      final result = OffsetDateTime.parse(localString);

      final expectedDateTime = DateTime.parse(localString);

      expect(result.year, 2024);
      expect(result.month, 3);
      expect(result.day, 14);
      expect(result.hour, 10);
      expect(result.minute, 30);
      expect(result.second, 45);

      expect(result.timeZoneOffset, expectedDateTime.timeZoneOffset);
    });

    test('should handle local timezone vs UTC timezone correctly', () {
      const timeString = '2024-03-14T10:30:45';

      final localResult = OffsetDateTime.parse(timeString);
      final utcResult = OffsetDateTime.parse('${timeString}Z');

      expect(utcResult.timeZoneOffset, Duration.zero);
      expect(utcResult.timeZoneName, 'UTC');

      final expectedLocalTime = DateTime.parse(timeString);
      expect(localResult.timeZoneOffset, expectedLocalTime.timeZoneOffset);

      expect(localResult.hour, 10);
      expect(localResult.minute, 30);
      expect(utcResult.hour, 10);
      expect(utcResult.minute, 30);
    });

    test('should preserve local time values correctly', () {
      const localString = '2024-03-14T15:30:45';
      final result = OffsetDateTime.parse(localString);

      expect(result.hour, 15);
      expect(result.minute, 30);
      expect(result.second, 45);

      final expectedLocalTime = DateTime.parse(localString);
      expect(result.timeZoneOffset, expectedLocalTime.timeZoneOffset);
    });
  });
}
