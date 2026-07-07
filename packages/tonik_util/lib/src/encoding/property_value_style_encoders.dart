import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/property_value.dart';
import 'package:tonik_util/src/encoding/uri_value_encoder.dart';

String _encodeValue(PropertyValue value) => switch (value) {
  ScalarPropertyValue(:final value) => encodeUriValue(
    value,
    allowReserved: false,
    useQueryComponent: false,
  ),
  ArrayPropertyValue(:final values) => values
      .map(
        (element) => encodeUriValue(
          element,
          allowReserved: false,
          useQueryComponent: false,
        ),
      )
      .join(','),
};

String _collapsedPairs(Map<String, PropertyValue> map) => map.entries
    .expand(
      (e) => [
        Uri.encodeComponent(e.key),
        _encodeValue(e.value),
      ],
    )
    .join(',');

void _guardEmpty(Map<String, PropertyValue> map, {required bool allowEmpty}) {
  if (map.isEmpty && !allowEmpty) {
    throw const EmptyValueException();
  }
  if (allowEmpty) {
    return;
  }
  for (final value in map.values) {
    final isValueEmpty = switch (value) {
      ScalarPropertyValue(:final value) => value.isEmpty,
      ArrayPropertyValue(:final values) => values.isEmpty,
    };
    if (isValueEmpty) {
      throw const EmptyValueException();
    }
  }
}

/// Style encoders over `Map<String, PropertyValue>` with raw (unescaped)
/// values, matching the string-map encoders' wire output.
///
/// Unlike those siblings, an empty scalar or array throws [EmptyValueException]
/// under `allowEmpty: false` instead of rendering `k,` — a deliberate guard,
/// not a parity gap to "fix".
extension PropertyValueStyleEncoders on Map<String, PropertyValue> {
  /// Encodes this property map using simple style encoding.
  String toSimple({required bool explode, required bool allowEmpty}) {
    _guardEmpty(this, allowEmpty: allowEmpty);
    if (isEmpty) {
      return '';
    }
    if (explode) {
      return entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}='
                '${_encodeValue(e.value)}',
          )
          .join(',');
    }
    return _collapsedPairs(this);
  }

  /// Encodes this property map using label style encoding.
  String toLabel({required bool explode, required bool allowEmpty}) {
    _guardEmpty(this, allowEmpty: allowEmpty);
    if (isEmpty) {
      return '.';
    }
    if (explode) {
      return entries
          .map(
            (e) =>
                '.${Uri.encodeComponent(e.key)}='
                '${_encodeValue(e.value)}',
          )
          .join();
    }
    return '.${_collapsedPairs(this)}';
  }

  /// Encodes this property map using matrix style encoding.
  String toMatrix(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
  }) {
    _guardEmpty(this, allowEmpty: allowEmpty);
    if (isEmpty) {
      return ';$paramName';
    }
    if (explode) {
      return entries
          .map(
            (e) =>
                ';${Uri.encodeComponent(e.key)}='
                '${_encodeValue(e.value)}',
          )
          .join();
    }
    return ';$paramName=${_collapsedPairs(this)}';
  }

  /// Encodes this property map using deepObject style encoding.
  ///
  /// [allowReserved] applies to values only; keys are always component-encoded.
  /// Throws [EncodingException] for a non-explode call or an array value, and
  /// [EmptyValueException] on an empty map or value under `allowEmpty: false`.
  List<ParameterEntry> toDeepObject(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool allowReserved = false,
  }) {
    if (!explode) {
      throw const EncodingException('deepObject style requires explode=true');
    }
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    final result = <ParameterEntry>[];
    for (final entry in entries) {
      switch (entry.value) {
        case ArrayPropertyValue():
          throw const EncodingException(
            'Lists are not supported in this encoding style',
          );
        case ScalarPropertyValue(:final value):
          if (value.isEmpty && !allowEmpty) {
            throw const EmptyValueException();
          }
          result.add((
            name: '$paramName[${Uri.encodeComponent(entry.key)}]',
            value: encodeUriValue(
              value,
              allowReserved: allowReserved,
              useQueryComponent: false,
            ),
          ));
      }
    }
    return result;
  }
}
