import 'dart:convert';

import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/date.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';
import 'package:tonik_util/src/offset_date_time.dart';

/// Extensions for decoding simple form values from strings.
///
/// Input is a literal field value: percent-decoding is intentionally not
/// performed.
extension SimpleDecoder on String? {
  /// Decodes a string to a string.
  ///
  /// Returns the string value as is.
  /// Throws [InvalidTypeException] if the value is null.
  String decodeSimpleString({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: String,
        context: context,
      );
    }

    return this!;
  }

  /// Decodes a string to a nullable string.
  ///
  /// Returns null if the string is empty or null.
  String? decodeSimpleNullableString({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return this!;
  }

  /// Decodes a string to an integer.
  ///
  /// Throws [InvalidTypeException] if the string is not a valid integer
  /// or if the value is null.
  int decodeSimpleInt({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: int,
        context: context,
      );
    }
    try {
      return int.parse(this!);
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: int,
        context: context,
      );
    }
  }

  /// Decodes a string to a nullable integer.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid integer.
  int? decodeSimpleNullableInt({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleInt(context: context);
  }

  /// Decodes a string to a double.
  ///
  /// Throws [InvalidTypeException] if the string is not a valid double
  /// or if the value is null.
  double decodeSimpleDouble({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: double,
        context: context,
      );
    }
    try {
      return double.parse(this!);
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: double,
        context: context,
      );
    }
  }

  /// Decodes a string to a nullable double.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid double.
  double? decodeSimpleNullableDouble({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleDouble(context: context);
  }

  /// Decodes a string to a boolean.
  ///
  /// Only accepts 'true' or 'false' (case-sensitive).
  /// Throws [InvalidTypeException] if the string is not a valid boolean
  /// or if the value is null.
  bool decodeSimpleBool({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: bool,
        context: context,
      );
    }
    if (this == 'true') return true;
    if (this == 'false') return false;
    throw InvalidTypeException(
      value: this!,
      targetType: bool,
      context: context,
    );
  }

  /// Decodes a string to a nullable boolean.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid boolean.
  bool? decodeSimpleNullableBool({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleBool(context: context);
  }

  /// Decodes a string to a DateTime with timezone awareness.
  ///
  /// Expects ISO 8601 format.
  /// Throws [InvalidTypeException] if the string is not a valid date
  /// or if the value is null.
  DateTime decodeSimpleDateTime({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: DateTime,
        context: context,
      );
    }
    try {
      return OffsetDateTime.parse(this!);
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: DateTime,
        context: context,
      );
    }
  }

  /// Decodes a string to a nullable DateTime.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid date.
  DateTime? decodeSimpleNullableDateTime({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleDateTime(context: context);
  }

  /// Decodes a string to a BigDecimal.
  ///
  /// Throws [InvalidTypeException] if the string is not a valid decimal
  /// or if the value is null.
  BigDecimal decodeSimpleBigDecimal({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: BigDecimal,
        context: context,
      );
    }
    try {
      return BigDecimal.parse(this!);
    } on Object catch (_) {
      throw InvalidTypeException(
        value: this!,
        targetType: BigDecimal,
        context: context,
      );
    }
  }

  /// Decodes a string to a nullable BigDecimal.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid decimal.
  BigDecimal? decodeSimpleNullableBigDecimal({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleBigDecimal(context: context);
  }

  /// Decodes a string to binary data (`List<int>`).
  ///
  /// Uses UTF-8 encoding with allowMalformed: true to handle any string input.
  /// This provides backward compatibility and handles both text and
  /// binary data.
  /// Throws [InvalidTypeException] if the value is null.
  List<int> decodeSimpleBinary({String? context}) {
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

  /// Decodes a string to nullable binary data.
  ///
  /// Returns null if the string is empty or null.
  List<int>? decodeSimpleNullableBinary({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleBinary(context: context);
  }

  /// Decodes a base64-encoded string to binary data (`List<int>`).
  ///
  /// Base64 text is decoded as-is; `+`, `/` and `=` are preserved.
  /// Throws [InvalidTypeException] if the value is null or cannot be decoded.
  List<int> decodeSimpleBase64({String? context}) {
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
    try {
      return base64.decode(this!);
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: List<int>,
        context: context,
      );
    }
  }

  /// Decodes a base64-encoded string to nullable binary data.
  ///
  /// Returns null if the string is empty or null.
  List<int>? decodeSimpleNullableBase64({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleBase64(context: context);
  }

  /// Decodes a string to a list of strings.
  ///
  /// Splits the string by commas.
  /// Empty string returns an empty list.
  /// Throws [InvalidTypeException] if the value is null.
  List<String> decodeSimpleStringList({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: List<String>,
        context: context,
      );
    }
    if (this!.isEmpty) return [];
    return this!
        .split(',')
        .map((s) => s.decodeSimpleString(context: context))
        .toList();
  }

  /// Decodes a string to a nullable list of strings.
  ///
  /// Returns null if the string is empty or null.
  /// Otherwise splits the string by commas.
  List<String>? decodeSimpleNullableStringList({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleStringList(context: context);
  }

  /// Decodes a string to a list of nullable strings.
  ///
  /// Splits the string by commas.
  /// Empty elements in the list are converted to null.
  /// Empty string returns an empty list.
  /// Throws [InvalidTypeException] if the value is null.
  List<String?> decodeSimpleStringNullableList({String? context}) {
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
        .map((s) => s.decodeSimpleNullableString(context: context))
        .toList();
  }

  /// Decodes a string to a nullable list of nullable strings.
  ///
  /// Returns null if the string is empty or null.
  /// Otherwise splits the string by commas and converts empty elements to null.
  List<String?>? decodeSimpleNullableStringNullableList({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleStringNullableList(context: context);
  }

  /// Decodes a flat simple-style object, converting values with [decodeValue].
  ///
  /// Exploded objects use `key=value,key=value`; non-exploded objects use
  /// `key,value,key,value`. A bare exploded key has an empty value.
  /// Keys and values retain literal percent sequences.
  /// An empty string represents an empty map. Throws [InvalidTypeException]
  /// for null and [InvalidFormatException] for malformed or duplicate pairs.
  Map<String, T> decodeSimpleMap<T>(
    T Function(String) decodeValue, {
    required bool explode,
    String? context,
  }) {
    final value = this;
    if (value == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: Map<String, T>,
        context: context,
      );
    }
    if (value.isEmpty) return {};

    final parts = value.split(',');
    final result = <String, T>{};
    final location = context == null ? '' : ' in $context';
    if (!explode && parts.length.isOdd) {
      throw InvalidFormatException(
        value: value,
        format: 'alternating key-value pairs$location',
      );
    }
    for (var i = 0; i < parts.length; i += explode ? 1 : 2) {
      final String key;
      final String rawValue;
      if (explode) {
        final separator = parts[i].indexOf('=');
        key = separator == -1 ? parts[i] : parts[i].substring(0, separator);
        rawValue = separator == -1 ? '' : parts[i].substring(separator + 1);
      } else {
        key = parts[i];
        rawValue = parts[i + 1];
      }
      if (result.containsKey(key)) {
        throw InvalidFormatException(
          value: key,
          format: 'single occurrence per key$location',
        );
      }
      result[key] = decodeValue(rawValue);
    }
    return result;
  }

  /// Decodes a nullable flat simple-style object.
  ///
  /// Returns null only when the field is absent.
  /// An empty field is an empty map.
  Map<String, T>? decodeSimpleNullableMap<T>(
    T Function(String) decodeValue, {
    required bool explode,
    String? context,
  }) {
    if (this == null) return null;
    return decodeSimpleMap(decodeValue, explode: explode, context: context);
  }

  /// Decodes a string to a Date.
  ///
  /// The string must be in ISO 8601 format (YYYY-MM-DD).
  /// Throws [FormatException] if the string is not in the correct format or if
  /// any of the date components are invalid.
  /// Throws [InvalidTypeException] if the value is null or empty.
  Date decodeSimpleDate({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: Date,
        context: context,
      );
    }
    if (this!.isEmpty) {
      throw InvalidTypeException(
        value: 'empty string',
        targetType: Date,
        context: context,
      );
    }
    try {
      return Date.fromString(this!);
    } on FormatException {
      rethrow;
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: Date,
        context: context,
      );
    }
  }

  /// Decodes a string to a nullable Date.
  ///
  /// Returns null if the string is empty or null.
  /// The string must be in ISO 8601 format (YYYY-MM-DD).
  /// Throws [FormatException] if the string is not in the correct format or if
  /// any of the date components are invalid.
  Date? decodeSimpleNullableDate({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleDate(context: context);
  }

  /// Decodes a string to a Uri.
  ///
  /// Expects a valid URI string.
  /// Throws [InvalidTypeException] if the value is null or if the string
  /// is not a valid URI.
  Uri decodeSimpleUri({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: Uri,
        context: context,
      );
    }
    if (this!.isEmpty) {
      throw InvalidTypeException(
        value: 'empty string',
        targetType: Uri,
        context: context,
      );
    }
    try {
      return Uri.parse(this!);
    } on FormatException catch (e) {
      throw InvalidTypeException(
        value: this!,
        targetType: Uri,
        context: e.message,
      );
    }
  }

  /// Decodes a string to a nullable Uri.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid URI.
  Uri? decodeSimpleNullableUri({String? context}) {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleUri(context: context);
  }
}
