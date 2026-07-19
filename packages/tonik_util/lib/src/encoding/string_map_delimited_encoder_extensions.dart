import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/uri_value_encoder.dart';

/// Extensions flattening a `Map<String, String>` into a single delimited entry.
///
/// Both styles collapse the map to one [ParameterEntry] whose value is the
/// alternating key/value tokens joined by the style delimiter, named by the
/// caller-supplied parameter name. Map values are always scalars here, so there
/// are no array-valued-property concerns.
///
/// Round-trip safety differs by style. Pipe uses a literal `|` separator while
/// a `|` inside a value encodes to `%7C`, so the two stay distinct and the
/// map round-trips. Space uses a pre-escaped `%20` separator, but a space
/// inside a value also encodes to `%20`, making it indistinguishable from the
/// separator — space-delimited values cannot round-trip.
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
