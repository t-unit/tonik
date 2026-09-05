import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Serialization styles for encoding properties.
///
/// These match the query parameter styles allowed in the OAS encoding object.
enum EncodingStyle { form, spaceDelimited, pipeDelimited, deepObject }

/// Encoding metadata for a single property in an
/// application/x-www-form-urlencoded request body.
@immutable
class FieldEncoding {
  const FieldEncoding({
    required this.allowReserved,
    required this.style,
    required this.explode,
  });

  final bool allowReserved;
  final EncodingStyle? style;
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
    String? wireContentType,
    this.textEncoding = TextEncoding.utf8,
  }) : wireContentType = wireContentType ?? rawContentType;

  final ContentType? contentType;
  final String? rawContentType;
  final String? wireContentType;
  final TextEncoding textEncoding;
  final Map<String, ResponseHeader>? headers;
  final EncodingStyle? style;
  final bool? explode;
  final bool? allowReserved;

  /// When false, serialization is content-based, driven by [contentType].
  bool get isStyleBased =>
      style != null || explode != null || allowReserved != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartEncoding &&
          runtimeType == other.runtimeType &&
          contentType == other.contentType &&
          rawContentType == other.rawContentType &&
          wireContentType == other.wireContentType &&
          textEncoding == other.textEncoding &&
          headers == other.headers &&
          style == other.style &&
          explode == other.explode &&
          allowReserved == other.allowReserved;

  @override
  int get hashCode => Object.hash(
    contentType,
    rawContentType,
    wireContentType,
    textEncoding,
    headers,
    style,
    explode,
    allowReserved,
  );

  @override
  String toString() =>
      'PartEncoding(contentType: $contentType, '
      'rawContentType: $rawContentType, '
      'wireContentType: $wireContentType, textEncoding: $textEncoding, '
      'headers: $headers, style: $style, explode: $explode, '
      'allowReserved: $allowReserved)';
}
