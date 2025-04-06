import 'package:meta/meta.dart';
import 'package:tonic_util/src/encoding/base_encoder.dart';

/// An encoder for OpenAPI's delimited style parameters.
///
/// Delimited style is often used for query parameters with array values,
/// supporting both pipe-delimited and space-delimited formats:
///
/// Space delimited:
/// - Arrays (explode=false): `name=value1%20value2%20value3`
/// - Arrays (explode=true): `name=value1&name=value2&name=value3`
///   (handled as multiple values)
///
/// Pipe delimited:
/// - Arrays (explode=false): `name=value1|value2|value3`
/// - Arrays (explode=true): `name=value1&name=value2&name=value3`
///   (handled as multiple values)
///
/// This encoder only encodes the value part, not the name=value combination,
/// as that's typically handled at a higher level.
///
/// Note: According to the OpenAPI specification, these delimited styles are
/// only applicable to arrays, not objects.
class DelimitedEncoder extends BaseEncoder {
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
    checkSupportedType(value, supportMaps: false);

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
            .map(
              (item) =>
                  encodeValue(
                    valueToString(item),
                    useQueryEncoding: true,
                  ),
            )
            .toList();
      } else {
        // With explode=false, join items with the specified delimiter
        return [
          value
              .map(
                (item) =>
                    encodeValue(
                      valueToString(item),
                      useQueryEncoding: true,
                    ),
              )
              .join(delimiter),
        ];
      }
    }

    return [
      encodeValue(
        valueToString(value),
        useQueryEncoding: true,
      ),
    ];
  }
}
