import 'package:meta/meta.dart';
import 'package:tonic_util/src/encoding/base_encoder.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';
import 'package:tonic_util/src/encoding/parameter_entry.dart';

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
  /// Throws an [UnsupportedEncodingTypeException] if the value type is not
  /// supported by this encoder or if the value is not a Map.
  List<ParameterEntry> encode(
    String paramName,
    dynamic value, {
    required bool allowEmpty,
  }) {
    checkSupportedType(value);

    if (value == null || (value as Map<String, dynamic>).isEmpty) {
      if (!allowEmpty) {
        throw const EmptyValueException();
      }
      return [(name: paramName, value: '')];
    }

    return _encodeMap(paramName, value, allowEmpty: allowEmpty);
  }

  /// Internal method to encode a Map according to deepObject style.
  List<ParameterEntry> _encodeMap(
    String path,
    Map<String, dynamic> map, {
    required bool allowEmpty,
  }) {
    final result = <ParameterEntry>[];

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) {
        result.add((name: '$path[$key]', value: ''));
      } else if (value is Map<String, dynamic>) {
        if (!allowEmpty && value.isEmpty) {
          throw const EmptyValueException();
        }
        if (value.isEmpty) {
          result.add((name: '$path[$key]', value: ''));
        } else {
          // Handle nested maps by recursively encoding them
          result.addAll(
            _encodeMap('$path[$key]', value, allowEmpty: allowEmpty),
          );
        }
      } else if (value is List || value is Set) {
        throw UnsupportedEncodingTypeException(valueType: value.runtimeType);
      } else if (value is String && !allowEmpty && value.isEmpty) {
        throw const EmptyValueException();
      } else {
        final encodedValue = encodeValue(
          valueToString(value),
          useQueryEncoding: true,
        );
        result.add((name: '$path[$key]', value: encodedValue));
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

        if (val == null || val is String || val is num || val is bool) {
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
    return value.toString();
  }
}
