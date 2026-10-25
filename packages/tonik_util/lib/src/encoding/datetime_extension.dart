import 'package:tonik_util/src/offset_date_time.dart';

/// Extension on DateTime to provide timezone-aware encoding.
///
/// This extension ensures that DateTime objects are encoded with a timezone
/// offset, unlike [DateTime.toIso8601String()] which only
/// works correctly for UTC dates.
extension DateTimeEncodingExtension on DateTime {
  /// Sub-minute offsets advance to the next full minute while preserving
  /// the instant. If rounding exceeds +23:59, encoding uses UTC.
  ///
  /// For UTC dates, this returns the same as [DateTime.toIso8601String()].
  /// For local dates, this ensures the timezone offset is properly included.
  String toTimeZonedIso8601String() {
    if (isUtc) {
      return toIso8601String();
    }

    final offset = timeZoneOffset;
    final remainder = offset.inMicroseconds % Duration.microsecondsPerMinute;
    if (remainder != 0) {
      // RFC 3339 offsets have minute precision; preserve the instant when
      // advancing the offset to the next representable minute.
      final roundedOffset =
          offset +
          Duration(microseconds: Duration.microsecondsPerMinute - remainder);
      return OffsetDateTime.from(
        toUtc(),
        offset: roundedOffset >= const Duration(days: 1)
            ? Duration.zero
            : roundedOffset,
      ).toTimeZonedIso8601String();
    }

    final year = this.year;
    final absoluteYear = year.abs();
    final paddedYear = absoluteYear.toString().padLeft(
      absoluteYear > 9999 ? 6 : 4,
      '0',
    );
    final formattedYear = year < 0
        ? '-$paddedYear'
        : year > 9999
        ? '+$paddedYear'
        : paddedYear;
    final month = _twoDigits(this.month);
    final day = _twoDigits(this.day);
    final hour = _twoDigits(this.hour);
    final minute = _twoDigits(this.minute);
    final second = _twoDigits(this.second);

    final String fractionalString;
    if (millisecond == 0 && microsecond == 0) {
      fractionalString = '';
    } else if (microsecond == 0) {
      fractionalString = '.${_threeDigits(millisecond)}';
    } else {
      fractionalString =
          '.${_threeDigits(millisecond)}${_threeDigits(microsecond)}';
    }

    final offsetHours = offset.inHours.abs();
    final offsetMinutes = offset.inMinutes.abs() % 60;

    final offsetSign = offset.isNegative ? '-' : '+';
    final offsetString =
        '$offsetSign'
        '${_twoDigits(offsetHours)}:${_twoDigits(offsetMinutes)}';

    return '$formattedYear-$month-${day}T$hour:$minute:$second'
        '$fractionalString$offsetString';
  }

  /// Formats a number as two digits with leading zero if needed.
  static String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  /// Formats a number as three digits with leading zeros if needed.
  static String _threeDigits(int n) {
    return n.toString().padLeft(3, '0');
  }
}
