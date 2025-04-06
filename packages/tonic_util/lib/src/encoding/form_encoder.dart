import 'package:big_decimal/big_decimal.dart';
import 'package:meta/meta.dart';
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
class FormEncoder {
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
          .map((item) => _encodeValue(valueToString(item)))
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
                  '${entry.key}=${_encodeValue(valueToString(entry.value))}',
            )
            .join(',');
      } else {
        // With explode=false, keys and values are comma-separated
        return value.entries
            .expand(
              (entry) => [entry.key, _encodeValue(valueToString(entry.value))],
            )
            .join(',');
      }
    }

    return _encodeValue(valueToString(value));
  }

  /// Checks if the given value is of a supported type and throws an
  /// [UnsupportedEncodingTypeException] if it's not.
  @protected
  void checkSupportedType(dynamic value) {
    if (value == null ||
        value is String ||
        value is num ||
        value is bool ||
        value is BigDecimal ||
        value is Uri ||
        value is DateTime) {
      return;
    }

    if (value is List || value is Set) {
      final iterable = value as Iterable;
      if (iterable.isEmpty) {
        return;
      }

      final hasUnsupportedElement = iterable.any((element) {
        return element is! String &&
            element is! num &&
            element is! bool &&
            element is! BigDecimal &&
            element is! Uri &&
            element is! DateTime;
      });

      if (hasUnsupportedElement) {
        throw UnsupportedEncodingTypeException(
          valueType: value.runtimeType,
        );
      }

      final hasNestedCollection = iterable.any((element) {
        return element is Iterable || element is Map;
      });

      if (hasNestedCollection) {
        throw UnsupportedEncodingTypeException(
          valueType: value.runtimeType,
        );
      }

      return;
    }

    if (value is Map<String, dynamic>) {
      if (value.isEmpty) {
        return;
      }

      final hasComplexValue = value.values.any((val) {
        return val is Iterable || val is Map;
      });
      
      if (hasComplexValue) {
        throw UnsupportedEncodingTypeException(
          valueType: value.runtimeType,
        );
      }
      
      final hasUnsupportedValue = value.values.any((val) {
        return val is! String &&
               val is! num &&
               val is! bool &&
               val is! BigDecimal &&
               val is! Uri &&
               val is! DateTime &&
               val != null;
      });
      
      if (hasUnsupportedValue) {
        throw UnsupportedEncodingTypeException(
          valueType: value.runtimeType,
        );
      }
      
      return;
    }

    throw UnsupportedEncodingTypeException(
      valueType: value.runtimeType,
    );
  }

  /// Converts a value to its string representation.
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

  /// Percent-encodes a string value according to RFC 3986.
  String _encodeValue(String value) {
    if (value.isEmpty) {
      return value;
    }
    return Uri.encodeQueryComponent(value);
  }
} 
