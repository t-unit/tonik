import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';

/// Extensions for decoding JSON values.
extension JsonDecoder on dynamic {
  /// Decodes a JSON value to a DateTime.
  ///
  /// Expects ISO 8601 format string.
  /// Throws [InvalidTypeException] if the value is not a valid date string
  /// or if the value is null.
  DateTime decodeJsonDateTime() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: DateTime,
        cause: 'Value is null',
      );
    }
    if (this is! String) {
      throw InvalidTypeException(
        value: toString(),
        targetType: DateTime,
        cause: 'Value is not a string',
      );
    }
    try {
      return DateTime.parse(this as String);
    } on FormatException catch (e) {
      throw InvalidTypeException(
        value: this as String,
        targetType: DateTime,
        cause: e.message,
      );
    }
  }

  /// Decodes a JSON value to a nullable DateTime.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid date string.
  DateTime? decodeJsonNullableDateTime() {
    if (this == null || (this is String && (this as String).isEmpty)) {
      return null;
    }
    return decodeJsonDateTime();
  }

  /// Decodes a JSON value to a BigDecimal.
  ///
  /// Throws [InvalidTypeException] if the value is not a valid decimal string
  /// or if the value is null.
  BigDecimal decodeJsonBigDecimal() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: BigDecimal,
        cause: 'Value is null',
      );
    }
    if (this is! String) {
      throw InvalidTypeException(
        value: toString(),
        targetType: BigDecimal,
        cause: 'Value is not a string',
      );
    }
    try {
      return BigDecimal.parse(this as String);
    } on Object catch (_) {
      throw InvalidTypeException(
        value: this as String,
        targetType: BigDecimal,
        cause: 'Not a valid decimal',
      );
    }
  }

  /// Decodes a JSON value to a nullable BigDecimal.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid decimal string.
  BigDecimal? decodeJsonNullableBigDecimal() {
    if (this == null || (this is String && (this as String).isEmpty)) {
      return null;
    }
    return decodeJsonBigDecimal();
  }
}
