import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/binary_extensions.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

/// Extensions for encoding values using simple style parameter encoding.

/// Extension for encoding Uri values.
extension SimpleUriEncoder on Uri {
  /// Encodes this Uri value using simple style parameter encoding.
  ///
  /// The [explode] and [allowEmpty] parameters are accepted for consistency
  /// but have no effect on Uri encoding.
  String toSimple({required bool explode, required bool allowEmpty}) =>
      uriEncode(allowEmpty: allowEmpty);
}

/// Extension for encoding String values.
extension SimpleStringEncoder on String {
  /// Encodes this string value using simple style encoding.
  String toSimple({required bool explode, required bool allowEmpty}) =>
      uriEncode(allowEmpty: allowEmpty);
}

/// Extension for encoding int values.
extension SimpleIntEncoder on int {
  /// Encodes this int value using simple style encoding.
  String toSimple({required bool explode, required bool allowEmpty}) =>
      uriEncode(allowEmpty: allowEmpty);
}

/// Extension for encoding double values.
extension SimpleDoubleEncoder on double {
  /// Encodes this double value using simple style encoding.
  String toSimple({required bool explode, required bool allowEmpty}) =>
      uriEncode(allowEmpty: allowEmpty);
}

/// Extension for encoding num values.
extension SimpleNumEncoder on num {
  /// Encodes this num value using simple style encoding.
  String toSimple({required bool explode, required bool allowEmpty}) =>
      uriEncode(allowEmpty: allowEmpty);
}

/// Extension for encoding bool values.
extension SimpleBoolEncoder on bool {
  /// Encodes this bool value using simple style encoding.
  String toSimple({required bool explode, required bool allowEmpty}) =>
      uriEncode(allowEmpty: allowEmpty);
}

/// Extension for encoding DateTime values.
extension SimpleDateTimeEncoder on DateTime {
  /// Encodes this DateTime value using simple style encoding.
  String toSimple({required bool explode, required bool allowEmpty}) =>
      uriEncode(allowEmpty: allowEmpty);
}

/// Extension for encoding BigDecimal values.
extension SimpleBigDecimalEncoder on BigDecimal {
  /// Encodes this BigDecimal value using simple style encoding.
  String toSimple({required bool explode, required bool allowEmpty}) =>
      uriEncode(allowEmpty: allowEmpty);
}

/// Extension for encoding List values.
extension SimpleStringListEncoder on List<String> {
  /// Encodes this List value using simple style encoding.
  ///
  /// When [explode] is true, array items are separately encoded.
  /// When false, they are encoded as a single string with comma delimiters.
  ///
  /// The [allowEmpty] parameter controls whether empty lists are allowed:
  /// - When `true`, empty lists are encoded as empty strings
  /// - When `false`, empty lists throw an exception
  ///
  /// The [alreadyEncoded] parameter indicates whether the list items are
  /// already URI-encoded and should not be encoded again.
  String toSimple({
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
  }) => uriEncode(allowEmpty: allowEmpty, alreadyEncoded: alreadyEncoded);
}

/// Extension for encoding Map values.
extension SimpleStringMapEncoder on Map<String, String> {
  /// Encodes this Map value using simple style encoding.
  ///
  /// When [explode] is true, produces key=value pairs separated by commas.
  /// When false, produces key,value pairs without separators.
  ///
  /// The [allowEmpty] parameter controls whether empty maps are allowed:
  /// - When `true`, empty maps are encoded as empty strings
  /// - When `false`, empty maps throw an exception
  ///
  /// The [alreadyEncoded] parameter indicates whether the values are already
  /// URL-encoded. When `true`, values are not re-encoded to prevent double
  /// encoding.
  String toSimple({
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
  }) {
    if (explode) {
      // explode=true: key1=value1,key2=value2
      if (isEmpty && !allowEmpty) {
        throw const EmptyValueException();
      }
      if (isEmpty) {
        return '';
      }
      return entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}='
                '${alreadyEncoded ? e.value : Uri.encodeComponent(e.value)}',
          )
          .join(',');
    } else {
      // explode=false: use uriEncode for key,value pairs
      return uriEncode(allowEmpty: allowEmpty, alreadyEncoded: alreadyEncoded);
    }
  }
}

/// Extension for encoding binary data (`List<int>`).
extension SimpleBinaryEncoder on List<int> {
  /// Encodes binary data to a UTF-8 string using simple style encoding.
  ///
  /// Uses Utf8Decoder with allowMalformed: true to handle any byte sequence.
  /// The resulting string is then URL-encoded for safe transport.
  ///
  /// The [explode] parameter is accepted for consistency but has no effect
  /// on binary encoding (binary data is treated as a primitive value).
  ///
  /// The [allowEmpty] parameter controls whether empty lists are allowed:
  /// - When `true`, empty lists are encoded as empty strings
  /// - When `false`, empty lists throw an exception
  String toSimple({required bool explode, required bool allowEmpty}) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return '';
    }
    final str = decodeToString();
    return Uri.encodeComponent(str);
  }
}
