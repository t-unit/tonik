import 'package:tonic_util/src/encoding/base_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';
import 'package:tonic_util/src/encoding/parameter_entry.dart';

/// An encoder for OpenAPI's "form" style parameters.
///
/// Form style is the default style for query parameters and is commonly used
/// in URL query strings:
/// - Primitives: name=value
/// - Arrays (explode=false): name=value1,value2,value3
/// - Arrays (explode=true): name=value1&name=value2&name=value3
/// - Objects (explode=false): name=key1,value1,key2,value2
/// - Objects (explode=true): key1=value1&key2=value2
///
/// This encoder handles both the name and value parts of parameters.
class FormEncoder extends BaseEncoder {
  /// Creates a new [FormEncoder].
  const FormEncoder();

  /// Encodes a value according to the form style.
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
  List<ParameterEntry> encode(
    String paramName,
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
      return [(name: paramName, value: '')];
    }

    if (value is Iterable) {
      final values = value.map(
        (item) => encodeValue(valueToString(item), useQueryEncoding: true),
      );

      if (explode) {
        return values.map((v) => (name: paramName, value: v)).toList();
      } else {
        return [(name: paramName, value: values.join(','))];
      }
    }

    if (value is Map<String, dynamic>) {
      if (explode) {
        // With explode=true, each property becomes a separate name=value pair
        return value.entries
            .map(
              (entry) => (
                name: entry.key,
                value: encodeValue(
                  valueToString(entry.value),
                  useQueryEncoding: true,
                ),
              ),
            )
            .toList();
      } else {
        // With explode=false, keys and values are comma-separated
        return [
          (
            name: paramName,
            value: value.entries
                .expand(
                  (entry) => [
                    entry.key,
                    encodeValue(
                      valueToString(entry.value),
                      useQueryEncoding: true,
                    ),
                  ],
                )
                .join(','),
          ),
        ];
      }
    }

    return [
      (
        name: paramName,
        value: encodeValue(valueToString(value), useQueryEncoding: true),
      ),
    ];
  }
}
