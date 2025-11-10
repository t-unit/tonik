import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

/// Extensions for encoding values using label style parameter encoding.
extension LabelUriEncoder on Uri {
  /// Encodes this Uri value using label style encoding.
  String toLabel({required bool explode, required bool allowEmpty}) =>
      '.${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding String values.
extension LabelStringEncoder on String {
  /// Encodes this string value using label style encoding.
  String toLabel({required bool explode, required bool allowEmpty}) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return '.';
    }
    return '.${uriEncode(allowEmpty: allowEmpty)}';
  }
}

/// Extension for encoding int values.
extension LabelIntEncoder on int {
  /// Encodes this int value using label style encoding.
  String toLabel({required bool explode, required bool allowEmpty}) =>
      '.${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding double values.
extension LabelDoubleEncoder on double {
  /// Encodes this double value using label style encoding.
  String toLabel({required bool explode, required bool allowEmpty}) =>
      '.${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding num values.
extension LabelNumEncoder on num {
  /// Encodes this num value using label style encoding.
  String toLabel({required bool explode, required bool allowEmpty}) =>
      '.${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding bool values.
extension LabelBoolEncoder on bool {
  /// Encodes this bool value using label style encoding.
  String toLabel({required bool explode, required bool allowEmpty}) =>
      '.${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding DateTime values.
extension LabelDateTimeEncoder on DateTime {
  /// Encodes this DateTime value using label style encoding.
  String toLabel({required bool explode, required bool allowEmpty}) =>
      '.${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding BigDecimal values.
extension LabelBigDecimalEncoder on BigDecimal {
  /// Encodes this BigDecimal value using label style encoding.
  String toLabel({required bool explode, required bool allowEmpty}) =>
      '.${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding List values.
extension LabelStringListEncoder on List<String> {
  /// Encodes this List value using label style encoding.
  ///
  /// The [alreadyEncoded] parameter indicates whether the list items are
  /// already URI-encoded and should not be encoded again.
  String toLabel({
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return '.';
    }

    if (explode) {
      return map(
        (item) =>
            '.'
            '${alreadyEncoded ? item : item.uriEncode(allowEmpty: allowEmpty)}',
      ).join();
    } else {
      final encodedValues = uriEncode(
        allowEmpty: allowEmpty,
        alreadyEncoded: alreadyEncoded,
      );
      return '.$encodedValues';
    }
  }
}

/// Extension for encoding Map values.
extension LabelStringMapEncoder on Map<String, String> {
  /// Encodes this Map value using label style encoding.
  ///
  /// The [alreadyEncoded] parameter indicates whether the values are already
  /// URL-encoded. When `true`, values are not re-encoded to prevent double
  /// encoding.
  String toLabel({
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return '.';
    }

    if (explode) {
      return entries.map(
        (entry) {
          final value =
              alreadyEncoded
                  ? entry.value
                  : entry.value.uriEncode(allowEmpty: allowEmpty);
          return '.${entry.key}=$value';
        },
      ).join();
    } else {
      final encodedPairs = uriEncode(
        allowEmpty: allowEmpty,
        alreadyEncoded: alreadyEncoded,
      );
      return '.$encodedPairs';
    }
  }
}
