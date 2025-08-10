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
  });
}
