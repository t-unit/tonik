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
      // For UTC dates, use toIso8601String which works correctly
      return toIso8601String();
    }

    // For local dates, we need to include timezone offset
    // Format the base date and time manually to match toIso8601String format
    final year = this.year;
    final month = _twoDigits(this.month);
    final day = _twoDigits(this.day);
    final hour = _twoDigits(this.hour);
    final minute = _twoDigits(this.minute);
    final second = _twoDigits(this.second);

    // Add milliseconds if present
    final millisecondString =
        millisecond > 0 ? '.${_threeDigits(millisecond)}' : '';

    // Add microseconds if present
    final microsecondString = microsecond > 0 ? _threeDigits(microsecond) : '';

    // Get the timezone offset in hours and minutes
    final offset = timeZoneOffset;
    final offsetHours = offset.inHours.abs();
    final offsetMinutes = offset.inMinutes.abs() % 60;

    // Format timezone offset
    final offsetSign = offset.isNegative ? '-' : '+';
    final offsetString =
        '$offsetSign'
        '${_twoDigits(offsetHours)}:${_twoDigits(offsetMinutes)}';

    return '$year-$month-${day}T$hour:$minute:$second'
        '$millisecondString$microsecondString$offsetString';
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
