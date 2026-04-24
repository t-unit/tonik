/// Extension for converting maps with non-string values to parameter maps.
///
/// Maps with non-string values (e.g., `Map<String, int>`) need to be
/// converted to `Map<String, String>` before they can be encoded using
/// the standard parameter encoding extensions (toSimple, toLabel, toMatrix,
/// toForm, uriEncode).
extension MapParameterEncoder<V> on Map<String, V> {
  /// Converts this map to a `Map<String, String>` for parameter encoding.
  ///
  /// Values are converted via `.toString()`. This is suitable for maps
  /// whose values are primitives (int, double, bool, num, String).
  Map<String, String> toParameterMap() =>
      map((key, value) => MapEntry(key, value.toString()));
}
