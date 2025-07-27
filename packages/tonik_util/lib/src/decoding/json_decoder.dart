import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/date.dart';
import 'package:tonik_util/src/decoding/decoding_exception.dart';
import 'package:tonik_util/src/offset_date_time.dart';

/// Extensions for decoding JSON values.
extension JsonDecoder on Object? {
  /// Decodes a JSON value to a DateTime with timezone awareness.
  ///
  /// Expects ISO 8601 format string.
  /// Throws [InvalidTypeException] if the value is not a valid date string
  /// or if the value is null.
  DateTime decodeJsonDateTime({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: DateTime,
        context: context,
      );
    }
    if (this is! String) {
      throw InvalidTypeException(
        value: toString(),
        targetType: DateTime,
        context: context,
      );
    }
    try {
      return OffsetDateTime.parse(this! as String);
    } on FormatException catch (e) {
      throw InvalidTypeException(
        value: this! as String,
        targetType: DateTime,
        context: e.message,
      );
    }
  }

  /// Decodes a JSON value to a nullable DateTime.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid date string.
  DateTime? decodeJsonNullableDateTime({String? context}) {
    if (this == null || (this is String && (this! as String).isEmpty)) {
      return null;
    }
    return decodeJsonDateTime(context: context);
  }

  /// Decodes a JSON value to a BigDecimal.
  ///
  /// Throws [InvalidTypeException] if the value is not a valid decimal string
  /// or if the value is null.
  BigDecimal decodeJsonBigDecimal({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: BigDecimal,
        context: context,
      );
    }
    if (this is! String) {
      throw InvalidTypeException(
        value: toString(),
        targetType: BigDecimal,
        context: context,
      );
    }
    try {
      return BigDecimal.parse(this! as String);
    } on Object catch (_) {
      throw InvalidTypeException(
        value: this! as String,
        targetType: BigDecimal,
        context: context,
      );
    }
  }

  /// Decodes a JSON value to a nullable BigDecimal.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid decimal string.
  BigDecimal? decodeJsonNullableBigDecimal({String? context}) {
    if (this == null || (this is String && (this! as String).isEmpty)) {
      return null;
    }
    return decodeJsonBigDecimal(context: context);
  }

  /// Decodes a JSON value to a String.
  ///
  /// Throws [InvalidTypeException] if the value is not a valid string
  /// or is null.
  String decodeJsonString({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: String,
        context: context,
      );
    }
    if (this is! String) {
      throw InvalidTypeException(
        value: toString(),
        targetType: String,
        context: context,
      );
    }
    return this! as String;
  }

  /// Decodes a JSON value to a nullable String.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid string.
  String? decodeJsonNullableString({String? context}) {
    if (this == null) {
      return null;
    }
    if (this is! String) {
      throw InvalidTypeException(
        value: toString(),
        targetType: String,
        context: context,
      );
    }
    return this! as String;
  }

  /// Decodes a JSON value to an int.
  ///
  /// Throws [InvalidTypeException] if the value is not a valid int or is null.
  int decodeJsonInt({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: int,
        context: context,
      );
    }
    if (this is! int) {
      throw InvalidTypeException(
        value: toString(),
        targetType: int,
        context: context,
      );
    }
    return this! as int;
  }

  /// Decodes a JSON value to a nullable int.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid int.
  int? decodeJsonNullableInt({String? context}) {
    if (this == null) {
      return null;
    }
    if (this is! int) {
      throw InvalidTypeException(
        value: toString(),
        targetType: int,
        context: context,
      );
    }
    return this! as int;
  }

  /// Decodes a JSON value to a num.
  ///
  /// Throws [InvalidTypeException] if the value is not a valid num or is null.
  num decodeJsonNum({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: num,
        context: context,
      );
    }
    if (this is! num) {
      throw InvalidTypeException(
        value: toString(),
        targetType: num,
        context: context,
      );
    }
    return this! as num;
  }

  /// Decodes a JSON value to a nullable num.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid num.
  num? decodeJsonNullableNum({String? context}) {
    if (this == null) {
      return null;
    }
    if (this is! num) {
      throw InvalidTypeException(
        value: toString(),
        targetType: num,
        context: context,
      );
    }
    return this! as num;
  }

  /// Decodes a JSON value to a double.
  ///
  /// Throws [InvalidTypeException] if the value is not a valid double or
  /// is null.
  double decodeJsonDouble({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: double,
        context: context,
      );
    }
    if (this is! double) {
      throw InvalidTypeException(
        value: toString(),
        targetType: double,
        context: context,
      );
    }
    return this! as double;
  }

  /// Decodes a JSON value to a nullable double.
  ///
  /// Returns null if the value is null or an empty string.
  /// Throws [InvalidTypeException] if the value is not a valid double.
  double? decodeJsonNullableDouble({String? context}) {
    if (this == null) {
      return null;
    }
    if (this is! double) {
      throw InvalidTypeException(
        value: toString(),
        targetType: double,
        context: context,
      );
    }
    return this! as double;
  }

  /// Decodes a JSON value to a List of type [T].
  ///
  /// Throws [InvalidTypeException] if the value is not a list or is null.
  List<T> decodeJsonList<T>({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: List<T>,
        context: context,
      );
    }
    if (this is! List) {
      throw InvalidTypeException(
        value: toString(),
        targetType: List<T>,
        context: context,
      );
    }

    final list = this! as List;
    final mapped = list.whereType<T>();

    if (mapped.length != list.length) {
      throw InvalidTypeException(
        value: toString(),
        targetType: List<T>,
        context: context,
      );
    }

    return mapped.toList();
  }

  /// Decodes a JSON value to a nullable List of type [T].
  ///
  /// Returns null if the value is null or an empty list.
  /// Throws [InvalidTypeException] if the value is not a list of the
  /// expected type.
  List<T>? decodeJsonNullableList<T>({String? context}) {
    if (this == null) {
      return null;
    }
    return decodeJsonList<T>(context: context);
  }

  /// Decodes a JSON value to a Map.
  ///
  /// Throws [InvalidTypeException] if the value is not a map or is null.
  Map<String, Object?> decodeMap({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: Map<String, Object?>,
        context: context,
      );
    }
    if (this is! Map<String, Object?>) {
      throw InvalidTypeException(
        value: toString(),
        targetType: Map<String, Object?>,
        context: context,
      );
    }
    return this! as Map<String, Object?>;
  }

  /// Decodes a JSON value to a bool.
  ///
  /// Throws [InvalidTypeException] if the value is not a valid bool or is null.
  bool decodeJsonBool({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: bool,
        context: context,
      );
    }
    if (this is! bool) {
      throw InvalidTypeException(
        value: toString(),
        targetType: bool,
        context: context,
      );
    }
    return this! as bool;
  }

  /// Decodes a JSON value to a nullable bool.
  ///
  /// Returns null if the value is null.
  /// Throws [InvalidTypeException] if the value is not a valid bool.
  bool? decodeJsonNullableBool({String? context}) {
    if (this == null) {
      return null;
    }
    if (this is! bool) {
      throw InvalidTypeException(
        value: toString(),
        targetType: bool,
        context: context,
      );
    }
    return this! as bool;
  }

  /// Decodes a JSON value to a Date.
  ///
  /// Expects ISO 8601 format string (YYYY-MM-DD).
  /// Throws [InvalidTypeException] if the value is not a valid date string
  /// or if the value is null.
  Date decodeJsonDate({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: Date,
        context: context,
      );
    }
    if (this is! String) {
      throw InvalidTypeException(
        value: toString(),
        targetType: Date,
        context: context,
      );
    }
    try {
      return Date.fromString(this! as String);
    } on FormatException catch (e) {
      throw InvalidTypeException(
        value: this! as String,
        targetType: Date,
        context: e.message,
      );
    }
  }

  /// Decodes a JSON value to a nullable Date.
  ///
  /// Returns null if the value is null.
  /// Throws [InvalidTypeException] if the value is not a valid date string.
  Date? decodeJsonNullableDate({String? context}) {
    if (this == null) {
      return null;
    }
    return decodeJsonDate(context: context);
  }

  /// Decodes a JSON value to a Uri.
  ///
  /// Expects a valid URI string.
  /// Throws [InvalidTypeException] if the value is not a valid URI string
  /// or if the value is null.
  Uri decodeJsonUri({String? context}) {
    if (this == null) {
      throw InvalidTypeException(
        value: 'null',
        targetType: Uri,
        context: context,
      );
    }
    if (this is! String) {
      throw InvalidTypeException(
        value: toString(),
        targetType: Uri,
        context: context,
      );
    }
    try {
      return Uri.parse(this! as String);
    } on FormatException catch (e) {
      throw InvalidTypeException(
        value: this! as String,
        targetType: Uri,
        context: e.message,
      );
    }
  }

  /// Decodes a JSON value to a nullable Uri.
  ///
  /// Returns null if the value is null.
  /// Throws [InvalidTypeException] if the value is not a valid URI string.
  Uri? decodeJsonNullableUri({String? context}) {
    if (this == null) {
      return null;
    }
    return decodeJsonUri(context: context);
  }
}
