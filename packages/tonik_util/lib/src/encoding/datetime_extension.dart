/// Extension on DateTime to provide timezone-aware encoding.
///
/// This extension ensures that DateTime objects are encoded with their full
/// timezone information, unlike [DateTime.toIso8601String()] which only
/// works correctly for UTC dates.
extension DateTimeEncodingExtension on DateTime {
  /// Encodes this DateTime to a string representation that preserves
  /// timezone information.
  ///
  /// For UTC dates, this returns the same as [DateTime.toIso8601String()].
  /// For local dates, this ensures the timezone offset is properly included.
  String toTimeZonedIso8601String() {
    if (isUtc) {
      return toIso8601String();
    }

    final year = this.year;
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

    final offset = timeZoneOffset;
    final offsetHours = offset.inHours.abs();
    final offsetMinutes = offset.inMinutes.abs() % 60;

    final offsetSign = offset.isNegative ? '-' : '+';
    final offsetString =
        '$offsetSign'
        '${_twoDigits(offsetHours)}:${_twoDigits(offsetMinutes)}';

    return '$year-$month-${day}T$hour:$minute:$second'
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
