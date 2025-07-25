import 'package:meta/meta.dart';
import 'package:tonik_util/tonik_util.dart';

/// Base class for OpenAPI parameter style encoders.
///
/// This abstract class provides common functionality used by all parameter
/// style encoders, such as type checking, value-to-string conversion,
/// and URI encoding.
abstract class BaseEncoder {
  /// Creates a new [BaseEncoder].
  const BaseEncoder();

  /// Checks if the given value is of a supported type and throws an
  /// [UnsupportedEncodingTypeException] if it's not.
  ///
  /// Set [supportMaps] to false to reject Map values (for encoders
  /// that don't support object encoding).
  @protected
  void checkSupportedType(dynamic value, {bool supportMaps = true}) {
    if (value == null ||
        value is String ||
        value is num ||
        value is bool ||
        value is Uri) {
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
            element is! Uri &&
            element != null;
      });

      if (hasUnsupportedElement) {
        throw UnsupportedEncodingTypeException(valueType: value.runtimeType);
      }

      final hasNestedCollection = iterable.any((element) {
        return element is Iterable || element is Map;
      });

      if (hasNestedCollection) {
        throw UnsupportedEncodingTypeException(valueType: value.runtimeType);
      }

      return;
    }

    if (supportMaps && value is Map<String, dynamic>) {
      if (value.isEmpty) {
        return;
      }

      final hasComplexValue = value.values.any((val) {
        return val is Iterable || val is Map;
      });

      if (hasComplexValue) {
        throw UnsupportedEncodingTypeException(valueType: value.runtimeType);
      }

      final hasUnsupportedValue = value.values.any((val) {
        return val is! String &&
            val is! num &&
            val is! bool &&
            val is! Uri &&
            val != null;
      });

      if (hasUnsupportedValue) {
        throw UnsupportedEncodingTypeException(valueType: value.runtimeType);
      }

      return;
    }

    throw UnsupportedEncodingTypeException(valueType: value.runtimeType);
  }

  /// Converts a value to its string representation.
  @protected
  String valueToString(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is DateTime) {
      return value.toTimeZonedIso8601String();
    }

    if (value is Uri) {
      return value.toString();
    }

    return value.toString();
  }

  /// Percent-encodes a string value according to RFC 3986.
  ///
  /// When [useQueryEncoding] is true, uses [Uri.encodeQueryComponent]
  /// which is appropriate for query parameters. When false, uses
  /// [Uri.encodeComponent] which is appropriate for path segments.
  @protected
  String encodeValue(String value, {bool useQueryEncoding = false}) {
    if (value.isEmpty) {
      return value;
    }

    if (useQueryEncoding) {
      return Uri.encodeQueryComponent(value);
    } else {
      return Uri.encodeComponent(value);
    }
  }

  /// Encodes a dynamic value, handling URI objects specially.
  ///
  /// For URI objects:
  /// - When [useQueryEncoding] is true (query parameters), returns the URI
  ///   string as-is since URIs are already properly encoded
  /// - When [useQueryEncoding] is false (path parameters), encodes the URI
  ///   string for use in path segments
  ///
  /// For other values, converts to string and applies standard encoding.
  @protected
  String encodeValueDynamic(dynamic value, {bool useQueryEncoding = false}) {
    final stringValue = valueToString(value);

    if (value is Uri && useQueryEncoding) {
      // URIs are already properly encoded, don't double-encode for query params
      return stringValue;
    }

    return encodeValue(stringValue, useQueryEncoding: useQueryEncoding);
  }
}
