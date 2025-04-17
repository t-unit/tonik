import 'package:tonik_util/src/encoding/base_encoder.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';

/// An encoder for OpenAPI's "label" style parameters.
///
/// Label style parameters are prefixed with a dot and typically used with
/// path parameters: `.paramValue`.
///
/// When 'explode' is false (default for label style), collections are
/// comma-separated: `.red,green,blue`.
///
/// When 'explode' is true, each value gets its own label:
/// `.red.green.blue`.
///
/// According to the OpenAPI spec, label style should only be used with
/// path parameters.
class LabelEncoder extends BaseEncoder {
  /// Creates a new [LabelEncoder].
  const LabelEncoder();

  /// Encodes a value according to the label style.
  ///
  /// When [explode] is true, array items and object properties are
  /// separately encoded. When false, they are encoded as a single string with
  /// delimiters (typically comma).
  ///
  /// The [allowEmpty] parameter controls whether empty values are allowed:
  /// - When `true`, empty values (null, empty strings, empty collections)
  ///   are encoded as empty strings
  /// - When `false`, empty values throw an [EmptyValueException]
  ///
  /// Throws an [UnsupportedEncodingTypeException] if the value type is not
  /// supported by this encoder.
  String encode(
    dynamic value, {
    required bool explode,
    required bool allowEmpty,
  }) {
    checkSupportedType(value);

    if (value == null ||
        (value is String && value.isEmpty) ||
        (value is Iterable && value.isEmpty) ||
        (value is Map && value.isEmpty)) {
      if (!allowEmpty) {
        throw const EmptyValueException();
      }
      return '.';
    }

    if (value is Iterable) {
      if (explode) {
        // With explode=true, each value gets its own dot prefix
        return value
            .map((item) => '.${encodeValue(valueToString(item))}')
            .join();
      } else {
        // With explode=false (default), comma-separate the values
        final encodedValues = value
            .map((item) => encodeValue(valueToString(item)))
            .join(',');
        return '.$encodedValues';
      }
    }

    if (value is Map<String, dynamic>) {
      if (explode) {
        // With explode=true, each property gets encoded as .key=value
        return value.entries
            .map(
              (entry) =>
                  '.${entry.key}=${encodeValue(valueToString(entry.value))}',
            )
            .join();
      } else {
        // With explode=false, properties are comma-separated pairs
        final encodedPairs = value.entries
            .expand(
              (entry) => [entry.key, encodeValue(valueToString(entry.value))],
            )
            .join(',');
        return '.$encodedPairs';
      }
    }

    return '.${encodeValue(valueToString(value))}';
  }
}
