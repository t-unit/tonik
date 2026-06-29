import 'package:tonik_util/src/encoding/encoding_exception.dart';
import 'package:tonik_util/src/encoding/parameter_entry.dart';
import 'package:tonik_util/src/encoding/uri_encoder_extensions.dart';

/// Extensions for encoding values using deepObject style parameter encoding.
///
/// DeepObject style is ONLY for query parameters with object values.
/// According to OpenAPI spec:
/// - Only works with objects
/// - Always requires explode=true
/// - Produces parameter entries like:
///   `(name: 'paramName[key1]', value: 'value1')`
extension DeepObjectStringMapEncoder on Map<String, String> {
  /// Encodes this Map using deepObject style encoding.
  ///
  /// Returns a list of parameter entries where each entry has:
  /// - name: `paramName[key]`
  /// - value: the encoded value
  ///
  /// The [paramName] is required as it becomes part of the parameter names.
  /// The [explode] parameter must be true; deepObject style always explodes.
  /// The [allowEmpty] parameter controls whether empty maps are allowed.
  /// The [alreadyEncoded] parameter indicates values are already URI-encoded.
  ///
  /// When [allowReserved] is true, RFC 3986 reserved characters in each VALUE
  /// are kept literal. Keys remain `Uri.encodeComponent`-encoded because they
  /// form part of the parameter name `name[key]`, as do the `[` `]` brackets.
  ///
  /// Throws [EncodingException] if explode is false.
  /// Throws [EmptyValueException] if the map is empty and allowEmpty is false.
  List<ParameterEntry> toDeepObject(
    String paramName, {
    required bool explode,
    required bool allowEmpty,
    bool alreadyEncoded = false,
    bool allowReserved = false,
  }) {
    if (!explode) {
      throw const EncodingException(
        'deepObject style requires explode=true',
      );
    }

    if (isEmpty && !allowEmpty) {
      throw const EmptyValueException();
    }

    if (isEmpty) {
      return [];
    }

    return entries.map((e) {
      final encodedKey = Uri.encodeComponent(e.key);
      final encodedValue = alreadyEncoded
          ? e.value
          : e.value.uriEncode(allowEmpty: true, allowReserved: allowReserved);
      return (name: '$paramName[$encodedKey]', value: encodedValue);
    }).toList();
  }
}
