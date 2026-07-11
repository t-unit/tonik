import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/binary_extensions.dart';
import 'package:tonik_util/src/encoding/datetime_extension.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/uri_value_encoder.dart';

/// Extension for URI encoding Uri values.
extension UriEncoder on Uri {
  /// URI encodes this Uri value.
  String uriEncode({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => encodeUriValue(
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
  }) => encodeUriValue(
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
  }) => encodeUriValue(
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
