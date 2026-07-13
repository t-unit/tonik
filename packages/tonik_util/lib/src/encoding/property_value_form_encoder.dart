import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/form_field_encoding.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/property_value.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

String _encode(
  String value, {
  required bool useQueryComponent,
  required bool allowReserved,
}) => value.uriEncode(
  allowEmpty: true,
  useQueryComponent: useQueryComponent,
  allowReserved: allowReserved,
);

String _joinEncoded(
  List<String> values, {
  required bool useQueryComponent,
  required bool allowReserved,
}) => values
    .map(
      (element) => _encode(
        element,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      ),
    )
    .join(',');

/// Extension for encoding a tagged property map using form style encoding.
///
/// This is the percent-encoding boundary for `Map<String, PropertyValue>` form
/// encoding: keys are raw property names and values are raw (unescaped).
extension PropertyValueFormEncoder on Map<String, PropertyValue> {
  /// Encodes this property map using form style encoding.
  ///
  /// When the map is exploded, per-property [FormFieldEncoding.explode]
  /// controls array assembly and [FormFieldEncoding.allowReserved] applies to
  /// values only; keys are always component-encoded. In collapse mode
  /// (object-level `explode` false) [fieldEncodings] is ignored and arrays are
  /// always comma-joined.
  List<ParameterEntry> toForm(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
    Map<String, FormFieldEncoding> fieldEncodings = const {},
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (!allowEmpty) {
      for (final value in values) {
        final isEmptyCollection = switch (value) {
          ScalarPropertyValue() => false,
          ArrayPropertyValue(:final values) => values.isEmpty,
        };
        if (isEmptyCollection) {
          throw const EmptyValueException();
        }
      }
    }

    if (!explode) {
      return _collapse(
        paramName,
        useQueryComponent: useQueryComponent,
        allowReserved: allowReserved,
      );
    }

    final result = <ParameterEntry>[];
    for (final entry in entries) {
      final name = entry.key;
      final encodedKey = _encode(
        name,
        useQueryComponent: useQueryComponent,
        allowReserved: false,
      );
      final encoding = fieldEncodings[name];
      final explodeArray = encoding?.explode ?? false;

      // A null/absent array property is flattened to an empty scalar upstream;
      // exploding it yields an empty list, so it drops out of the body.
      if (entry.value case ScalarPropertyValue(value: '') when explodeArray) {
        continue;
      }

      // A present descriptor always carries a concrete allowReserved, so the
      // object-level value is only a fallback for properties without one.
      final valueAllowReserved = encoding?.allowReserved ?? allowReserved;

      switch (entry.value) {
        case ScalarPropertyValue(:final value):
          result.add((
            name: encodedKey,
            value: _encode(
              value,
              useQueryComponent: useQueryComponent,
              allowReserved: valueAllowReserved,
            ),
          ));
        case ArrayPropertyValue(:final values):
          if (explodeArray) {
            for (final element in values) {
              result.add((
                name: encodedKey,
                value: _encode(
                  element,
                  useQueryComponent: useQueryComponent,
                  allowReserved: valueAllowReserved,
                ),
              ));
            }
          } else {
            result.add((
              name: encodedKey,
              value: _joinEncoded(
                values,
                useQueryComponent: useQueryComponent,
                allowReserved: valueAllowReserved,
              ),
            ));
          }
      }
    }
    return result;
  }

  List<ParameterEntry> _collapse(
    String paramName, {
    required bool useQueryComponent,
    required bool allowReserved,
  }) {
    final parts = <String>[];
    for (final entry in entries) {
      parts
        ..add(
          _encode(
            entry.key,
            useQueryComponent: useQueryComponent,
            allowReserved: false,
          ),
        )
        ..add(
          switch (entry.value) {
            ScalarPropertyValue(:final value) => _encode(
              value,
              useQueryComponent: useQueryComponent,
              allowReserved: allowReserved,
            ),
            ArrayPropertyValue(:final values) => _joinEncoded(
              values,
              useQueryComponent: useQueryComponent,
              allowReserved: allowReserved,
            ),
          },
        );
    }
    return [(name: paramName, value: parts.join(','))];
  }
}
