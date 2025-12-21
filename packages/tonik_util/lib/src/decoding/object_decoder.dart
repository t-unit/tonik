import 'package:tonik_util/src/decoding/decoding_exception.dart';

/// Extensions for decoding URI-encoded objects from strings.
///
/// Provides functionality to decode flat objects (key-value pairs) from
/// URI-encoded strings according to RFC 6570 URI Template specification.
/// Supports both form and simple encoding styles with explode variations.
extension ObjectDecoder on String? {
  /// Decodes a URI-encoded object string into a map of key-value pairs.
  ///
  /// Parses a URI-encoded string containing object properties and returns
  /// a map where keys are property names and values are the decoded values.
  /// Supports both exploded and non-exploded formats, as well as list
  /// properties.
  ///
  /// ## Explode Format
  ///
  /// When [explode] is `true`, properties are encoded as `key=value` pairs
  /// separated by [explodeSeparator]:
  /// - Form style: `name=John&age=30` (separator: `&`)
  /// - Simple style: `name=John,age=30` (separator: `,`)
  ///
  /// For list properties in exploded format:
  /// - `tags=foo,bar,baz` (comma-separated values for a single property)
  ///
  /// ## Non-Explode Format
  ///
  /// When [explode] is `false`, properties are encoded in alternating
  /// key-value format separated by commas:
  /// - `name,John,age,30`
  ///
  /// For list properties in non-exploded format, the decoder consumes
  /// values until the next expected key is found:
  /// - `tags,foo,bar,baz,name,John` (tags gets `foo,bar,baz`)
  ///
  /// ## Parameters
  ///
  /// - [explode]: Whether the encoding uses explode format.
  /// - [explodeSeparator]: Separator between key=value pairs when exploded.
  ///   Typically `&` for form style or `,` for simple style.
  /// - [expectedKeys]: Set of property names to decode. Additional keys
  ///   in the input are ignored for forward compatibility.
  /// - [listKeys]: Subset of [expectedKeys] that contain list values.
  ///   These properties will consume comma-separated values.
  /// - [context]: Optional context string included in error messages
  ///   to help identify where decoding failed.
  ///
  /// ## Returns
  ///
  /// A map of property names to their decoded string values. List values
  /// are returned as comma-separated strings.
  ///
  /// ## Throws
  ///
  /// - [InvalidFormatException] if the input is null or empty.
  /// - [InvalidFormatException] if the format is invalid (e.g., missing `=` in
  ///   exploded format, odd number of parts in non-exploded format without
  ///   lists, or missing value after a key).
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Form style exploded
  /// 'name=John&age=30'.decodeObject(
  ///   explode: true,
  ///   explodeSeparator: '&',
  ///   expectedKeys: {'name', 'age'},
  ///   listKeys: {},
  /// );
  /// // Returns: {'name': 'John', 'age': '30'}
  ///
  /// // Simple style with list
  /// 'tags,foo,bar,baz,name,Test'.decodeObject(
  ///   explode: false,
  ///   explodeSeparator: ',',
  ///   expectedKeys: {'tags', 'name'},
  ///   listKeys: {'tags'},
  /// );
  /// // Returns: {'tags': 'foo,bar,baz', 'name': 'Test'}
  /// ```
  Map<String, String> decodeObject({
    required bool explode,
    required String explodeSeparator,
    required Set<String> expectedKeys,
    required Set<String> listKeys,
    String? context,
  }) {
    if (this == null || this!.isEmpty) {
      throw InvalidFormatException(
        value: '',
        format:
            'non-empty object string${context != null ? ' for $context' : ''}',
      );
    }

    final values = <String, String>{};

    if (explode) {
      _parseExploded(
        this!,
        explodeSeparator,
        expectedKeys,
        listKeys,
        values,
        context,
      );
    } else {
      _parseNonExploded(
        this!,
        expectedKeys,
        listKeys,
        values,
        context,
      );
    }

    return values;
  }

  /// Parses exploded format where properties are encoded as key=value pairs.
  ///
  /// Splits the input by [separator] and processes each key=value pair.
  /// For list properties, supports both repeated keys (e.g., `a=1&a=2&a=3`)
  /// and comma-separated values (e.g., `a=1,2,3`).
  /// Tokens that don't contain `=` are treated as continuation of the previous
  /// list value.
  /// Tokens without `=` that are not part of a list are skipped for forward
  /// compatibility.
  void _parseExploded(
    String value,
    String separator,
    Set<String> expectedKeys,
    Set<String> listKeys,
    Map<String, String> result,
    String? context,
  ) {
    final pairs = value.split(separator);

    var i = 0;
    while (i < pairs.length) {
      final pair = pairs[i];
      final parts = pair.split('=');

      if (parts.length == 1) {
        i++;
        continue;
      }

      if (parts.length != 2) {
        throw InvalidFormatException(
          value: pair,
          format: 'key=value pair${context != null ? ' in $context' : ''}',
        );
      }

      final key = Uri.decodeComponent(parts[0]);

      if (!expectedKeys.contains(key)) {
        i++;
        continue;
      }

      final rawValue = parts[1];

      if (listKeys.contains(key)) {
        final listParts = <String>[rawValue];

        i++;
        while (i < pairs.length) {
          final nextPair = pairs[i];
          if (nextPair.contains('=')) {
            break;
          }

          listParts.add(nextPair);
          i++;
        }

        if (result.containsKey(key)) {
          result[key] = '${result[key]},${listParts.join(',')}';
        } else {
          result[key] = listParts.join(',');
        }
      } else {
        result[key] = rawValue;
        i++;
      }
    }
  }

  /// Parses non-exploded format with alternating key-value pairs.
  ///
  /// Splits the input by comma and processes pairs in sequence:
  /// key,value,key,value.
  /// For list properties, continues consuming values until an expected
  /// key is found.
  /// This handles the ambiguity where comma could be a separator or part
  /// of a list.
  void _parseNonExploded(
    String value,
    Set<String> expectedKeys,
    Set<String> listKeys,
    Map<String, String> result,
    String? context,
  ) {
    final parts = value.split(',');

    var i = 0;
    while (i < parts.length) {
      final rawKey = parts[i];
      final key = Uri.decodeComponent(rawKey);

      if (!expectedKeys.contains(key)) {
        i += 2;
        continue;
      }

      i++;

      if (i >= parts.length) {
        throw InvalidFormatException(
          value: key,
          format:
              'alternating key-value format with value after '
              'key${context != null ? ' in $context' : ''}',
        );
      }

      if (listKeys.contains(key)) {
        final listValues = <String>[];

        while (i < parts.length) {
          final potentialValue = parts[i];
          final decodedPotentialValue = Uri.decodeComponent(potentialValue);

          if (expectedKeys.contains(decodedPotentialValue)) {
            break;
          }

          listValues.add(potentialValue);
          i++;
        }

        result[key] = listValues.join(',');
      } else {
        final rawValue = parts[i];

        result[key] = rawValue;
        i++;
      }
    }
  }
}
