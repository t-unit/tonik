import 'package:big_decimal/big_decimal.dart';
import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/form_field_encoding.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

/// Extensions for encoding values using form style parameter encoding.
///
/// Form encoding produces a list of [ParameterEntry] (`name=value` pairs) that
/// callers join with the separator for their context — `&` for query strings
/// and urlencoded bodies, `; ` for cookies.

// Items, keys, and values may be empty strings; encode to '' rather than throw.
String _encodeValue(
  String value, {
  required bool useQueryComponent,
  bool allowReserved = false,
}) => value.uriEncode(
  allowEmpty: true,
  useQueryComponent: useQueryComponent,
  allowReserved: allowReserved,
);

/// Extension for encoding Uri values.
extension FormUriEncoder on Uri {
  /// Encodes this Uri value using form style parameter encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
    ),
  ];
}

/// Extension for encoding String values.
extension FormStringEncoder on String {
  /// Encodes this string value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
    ),
  ];
}

/// Extension for encoding int values.
extension FormIntEncoder on int {
  /// Encodes this int value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
    ),
  ];
}

/// Extension for encoding double values.
extension FormDoubleEncoder on double {
  /// Encodes this double value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
    ),
  ];
}

/// Extension for encoding num values.
extension FormNumEncoder on num {
  /// Encodes this num value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
    ),
  ];
}

/// Extension for encoding bool values.
extension FormBoolEncoder on bool {
  /// Encodes this bool value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
    ),
  ];
}

/// Extension for encoding DateTime values.
extension FormDateTimeEncoder on DateTime {
  /// Encodes this DateTime value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
    ),
  ];
}

/// Extension for encoding BigDecimal values.
extension FormBigDecimalEncoder on BigDecimal {
  /// Encodes this BigDecimal value using form style encoding.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
    ),
  ];
}

/// Extension for encoding List values.
extension FormStringListEncoder on List<String> {
  /// Encodes this List value using form style encoding.
  ///
  /// The [alreadyEncoded] parameter indicates whether the items are already
  /// URI-encoded and should not be encoded again.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (!explode) {
      return [
        (
          name: paramName,
          value: uriEncode(
            allowEmpty: allowEmpty,
            alreadyEncoded: alreadyEncoded,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          ),
        ),
      ];
    }

    return [
      for (final item in this)
        (
          name: paramName,
          value: alreadyEncoded
              ? item
              : _encodeValue(
                  item,
                  useQueryComponent: useQueryComponent,
                  allowReserved: allowReserved,
                ),
        ),
    ];
  }
}

/// Extension for encoding Map values.
extension FormStringMapEncoder on Map<String, String> {
  /// Encodes this Map value using form style encoding.
  ///
  /// The [alreadyEncoded] parameter indicates whether the values are already
  /// URL-encoded, in which case they are not re-encoded to prevent double
  /// encoding.
  ///
  /// [fieldEncodings], keyed by raw property name, carries per-property array
  /// explode. When a key's descriptor has `explode == true`, its element
  /// strings are taken from [explodedValues] (keeping element boundaries that a
  /// comma-joined value would lose) and emitted as one entry per element, so
  /// the wire form matches `style: form, explode: true` (repeated keys). An
  /// exploded empty list yields no entries; a single empty-string element
  /// yields one empty-value entry.
  ///
  /// [fieldEncodings] and [explodedValues] are ignored when [explode] is false.
  /// The descriptors' `allowReserved` is not consulted here: values arrive
  /// already URI-encoded upstream.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool useQueryComponent = false,
    bool allowReserved = false,
    Map<String, FormFieldEncoding> fieldEncodings = const {},
    Map<String, List<String>> explodedValues = const {},
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (!explode) {
      return [
        (
          name: paramName,
          value: uriEncode(
            allowEmpty: allowEmpty,
            alreadyEncoded: alreadyEncoded,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          ),
        ),
      ];
    }

    String encodeValue(String value) => alreadyEncoded
        ? value
        : _encodeValue(
            value,
            useQueryComponent: useQueryComponent,
            allowReserved: allowReserved,
          );

    final result = <ParameterEntry>[];
    for (final e in entries) {
      final name = _encodeValue(
        e.key,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      );

      if (fieldEncodings[e.key]?.explode ?? false) {
        final exploded = explodedValues[e.key];
        if (exploded == null) {
          throw EncodingException(
            'Form property "${e.key}" of "$paramName" is marked exploded but '
            'has no exploded values. This indicates the generated code and '
            'runtime disagree (drift or version skew), not invalid input.',
          );
        }
        for (final item in exploded) {
          result.add((name: name, value: encodeValue(item)));
        }
      } else {
        result.add((name: name, value: encodeValue(e.value)));
      }
    }
    return result;
  }
}

/// Extension for encoding binary data (`List<int>`).
extension FormBinaryEncoder on List<int> {
  /// Encodes binary data using form style encoding.
  ///
  /// The [explode] parameter has no effect; binary data is a primitive value.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
  }) => [
    (
      name: paramName,
      value: uriEncode(
        allowEmpty: allowEmpty,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
    ),
  ];
}
