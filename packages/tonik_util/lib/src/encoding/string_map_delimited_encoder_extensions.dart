import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/uri_value_encoder.dart';

/// Flattens a `Map<String, String>` into a single delimited [ParameterEntry].
///
/// On the wire both delimiters are percent-encoded (`|` as `%7C`, space as
/// `%20`), so a delimiter character inside a value is indistinguishable from
/// the structural delimiter for both styles — neither round-trips.
extension StringMapDelimitedEncoder on Map<String, String> {
  /// Joins the alternating key/value tokens with a literal `|`.
  List<ParameterEntry> toPipeDelimited(
    String paramName, {
    required bool allowEmpty,
    bool allowReserved = false,
  }) => _delimitedEntries(
    paramName,
    delimiter: '|',
    allowEmpty: allowEmpty,
    allowReserved: allowReserved,
  );

  /// Joins the alternating key/value tokens with a pre-escaped `%20`.
  List<ParameterEntry> toSpaceDelimited(
    String paramName, {
    required bool allowEmpty,
    bool allowReserved = false,
  }) => _delimitedEntries(
    paramName,
    delimiter: '%20',
    allowEmpty: allowEmpty,
    allowReserved: allowReserved,
  );

  List<ParameterEntry> _delimitedEntries(
    String paramName, {
    required String delimiter,
    required bool allowEmpty,
    required bool allowReserved,
  }) {
    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }
    if (isEmpty) {
      return const [];
    }

    String encode(String value) => encodeUriValue(
      value,
      allowReserved: allowReserved,
      useQueryComponent: false,
    );

    final flattened = entries
        .expand((e) => [encode(e.key), encode(e.value)])
        .join(delimiter);
    return [(name: paramName, value: flattened)];
  }
}
