import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/binary_extensions.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

/// Extensions for encoding values using form style parameter encoding.
///
/// Form style is the default for query parameters and follows RFC 6570 URI
/// encoding rules:
/// - Primitives: value
/// - Arrays (explode=false): value1,value2,value3
/// - Arrays (explode=true): value1&value2&value3 (handled at parameter level)
/// - Objects (explode=false): key1,value1,key2,value2
/// - Objects (explode=true): key1=value1&key2=value2 (handled at parameter
///   level)

/// Extension for encoding Uri values.
extension FormUriEncoder on Uri {
  /// Encodes this Uri value using form style parameter encoding.
  ///
  /// URI values are always URL-encoded regardless of explode setting.
  /// Uses query component encoding for consistency with form style.
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
}

/// Extension for encoding String values.
extension FormStringEncoder on String {
  /// Encodes this string value using form style encoding.
  ///
  /// String values are URL-encoded per RFC 6570. Empty strings are handled
  /// based on allowEmpty.
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
}

/// Extension for encoding int values.
extension FormIntEncoder on int {
  /// Encodes this int value using form style encoding.
  ///
  /// Integer values are converted to string representation.
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
}

/// Extension for encoding double values.
extension FormDoubleEncoder on double {
  /// Encodes this double value using form style encoding.
  ///
  /// Double values are converted to string representation.
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
}

/// Extension for encoding num values.
extension FormNumEncoder on num {
  /// Encodes this num value using form style encoding.
  ///
  /// Numeric values are converted to string representation.
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
}

/// Extension for encoding bool values.
extension FormBoolEncoder on bool {
  /// Encodes this bool value using form style encoding.
  ///
  /// Boolean values are converted to 'true' or 'false' strings.
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
}

/// Extension for encoding DateTime values.
extension FormDateTimeEncoder on DateTime {
  /// Encodes this DateTime value using form style encoding.
  ///
  /// DateTime values are converted to URL-encoded ISO 8601 strings
  /// per RFC 6570.
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
}

/// Extension for encoding BigDecimal values.
extension FormBigDecimalEncoder on BigDecimal {
  /// Encodes this BigDecimal value using form style encoding.
  ///
  /// BigDecimal values are converted to string representation.
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) => uriEncode(allowEmpty: allowEmpty, useQueryComponent: useQueryComponent);
}

/// Extension for encoding List values.
extension FormStringListEncoder on List<String> {
  /// Encodes this List value using form style encoding.
  ///
  /// According to OpenAPI spec for form style:
  /// - explode=false: comma-separated values (value1,value2,value3)
  /// - explode=true: multiple parameter instances (handled at parameter level)
  ///
  /// Note: When explode=true, the parameter name is repeated for each value,
  /// which is handled by the parameter encoder, not this extension.
  ///
  /// The [allowEmpty] parameter controls whether empty lists are allowed:
  /// - When `true`, empty lists are encoded as empty strings
  /// - When `false`, empty lists throw an exception
  ///
  /// The [alreadyEncoded] parameter indicates whether the list items are
  /// already URI-encoded and should not be encoded again.
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool useQueryComponent = false,
  }) => uriEncode(
    allowEmpty: allowEmpty,
    alreadyEncoded: alreadyEncoded,
    useQueryComponent: useQueryComponent,
  );
}

/// Extension for encoding Map values.
extension FormStringMapEncoder on Map<String, String> {
  /// Encodes this Map value using form style encoding.
  ///
  /// According to OpenAPI spec for form style objects:
  /// - explode=false: comma-separated key,value pairs
  ///   (key1,value1,key2,value2)
  /// - explode=true: separate parameters for each key (handled at parameter
  ///   level)
  ///
  /// Note: When explode=true, each key becomes a separate parameter,
  /// which is handled by the parameter encoder, not this extension.
  ///
  /// The [allowEmpty] parameter controls whether empty maps are allowed:
  /// - When `true`, empty maps are encoded as empty strings
  /// - When `false`, empty maps throw an exception
  ///
  /// The [alreadyEncoded] parameter indicates whether the values are already
  /// URL-encoded. When `true`, values are not re-encoded to prevent double
  /// encoding.
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool useQueryComponent = false,
  }) {
    if (explode) {
      // explode=true: This should be handled at parameter level,
      // but for completeness, return key=value format
      if (isEmpty && !allowEmpty) {
        throw const EmptyValueException();
      }
      if (isEmpty) {
        return '';
      }
      return entries
          .map(
            (e) {
              final value = alreadyEncoded
                  ? e.value
                  : e.value.toForm(
                      explode: explode,
                      allowEmpty: allowEmpty,
                      useQueryComponent: useQueryComponent,
                    );
              return '${e.key.toForm(
                explode: explode,
                allowEmpty: allowEmpty,
                useQueryComponent: useQueryComponent,
              )}=$value';
            },
          )
          .join('&');
    } else {
      // explode=false: use uriEncode for key,value pairs (don't encode keys)
      return uriEncode(
        allowEmpty: allowEmpty,
        alreadyEncoded: alreadyEncoded,
        encodeKeys: false,
        useQueryComponent: useQueryComponent,
      );
    }
  }
}

/// Extension for encoding binary data (`List<int>`).
extension FormBinaryEncoder on List<int> {
  /// Encodes binary data to a UTF-8 string using form style encoding.
  ///
  /// Uses Utf8Decoder with allowMalformed: true to handle any byte sequence.
  /// The resulting string is then URL-encoded for safe transport.
  ///
  /// The [explode] parameter is accepted for consistency but has no effect
  /// on binary encoding (binary data is treated as a primitive value).
  ///
  /// The [allowEmpty] parameter controls whether empty lists are allowed:
  /// - When `true`, empty lists are encoded as empty strings
  /// - When `false`, empty lists throw an exception
  String toForm({
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return '';
    }
    final str = decodeToString();
    return useQueryComponent
        ? Uri.encodeQueryComponent(str)
        : Uri.encodeComponent(str);
  }
}
