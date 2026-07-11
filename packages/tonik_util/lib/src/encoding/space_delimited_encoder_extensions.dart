import 'package:tonik_util/src/encoding/binary_extensions.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

/// Extensions for encoding values using space-delimited style parameter
/// encoding.
///
/// According to the OpenAPI specification, spaceDelimited style is only
/// applicable to arrays in query parameters:
/// - Arrays (explode=false): `name=value1%20value2%20value3`
/// - Arrays (explode=true): `name=value1&name=value2&name=value3`
///   (handled as multiple values)

extension SpaceDelimitedStringListEncoder on List<String> {
  /// Encodes this List value using space-delimited style encoding.
  ///
  /// According to the OpenAPI specification for spaceDelimited style:
  /// - explode=false: space-separated values (value1%20value2%20value3)
  /// - explode=true: multiple parameter instances (handled at parameter level)
  ///
  /// An empty list is omitted; [allowEmpty] gates empty-string values, not
  /// empty arrays.
  ///
  /// The [alreadyEncoded] parameter indicates whether the list items are
  /// already URI-encoded and should not be encoded again.
  ///
  /// When [allowReserved] is true, most reserved characters are kept
  /// literal in each item; the `%20` delimiter is unaffected.
  List<String> toSpaceDelimited({
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool percentEncodeDelimiter = true,
    bool allowReserved = false,
  }) {
    if (isEmpty) {
      return const [];
    }

    if (explode) {
      if (alreadyEncoded) {
        return this;
      }
      return map(
        (item) => item.uriEncode(
          allowEmpty: allowEmpty,
          allowReserved: allowReserved,
        ),
      ).toList();
    } else {
      final delimiter = alreadyEncoded && !percentEncodeDelimiter ? ' ' : '%20';
      if (alreadyEncoded) {
        return [join(delimiter)];
      }
      return [
        map(
          (item) => item.uriEncode(
            allowEmpty: allowEmpty,
            allowReserved: allowReserved,
          ),
        ).join('%20'),
      ];
    }
  }
}

/// Extension for encoding binary data (`List<int>`).
extension SpaceDelimitedBinaryEncoder on List<int> {
  /// Encodes binary data using space-delimited style parameter encoding.
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
  ///
  /// When [allowReserved] is true, most reserved characters in the decoded
  /// value are kept literal.
  List<String> toSpaceDelimited({
    required bool explode,
    required bool allowEmpty,
    bool allowReserved = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return [''];
    }
    return [
      decodeToString().uriEncode(
        allowEmpty: true,
        allowReserved: allowReserved,
      ),
    ];
  }
}
