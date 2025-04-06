import 'package:big_decimal/big_decimal.dart';
import 'package:meta/meta.dart';
import 'package:tonic_util/src/encoding/base_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';

/// An encoder for OpenAPI's "deepObject" style parameters.
///
/// DeepObject style is used for query parameters with complex object values
/// that need to maintain their structure. It applies square brackets notation
/// to parameter names to indicate nested objects:
///
/// - Objects: `paramName[propA]=valueA&paramName[propB]=valueB`
/// - Nested objects: `paramName[propA][subPropA]=value`
/// - Arrays in objects: `paramName[propA][]=value1&paramName[propA][]=value2`
///
/// This encoder is designed to handle the value part of a parameter, not the
/// complete query string. The parameter name and its combination with values
/// is typically handled at a higher level.
///
/// According to the OpenAPI spec, deepObject style should only be used with
/// query parameters for object values. The behavior for nested objects and
/// arrays is undefined by the specification.
///
/// This implementation throws an UnsupportedEncodingTypeException when arrays
/// are encountered, as arrays are not explicitly supported by the deepObject
/// style.
class DeepObjectEncoder extends BaseEncoder {
  /// Creates a new [DeepObjectEncoder].
  const DeepObjectEncoder();

  /// Encodes a parameter with the given name according to the deepObject style.
  ///
  /// The [paramName] is required as deepObject encoding includes the parameter
  /// name in the encoded result.
  ///
  /// Note: Unlike other encoders, the [explode] parameter is ignored as
  /// deepObject style always uses the exploded form.
  ///
  /// Throws an [UnsupportedEncodingTypeException] if the value type is not
  /// supported by this encoder or if the value is not a Map.
  Map<String, String> encode(
    String paramName,
    dynamic value, {
    bool explode = true,
  }) {
    // DeepObject style only works with objects (Maps)
    if (value is! Map<String, dynamic>) {
      throw UnsupportedEncodingTypeException(
        valueType: value?.runtimeType ?? Null,
      );
    }

    checkSupportedType(value);

    if (value.isEmpty) {
      return {};
    }

    return _encodeMap(paramName, value);
  }

  /// Internal method to encode a Map according to deepObject style.
  Map<String, String> _encodeMap(String path, Map<String, dynamic> map) {
    final result = <String, String>{};

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) {
        result['$path[$key]'] = '';
      } else if (value is Map<String, dynamic>) {
        // Handle nested maps by recursively encoding them
        result.addAll(_encodeMap('$path[$key]', value));
      } else if (value is List || value is Set) {
        // Arrays are not supported in deepObject style
        throw UnsupportedEncodingTypeException(valueType: value.runtimeType);
      } else if (value is DateTime) {
        // Handle DateTime values without URL encoding
        result['$path[$key]'] = valueToString(value);
      } else {
        // Handle primitive values
        final encodedValue = encodeValue(
          valueToString(value),
          useQueryEncoding: true,
        );
        result['$path[$key]'] = encodedValue;
      }
    }

    return result;
  }

  /// Checks if the given value is of a supported type and throws an
  /// [UnsupportedEncodingTypeException] if it's not.
  @override
  @protected
  void checkSupportedType(dynamic value, {bool supportMaps = true}) {
    if (value == null) {
      return;
    }

    if (value is Map<String, dynamic>) {
      if (value.isEmpty) {
        return;
      }

      // Check each value in the map
      for (final entry in value.entries) {
        final val = entry.value;

        if (val == null ||
            val is String ||
            val is num ||
            val is bool ||
            val is BigDecimal ||
            val is Uri ||
            val is DateTime) {
          continue;
        }

        if (val is Map<String, dynamic>) {
          // Recursively check nested maps
          checkSupportedType(val);
          continue;
        }

        if (val is List || val is Set) {
          // Arrays are not supported in deepObject style
          throw UnsupportedEncodingTypeException(valueType: val.runtimeType);
        }

        throw UnsupportedEncodingTypeException(valueType: val.runtimeType);
      }

      return;
    }

    throw UnsupportedEncodingTypeException(valueType: value.runtimeType);
  }

  /// Converts a value to its string representation.
  @override
  @protected
  String valueToString(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    return value.toString();
  }
}
