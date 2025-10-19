import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/datetime_extension.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';

/// Extensions for URI encoding individual values.

/// Extension for URI encoding Uri values.
extension UriEncoder on Uri {
  /// URI encodes this Uri value.
  String uriEncode({required bool allowEmpty}) {
    return Uri.encodeComponent(toString());
  }
}

/// Extension for URI encoding String values.
extension StringUriEncoder on String {
  /// URI encodes this string value.
  String uriEncode({required bool allowEmpty, bool useQueryComponent = false}) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    return useQueryComponent
        ? Uri.encodeQueryComponent(this)
        : Uri.encodeComponent(this);
  }
}

/// Extension for URI encoding int values.
extension IntUriEncoder on int {
  /// URI encodes this int value.
  String uriEncode({required bool allowEmpty}) => toString();
}

/// Extension for URI encoding double values.
extension DoubleUriEncoder on double {
  /// URI encodes this double value.
  String uriEncode({required bool allowEmpty, bool useQueryComponent = false}) {
    return useQueryComponent
        ? Uri.encodeQueryComponent(toString())
        : Uri.encodeComponent(toString());
  }
}

/// Extension for URI encoding num values.
extension NumUriEncoder on num {
  /// URI encodes this num value.
  String uriEncode({required bool allowEmpty}) => toString();
}

/// Extension for URI encoding bool values.
extension BoolUriEncoder on bool {
  /// URI encodes this bool value.
  String uriEncode({required bool allowEmpty}) => toString();
}

/// Extension for URI encoding DateTime values.
extension DateTimeUriEncoder on DateTime {
  /// URI encodes this DateTime value.
  String uriEncode({required bool allowEmpty, bool useQueryComponent = false}) {
    return useQueryComponent
        ? Uri.encodeQueryComponent(toTimeZonedIso8601String())
        : Uri.encodeComponent(toTimeZonedIso8601String());
  }
}

/// Extension for URI encoding BigDecimal values.
extension BigDecimalUriEncoder on BigDecimal {
  /// URI encodes this BigDecimal value.
  String uriEncode({required bool allowEmpty}) => toString();
}

/// Extension for URI encoding List values.
extension StringListUriEncoder on List<String> {
  /// URI encodes this List value.
  String uriEncode({required bool allowEmpty, bool useQueryComponent = false}) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (isEmpty) {
      return '';
    }

    return map(
      (item) =>
          useQueryComponent
              ? Uri.encodeQueryComponent(item)
              : Uri.encodeComponent(item),
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
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (isEmpty) {
      return '';
    }

    final encodeKey =
        encodeKeys
            ? (useQueryComponent
                ? Uri.encodeQueryComponent
                : Uri.encodeComponent)
            : (String key) => key;
    final encodeValue =
        useQueryComponent ? Uri.encodeQueryComponent : Uri.encodeComponent;

    return entries
        .expand(
          (e) => [
            encodeKey(e.key),
            if (alreadyEncoded) e.value else encodeValue(e.value),
          ],
        )
        .join(',');
  }
}
