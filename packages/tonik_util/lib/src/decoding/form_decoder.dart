import 'dart:convert';

import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/date.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';
import 'package:tonik_util/src/offset_date_time.dart';

/// Extensions for decoding form-encoded values from strings.
///
/// Form decoding handles URL-encoded strings that use query component
/// (spaces as '+', special characters as '%XX').
extension FormDecoder on String? {
  /// Decodes a form-encoded string to a string.
  ///
  /// Uses URI query component decoding (+ becomes space, %XX becomes
  /// character).
  /// Throws [InvalidTypeException] if the value is null.
  String decodeFormString({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: String,
        context: context,
      );
    }
    try {
      return Uri.decodeQueryComponent(this!);
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: String,
        context: context,
      );
    }
  }

  /// Decodes a form-encoded string to a nullable string.
  ///
  /// Returns null if the string is empty or null.
  String? decodeFormNullableString({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeFormString(context: context);
  }

  /// Decodes a form-encoded string to an integer.
  ///
  /// Throws [InvalidTypeException] if the string is not a valid integer
  /// or if the value is null.
  int decodeFormInt({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: int,
        context: context,
      );
    }
    try {
      final decoded = _decodeFormValue();
      return int.parse(decoded);
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: int,
        context: context,
      );
    }
  }

  /// Decodes a form-encoded string to a nullable integer.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid integer.
  int? decodeFormNullableInt({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeFormInt(context: context);
  }

  /// Decodes a form-encoded string to a double.
  ///
  /// Throws [InvalidTypeException] if the string is not a valid double
  /// or if the value is null.
  double decodeFormDouble({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: double,
        context: context,
      );
    }
    try {
      final decoded = _decodeFormValue();
      final result = double.parse(decoded);
      return result;
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: double,
        context: context,
      );
    }
  }

  /// Decodes a form-encoded string to a nullable double.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid double.
  double? decodeFormNullableDouble({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeFormDouble(context: context);
  }

  /// Decodes a form-encoded string to a boolean.
  ///
  /// Only accepts 'true' or 'false' (case-sensitive).
  /// Throws [InvalidTypeException] if the string is not a valid boolean
  /// or if the value is null.
  bool decodeFormBool({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: bool,
        context: context,
      );
    }
    final decoded = Uri.decodeQueryComponent(this!);
    if (decoded == 'true') return true;
    if (decoded == 'false') return false;
    throw InvalidTypeException(
      value: this!,
      targetType: bool,
      context: context,
    );
  }

  /// Decodes a form-encoded string to a nullable boolean.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid boolean.
  bool? decodeFormNullableBool({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeFormBool(context: context);
  }

  /// Decodes a form-encoded string to a DateTime.
  ///
  /// Expects ISO 8601 format (e.g., '2023-01-01T12:00:00Z').
  /// Throws [InvalidTypeException] if the string is not a valid DateTime
  /// or if the value is null.
  DateTime decodeFormDateTime({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: DateTime,
        context: context,
      );
    }
    try {
      final decoded = Uri.decodeQueryComponent(this!);
      return OffsetDateTime.parse(decoded);
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: DateTime,
        context: context,
      );
    }
  }

  /// Decodes a form-encoded string to a nullable DateTime.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid DateTime.
  DateTime? decodeFormNullableDateTime({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeFormDateTime(context: context);
  }

  /// Decodes a form-encoded string to a BigDecimal.
  ///
  /// Throws [InvalidTypeException] if the string is not a valid BigDecimal
  /// or if the value is null.
  BigDecimal decodeFormBigDecimal({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: BigDecimal,
        context: context,
      );
    }
    try {
      final decoded = _decodeFormValue();
      return BigDecimal.parse(decoded);
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: BigDecimal,
        context: context,
      );
    }
  }

  /// Decodes a form-encoded string to a nullable BigDecimal.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid BigDecimal.
  BigDecimal? decodeFormNullableBigDecimal({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeFormBigDecimal(context: context);
  }

  /// Decodes a form-encoded string to binary data (`List<int>`).
  ///
  /// Uses UTF-8 encoding with allowMalformed: true to handle any string input.
  /// This provides backward compatibility and handles both text and
  /// binary data.
  /// Throws [InvalidTypeException] if the value is null.
  List<int> decodeFormBinary({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: List<int>,
        context: context,
      );
    }
    if (this!.isEmpty) {
      return <int>[];
    }
    return utf8.encode(this!);
  }

  /// Decodes a form-encoded string to nullable binary data.
  ///
  /// Returns null if the string is empty or null.
  List<int>? decodeFormNullableBinary({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeFormBinary(context: context);
  }

  /// Decodes a form-encoded string to a Date.
  ///
  /// Expects ISO 8601 date format (e.g., '2023-01-01').
  /// Throws [InvalidTypeException] if the string is not a valid Date
  /// or if the value is null.
  Date decodeFormDate({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: Date,
        context: context,
      );
    }
    try {
      final decoded = Uri.decodeQueryComponent(this!);
      return Date.fromString(decoded);
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: Date,
        context: context,
      );
    }
  }

  /// Decodes a form-encoded string to a nullable Date.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid Date.
  Date? decodeFormNullableDate({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeFormDate(context: context);
  }

  /// Decodes a form-encoded string to a Uri.
  ///
  /// Throws [InvalidTypeException] if the string is not a valid Uri
  /// or if the value is null.
  Uri decodeFormUri({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: Uri,
        context: context,
      );
    }
    try {
      final decoded = Uri.decodeQueryComponent(this!);
      return Uri.parse(decoded);
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: Uri,
        context: context,
      );
    }
  }

  /// Decodes a form-encoded string to a nullable Uri.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid Uri.
  Uri? decodeFormNullableUri({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeFormUri(context: context);
  }

  /// Decodes a form-encoded string to a list of strings.
  ///
  /// Splits the string by commas and decodes each element.
  /// Empty string returns an empty list.
  /// Throws [InvalidTypeException] if the value is null.
  List<String> decodeFormStringList({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: List<String>,
        context: context,
      );
    }
    if (this!.isEmpty) return [];
    return this!.split(',').map(Uri.decodeQueryComponent).toList();
  }

  /// Decodes a form-encoded string to a nullable list of strings.
  ///
  /// Returns null if the string is empty or null.
  List<String>? decodeFormNullableStringList({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeFormStringList(context: context);
  }

  /// Decodes a form-encoded string to a list of nullable strings.
  ///
  /// Splits the string by commas and decodes each element.
  /// Empty elements in the list are converted to null.
  /// Empty string returns an empty list.
  /// Throws [InvalidTypeException] if the value is null.
  List<String?> decodeFormStringNullableList({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: List<String?>,
        context: context,
      );
    }
    if (this!.isEmpty) return [];
    return this!
        .split(',')
        .map((s) => s.isEmpty ? null : Uri.decodeQueryComponent(s))
        .toList();
  }

  /// Decodes a form-encoded string to a nullable list of nullable strings.
  ///
  /// Returns null if the string is empty or null.
  List<String?>? decodeFormNullableStringNullableList({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeFormStringNullableList(context: context);
  }

  String _decodeFormValue() {
    if (this == null) {
      throw ArgumentError('Cannot decode null string');
    }

    // For numeric values with scientific notation, preserve + signs
    if (this!.contains('e+') || this!.contains('E+')) {
      return Uri.decodeComponent(this!);
    } else {
      return Uri.decodeQueryComponent(this!);
    }
  }
}
