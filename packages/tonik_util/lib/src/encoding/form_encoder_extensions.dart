import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

/// Extensions for encoding values using form style parameter encoding.
///
/// Form encoding always produces a list of [ParameterEntry] (`name=value`
/// pairs). Callers join them with the separator for their context — `&` for
/// query strings and urlencoded bodies, `; ` for cookies.
/// - Primitives: a single entry `(paramName, value)`.
/// - Arrays (explode=false): `(paramName, value1,value2,value3)`.
/// - Arrays (explode=true): one entry per item, each named `paramName`.
/// - Objects (explode=false): `(paramName, key1,value1,key2,value2)`.
/// - Objects (explode=true): one entry per property, keyed by the bare key.

String _encodeValue(String value, {required bool useQueryComponent}) =>
    useQueryComponent
        ? Uri.encodeQueryComponent(value)
        : Uri.encodeComponent(value);

/// Extension for encoding Uri values.
extension FormUriEncoder on Uri {
  /// Encodes this Uri value using form style parameter encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      ),
    ),
  ];
}

/// Extension for encoding String values.
extension FormStringEncoder on String {
  /// Encodes this string value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      ),
    ),
  ];
}

/// Extension for encoding int values.
extension FormIntEncoder on int {
  /// Encodes this int value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      ),
    ),
  ];
}

/// Extension for encoding double values.
extension FormDoubleEncoder on double {
  /// Encodes this double value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      ),
    ),
  ];
}

/// Extension for encoding num values.
extension FormNumEncoder on num {
  /// Encodes this num value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      ),
    ),
  ];
}

/// Extension for encoding bool values.
extension FormBoolEncoder on bool {
  /// Encodes this bool value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      ),
    ),
  ];
}

/// Extension for encoding DateTime values.
extension FormDateTimeEncoder on DateTime {
  /// Encodes this DateTime value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      ),
    ),
  ];
}

/// Extension for encoding BigDecimal values.
extension FormBigDecimalEncoder on BigDecimal {
  /// Encodes this BigDecimal value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      ),
    ),
  ];
}

/// Extension for encoding List values.
extension FormStringListEncoder on List<String> {
  /// Encodes this List value using form style encoding.
  ///
  /// - explode=false: a single comma-separated entry named [paramName].
  /// - explode=true: one entry per item, each named [paramName].
  ///
  /// The [allowEmpty] parameter controls whether empty lists are allowed:
  /// empty lists with explode=false yield a single empty-value entry, with
  /// explode=true yield no entries, and throw when [allowEmpty] is false.
  ///
  /// The [alreadyEncoded] parameter indicates whether the items are already
  /// URI-encoded and should not be encoded again.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool useQueryComponent = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (!explode) {
      return [
        (
          name: paramName,
          value: uriEncode(
            allowEmpty: allowEmpty,
            alreadyEncoded: alreadyEncoded,
            useQueryComponent: useQueryComponent,
          ),
        ),
      ];
    }

    return [
      for (final item in this)
        (
          name: paramName,
          value: alreadyEncoded
              ? item
              : _encodeValue(item, useQueryComponent: useQueryComponent),
        ),
    ];
  }
}

/// Extension for encoding Map values.
extension FormStringMapEncoder on Map<String, String> {
  /// Encodes this Map value using form style encoding.
  ///
  /// - explode=false: a single entry named [paramName] holding the
  ///   comma-separated `key1,value1,key2,value2` rendering.
  /// - explode=true: one entry per property, keyed by the (URL-encoded) key.
  ///
  /// The [allowEmpty] parameter controls whether empty maps are allowed:
  /// empty maps with explode=false yield a single empty-value entry, with
  /// explode=true yield no entries, and throw when [allowEmpty] is false.
  ///
  /// The [alreadyEncoded] parameter indicates whether the values are already
  /// URL-encoded. When `true`, values are not re-encoded to prevent double
  /// encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool useQueryComponent = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (!explode) {
      return [
        (
          name: paramName,
          value: uriEncode(
            allowEmpty: allowEmpty,
            alreadyEncoded: alreadyEncoded,
            encodeKeys: false,
            useQueryComponent: useQueryComponent,
          ),
        ),
      ];
    }

    return [
      for (final e in entries)
        (
          name: _encodeValue(e.key, useQueryComponent: useQueryComponent),
          value: alreadyEncoded
              ? e.value
              : _encodeValue(e.value, useQueryComponent: useQueryComponent),
        ),
    ];
  }
}

/// Extension for encoding binary data (`List<int>`).
extension FormBinaryEncoder on List<int> {
  /// Encodes binary data to a single UTF-8 string entry using form style.
  ///
  /// The [explode] parameter is accepted for consistency but has no effect
  /// on binary encoding (binary data is treated as a primitive value).
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
      ),
    ),
  ];
}
