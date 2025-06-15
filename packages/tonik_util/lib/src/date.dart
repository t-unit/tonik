import 'package:meta/meta.dart';
import 'package:tonik_util/src/decoding/json_decoder.dart';
import 'package:tonik_util/src/decoding/simple_decoder.dart';

/// A class representing a date without time information.
///
/// This class follows the RFC3339 date format (YYYY-MM-DD) and is immutable.
/// It provides methods for JSON serialization and simple string encoding/decoding.
@immutable
class Date {
  /// Creates a new [Date] instance.
  ///
  /// Throws [FormatException] if any of the date components are invalid.
  Date(this.year, this.month, this.day) {
    _validate();
  }

  /// Creates a [Date] from a [DateTime] instance.
  ///
  /// The time components are ignored.
  factory Date.fromDateTime(DateTime dateTime) {
    return Date(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Creates a [Date] from an ISO 8601 formatted string (YYYY-MM-DD).
  ///
  /// Throws [FormatException] if the string is not in the correct format
  /// or if any of the date components are invalid.
  factory Date.fromString(String dateString) {
    final parts = dateString.split('-');
    if (parts.length != 3) {
      throw const FormatException('Invalid date format. Expected YYYY-MM-DD');
    }

    try {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final date = Date(year, month, day).._validate();
      return date;
    } on Object {
      throw const FormatException('Invalid date format. Expected YYYY-MM-DD');
    }
  }

  /// Creates a [Date] from a JSON string.
  ///
  /// The string must be in ISO 8601 format (YYYY-MM-DD).
  factory Date.fromJson(Object? json) {
    return Date.fromString(json.decodeJsonString());
  }

  /// Creates a [Date] from a simple string format.
  ///
  /// The string must be in ISO 8601 format (YYYY-MM-DD).
  factory Date.fromSimple(String? simple) {
    return Date.fromString(simple.decodeSimpleString());
  }

  /// The year component of the date.
  final int year;

  /// The month component of the date (1-12).
  final int month;

  /// The day component of the date (1-31).
  final int day;

  /// Converts this [Date] to a [DateTime] instance.
  ///
  /// The time components are set to midnight (00:00:00.000).
  DateTime toDateTime() {
    return DateTime(year, month, day);
  }

  /// Converts this [Date] to a JSON string.
  ///
  /// Returns the date in ISO 8601 format (YYYY-MM-DD).
  String toJson() {
    return toString();
  }

  /// Converts this [Date] to a simple string format.
  ///
  /// Returns the date in ISO 8601 format (YYYY-MM-DD).
  String toSimple() {
    return toString();
  }

  /// Creates a copy of this [Date] with the given fields replaced
  /// with new values.
  Date copyWith({int? year, int? month, int? day}) {
    return Date(year ?? this.year, month ?? this.month, day ?? this.day)
      .._validate();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Date &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() {
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  void _validate() {
    if (month < 1 || month > 12) {
      throw FormatException(
        'Invalid month: $month. Month must be between 1 and 12.',
      );
    }

    final daysInMonth = DateTime(year, month + 1, 0).day;
    if (day < 1 || day > daysInMonth) {
      throw FormatException(
        'Invalid day: $day. Day must be between 1 and $daysInMonth for '
        'month $month.',
      );
    }
  }
}
