import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/property_value.dart';
import 'package:tonik_util/src/encoding/uri_value_encoder.dart';

String _encodeValue(PropertyValue value, {required bool allowReserved}) =>
    switch (value) {
      ScalarPropertyValue(:final value) => encodeUriValue(
        value,
        allowReserved: allowReserved,
        useQueryComponent: false,
      ),
      ArrayPropertyValue(:final values) => values
          .map(
            (element) => encodeUriValue(
              element,
              allowReserved: allowReserved,
              useQueryComponent: false,
            ),
          )
          .join(','),
    };

String _collapsedPairs(Map<String, PropertyValue> map) => map.entries
    .expand(
      (e) => [
        Uri.encodeComponent(e.key),
        _encodeValue(e.value, allowReserved: false),
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

/// Simple/label/matrix/deepObject encoders over `Map<String, PropertyValue>`
/// whose values are raw (unescaped).
///
/// Each is byte-identical to encoding every value with
/// [encodeUriValue] (`useQueryComponent: false`) and then assembling the
/// resulting `Map<String, String>` through the matching string-map encoder with
/// `alreadyEncoded: true`. Array values contribute their percent-encoded
/// elements comma-joined; the comma separators between elements stay literal.
extension PropertyValueStyleEncoders on Map<String, PropertyValue> {
  /// Encodes this property map using simple style encoding.
  ///
  /// With [explode] false the result is `key,value,key2,value2`; with [explode]
  /// true it is `key=value,key2=value2`.
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
                '${_encodeValue(e.value, allowReserved: false)}',
          )
          .join(',');
    }
    return _collapsedPairs(this);
  }

  /// Encodes this property map using label style encoding.
  ///
  /// With [explode] false the result is `.key,value,key2,value2`; with
  /// [explode] true it is `.key=value.key2=value2`. An empty map renders
  /// as `.`.
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
                '${_encodeValue(e.value, allowReserved: false)}',
          )
          .join();
    }
    return '.${_collapsedPairs(this)}';
  }

  /// Encodes this property map using matrix style encoding.
  ///
  /// With [explode] false the result is `;paramName=key,value,key2,value2`;
  /// with [explode] true it is `;key=value;key2=value2`. An empty map renders
  /// as `;paramName`.
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
                '${_encodeValue(e.value, allowReserved: false)}',
          )
          .join();
    }
    return ';$paramName=${_collapsedPairs(this)}';
  }

  /// Encodes this property map using deepObject style encoding.
  ///
  /// Returns entries of the form `(name: 'paramName[key]', value: value)`.
  /// [allowReserved] threads into value encoding only; keys are always
  /// component-encoded. An empty map renders as an empty list.
  ///
  /// Throws [EncodingException] when [explode] is false, and when any value is
  /// an array (deepObject does not support lists).
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
