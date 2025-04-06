import 'package:tonic_util/src/encoding/base_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';

/// An encoder for OpenAPI's "matrix" style parameters.
///
/// Matrix style parameters are appended to path segments using the format
/// `;paramName=paramValue`.
///
/// When 'explode' is false (default for matrix style), collections are
/// comma-separated: `;colors=red,green,blue`.
///
/// When 'explode' is true, each value gets its own parameter instance:
/// `;colors=red;colors=green;colors=blue`.
///
/// According to the OpenAPI spec, matrix style should only be used with
/// path parameters.
class MatrixEncoder extends BaseEncoder {
  /// Creates a new [MatrixEncoder].
  const MatrixEncoder();

  /// Encodes a parameter with the given name and value according to the
  /// matrix style.
  ///
  /// When [explode] is true, array items and object properties are
  /// separately encoded. When false, they are encoded as a single string with
  /// delimiters (typically comma).
  ///
  /// Throws an [UnsupportedEncodingTypeException] if the value type is not
  /// supported by this encoder.
  String encode(String paramName, dynamic value, {bool explode = false}) {
    checkSupportedType(value);

    if (value == null) {
      return ';$paramName';
    }

    if (value is Iterable) {
      if (explode) {
        if (value.isEmpty) {
          return '';
        }

        return value
            .map((item) => ';$paramName=${encodeValue(valueToString(item))}')
            .join();
      } else {
        // With explode=false (default), comma-separate the values
        final encodedValues = value
            .map((item) => encodeValue(valueToString(item)))
            .join(',');
        return ';$paramName=$encodedValues';
      }
    }

    if (value is Map<String, dynamic>) {
      if (value.isEmpty) {
        return ';$paramName=';
      }

      if (explode) {
        // With explode=true, each property gets its own parameter instance
        // using dot notation: ;point.x=1;point.y=2
        return value.entries
            .map(
              (entry) =>
                  ';$paramName.${entry.key}='
                  '${encodeValue(valueToString(entry.value))}',
            )
            .join();
      } else {
        // With explode=false, properties are
        // comma-separated pairs: ;point=x,1,y,2
        final encodedPairs = value.entries
            .expand(
              (entry) => [entry.key, encodeValue(valueToString(entry.value))],
            )
            .join(',');
        return ';$paramName=$encodedPairs';
      }
    }

    return ';$paramName=${encodeValue(valueToString(value))}';
  }
}
