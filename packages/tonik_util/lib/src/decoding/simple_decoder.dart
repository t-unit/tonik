import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';

/// Extensions for decoding simple form values from strings.
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
    return Uri.decodeComponent(this!);
  }

  /// Decodes a string to a nullable string.
  ///
  /// Returns null if the string is empty or null.
  String? decodeSimpleNullableString({String? context}) {
    if (this?.isEmpty ?? true) return null;

    try {
      return Uri.decodeComponent(this!);
    } on Object {
      throw InvalidTypeException(
        value: this!,
        targetType: String,
        context: context,
      );
    }
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

  /// Decodes a string to a DateTime.
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
      return DateTime.parse(this!);
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
}
