import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';

/// Extensions for decoding JSON values.
extension JsonDecoder on Object? {
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
      return DateTime.parse(this! as String);
    } on FormatException catch (e) {
      throw InvalidTypeException(
        value: this! as String,
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
    if (this == null || (this is String && (this! as String).isEmpty)) {
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
      return BigDecimal.parse(this! as String);
    } on Object catch (_) {
      throw InvalidTypeException(
        value: this! as String,
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
    if (this == null || (this is String && (this! as String).isEmpty)) {
      return null;
    }
    return decodeJsonBigDecimal();
  }

  /// Decodes a JSON value to a String.
  ///
  /// Throws [InvalidTypeException] if the value is not a valid string
  /// or is null.
  String decodeJsonString() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: String,
        cause: 'Value is null',
      );
    }
    if (this is! String) {
      throw InvalidTypeException(
        value: toString(),
        targetType: String,
        cause: 'Value is not a string',
      );
    }
    return this! as String;
  }

  /// Decodes a JSON value to a nullable String.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid string.
  String? decodeJsonNullableString() {
    if (this == null) {
      return null;
    }
    if (this is! String) {
      throw InvalidTypeException(
        value: toString(),
        targetType: String,
        cause: 'Value is not a string',
      );
    }
    return this! as String;
  }

  /// Decodes a JSON value to an int.
  ///
  /// Throws [InvalidTypeException] if the value is not a valid int or is null.
  int decodeJsonInt() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: int,
        cause: 'Value is null',
      );
    }
    if (this is! int) {
      throw InvalidTypeException(
        value: toString(),
        targetType: int,
        cause: 'Value is not an int',
      );
    }
    return this! as int;
  }

  /// Decodes a JSON value to a nullable int.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid int.
  int? decodeJsonNullableInt() {
    if (this == null) {
      return null;
    }
    if (this is! int) {
      throw InvalidTypeException(
        value: toString(),
        targetType: int,
        cause: 'Value is not an int',
      );
    }
    return this! as int;
  }

  /// Decodes a JSON value to a num.
  ///
  /// Throws [InvalidTypeException] if the value is not a valid num or is null.
  num decodeJsonNum() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: num,
        cause: 'Value is null',
      );
    }
    if (this is! num) {
      throw InvalidTypeException(
        value: toString(),
        targetType: num,
        cause: 'Value is not a num',
      );
    }
    return this! as num;
  }

  /// Decodes a JSON value to a nullable num.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid num.
  num? decodeJsonNullableNum() {
    if (this == null) {
      return null;
    }
    if (this is! num) {
      throw InvalidTypeException(
        value: toString(),
        targetType: num,
        cause: 'Value is not a num',
      );
    }
    return this! as num;
  }

  /// Decodes a JSON value to a double.
  ///
  /// Throws [InvalidTypeException] if the value is not a valid double or
  /// is null.
  double decodeJsonDouble() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: double,
        cause: 'Value is null',
      );
    }
    if (this is! double) {
      throw InvalidTypeException(
        value: toString(),
        targetType: double,
        cause: 'Value is not a double',
      );
    }
    return this! as double;
  }

  /// Decodes a JSON value to a nullable double.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid double.
  double? decodeJsonNullableDouble() {
    if (this == null) {
      return null;
    }
    if (this is! double) {
      throw InvalidTypeException(
        value: toString(),
        targetType: double,
        cause: 'Value is not a double',
      );
    }
    return this! as double;
  }

  /// Decodes a JSON value to a List of type [T].
  ///
  /// Throws [InvalidTypeException] if the value is not a list or is null.
  List<T> decodeJsonList<T>() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: List<T>,
        cause: 'Value is null',
      );
    }
    if (this is! List) {
      throw InvalidTypeException(
        value: toString(),
        targetType: List<T>,
        cause: 'Value is not a list',
      );
    }

    final list = this! as List;
    final mapped = list.whereType<T>();

    if (mapped.length != list.length) {
      throw InvalidTypeException(
        value: toString(),
        targetType: List<T>,
        cause: 'Value is not a list of $T',
      );
    }

    return mapped.toList();
  }

  /// Decodes a JSON value to a nullable List of type [T].
  ///
  /// Returns null if the value is null or an empty list.
  /// Throws [InvalidTypeException] if the value is not a list of the
  /// expected type.
  List<T>? decodeJsonNullableList<T>() {
    if (this == null) {
      return null;
    }
    return decodeJsonList<T>();
  }
}
