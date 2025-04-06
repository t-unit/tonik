import 'package:tonic_util/src/encoding/base_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';

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
  /// Throws an [UnsupportedEncodingTypeException] if the value type is not
  /// supported by this encoder.
  String encode(dynamic value, {bool explode = false}) {
    checkSupportedType(value);

    if (value == null) {
      return '.';
    }

    if (value is Iterable) {
      if (explode) {
        // With explode=true, each value gets its own dot prefix
        // Handle empty collections
        if (value.isEmpty) {
          return '';
        }

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
      if (value.isEmpty) {
        return '.';
      }

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
