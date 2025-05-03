import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';


/// Extensions for decoding simple form values from strings.
extension SimpleDecoder on String? {
  /// Decodes a string to a string.
  ///
  /// Returns the string value as is.
  /// Throws [InvalidTypeException] if the value is null.
  String decodeSimpleString() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: String,
        cause: 'Value is null',
      );
    }
    return Uri.decodeComponent(this!);
  }

  /// Decodes a string to a nullable string.
  ///
  /// Returns null if the string is empty or null.
  String? decodeSimpleNullableString() {
    if (this?.isEmpty ?? true) return null;
    return Uri.decodeComponent(this!);
  }

  /// Decodes a string to an integer.
  ///
  /// Throws [InvalidTypeException] if the string is not a valid integer
  /// or if the value is null.
  int decodeSimpleInt() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: int,
        cause: 'Value is null',
      );
    }
    try {
      return int.parse(this!);
    } on FormatException catch (e) {
      throw InvalidTypeException(
        value: this!,
        targetType: int,
        cause: e.message,
      );
    }
  }

  /// Decodes a string to a nullable integer.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid integer.
  int? decodeSimpleNullableInt() {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleInt();
  }

  /// Decodes a string to a double.
  ///
  /// Throws [InvalidTypeException] if the string is not a valid double
  /// or if the value is null.
  double decodeSimpleDouble() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: double,
        cause: 'Value is null',
      );
    }
    try {
      return double.parse(this!);
    } on FormatException catch (e) {
      throw InvalidTypeException(
        value: this!,
        targetType: double,
        cause: e.message,
      );
    }
  }

  /// Decodes a string to a nullable double.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid double.
  double? decodeSimpleNullableDouble() {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleDouble();
  }

  /// Decodes a string to a boolean.
  ///
  /// Only accepts 'true' or 'false' (case-sensitive).
  /// Throws [InvalidTypeException] if the string is not a valid boolean
  /// or if the value is null.
  bool decodeSimpleBool() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: bool,
        cause: 'Value is null',
      );
    }
    if (this == 'true') return true;
    if (this == 'false') return false;
    throw InvalidTypeException(
      value: this!,
      targetType: bool,
      cause: 'Expected "true" or "false"',
    );
  }

  /// Decodes a string to a nullable boolean.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid boolean.
  bool? decodeSimpleNullableBool() {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleBool();
  }

  /// Decodes a string to a DateTime.
  ///
  /// Expects ISO 8601 format.
  /// Throws [InvalidTypeException] if the string is not a valid date
  /// or if the value is null.
  DateTime decodeSimpleDateTime() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: DateTime,
        cause: 'Value is null',
      );
    }
    try {
      return DateTime.parse(this!);
    } on FormatException catch (e) {
      throw InvalidTypeException(
        value: this!,
        targetType: DateTime,
        cause: e.message,
      );
    }
  }

  /// Decodes a string to a nullable DateTime.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid date.
  DateTime? decodeSimpleNullableDateTime() {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleDateTime();
  }

  /// Decodes a string to a BigDecimal.
  ///
  /// Throws [InvalidTypeException] if the string is not a valid decimal
  /// or if the value is null.
  BigDecimal decodeSimpleBigDecimal() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: BigDecimal,
        cause: 'Value is null',
      );
    }
    try {
      return BigDecimal.parse(this!);
    } on Object catch (_) {
      throw InvalidTypeException(
        value: this!,
        targetType: BigDecimal,
        cause: 'Not a valid decimal',
      );
    }
  }

  /// Decodes a string to a nullable BigDecimal.
  ///
  /// Returns null if the string is empty or null.
  /// Throws [InvalidTypeException] if the string is not a valid decimal.
  BigDecimal? decodeSimpleNullableBigDecimal() {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleBigDecimal();
  }

  /// Decodes a string to a list of strings.
  ///
  /// Splits the string by commas.
  /// Empty string returns an empty list.
  /// Throws [InvalidTypeException] if the value is null.
  List<String> decodeSimpleStringList() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: List<String>,
        cause: 'Value is null',
      );
    }
    if (this!.isEmpty) return [];
    return this!.split(',').map((s) => s.decodeSimpleString()).toList();
  }

  /// Decodes a string to a nullable list of strings.
  ///
  /// Returns null if the string is empty or null.
  /// Otherwise splits the string by commas.
  List<String>? decodeSimpleNullableStringList() {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleStringList();
  }

  /// Decodes a string to a list of nullable strings.
  ///
  /// Splits the string by commas.
  /// Empty elements in the list are converted to null.
  /// Empty string returns an empty list.
  /// Throws [InvalidTypeException] if the value is null.
  List<String?> decodeSimpleStringNullableList() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: List<String?>,
        cause: 'Value is null',
      );
    }
    if (this!.isEmpty) return [];
    return this!.split(',').map((s) => s.decodeSimpleNullableString()).toList();
  }

  /// Decodes a string to a nullable list of nullable strings.
  ///
  /// Returns null if the string is empty or null.
  /// Otherwise splits the string by commas and converts empty elements to null.
  List<String?>? decodeSimpleNullableStringNullableList() {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleStringNullableList();
  }

  /// Decodes a string to a set of strings.
  ///
  /// Splits the string by commas.
  /// Empty string returns an empty set.
  /// Throws [InvalidTypeException] if the value is null.
  Set<String> decodeSimpleStringSet() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: Set<String>,
        cause: 'Value is null',
      );
    }
    if (this!.isEmpty) return {};
    return this!.split(',').map((s) => s.decodeSimpleString()).toSet();
  }

  /// Decodes a string to a nullable set of strings.
  ///
  /// Returns null if the string is empty or null.
  /// Otherwise splits the string by commas.
  Set<String>? decodeSimpleNullableStringSet() {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleStringSet();
  }

  /// Decodes a string to a set of nullable strings.
  ///
  /// Splits the string by commas.
  /// Empty elements in the set are converted to null.
  /// Empty string returns an empty set.
  /// Throws [InvalidTypeException] if the value is null.
  Set<String?> decodeSimpleStringNullableSet() {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: Set<String?>,
        cause: 'Value is null',
      );
    }
    if (this!.isEmpty) return {};
    return this!.split(',').map((s) => s.decodeSimpleNullableString()).toSet();
  }

  /// Decodes a string to a nullable set of nullable strings.
  ///
  /// Returns null if the string is empty or null.
  /// Otherwise splits the string by commas and converts empty elements to null.
  Set<String?>? decodeSimpleNullableStringNullableSet() {
    if (this?.isEmpty ?? true) return null;
    return decodeSimpleStringNullableSet();
  }
}
