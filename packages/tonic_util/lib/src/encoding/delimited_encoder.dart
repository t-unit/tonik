import 'package:big_decimal/big_decimal.dart';
import 'package:meta/meta.dart';
import 'package:tonic_util/src/encoding/encoding_exception.dart';

/// An encoder for OpenAPI's delimited style parameters.
///
/// Delimited style is often used for query parameters with array values,
/// supporting both pipe-delimited and space-delimited formats:
/// 
/// Space delimited:
/// - Arrays (explode=false): name=value1%20value2%20value3
/// - Arrays (explode=true): name=value1&name=value2&name=value3 (handled as multiple values)
///
/// Pipe delimited:
/// - Arrays (explode=false): name=value1|value2|value3
/// - Arrays (explode=true): name=value1&name=value2&name=value3 (handled as multiple values)
///
/// This encoder only encodes the value part, not the name=value combination, 
/// as that's typically handled at a higher level.
///
/// Note: According to the OpenAPI specification, these delimited styles are
/// only applicable to arrays, not objects.
class DelimitedEncoder {
  /// Creates a new [DelimitedEncoder].
  const DelimitedEncoder();

  /// Encodes a value using pipe-delimited style.
  ///
  /// Shorthand for [encode] with `delimiter` set to `|`.
  List<String> encodePiped(dynamic value, {bool explode = false}) {
    return encode(value, delimiter: '|', explode: explode);
  }

  /// Encodes a value using space-delimited style.
  ///
  /// Shorthand for [encode] with `delimiter` set to `%20`.
  List<String> encodeSpaced(dynamic value, {bool explode = false}) {
    return encode(value, delimiter: '%20', explode: explode);
  }

  /// Encodes a value according to the specified delimiter style.
  @protected
  List<String> encode(
    dynamic value, {
    required String delimiter,
    bool explode = false,
  }) {
    checkSupportedType(value);

    if (value == null) {
      return [''];
    }

    if (value is Iterable) {
      if (value.isEmpty) {
        return [''];
      }

      if (explode) {
        // With explode=true, each array item becomes a separate value
        return value
            .map((item) => _encodeValue(valueToString(item)))
            .toList();
      } else {
        // With explode=false, join items with the specified delimiter
        return [
          value
              .map((item) => _encodeValue(valueToString(item)))
              .join(delimiter)
        ];
      }
    }

    if (value is Map<String, dynamic>) {
      throw UnsupportedEncodingTypeException(
        valueType: value.runtimeType,
      );
    }

    return [_encodeValue(valueToString(value))];
  }

  /// Checks if the given value is of a supported type and throws an
  /// [UnsupportedEncodingTypeException] if it's not.
  @protected
  void checkSupportedType(dynamic value) {
    if (value == null ||
        value is String ||
        value is num ||
        value is BigDecimal ||
        value is Uri ||
        value is DateTime || value is bool) {
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
      // According to the OpenAPI specification, delimited styles are not
      // applicable to objects/maps
      throw UnsupportedEncodingTypeException(
        valueType: value.runtimeType,
      );
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