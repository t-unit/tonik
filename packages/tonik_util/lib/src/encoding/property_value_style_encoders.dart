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
}

List<ParameterEntry> _delimitedEntries(
  Map<String, PropertyValue> map,
  String paramName, {
  required String delimiter,
  required bool allowEmpty,
  required bool allowReserved,
}) {
  _guardEmpty(map, allowEmpty: allowEmpty);
  if (map.isEmpty) {
    return const [];
  }

  String encode(String value) => encodeUriValue(
    value,
    allowReserved: allowReserved,
    useQueryComponent: false,
  );
  String encodeProperty(PropertyValue value) => switch (value) {
    ScalarPropertyValue(:final value) => encode(value),
    // Array elements collapse into the delimiter stream, indistinguishable
    // from the key/value tokens, consistent with the form/toUri path.
    ArrayPropertyValue(:final values) => values.map(encode).join(delimiter),
  };

  final flattened = map.entries
      .expand((e) => [encode(e.key), encodeProperty(e.value)])
      .join(delimiter);
  return [(name: paramName, value: flattened)];
}

/// Enforces empty-value and URI-escaping rules for object-valued parameters.
extension PropertyValueStyleEncoders on Map<String, PropertyValue> {
  /// Produces alternating key/value tokens with configurable URI escaping.
  String toUri({
    required bool allowEmpty,
    bool useQueryComponent = false,
    bool allowReserved = false,
    bool literal = false,
  }) {
    _guardEmpty(this, allowEmpty: allowEmpty);
    if (isEmpty) {
      return '';
    }

    String encode(String value) => literal
        ? value
        : encodeUriValue(
            value,
            allowReserved: allowReserved,
            useQueryComponent: useQueryComponent,
          );
    String encodePropertyValue(PropertyValue value) => switch (value) {
      ScalarPropertyValue(:final value) => encode(value),
      ArrayPropertyValue(:final values) => values.map(encode).join(','),
    };

    return entries
        .expand((e) => [encode(e.key), encodePropertyValue(e.value)])
        .join(',');
  }

  /// Set [literal] for header field-values that must bypass URI encoding.
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
      return entries.map((e) {
        final key = _encodeKey(e.key, literal: literal);
        final isValueEmpty = switch (e.value) {
          ScalarPropertyValue(:final value) => value.isEmpty,
          ArrayPropertyValue(:final values) => values.isEmpty,
        };
        return isValueEmpty
            ? key
            : '$key=${_encodeValue(e.value, literal: literal)}';
      }).join(',');
    }
    return _collapsedPairs(this, literal: literal);
  }

  /// Emits `.key=value` pairs when exploded and `.key,value` when collapsed.
  String toLabel({required bool explode, required bool allowEmpty}) {
    _guardEmpty(this, allowEmpty: allowEmpty);
    if (isEmpty) {
      return '.';
    }
    if (explode) {
      return entries.map((e) {
        final key = Uri.encodeComponent(e.key);
        final isValueEmpty = switch (e.value) {
          ScalarPropertyValue(:final value) => value.isEmpty,
          ArrayPropertyValue(:final values) => values.isEmpty,
        };
        return isValueEmpty
            ? '.$key'
            : '.$key=${_encodeValue(e.value, literal: false)}';
      }).join();
    }
    return '.${_collapsedPairs(this, literal: false)}';
  }

  /// Uses property names when exploded and [paramName] when collapsed.
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
      // Matrix is an RFC 6570 named operator: empty values expand to the
      // name alone, without '='.
      return entries.map((e) {
        final key = Uri.encodeComponent(e.key);
        final isValueEmpty = switch (e.value) {
          ScalarPropertyValue(:final value) => value.isEmpty,
          ArrayPropertyValue(:final values) => values.isEmpty,
        };
        return isValueEmpty
            ? ';$key'
            : ';$key=${_encodeValue(e.value, literal: false)}';
      }).join();
    }
    return ';$paramName=${_collapsedPairs(this, literal: false)}';
  }

  /// Leaves values unescaped for the multipart encoder to transfer-encode.
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

  /// Joins the alternating key/value tokens with a `|`.
  ///
  /// On the wire the `|` is percent-encoded to `%7C`, identical to a `|`
  /// inside a value, so keys, values, and array elements all collapse
  /// irreversibly into the delimiter stream.
  List<ParameterEntry> toPipeDelimited(
    String paramName, {
    required bool allowEmpty,
    bool allowReserved = false,
  }) => _delimitedEntries(
    this,
    paramName,
    delimiter: '|',
    allowEmpty: allowEmpty,
    allowReserved: allowReserved,
  );

  /// Joins the alternating key/value tokens with a pre-escaped `%20`.
  ///
  /// A value's own space also encodes to `%20`, so keys, values, and array
  /// elements all collapse irreversibly into the delimiter stream.
  List<ParameterEntry> toSpaceDelimited(
    String paramName, {
    required bool allowEmpty,
    bool allowReserved = false,
  }) => _delimitedEntries(
    this,
    paramName,
    delimiter: '%20',
    allowEmpty: allowEmpty,
    allowReserved: allowReserved,
  );

  /// Keeps keys component-encoded when [allowReserved] preserves value bytes.
  /// Throws [EncodingException] for a non-explode call or an array value, and
  /// [EmptyValueException] on an empty map under `allowEmpty: false`.
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
