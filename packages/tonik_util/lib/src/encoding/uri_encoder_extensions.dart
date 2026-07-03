import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/binary_extensions.dart';
import 'package:tonik_util/src/encoding/datetime_extension.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';

/// With [allowReserved] false the result is byte-identical to
/// [Uri.encodeQueryComponent] / [Uri.encodeComponent] — call sites rely on
/// this. With [allowReserved] true reserved chars including `[ ]` pass through
/// literally; the form delimiters `& =`, along with `+`, `%`, and non-ASCII,
/// stay encoded, and a space becomes `%20` (or `+` under [useQueryComponent]).
String _encodeUriValue(
  String value, {
  required bool allowReserved,
  required bool useQueryComponent,
}) {
  if (!allowReserved) {
    return useQueryComponent
        ? Uri.encodeQueryComponent(value)
        : Uri.encodeComponent(value);
  }

  // Uri.encodeFull keeps reserved chars literal, but & and = are data here,
  // not delimiters, so they must stay encoded. A literal + must become %2B
  // before a space is rendered as +, otherwise a data + and a space would be
  // indistinguishable. encodeFull predates RFC 3986 treating [ ] as reserved
  // and still percent-encodes them, so restore those to literal.
  var encoded = Uri.encodeFull(value)
      .replaceAll('+', '%2B')
      .replaceAll('&', '%26')
      .replaceAll('=', '%3D')
      .replaceAll('%5B', '[')
      .replaceAll('%5D', ']');
  if (useQueryComponent) {
    encoded = encoded.replaceAll('%20', '+');
  }
  return encoded;
}

/// Extension for URI encoding Uri values.
extension UriEncoder on Uri {
  /// URI encodes this Uri value.
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => _encodeUriValue(
    toString(),
    allowReserved: allowReserved,
    useQueryComponent: useQueryComponent,
  );
}

/// Extension for URI encoding String values.
extension StringUriEncoder on String {
  /// URI encodes this string value.
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    return _encodeUriValue(
      this,
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );
  }
}

/// Extension for URI encoding int values.
extension IntUriEncoder on int {
  /// URI encodes this int value.
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) {
    return useQueryComponent
        ? Uri.encodeQueryComponent(toString())
        : toString();
  }
}

/// Extension for URI encoding double values.
extension DoubleUriEncoder on double {
  /// URI encodes this double value.
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => _encodeUriValue(
    toString(),
    allowReserved: allowReserved,
    useQueryComponent: useQueryComponent,
  );
}

/// Extension for URI encoding num values.
extension NumUriEncoder on num {
  /// URI encodes this num value.
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) {
    return useQueryComponent
        ? Uri.encodeQueryComponent(toString())
        : toString();
  }
}

/// Extension for URI encoding bool values.
extension BoolUriEncoder on bool {
  /// URI encodes this bool value.
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) {
    return useQueryComponent
        ? Uri.encodeQueryComponent(toString())
        : toString();
  }
}

/// Extension for URI encoding DateTime values.
extension DateTimeUriEncoder on DateTime {
  /// URI encodes this DateTime value.
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => _encodeUriValue(
    toTimeZonedIso8601String(),
    allowReserved: allowReserved,
    useQueryComponent: useQueryComponent,
  );
}

/// Extension for URI encoding BigDecimal values.
extension BigDecimalUriEncoder on BigDecimal {
  /// URI encodes this BigDecimal value.
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) {
    return useQueryComponent
        ? Uri.encodeQueryComponent(toString())
        : toString();
  }
}

/// Extension for URI encoding binary data (`List<int>`) values.
extension BinaryUriEncoder on List<int> {
  /// URI encodes this binary data value.
  ///
  /// Converts the binary data to a UTF-8 string first, then URI encodes it.
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return '';
    }
    return _encodeUriValue(
      decodeToString(),
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );
  }
}

/// Extension for URI encoding List values.
extension StringListUriEncoder on List<String> {
  /// URI encodes this List value.
  ///
  /// The [alreadyEncoded] parameter indicates whether the list items are
  /// already URL-encoded. When `true`, items are not re-encoded to prevent
  /// double encoding.
  String uriEncode({
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (isEmpty) {
      return '';
    }

    if (alreadyEncoded) {
      return join(',');
    }

    return map(
      (item) => _encodeUriValue(
        item,
        allowReserved: allowReserved,
        useQueryComponent: useQueryComponent,
      ),
    ).join(',');
  }
}

/// Extension for URI encoding Map values.
extension StringMapUriEncoder on Map<String, String> {
  /// URI encodes this Map value.
  String uriEncode({
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool useQueryComponent = false,
    bool encodeKeys = true,
    bool allowReserved = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (isEmpty) {
      return '';
    }

    String encode(String value) => _encodeUriValue(
      value,
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );

    return entries
        .expand(
          (e) => [
            if (encodeKeys) encode(e.key) else e.key,
            if (alreadyEncoded) e.value else encode(e.value),
          ],
        )
        .join(',');
  }
}
