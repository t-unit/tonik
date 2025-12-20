import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/binary_extensions.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

/// Extensions for encoding values using matrix style parameter encoding.
///
/// Matrix style parameters are appended to path segments using the format
/// `;paramName=paramValue` as defined in RFC 6570 Section 3.2.7.

/// Extension for encoding Uri values.
extension MatrixUriEncoder on Uri {
  /// Encodes this Uri value using matrix style parameter encoding.
  ///
  /// The [allowEmpty] parameter is accepted for consistency
  /// but has no effect on Uri encoding.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) => ';$paramName=${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding String values.
extension MatrixStringEncoder on String {
  /// Encodes this string value using matrix style encoding.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) => ';$paramName=${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding int values.
extension MatrixIntEncoder on int {
  /// Encodes this int value using matrix style encoding.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) => ';$paramName=${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding double values.
extension MatrixDoubleEncoder on double {
  /// Encodes this double value using matrix style encoding.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) => ';$paramName=${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding num values.
extension MatrixNumEncoder on num {
  /// Encodes this num value using matrix style encoding.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) => ';$paramName=${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding bool values.
extension MatrixBoolEncoder on bool {
  /// Encodes this bool value using matrix style encoding.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) => ';$paramName=${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding DateTime values.
extension MatrixDateTimeEncoder on DateTime {
  /// Encodes this DateTime value using matrix style encoding.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) => ';$paramName=${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding BigDecimal values.
extension MatrixBigDecimalEncoder on BigDecimal {
  /// Encodes this BigDecimal value using matrix style encoding.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) => ';$paramName=${uriEncode(allowEmpty: allowEmpty)}';
}

/// Extension for encoding List values.
extension MatrixStringListEncoder on List<String> {
  /// Encodes this List value using matrix style encoding.
  ///
  /// When [explode] is true, array items are separately encoded.
  /// When false, they are encoded as a single string with comma delimiters.
  ///
  /// The [allowEmpty] parameter controls whether empty lists are allowed:
  /// - When `true`, empty lists are encoded as `;paramName`
  /// - When `false`, empty lists throw an exception
  ///
  /// The [alreadyEncoded] parameter indicates whether the list items are
  /// already URL-encoded. When `true`, items are not re-encoded to prevent
  /// double encoding.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return ';$paramName';
    }

    if (explode) {
      return map(
        (item) =>
            ';$paramName='
            '${alreadyEncoded ? item : Uri.encodeComponent(item)}',
      ).join();
    } else {
      return ';$paramName=${uriEncode(
        allowEmpty: allowEmpty,
        alreadyEncoded: alreadyEncoded,
      )}';
    }
  }
}

/// Extension for encoding Map values.
extension MatrixStringMapEncoder on Map<String, String> {
  /// Encodes this Map value using matrix style encoding.
  ///
  /// When [explode] is true, produces key=value pairs separated by semicolons.
  /// When false, produces key,value pairs without separators.
  ///
  /// The [allowEmpty] parameter controls whether empty maps are allowed:
  /// - When `true`, empty maps are encoded as `;paramName`
  /// - When `false`, empty maps throw an exception
  ///
  /// The [alreadyEncoded] parameter indicates whether the values are already
  /// URL-encoded. When `true`, values are not re-encoded to prevent double
  /// encoding.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return ';$paramName';
    }

    if (explode) {
      return entries
          .map(
            (e) =>
                ';${Uri.encodeComponent(e.key)}='
                '${alreadyEncoded ? e.value : Uri.encodeComponent(e.value)}',
          )
          .join();
    } else {
      return ';$paramName=${uriEncode(
        allowEmpty: allowEmpty,
        alreadyEncoded: alreadyEncoded,
      )}';
    }
  }
}

/// Extension for encoding binary data (`List<int>`).
extension MatrixBinaryEncoder on List<int> {
  /// Encodes binary data using matrix style parameter encoding.
  ///
  /// Uses Utf8Decoder with allowMalformed: true to handle any byte sequence.
  /// The resulting string is then URL-encoded and prefixed with `;paramName=`.
  ///
  /// The [explode] parameter is accepted for consistency but has no effect
  /// on binary encoding (binary data is treated as a primitive value).
  ///
  /// The [allowEmpty] parameter controls whether empty lists are allowed:
  /// - When `true`, empty lists produce `;paramName=`
  /// - When `false`, empty lists throw an exception
  String toMatrix(
    String paramName, {
    required bool allowEmpty,
    required bool explode,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    final str = isEmpty ? '' : decodeToString();
    final encoded = Uri.encodeComponent(str);
    return ';$paramName=$encoded';
  }
}
