import 'package:tonic_util/src/encoding/base_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';

/// An encoder for OpenAPI's "simple" style parameters.
///
/// Simple style provides a simple encoding:
/// - Primitives: The parameter value without formatting
/// - Arrays (explode=false): Comma-separated values
/// - Arrays (explode=true): Multiple parameter instances
///   (not directly supported)
/// - Objects (explode=false): Comma-separated key,value pairs
/// - Objects (explode=true): Comma-separated key=value pairs
///
/// Simple style is the default for path parameters.
class SimpleEncoder extends BaseEncoder {
  /// Creates a new [SimpleEncoder].
  const SimpleEncoder();

  /// Encodes a value according to the simple style.
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
      return '';
    }

    if (value is Iterable) {
      if (explode) {
        // With explode=true, we'd need multiple parameter instances,
        // but since SimpleEncoder only encodes the value part
        // (not the full parameter), we'll use comma-separated values
        // as a fallback
        return value.map((item) => encodeValue(valueToString(item))).join(',');
      } else {
        // With explode=false, comma-separate the values
        return value.map((item) => encodeValue(valueToString(item))).join(',');
      }
    }

    if (value is Map<String, dynamic>) {
      if (explode) {
        // With explode=true, key=value pairs are comma-separated
        return value.entries
            .map(
              (entry) =>
                  '${entry.key}=${encodeValue(valueToString(entry.value))}',
            )
            .join(',');
      } else {
        // With explode=false, keys and values are comma-separated
        return value.entries
            .expand(
              (entry) => [entry.key, encodeValue(valueToString(entry.value))],
            )
            .join(',');
      }
    }

    return encodeValue(valueToString(value));
  }
}
