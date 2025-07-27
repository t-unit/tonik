import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('OffsetDateTime', () {
    group('constructor', () {
      test('should create OffsetDateTime with explicit timezone name', () {
        // Arrange
        final dateTime = DateTime(2023, 1, 15, 12, 30, 45);
        const offset = Duration(hours: 5, minutes: 30);
        const timeZoneName = 'Asia/Kolkata';

        // Act
        final offsetDateTime = OffsetDateTime.from(
          dateTime,
          offset: offset,
          timeZoneName: timeZoneName,
        );

        // Assert
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
        // Arrange
        final dateTime = DateTime(2023, 1, 15, 12);
        const offset = Duration(hours: 5, minutes: 30);

        // Act
        final offsetDateTime = OffsetDateTime.from(
          dateTime,
          offset: offset,
        );

        // Assert
        expect(offsetDateTime.timeZoneName, 'UTC+05:30');
      });

      test('should use UTC for zero offset', () {
        // Arrange
        final dateTime = DateTime.utc(2023, 1, 15, 12);

        // Act
        final offsetDateTime = OffsetDateTime.from(
          dateTime,
          offset: Duration.zero,
        );

        // Assert
        expect(offsetDateTime.timeZoneName, 'UTC');
        expect(offsetDateTime.isUtc, isTrue);
      });
    });

    group('timezone name generation', () {
      test('should generate UTC for zero offset', () {
        // Arrange & Act
        final offsetDateTime = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12),
          offset: Duration.zero,
        );

        // Assert
        expect(offsetDateTime.timeZoneName, 'UTC');
      });

      test('should generate positive offset names', () {
        // Arrange & Act
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 17),
          offset: const Duration(hours: 5, minutes: 30),
        );

        // Assert
        expect(offsetDateTime.timeZoneName, 'UTC+05:30');
      });

      test('should generate negative offset names', () {
        // Arrange & Act
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 4),
          offset: const Duration(hours: -8),
        );

        // Assert
        expect(offsetDateTime.timeZoneName, 'UTC-08:00');
      });

      test('should generate names for unusual offsets', () {
        // Arrange & Act
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 4),
          offset: const Duration(hours: 9, minutes: 45),
        );

        // Assert
        expect(offsetDateTime.timeZoneName, 'UTC+09:45');
      });

      test('should generate names for negative offsets with minutes', () {
        // Arrange & Act
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 4),
          offset: const Duration(hours: -3, minutes: -30),
        );

        // Assert
        expect(offsetDateTime.timeZoneName, 'UTC-03:30');
      });

      test(
        'should override auto-generated name when explicit name provided',
        () {
          // Arrange & Act
          final offsetDateTime = OffsetDateTime.from(
            DateTime(2023, 1, 15, 17),
            offset: const Duration(hours: 5, minutes: 30),
            timeZoneName: 'Asia/Kolkata',
          );

          // Assert
          expect(offsetDateTime.timeZoneName, 'Asia/Kolkata');
        },
      );
    });

    group('toLocal()', () {
      test('should convert to local system time', () {
        // Arrange
        final utcTime = DateTime.utc(2023, 1, 15, 12);
        final offsetDateTime = OffsetDateTime.from(
          utcTime,
          offset: Duration.zero,
          timeZoneName: 'UTC',
        );

        // Act
        final localDateTime = offsetDateTime.toLocal();

        // Assert
        expect(localDateTime.isUtc, isFalse);
        expect(
          localDateTime.microsecondsSinceEpoch,
          offsetDateTime.microsecondsSinceEpoch,
        );
      });

      test('should preserve exact moment in time when converting to local', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 17, 30, 45),
          offset: const Duration(hours: 2),
        );

        // Act
        final localDateTime = offsetDateTime.toLocal();

        // Assert
        expect(localDateTime.isUtc, isFalse);
        expect(
          localDateTime.microsecondsSinceEpoch,
          offsetDateTime.microsecondsSinceEpoch,
        );
      });
    });

    group('toUtc()', () {
      test('should convert to UTC when offset is not zero', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 17, 30),
          offset: const Duration(hours: 5, minutes: 30),
        );

        // Act
        final utcDateTime = offsetDateTime.toUtc();

        // Assert
        expect(utcDateTime.isUtc, isTrue);
        expect(utcDateTime.timeZoneName, 'UTC');
        expect(utcDateTime.offset, Duration.zero);
        expect(
          utcDateTime.microsecondsSinceEpoch,
          offsetDateTime.microsecondsSinceEpoch,
        );
      });

      test('should return same instance for UTC offset', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12),
          offset: Duration.zero,
        );

        // Act
        final utcDateTime = offsetDateTime.toUtc();

        // Assert
        expect(identical(utcDateTime, offsetDateTime), isTrue);
      });
    });

    group('date and time components', () {
      test('should return correct local date components', () {
        // Arrange: UTC midnight + 5:30 offset = 5:30 AM local
        final offsetDateTime = OffsetDateTime.from(
          DateTime.utc(2023, 6, 15),
          offset: const Duration(hours: 5, minutes: 30),
        );

        // Act & Assert
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
        // Arrange: UTC 23:00 + 2 hours = 01:00 next day local
        final offsetDateTime = OffsetDateTime.from(
          DateTime.utc(2023, 6, 15, 23),
          offset: const Duration(hours: 2),
        );

        // Act & Assert
        expect(offsetDateTime.year, 2023);
        expect(offsetDateTime.month, 6);
        expect(offsetDateTime.day, 16); // Next day
        expect(offsetDateTime.hour, 1);
      });

      test('should return correct weekday', () {
        // Arrange: June 15, 2023 is a Thursday (weekday 4)
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 6, 15, 12),
          offset: const Duration(hours: 2),
        );

        // Act & Assert
        expect(offsetDateTime.weekday, 4); // Thursday
      });
    });

    group('epoch time methods', () {
      test('should return correct milliseconds since epoch', () {
        // Arrange
        final baseDateTime = DateTime.utc(2023, 1, 1, 12);
        final offsetDateTime = OffsetDateTime.from(
          baseDateTime,
          offset: const Duration(hours: 5),
        );

        // Act & Assert
        // The epoch time should match the input UTC time
        expect(
          offsetDateTime.millisecondsSinceEpoch,
          baseDateTime.millisecondsSinceEpoch,
        );
      });

      test('should return correct microseconds since epoch', () {
        // Arrange
        final baseDateTime = DateTime.utc(2023, 1, 1, 12);
        final offsetDateTime = OffsetDateTime.from(
          baseDateTime,
          offset: const Duration(hours: 5),
        );

        // Act & Assert
        // The epoch time should match the input UTC time
        expect(
          offsetDateTime.microsecondsSinceEpoch,
          baseDateTime.microsecondsSinceEpoch,
        );
      });
    });

    group('arithmetic operations', () {
      test('should add duration correctly', () {
        // Arrange: Create from UTC to avoid system timezone issues
        final offsetDateTime = OffsetDateTime.from(
          DateTime.utc(
            2023,
            1,
            15,
            7,
          ), // UTC 07:00 + 5 hour offset = 12:00 local
          offset: const Duration(hours: 5),
        );

        // Act
        final result = offsetDateTime.add(const Duration(hours: 2));

        // Assert: Local time should be 12:00 + 2 = 14:00
        expect(result.hour, 14);
        expect(result.offset, offsetDateTime.offset);
        expect(result.timeZoneName, offsetDateTime.timeZoneName);
      });

      test('should subtract duration correctly', () {
        // Arrange: Create from UTC to avoid system timezone issues
        final offsetDateTime = OffsetDateTime.from(
          DateTime.utc(
            2023,
            1,
            15,
            7,
          ), // UTC 07:00 + 5 hour offset = 12:00 local
          offset: const Duration(hours: 5),
        );

        // Act
        final result = offsetDateTime.subtract(const Duration(hours: 2));

        // Assert: Local time should be 12:00 - 2 = 10:00
        expect(result.hour, 10);
        expect(result.offset, offsetDateTime.offset);
        expect(result.timeZoneName, offsetDateTime.timeZoneName);
      });

      test('should calculate difference between OffsetDateTime instances', () {
        // Arrange: Both should represent the same UTC moment
        final offsetDateTime1 = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12), // UTC 12:00
          offset: Duration.zero,
        );
        final offsetDateTime2 = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12), // Same UTC 12:00
          offset: const Duration(hours: 5),
        );

        // Act
        final difference = offsetDateTime2.difference(offsetDateTime1);

        // Assert
        expect(difference, Duration.zero); // Same UTC time
      });

      test('should calculate difference with regular DateTime', () {
        // Arrange: Both should represent the same UTC moment
        final offsetDateTime = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12), // UTC 12:00
          offset: const Duration(hours: 5),
        );
        final regularDateTime = DateTime.utc(2023, 1, 15, 12);

        // Act
        final difference = offsetDateTime.difference(regularDateTime);

        // Assert
        expect(difference, Duration.zero); // Same UTC time
      });
    });

    group('comparison methods', () {
      late OffsetDateTime offsetDateTime1;
      late OffsetDateTime offsetDateTime2;
      late OffsetDateTime offsetDateTime3;

      setUp(() {
        // All represent the same UTC moment: 2023-01-15 12:00 UTC
        offsetDateTime1 = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12),
          offset: Duration.zero,
        );
        // Create from a local time: if offset is +5,
        // then local 17:00 should equal UTC 12:00
        // But to avoid system timezone issues, we'll create directly from UTC
        offsetDateTime2 = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12), // Same UTC base
          offset: const Duration(hours: 5),
        );
        // Different UTC moment: one hour later
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
        // Arrange: Both should represent the same UTC moment
        final offsetDateTime1 = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12),
          offset: Duration.zero,
        );
        final offsetDateTime2 = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12), // Same UTC moment
          offset: const Duration(hours: 5),
        );

        // Act & Assert
        expect(offsetDateTime1 == offsetDateTime2, isTrue);
        expect(offsetDateTime1.hashCode, offsetDateTime2.hashCode);
      });

      test('should not be equal when representing different UTC moments', () {
        // Arrange
        final offsetDateTime1 = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12),
          offset: Duration.zero,
        );
        final offsetDateTime2 = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 13),
          offset: Duration.zero,
        );

        // Act & Assert
        expect(offsetDateTime1 == offsetDateTime2, isFalse);
      });

      test('should be identical to itself', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12),
          offset: Duration.zero,
        );

        // Act & Assert
        expect(offsetDateTime == offsetDateTime, isTrue);
        expect(identical(offsetDateTime, offsetDateTime), isTrue);
      });
    });

    group('timeZoneOffset property', () {
      test('should return the offset', () {
        // Arrange
        const offset = Duration(hours: 5, minutes: 30);
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 12),
          offset: offset,
        );

        // Act & Assert
        expect(offsetDateTime.timeZoneOffset, offset);
      });
    });

    group('string representation', () {
      test('should format UTC time with Z suffix', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime.utc(2023, 1, 15, 12, 30, 45, 123),
          offset: Duration.zero,
        );

        // Act
        final isoString = offsetDateTime.toIso8601String();
        final toString = offsetDateTime.toString();

        // Assert
        expect(isoString, '2023-01-15T12:30:45.123Z');
        expect(toString, '2023-01-15 12:30:45.123Z');
      });

      test('should format offset time with offset suffix', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 12, 30, 45, 123),
          offset: const Duration(hours: 5, minutes: 30),
        );

        // Act
        final isoString = offsetDateTime.toIso8601String();
        final toString = offsetDateTime.toString();

        // Assert
        expect(isoString, '2023-01-15T12:30:45.123+0530');
        expect(toString, '2023-01-15 12:30:45.123+0530');
      });

      test('should format negative offset correctly', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 12, 30, 45, 123),
          offset: const Duration(hours: -8),
        );

        // Act
        final isoString = offsetDateTime.toIso8601String();

        // Assert
        expect(isoString, '2023-01-15T12:30:45.123-0800');
      });

      test('should handle microseconds in string representation', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 12, 30, 45, 123, 456),
          offset: const Duration(hours: 2),
        );

        // Act
        final isoString = offsetDateTime.toIso8601String();

        // Assert
        expect(isoString, '2023-01-15T12:30:45.123456+0200');
      });
    });

    group('edge cases', () {
      test('should handle maximum positive offset', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 12),
          offset: const Duration(hours: 14),
        );

        // Act & Assert
        expect(offsetDateTime.timeZoneName, 'UTC+14:00');
      });

      test('should handle maximum negative offset', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 12),
          offset: const Duration(hours: -12),
        );

        // Act & Assert
        expect(offsetDateTime.timeZoneName, 'UTC-12:00');
      });

      test('should handle leap year dates', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2024, 2, 29, 12), // Leap year
          offset: const Duration(hours: 3),
        );

        // Act & Assert
        expect(offsetDateTime.year, 2024);
        expect(offsetDateTime.month, 2);
        expect(offsetDateTime.day, 29);
      });

      test('should handle year boundary crossing', () {
        // Arrange: New Year's Eve UTC + positive offset = New Year's Day local
        final offsetDateTime = OffsetDateTime.from(
          DateTime.utc(2023, 12, 31, 23),
          offset: const Duration(hours: 2),
        );

        // Act & Assert
        expect(offsetDateTime.year, 2024);
        expect(offsetDateTime.month, 1);
        expect(offsetDateTime.day, 1);
        expect(offsetDateTime.hour, 1);
      });

      test('should handle minute-level offsets', () {
        // Arrange
        final offsetDateTime = OffsetDateTime.from(
          DateTime(2023, 1, 15, 12),
          offset: const Duration(minutes: 30),
        );

        // Act & Assert
        expect(offsetDateTime.timeZoneName, 'UTC+00:30');
      });
    });
  });

  group('OffsetDateTime.parse', () {
    group('UTC parsing', () {
      test('should parse UTC datetime with Z suffix', () {
        // Arrange & Act
        const input = '2023-12-25T15:30:45Z';
        final result = OffsetDateTime.parse(input);

        // Assert
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
        // Arrange & Act
        const input = '2023-12-25T15:30:45.123Z';
        final result = OffsetDateTime.parse(input);

        // Assert
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

      test('should parse UTC datetime with microseconds', () {
        // Arrange & Act
        const input = '2023-12-25T15:30:45.123456Z';
        final result = OffsetDateTime.parse(input);

        // Assert
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

        // Should match system timezone, not be treated as UTC
        final expectedLocalTime = DateTime.parse(input);
        expect(result.isUtc, expectedLocalTime.isUtc);
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

        // Should match system timezone for space-separated format
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

        // Should match system timezone for milliseconds format
        final expectedLocalTime = DateTime.parse(input);
        expect(result.timeZoneOffset, expectedLocalTime.timeZoneOffset);
      });
    });

    group('timezone offset parsing', () {
      test('should parse positive timezone offset with colon', () {
        // Arrange & Act
        const input = '2023-12-25T15:30:45+05:30';
        final result = OffsetDateTime.parse(input);

        // Assert
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
        // Arrange & Act
        const input = '2023-12-25T15:30:45-03:15';
        final result = OffsetDateTime.parse(input);

        // Assert
        expect(result, isA<OffsetDateTime>());
        expect(result.timeZoneName, 'UTC-03:15');
        expect(result.timeZoneOffset.inMinutes, -195); // -3.25 hours
      });

      test('should parse timezone offset without colon', () {
        // Arrange & Act
        const input = '2023-12-25T15:30:45+0800';
        final result = OffsetDateTime.parse(input);

        // Assert
        expect(result, isA<OffsetDateTime>());
        expect(result.timeZoneName, 'UTC+08:00');
        expect(result.timeZoneOffset.inHours, 8);
      });

      test('should parse zero timezone offset', () {
        // Arrange & Act
        const input = '2023-12-25T15:30:45+00:00';
        final result = OffsetDateTime.parse(input);

        // Assert
        expect(result, isA<OffsetDateTime>());
        expect(result.timeZoneName, 'UTC');
        expect(result.timeZoneOffset.inMinutes, 0);
      });

      test('should parse datetime with offset and milliseconds', () {
        // Arrange & Act
        const input = '2023-12-25T15:30:45.123+02:00';
        final result = OffsetDateTime.parse(input);

        // Assert
        expect(result, isA<OffsetDateTime>());
        expect(result.timeZoneName, 'UTC+02:00');
        expect(result.timeZoneOffset.inHours, 2);
        expect(result.millisecond, 123);
      });

      test('should parse datetime with offset and microseconds', () {
        // Arrange & Act
        const input = '2023-12-25T15:30:45.123456-07:00';
        final result = OffsetDateTime.parse(input);

        // Assert
        expect(result, isA<OffsetDateTime>());
        expect(result.timeZoneName, 'UTC-07:00');
        expect(result.timeZoneOffset.inHours, -7);
        expect(result.millisecond, 123);
        expect(result.microsecond, 456);
      });
    });

    group('error handling', () {
      test('should throw InvalidFormatException for empty string', () {
        // Act & Assert
        expect(
          () => OffsetDateTime.parse(''),
          throwsA(isA<InvalidFormatException>()),
        );
      });

      test('should throw InvalidFormatException for invalid format', () {
        // Act & Assert
        expect(
          () => OffsetDateTime.parse('not-a-date'),
          throwsA(isA<InvalidFormatException>()),
        );
      });

      test(
        'should throw InvalidFormatException for invalid timezone offset',
        () {
          // Act & Assert
          expect(
            () => OffsetDateTime.parse('2023-12-25T15:30:45+25:00'),
            // Invalid hour
            throwsA(isA<InvalidFormatException>()),
          );
        },
      );

      test(
        'should throw InvalidFormatException for invalid timezone format',
        () {
          // Act & Assert
          expect(
            () => OffsetDateTime.parse('2023-12-25T15:30:45+5:30'),
            // Missing leading zero
            throwsA(isA<InvalidFormatException>()),
          );
        },
      );

      test('should throw InvalidFormatException for invalid minutes', () {
        // Act & Assert
        expect(
          () => OffsetDateTime.parse('2023-12-25T15:30:45+05:60'),
          // Invalid minutes
          throwsA(isA<InvalidFormatException>()),
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
      expect(result.timeZoneName, isNot('UTC'));
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
