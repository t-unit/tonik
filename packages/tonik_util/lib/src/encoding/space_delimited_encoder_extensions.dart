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
  /// The [allowEmpty] parameter controls whether empty lists are allowed:
  /// - When `true`, empty lists are encoded as a list with an empty string
  /// - When `false`, empty lists throw an [EmptyValueException]
  ///
  /// The [alreadyEncoded] parameter indicates whether the list items are
  /// already URI-encoded and should not be encoded again.
  List<String> toSpaceDelimited({
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
        (item) =>
            item.uriEncode(allowEmpty: allowEmpty),
      ).toList();
    } else {
      if (alreadyEncoded) {
        return [join('%20')];
      }
      return [
        map(
          (item) =>
              item.uriEncode(allowEmpty: allowEmpty),
        ).join('%20'),
      ];
    }
  }
}
