import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Serialization styles for encoding properties.
///
/// These match the query parameter styles allowed in the OAS encoding object.
enum EncodingStyle {
  form,
  spaceDelimited,
  pipeDelimited,
  deepObject,
}

/// Encoding metadata for a single property in an
/// application/x-www-form-urlencoded request body.
@immutable
class FieldEncoding {
  const FieldEncoding({
    required this.allowReserved,
    required this.style,
    required this.explode,
  });

  /// Whether reserved characters are allowed without encoding.
  final bool allowReserved;

  /// Serialization style for this property.
  final EncodingStyle? style;

  /// Whether arrays/objects generate separate values.
  final bool? explode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldEncoding &&
          runtimeType == other.runtimeType &&
          allowReserved == other.allowReserved &&
          style == other.style &&
          explode == other.explode;

  @override
  int get hashCode => Object.hash(allowReserved, style, explode);

  @override
  String toString() =>
      'FieldEncoding(allowReserved: $allowReserved, '
      'style: $style, explode: $explode)';
}

/// Encoding metadata for a single property in a multipart/form-data
/// request body.
@immutable
class PartEncoding {
  const PartEncoding({
    required this.contentType,
    required this.rawContentType,
    required this.headers,
    required this.style,
    required this.explode,
    required this.allowReserved,
  });

  /// Typed content type for this property's part.
  final ContentType? contentType;

  /// Raw content type string for this property's part (e.g. 'application/json').
  final String? rawContentType;

  /// Per-part headers, resolved from encoding header refs.
  final Map<String, ResponseHeader>? headers;

  /// Serialization style for this property.
  final EncodingStyle? style;

  /// Whether arrays/objects generate separate values.
  final bool? explode;

  /// Whether reserved characters are allowed without encoding.
  final bool? allowReserved;

  /// Whether this encoding uses style-based serialization mode.
  ///
  /// True when any of [style], [explode], or [allowReserved] is non-null,
  /// meaning the OAS spec explicitly specified at least one of these fields.
  /// When false, serialization is content-based (determined by [contentType]).
  bool get isStyleBased =>
      style != null || explode != null || allowReserved != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartEncoding &&
          runtimeType == other.runtimeType &&
          contentType == other.contentType &&
          rawContentType == other.rawContentType &&
          headers == other.headers &&
          style == other.style &&
          explode == other.explode &&
          allowReserved == other.allowReserved;

  @override
  int get hashCode => Object.hash(
    contentType,
    rawContentType,
    headers,
    style,
    explode,
    allowReserved,
  );

  @override
  String toString() =>
      'PartEncoding(contentType: $contentType, '
      'rawContentType: $rawContentType, '
      'headers: $headers, style: $style, explode: $explode, '
      'allowReserved: $allowReserved)';
}
