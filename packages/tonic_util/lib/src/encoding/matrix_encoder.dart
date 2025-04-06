import 'package:big_decimal/big_decimal.dart';
import 'package:meta/meta.dart';
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
class MatrixEncoder {
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
            .map((item) => ';$paramName=${_encodeValue(valueToString(item))}')
            .join();
      } else {
        // With explode=false (default), comma-separate the values
        final encodedValues = value
            .map((item) => _encodeValue(valueToString(item)))
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
                  '${_encodeValue(valueToString(entry.value))}',
            )
            .join();
      } else {
        // With explode=false, properties are 
        // comma-separated pairs: ;point=x,1,y,2
        final encodedPairs = value.entries
            .expand(
              (entry) => [entry.key, _encodeValue(valueToString(entry.value))],
            )
            .join(',');
        return ';$paramName=$encodedPairs';
      }
    }

    return ';$paramName=${_encodeValue(valueToString(value))}';
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
    return Uri.encodeComponent(value);
  }
}
