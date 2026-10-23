import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:tonik_util/src/decoding/form_decoder.dart';
import 'package:tonik_util/src/decoding/json_decoder.dart';
import 'package:tonik_util/src/decoding/simple_decoder.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

/// A class representing a date without time information.
///
/// Years 0000–9999 use the RFC 3339 date format (YYYY-MM-DD). Negative years
/// through -9999 use a minus sign and four digits. Years outside -9999–9999
/// use a sign and at least six digits, matching [DateTime.toIso8601String]
/// within its supported range.
/// It provides methods for JSON serialization and simple string encoding/decoding.
@immutable
class Date(
  /// The year component of the date.
  final int year,

  /// The month component of the date (1-12).
  final int month,

  /// The day component of the date (1-31).
  final int day,
) {
  /// Throws [FormatException] if any of the date components are invalid.
  this {
    _validate();
  }

  /// Converts [dateTime] to a date without time components.
  ///
  /// The time components are ignored.
  factory fromDateTime(DateTime dateTime) =>
      Date(dateTime.year, dateTime.month, dateTime.day);

  /// Parses a date string (YYYY-MM-DD, with optional sign and extended year).
  ///
  /// Throws [FormatException] if the string is not in the correct format
  /// or if any of the date components are invalid.
  factory fromString(String dateString) {
    final parts = RegExp(r'^([+-]?\d+)-(\+?\d+)-(\+?\d+)$')
        .firstMatch(dateString);
    if (parts == null) {
      throw const FormatException('Invalid date format. Expected YYYY-MM-DD');
    }

    try {
      return Date(
        int.parse(parts[1]!),
        int.parse(parts[2]!),
        int.parse(parts[3]!),
      );
    } on FormatException {
      throw const FormatException('Invalid date format. Expected YYYY-MM-DD');
    }
  }

  /// Decodes a date from a JSON string.
  ///
  /// Accepts the date format described by [Date.fromString].
  /// Throws [FormatException] for malformed dates and `InvalidTypeException`
  /// for null or non-string values.
  factory fromJson(Object? json) => Date.fromString(json.decodeJsonString());

  /// Decodes a date from a simple string value.
  ///
  /// Accepts the date format described by [Date.fromString].
  factory fromSimple(String? simple) =>
      Date.fromString(simple.decodeSimpleString());

  /// Decodes a date from a form-encoded string.
  ///
  /// Accepts the date format described by [Date.fromString], URL-encoded.
  factory fromForm(String? form) => Date.fromString(form.decodeFormString());

  /// Converts this [Date] to a [DateTime] instance.
  ///
  /// The time components are set to midnight (00:00:00.000).
  DateTime toDateTime() => DateTime(year, month, day);

  /// Converts this [Date] to a JSON string.
  ///
  /// Uses the year formatting described by [Date].
  String toJson() => toString();

  /// Converts this [Date] to a simple string format.
  ///
  /// Uses the year formatting described by [Date].
  String toSimple({
    required bool explode,
    required bool allowEmpty,
    bool literal = false,
  }) => uriEncode(allowEmpty: allowEmpty, literal: literal, textEncoding: utf8);

  /// Converts this [Date] to a form-encoded parameter entry.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    required Encoding textEncoding,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => [
    (
      name: paramName.uriEncode(
        allowEmpty: true,
        useQueryComponent: useQueryComponent,
        textEncoding: textEncoding,
      ),
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
        textEncoding: textEncoding,
      ),
    ),
  ];

  /// Converts this [Date] to a label-encoded string.
  ///
  /// Uses the year formatting described by [Date] with a label prefix.
  String toLabel({required bool explode, required bool allowEmpty}) {
    return '.${uriEncode(allowEmpty: allowEmpty, textEncoding: utf8)}';
  }

  /// Converts this [Date] to a matrix-encoded string.
  ///
  /// Uses the year formatting described by [Date] with a matrix prefix.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) {
    final value = uriEncode(allowEmpty: allowEmpty, textEncoding: utf8);
    return ';$paramName=$value';
  }

  /// URI encodes this Date value.
  ///
  /// [literal] returns the value unencoded, overriding [useQueryComponent] and
  /// [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    required Encoding textEncoding,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) => toString().uriEncode(
    allowEmpty: allowEmpty,
    useQueryComponent: useQueryComponent,
    allowReserved: allowReserved,
    literal: literal,
    textEncoding: textEncoding,
  );

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
    final digits = year < 0 ? year.toString().substring(1) : year.toString();
    final paddedYear = digits.padLeft(year < -9999 || year > 9999 ? 6 : 4, '0');
    final yearString = year < 0
        ? '-$paddedYear'
        : year > 9999
        ? '+$paddedYear'
        : paddedYear;
    return '$yearString-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  void _validate() {
    if (month < 1 || month > 12) {
      throw FormatException(
        'Invalid month: $month. Month must be between 1 and 12.',
      );
    }

    final daysInMonth = switch (month) {
      2 when year % 400 == 0 || (year % 4 == 0 && year % 100 != 0) => 29,
      2 => 28,
      4 || 6 || 9 || 11 => 30,
      _ => 31,
    };
    if (day < 1 || day > daysInMonth) {
      throw FormatException(
        'Invalid day: $day. Day must be between 1 and $daysInMonth for '
        'month $month.',
      );
    }
  }
}
