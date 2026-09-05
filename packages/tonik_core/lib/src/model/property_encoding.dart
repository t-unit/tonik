import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Serialization styles for encoding properties.
///
/// These match the query parameter styles allowed in the OAS encoding object.
enum EncodingStyle() {
  form,
  spaceDelimited,
  pipeDelimited,
  deepObject,
}

/// Encoding metadata for a single property in an
/// application/x-www-form-urlencoded request body.
@immutable
class const FieldEncoding({
  required final bool allowReserved,
  required final EncodingStyle? style,
  required final bool? explode,
}) {
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
class const PartEncoding._({
  required final ContentType? contentType,
  required final String? rawContentType,
  required final String? wireContentType,
  required final TextEncoding textEncoding,
  required final Map<String, ResponseHeader>? headers,
  required final EncodingStyle? style,
  required final bool? explode,
  required final bool? allowReserved,
}) {
  const new({
    required ContentType? contentType,
    required String? rawContentType,
    required Map<String, ResponseHeader>? headers,
    required EncodingStyle? style,
    required bool? explode,
    required bool? allowReserved,
    String? wireContentType,
    TextEncoding textEncoding = TextEncoding.utf8,
  }) : this._(
         contentType: contentType,
         rawContentType: rawContentType,
         wireContentType: wireContentType ?? rawContentType,
         textEncoding: textEncoding,
         headers: headers,
         style: style,
         explode: explode,
         allowReserved: allowReserved,
       );

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
