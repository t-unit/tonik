import 'package:test/test.dart';
import 'package:tonik_util/src/date.dart';

void main() {
  group('Date', () {
    test('creates date from DateTime', () {
      final date = Date.fromDateTime(DateTime(2024, 3, 15));
      expect(date.year, 2024);
      expect(date.month, 3);
      expect(date.day, 15);
    });

    test('creates date from string in ISO format', () {
      final date = Date.fromString('2024-03-15');
      expect(date.year, 2024);
      expect(date.month, 3);
      expect(date.day, 15);
    });

    test('throws on invalid date string', () {
      expect(() => Date.fromString('invalid'), throwsA(isA<FormatException>()));
    });

    test('converts to ISO string', () {
      final date = Date(2024, 3, 15);
      expect(date.toString(), '2024-03-15');
    });

    test('converts to DateTime', () {
      final date = Date(2024, 3, 15);
      final dateTime = date.toDateTime();
      expect(dateTime.year, 2024);
      expect(dateTime.month, 3);
      expect(dateTime.day, 15);
      expect(dateTime.hour, 0);
      expect(dateTime.minute, 0);
      expect(dateTime.second, 0);
      expect(dateTime.millisecond, 0);
    });

    test('equals and hashCode', () {
      final date1 = Date(2024, 3, 15);
      final date2 = Date(2024, 3, 15);
      final date3 = Date(2024, 3, 16);

      expect(date1.year, date2.year);
      expect(date1.month, date2.month);
      expect(date1.day, date2.day);
      expect(date1.hashCode, date2.hashCode);

      expect(date1.year, date3.year);
      expect(date1.month, date3.month);
      expect(date1.day, isNot(date3.day));
      expect(date1.hashCode, isNot(date3.hashCode));
    });

    test('copyWith', () {
      final date = Date(2024, 3, 15);

      final sameDate = date.copyWith();
      expect(sameDate.year, date.year);
      expect(sameDate.month, date.month);
      expect(sameDate.day, date.day);

      final newYear = date.copyWith(year: 2025);
      expect(newYear.year, 2025);
      expect(newYear.month, 3);
      expect(newYear.day, 15);

      final newMonth = date.copyWith(month: 4);
      expect(newMonth.year, 2024);
      expect(newMonth.month, 4);
      expect(newMonth.day, 15);

      final newDay = date.copyWith(day: 16);
      expect(newDay.year, 2024);
      expect(newDay.month, 3);
      expect(newDay.day, 16);
    });

    test('toJson and fromJson', () {
      final date = Date(2024, 3, 15);
      final json = date.toJson();
      expect(json, '2024-03-15');

      final fromJson = Date.fromJson(json);
      expect(fromJson.year, date.year);
      expect(fromJson.month, date.month);
      expect(fromJson.day, date.day);
    });

    test('fromJson throws on invalid format', () {
      expect(() => Date.fromJson('invalid'), throwsA(isA<FormatException>()));
      expect(
        () => Date.fromJson('2024/03/15'),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson throws on invalid date values', () {
      expect(
        () => Date.fromJson('2024-00-15'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Date.fromJson('2024-13-15'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Date.fromJson('2024-03-00'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Date.fromJson('2024-03-32'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Date.fromJson('2024-02-30'),
        throwsA(isA<FormatException>()),
      ); // February 30th
    });

    test('toSimple and fromSimple', () {
      final date = Date(2024, 3, 15);
      final simple = date.toSimple(explode: false, allowEmpty: true);
      expect(simple, '2024-03-15');

      final fromSimple = Date.fromSimple(simple);
      expect(fromSimple.year, date.year);
      expect(fromSimple.month, date.month);
      expect(fromSimple.day, date.day);
    });

    test('fromSimple throws on invalid format', () {
      expect(() => Date.fromSimple('invalid'), throwsA(isA<FormatException>()));
      expect(
        () => Date.fromSimple('2024/03/15'),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromSimple throws on invalid date values', () {
      expect(
        () => Date.fromSimple('2024-00-15'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Date.fromSimple('2024-13-15'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Date.fromSimple('2024-03-00'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Date.fromSimple('2024-03-32'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Date.fromSimple('2024-02-30'),
        throwsA(isA<FormatException>()),
      ); // February 30th
    });

    test('validates date components', () {
      expect(() => Date(2024, 0, 15), throwsA(isA<FormatException>()));
      expect(() => Date(2024, 13, 15), throwsA(isA<FormatException>()));
      expect(() => Date(2024, 3, 0), throwsA(isA<FormatException>()));
      expect(() => Date(2024, 3, 32), throwsA(isA<FormatException>()));
      expect(
        () => Date(2024, 2, 30),
        throwsA(isA<FormatException>()),
      ); // February 30th
    });

    group('form encoding', () {
      test('toForm returns URL-encoded ISO date string', () {
        final date = Date(2024, 3, 15);
        final encoded = date.toForm(explode: false, allowEmpty: true);
        expect(encoded, '2024-03-15');
      });

      test('toForm handles explode parameter', () {
        final date = Date(2024, 12, 31);
        final encodedNoExplode = date.toForm(explode: false, allowEmpty: true);
        final encodedExplode = date.toForm(explode: true, allowEmpty: true);
        expect(encodedNoExplode, '2024-12-31');
        expect(encodedExplode, '2024-12-31');
      });

      test('toForm handles allowEmpty parameter', () {
        final date = Date(2024, 1, 1);
        final encoded1 = date.toForm(explode: false, allowEmpty: true);
        final encoded2 = date.toForm(explode: false, allowEmpty: false);
        expect(encoded1, '2024-01-01');
        expect(encoded2, '2024-01-01');
      });

      test('fromForm creates date from URL-encoded string', () {
        final date = Date.fromForm('2024-03-15');
        expect(date.year, 2024);
        expect(date.month, 3);
        expect(date.day, 15);
      });

      test('fromForm handles URL-encoded date string', () {
        final encoded = Uri.encodeQueryComponent('2024-03-15');
        final date = Date.fromForm(encoded);
        expect(date.year, 2024);
        expect(date.month, 3);
        expect(date.day, 15);
      });

      test('fromForm throws on null input', () {
        expect(
          () => Date.fromForm(null),
          throwsA(isA<Exception>()),
        );
      });

      test('fromForm throws on empty string', () {
        expect(
          () => Date.fromForm(''),
          throwsA(isA<Exception>()),
        );
      });

      test('fromForm throws on invalid date format', () {
        expect(
          () => Date.fromForm('invalid-date'),
          throwsA(isA<Exception>()),
        );
        expect(
          () => Date.fromForm('2024/03/15'),
          throwsA(isA<Exception>()),
        );
        expect(
          () => Date.fromForm('15-03-2024'),
          throwsA(isA<Exception>()),
        );
      });

      test('fromForm throws on invalid date values', () {
        expect(
          () => Date.fromForm('2024-00-15'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => Date.fromForm('2024-13-15'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => Date.fromForm('2024-03-00'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => Date.fromForm('2024-03-32'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => Date.fromForm('2024-02-30'),
          throwsA(isA<FormatException>()),
        );
      });

      test('round-trip form encoding preserves date', () {
        final originalDate = Date(2024, 7, 4);
        final encoded = originalDate.toForm(explode: false, allowEmpty: true);
        final decodedDate = Date.fromForm(encoded);

        expect(decodedDate.year, originalDate.year);
        expect(decodedDate.month, originalDate.month);
        expect(decodedDate.day, originalDate.day);
      });

      test('round-trip with URL encoding preserves date', () {
        final originalDate = Date(2024, 12, 25);
        final encoded = originalDate.toForm(explode: true, allowEmpty: false);
        final urlEncoded = Uri.encodeQueryComponent(encoded);
        final decodedDate = Date.fromForm(urlEncoded);

        expect(decodedDate.year, originalDate.year);
        expect(decodedDate.month, originalDate.month);
        expect(decodedDate.day, originalDate.day);
      });

      test('handles leap year dates correctly', () {
        final leapDate = Date(2024, 2, 29);
        final encoded = leapDate.toForm(explode: false, allowEmpty: true);
        final decoded = Date.fromForm(encoded);

        expect(decoded.year, 2024);
        expect(decoded.month, 2);
        expect(decoded.day, 29);
      });

      test('handles edge case dates correctly', () {
        final testCases = [
          Date(1900, 1, 1),
          Date(2000, 12, 31),
          Date(2024, 2, 29), // leap year
          Date(2023, 2, 28), // non-leap year
          Date(9999, 12, 31),
        ];

        for (final testDate in testCases) {
          final encoded = testDate.toForm(explode: false, allowEmpty: true);
          final decoded = Date.fromForm(encoded);

          expect(decoded.year, testDate.year);
          expect(decoded.month, testDate.month);
          expect(decoded.day, testDate.day);
        }
      });
    });
  });

  group('label encoding', () {
    test('toLabel returns label-prefixed ISO date string', () {
      final date = Date(2024, 3, 15);
      final encoded = date.toLabel(explode: false, allowEmpty: true);
      expect(encoded, '.2024-03-15');
    });

    test('toLabel handles explode parameter', () {
      final date = Date(2024, 12, 31);
      final encodedNoExplode = date.toLabel(explode: false, allowEmpty: true);
      final encodedExplode = date.toLabel(explode: true, allowEmpty: true);
      expect(encodedNoExplode, '.2024-12-31');
      expect(encodedExplode, '.2024-12-31');
    });

    test('toLabel handles allowEmpty parameter', () {
      final date = Date(2024, 1, 1);
      final encoded1 = date.toLabel(explode: false, allowEmpty: true);
      final encoded2 = date.toLabel(explode: false, allowEmpty: false);
      expect(encoded1, '.2024-01-01');
      expect(encoded2, '.2024-01-01');
    });

    test('toLabel encodes date with special characters properly', () {
      final date = Date(2024, 2, 29);
      final encoded = date.toLabel(explode: false, allowEmpty: true);
      expect(encoded, '.2024-02-29');
    });

    test('toLabel handles edge case dates correctly', () {
      final testCases = [
        Date(2024, 1, 1),
        Date(2024, 12, 31),
        Date(2024, 2, 29),
        Date(2023, 2, 28),
      ];

      for (final testDate in testCases) {
        final encoded = testDate.toLabel(explode: false, allowEmpty: true);
        expect(encoded, startsWith('.'));
        expect(encoded.substring(1), testDate.toString());
      }
    });
  });
}
