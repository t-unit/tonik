import 'dart:core';

import 'package:meta/meta.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';

/// A DateTime implementation that supports fixed timezone offsets.
///
/// This class provides timezone-aware DateTime functionality with a fixed
/// offset from UTC.
/// It implements the DateTime interface by delegating to an internal UTC
/// DateTime object and applying offset adjustments for local time operations.
@immutable
class OffsetDateTime implements DateTime {
  /// Creates an [OffsetDateTime] from an existing [DateTime] with the
  /// specified offset.
  ///
  /// The [dateTime] is interpreted as being in the timezone specified
  /// by [offset]. The resulting [OffsetDateTime] will represent the same
  /// moment in time, but with the specified offset.
  OffsetDateTime.from(
    DateTime dateTime, {
    required this.offset,
    String? timeZoneName,
  }) : timeZoneName = timeZoneName ?? _generateTimeZoneName(offset),
       _utcDateTime = dateTime.isUtc
           ? dateTime
           : _toUtcDateTime(dateTime, offset);

  const OffsetDateTime._fromUtc(
    this._utcDateTime, {
    required this.offset,
    required this.timeZoneName,
  });

  /// Parses a datetime string with timezone offset.
  factory OffsetDateTime._parseWithTimezoneOffset(
    String input,
    RegExpMatch timezoneMatch,
  ) {
    final offsetString = timezoneMatch.group(0)!;
    final datetimeString = input.substring(
      0,
      input.length - offsetString.length,
    );

    final offset = _parseTimezoneOffset(offsetString);

    // Parse the datetime part (without timezone) as local time
    final localDateTime = DateTime.parse(datetimeString);

    // Create OffsetDateTime from the local time and offset
    return OffsetDateTime.from(
      localDateTime,
      offset: offset,
    );
  }

  /// Parses an ISO8601 datetime string with timezone support.
  ///
  /// Always returns an [OffsetDateTime] object:
  /// - For strings ending with 'Z': OffsetDateTime with zero offset (UTC)
  /// - For strings without timezone: OffsetDateTime with system timezone offset
  /// - For strings with timezone offset: OffsetDateTime with the specified
  ///   offset
  ///
  /// Throws [DecodingException] if the string is not a valid ISO8601 format.
  ///
  /// Examples:
  /// ```dart
  /// OffsetDateTime.parse('2023-12-25T15:30:45Z'); // OffsetDateTime (UTC)
  /// OffsetDateTime.parse('2023-12-25T15:30:45'); // OffsetDateTime (system timezone)
  /// OffsetDateTime.parse('2023-12-25T15:30:45+05:30'); // OffsetDateTime (+05:30)
  /// ```
  static OffsetDateTime parse(String input) {
    if (input.isEmpty) {
      throw const InvalidFormatException(
        value: '',
        format: 'ISO8601 datetime string',
      );
    }

    // Handle different separator formats (T or space)
    final normalizedInput = input.replaceFirst(' ', 'T');

    // Check if it has timezone offset (±HH:MM or ±HHMM)
    final timezoneRegex = RegExp(r'[+-]\d{2}:?\d{2}$');
    final timezoneMatch = timezoneRegex.firstMatch(normalizedInput);

    if (timezoneMatch != null) {
      return OffsetDateTime._parseWithTimezoneOffset(
        normalizedInput,
        timezoneMatch,
      );
    }

    // Parse as UTC (ends with Z) or local time (no timezone info)
    try {
      final dateTime = DateTime.parse(normalizedInput);

      // Create OffsetDateTime from the parsed DateTime
      if (dateTime.isUtc) {
        // UTC datetime - create with zero offset
        return OffsetDateTime.from(dateTime, offset: Duration.zero);
      } else {
        // Local datetime - preserve the system timezone offset
        return OffsetDateTime.from(dateTime, offset: dateTime.timeZoneOffset);
      }
    } on FormatException {
      throw InvalidFormatException(
        value: normalizedInput,
        format: 'ISO8601 datetime format',
      );
    }
  }

  /// Parses timezone offset string (±HH:MM or ±HHMM) into Duration.
  static Duration _parseTimezoneOffset(String offsetString) {
    // Remove optional colon for compact format
    final normalized = offsetString.replaceAll(':', '');

    if (normalized.length != 5) {
      throw InvalidFormatException(
        value: offsetString,
        format: '±HHMM or ±HH:MM timezone offset',
      );
    }

    final sign = normalized[0] == '+' ? 1 : -1;
    final hoursStr = normalized.substring(1, 3);
    final minutesStr = normalized.substring(3, 5);

    final hours = int.parse(hoursStr);
    final minutes = int.parse(minutesStr);

    if (hours < 0 || hours > 23) {
      throw InvalidFormatException(
        value: offsetString,
        format: 'timezone offset hours must be between 00 and 23',
      );
    }

    if (minutes < 0 || minutes > 59) {
      throw InvalidFormatException(
        value: offsetString,
        format: 'timezone offset minutes must be between 00 and 59',
      );
    }

    return Duration(hours: sign * hours, minutes: sign * minutes);
  }

  /// The canonical UTC representation of this datetime.
  ///
  /// This represents the same moment in time as this [OffsetDateTime],
  /// but in UTC time zone.
  final DateTime _utcDateTime;

  /// The timezone offset from UTC.
  ///
  /// Positive values are east of UTC, negative values are west of UTC.
  /// For example, an offset of +5 hours would be Duration(hours: 5).
  final Duration offset;

  @override
  final String timeZoneName;

  /// Converts a local DateTime with an offset to UTC DateTime.
  static DateTime _toUtcDateTime(DateTime localDateTime, Duration offset) {
    // Calculate the UTC moment by subtracting the offset
    final utcMoment = localDateTime.subtract(offset);
    // Return a proper UTC DateTime with isUtc = true
    return DateTime.utc(
      utcMoment.year,
      utcMoment.month,
      utcMoment.day,
      utcMoment.hour,
      utcMoment.minute,
      utcMoment.second,
      utcMoment.millisecond,
      utcMoment.microsecond,
    );
  }

  /// Generates a timezone name from an offset.
  ///
  /// Returns 'UTC' for zero offset, otherwise returns a UTC-based formatted
  /// offset like 'UTC+05:30' or 'UTC-08:00'.
  static String _generateTimeZoneName(Duration offset) {
    if (offset == Duration.zero) {
      return 'UTC';
    }

    final hours = offset.inHours;
    final minutes = offset.inMinutes.abs() % 60;
    final sign = hours < 0 || (hours == 0 && offset.isNegative) ? '-' : '+';
    final absHours = hours.abs();

    final hourPart = absHours.toString().padLeft(2, '0');
    final minutePart = minutes.toString().padLeft(2, '0');
    return 'UTC$sign$hourPart:$minutePart';
  }

  @override
  OffsetDateTime toUtc() {
    if (offset == Duration.zero) {
      return this;
    }
    return OffsetDateTime._fromUtc(
      _utcDateTime,
      offset: Duration.zero,
      timeZoneName: 'UTC',
    );
  }

  @override
  DateTime toLocal() {
    return DateTime.fromMicrosecondsSinceEpoch(
      microsecondsSinceEpoch,
    );
  }

  @override
  int get millisecondsSinceEpoch => _utcDateTime.millisecondsSinceEpoch;

  @override
  int get microsecondsSinceEpoch => _utcDateTime.microsecondsSinceEpoch;

  @override
  bool get isUtc => offset == Duration.zero;

  @override
  OffsetDateTime add(Duration duration) {
    final newUtcDateTime = _utcDateTime.add(duration);
    return OffsetDateTime._fromUtc(
      newUtcDateTime,
      offset: offset,
      timeZoneName: timeZoneName,
    );
  }

  @override
  OffsetDateTime subtract(Duration duration) {
    final newUtcDateTime = _utcDateTime.subtract(duration);
    return OffsetDateTime._fromUtc(
      newUtcDateTime,
      offset: offset,
      timeZoneName: timeZoneName,
    );
  }

  @override
  Duration difference(DateTime other) =>
      _utcDateTime.difference(_toNative(other));

  @override
  bool isBefore(DateTime other) => _utcDateTime.isBefore(_toNative(other));

  @override
  bool isAfter(DateTime other) => _utcDateTime.isAfter(_toNative(other));

  @override
  bool isAtSameMomentAs(DateTime other) =>
      _utcDateTime.isAtSameMomentAs(_toNative(other));

  @override
  int compareTo(DateTime other) => _utcDateTime.compareTo(_toNative(other));

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DateTime && _utcDateTime.isAtSameMomentAs(_toNative(other));
  }

  @override
  int get hashCode => _utcDateTime.hashCode;

  @override
  Duration get timeZoneOffset => offset;

  DateTime get _localDateTime => _utcDateTime.add(offset);

  @override
  int get year => _localDateTime.year;

  @override
  int get month => _localDateTime.month;

  @override
  int get day => _localDateTime.day;

  @override
  int get hour => _localDateTime.hour;

  @override
  int get minute => _localDateTime.minute;

  @override
  int get second => _localDateTime.second;

  @override
  int get millisecond => _localDateTime.millisecond;

  @override
  int get microsecond => _localDateTime.microsecond;

  @override
  int get weekday => _localDateTime.weekday;

  @override
  String toString() => _toString(iso8601: false);

  @override
  String toIso8601String() => _toString();

  String _toString({bool iso8601 = true}) {
    final local = _localDateTime;
    final y = _fourDigits(local.year);
    final m = _twoDigits(local.month);
    final d = _twoDigits(local.day);
    final sep = iso8601 ? 'T' : ' ';
    final h = _twoDigits(local.hour);
    final min = _twoDigits(local.minute);
    final sec = _twoDigits(local.second);
    final ms = _threeDigits(local.millisecond);
    final us = local.microsecond == 0 ? '' : _threeDigits(local.microsecond);

    if (isUtc || offset == Duration.zero) {
      return '$y-$m-$d$sep$h:$min:$sec.$ms${us}Z';
    } else {
      final offsetSign = offset.isNegative ? '-' : '+';
      final offsetAbs = offset.abs();
      final offsetHours = offsetAbs.inHours;
      final offsetMinutes = offsetAbs.inMinutes % 60;
      final offH = _twoDigits(offsetHours);
      final offM = _twoDigits(offsetMinutes);

      return '$y-$m-$d$sep$h:$min:$sec.$ms$us$offsetSign$offH$offM';
    }
  }

  static String _fourDigits(int n) {
    final absN = n.abs();
    final sign = n < 0 ? '-' : '';
    if (absN >= 1000) return '$n';
    if (absN >= 100) return '${sign}0$absN';
    if (absN >= 10) return '${sign}00$absN';
    return '${sign}000$absN';
  }

  static String _threeDigits(int n) {
    if (n >= 100) return '$n';
    if (n >= 10) return '0$n';
    return '00$n';
  }

  static String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }

  /// Returns the native [DateTime] object.
  static DateTime _toNative(DateTime t) =>
      t is OffsetDateTime ? t._utcDateTime : t;
}
