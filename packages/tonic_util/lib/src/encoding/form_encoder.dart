import 'package:tonic_util/src/encoding/base_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';

/// An encoder for OpenAPI's "form" style parameters.
///
/// Form style is the default style for query parameters and is commonly used
/// in URL query strings:
/// - Primitives: name=value
/// - Arrays (explode=false): name=value1,value2,value3
/// - Arrays (explode=true): name=value1&name=value2&name=value3
///   (not directly encoded)
/// - Objects (explode=false): name=key1,value1,key2,value2
/// - Objects (explode=true): key1=value1&key2=value2 (not directly encoded)
///
/// This encoder only encodes the value part, not the name=value combination,
/// as that's typically handled at a higher level.
class FormEncoder extends BaseEncoder {
  /// Creates a new [FormEncoder].
  const FormEncoder();

  /// Encodes a value according to the form style.
  ///
  /// When [explode] is true, array items and object properties are
  /// separately encoded. When false, they are encoded as a single string with
  /// delimiters (typically comma).
  ///
  /// Note: For arrays and objects with explode=true, this encoder only returns
  /// the value part. The full name=value combination for each item should be
  /// handled at a higher level.
  ///
  /// Throws an [UnsupportedEncodingTypeException] if the value type is not
  /// supported by this encoder.
  String encode(dynamic value, {bool explode = false}) {
    checkSupportedType(value);

    if (value == null) {
      return '';
    }

    if (value is Iterable) {
      if (value.isEmpty) {
        return '';
      }

      // For form style, explode=true normally means separate name=value pairs,
      // but this encoder only handles the value part. For consistency, we
      // return a comma-separated list just like with explode=false.
      return value
          .map(
            (item) => encodeValue(
              valueToString(item),
              useQueryEncoding: true,
            ),
          )
          .join(',');
    }

    if (value is Map<String, dynamic>) {
      if (value.isEmpty) {
        return '';
      }

      if (explode) {
        // With explode=true, the format would be key1=value1&key2=value2,
        // but this encoder only handles a single value, so we'll use
        // comma-separated key=value pairs as a fallback
        return value.entries
            .map(
              (entry) =>
                  '${entry.key}=${encodeValue(
                    valueToString(entry.value),
                    useQueryEncoding: true,
                  )}',
            )
            .join(',');
      } else {
        // With explode=false, keys and values are comma-separated
        return value.entries
            .expand(
              (entry) => [
                entry.key,
                encodeValue(
                  valueToString(entry.value),
                  useQueryEncoding: true,
                ),
              ],
            )
            .join(',');
      }
    }

    return encodeValue(
      valueToString(value),
      useQueryEncoding: true,
    );
  }
}
