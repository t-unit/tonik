import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/binary_extensions.dart';
import 'package:tonik_util/src/encoding/datetime_extension.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/uri_value_encoder.dart';

/// Extension for URI encoding Uri values.
extension UriEncoder on Uri {
  /// URI encodes this Uri value.
  ///
  /// [literal] returns the value unencoded, overriding [useQueryComponent] and
  /// [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    if (literal) {
      return toString();
    }
    return encodeUriValue(
      toString(),
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );
  }
}

/// Extension for URI encoding String values.
extension StringUriEncoder on String {
  /// URI encodes this string value.
  ///
  /// [literal] returns the value unencoded, overriding [useQueryComponent] and
  /// [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    if (literal) {
      return this;
    }
    return encodeUriValue(
      this,
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );
  }
}

/// Extension for URI encoding int values.
extension IntUriEncoder on int {
  /// URI encodes this int value.
  ///
  /// [literal] returns the value unencoded, overriding [useQueryComponent] and
  /// [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    if (literal) {
      return toString();
    }
    return encodeUriValue(
      toString(),
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );
  }
}

/// Extension for URI encoding double values.
extension DoubleUriEncoder on double {
  /// URI encodes this double value.
  ///
  /// [literal] returns the value unencoded, overriding [useQueryComponent] and
  /// [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    if (literal) {
      return toString();
    }
    return encodeUriValue(
      toString(),
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );
  }
}

/// Extension for URI encoding num values.
extension NumUriEncoder on num {
  /// URI encodes this num value.
  ///
  /// [literal] returns the value unencoded, overriding [useQueryComponent] and
  /// [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    if (literal) {
      return toString();
    }
    return encodeUriValue(
      toString(),
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );
  }
}

/// Extension for URI encoding bool values.
extension BoolUriEncoder on bool {
  /// URI encodes this bool value.
  ///
  /// [literal] returns the value unencoded, overriding [useQueryComponent] and
  /// [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    if (literal) {
      return toString();
    }
    return encodeUriValue(
      toString(),
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );
  }
}

/// Extension for URI encoding DateTime values.
extension DateTimeUriEncoder on DateTime {
  /// URI encodes this DateTime value.
  ///
  /// [literal] returns the value unencoded, overriding [useQueryComponent] and
  /// [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    if (literal) {
      return toTimeZonedIso8601String();
    }
    return encodeUriValue(
      toTimeZonedIso8601String(),
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );
  }
}

/// Extension for URI encoding BigDecimal values.
extension BigDecimalUriEncoder on BigDecimal {
  /// URI encodes this BigDecimal value.
  ///
  /// [literal] returns the value unencoded, overriding [useQueryComponent] and
  /// [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    if (literal) {
      return toString();
    }
    return encodeUriValue(
      toString(),
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );
  }
}

/// Extension for URI encoding binary data (`List<int>`) values.
extension BinaryUriEncoder on List<int> {
  /// URI encodes this binary data value.
  ///
  /// Converts the binary data to a UTF-8 string first, then URI encodes it.
  ///
  /// [literal] returns the UTF-8 conversion unencoded, overriding
  /// [useQueryComponent] and [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return '';
    }
    if (literal) {
      return decodeToString();
    }
    return encodeUriValue(
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
  ///
  /// [literal] joins members with `,` without encoding any member, overriding
  /// [useQueryComponent] and [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (isEmpty) {
      return '';
    }

    if (literal) {
      return join(',');
    }

    if (alreadyEncoded) {
      return join(',');
    }

    return map(
      (item) => encodeUriValue(
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
  ///
  /// [literal] emits keys and values unencoded as `k1,v1,k2,v2`, overriding
  /// [useQueryComponent] and [allowReserved].
  String uriEncode({
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (isEmpty) {
      return '';
    }

    if (literal) {
      return entries.expand((e) => [e.key, e.value]).join(',');
    }

    String encode(String value) => encodeUriValue(
      value,
      allowReserved: allowReserved,
      useQueryComponent: useQueryComponent,
    );

    return entries
        .expand(
          (e) => [
            encode(e.key),
            if (alreadyEncoded) e.value else encode(e.value),
          ],
        )
        .join(',');
  }
}
