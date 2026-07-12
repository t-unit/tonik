import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/property_value.dart';
import 'package:tonik_util/src/encoding/uri_value_encoder.dart';

String _encodeValue(PropertyValue value, {required bool literal}) =>
    switch (value) {
      ScalarPropertyValue(:final value) => literal
          ? value
          : encodeUriValue(
              value,
              allowReserved: false,
              useQueryComponent: false,
            ),
      ArrayPropertyValue(:final values) => values
          .map(
            (element) => literal
                ? element
                : encodeUriValue(
                    element,
                    allowReserved: false,
                    useQueryComponent: false,
                  ),
          )
          .join(','),
    };

String _encodeKey(String key, {required bool literal}) =>
    literal ? key : Uri.encodeComponent(key);

String _collapsedPairs(
  Map<String, PropertyValue> map, {
  required bool literal,
}) => map.entries
    .expand(
      (e) => [
        _encodeKey(e.key, literal: literal),
        _encodeValue(e.value, literal: literal),
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
  ///
  /// When [literal] is true, keys and values are emitted without URI encoding,
  /// as required for HTTP header field-values.
  String toSimple({
    required bool explode,
    required bool allowEmpty,
    bool literal = false,
  }) {
    _guardEmpty(this, allowEmpty: allowEmpty);
    if (isEmpty) {
      return '';
    }
    if (explode) {
      return entries
          .map(
            (e) =>
                '${_encodeKey(e.key, literal: literal)}='
                '${_encodeValue(e.value, literal: literal)}',
          )
          .join(',');
    }
    return _collapsedPairs(this, literal: literal);
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
                '${_encodeValue(e.value, literal: false)}',
          )
          .join();
    }
    return '.${_collapsedPairs(this, literal: false)}';
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
                '${_encodeValue(e.value, literal: false)}',
          )
          .join();
    }
    return ';$paramName=${_collapsedPairs(this, literal: false)}';
  }

  /// Renders raw style-based multipart part entries.
  ///
  /// Exploded objects emit one entry per key whose name is the RFC 6570
  /// query name and whose value is the raw part body; non-exploded objects
  /// emit one entry under [paramName] with the raw comma-joined expansion.
  /// Nothing is URI- or form-percent-encoded, and `?`, `=`, and `&` never
  /// appear as serialization delimiters.
  List<ParameterEntry> toRawStyleParts(
    String paramName, {
    required bool explode,
  }) {
    String raw(PropertyValue value) => switch (value) {
      ScalarPropertyValue(:final value) => value,
      ArrayPropertyValue(:final values) => values.join(','),
    };

    if (explode) {
      return [
        for (final entry in entries)
          (name: entry.key, value: raw(entry.value)),
      ];
    }
    final parts = <String>[
      for (final entry in entries) ...[entry.key, raw(entry.value)],
    ];
    return [(name: paramName, value: parts.join(','))];
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
