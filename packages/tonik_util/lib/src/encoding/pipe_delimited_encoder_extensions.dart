import 'package:tonik_util/src/encoding/binary_extensions.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

/// Extensions for encoding values using pipe-delimited style parameter
/// encoding.
///
/// According to the OpenAPI specification, pipeDelimited style is only
/// applicable to arrays in query parameters:
/// - Arrays (explode=false): `name=value1|value2|value3`
/// - Arrays (explode=true): `name=value1&name=value2&name=value3`
///   (handled as multiple values)

extension PipeDelimitedStringListEncoder on List<String> {
  /// Encodes this List value using pipe-delimited style encoding.
  ///
  /// According to the OpenAPI specification for pipeDelimited style:
  /// - explode=false: pipe-separated values (value1|value2|value3)
  /// - explode=true: multiple parameter instances (handled at parameter level)
  ///
  /// The [allowEmpty] parameter controls whether empty lists are allowed:
  /// - When `true`, empty lists are encoded as a list with an empty string
  /// - When `false`, empty lists throw an [EmptyValueException]
  ///
  /// The [alreadyEncoded] parameter indicates whether the list items are
  /// already URI-encoded and should not be encoded again.
  List<String> toPipeDelimited({
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
  }) {
    if (isEmpty) {
      if (!allowEmpty) {
        throw const EmptyValueException();
      }
      return [''];
    }

    if (explode) {
      if (alreadyEncoded) {
        return this;
      }
      return map(
        (item) => item.uriEncode(allowEmpty: allowEmpty),
      ).toList();
    } else {
      if (alreadyEncoded) {
        return [join('|')];
      }
      return [
        map(
          (item) => item.uriEncode(allowEmpty: allowEmpty),
        ).join('|'),
      ];
    }
  }
}

/// Extension for encoding binary data (`List<int>`).
extension PipeDelimitedBinaryEncoder on List<int> {
  /// Encodes binary data using pipe-delimited style parameter encoding.
  ///
  /// Uses Utf8Decoder with allowMalformed: true to handle any byte sequence.
  /// Returns a list containing a single URL-encoded string.
  ///
  /// The [explode] parameter is accepted for consistency but has no effect
  /// on binary encoding (binary data is treated as a primitive value).
  ///
  /// The [allowEmpty] parameter controls whether empty lists are allowed:
  /// - When `true`, empty lists return `['']`
  /// - When `false`, empty lists throw an exception
  List<String> toPipeDelimited({
    required bool explode,
    required bool allowEmpty,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return [''];
    }
    final str = decodeToString();
    return [Uri.encodeComponent(str)];
  }
}
