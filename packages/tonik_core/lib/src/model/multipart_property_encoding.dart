import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Serialization styles for multipart encoding properties.
///
/// These match the query parameter styles allowed in the OAS encoding object.
enum MultipartEncodingStyle {
  form,
  spaceDelimited,
  pipeDelimited,
  deepObject,
}

/// Encoding metadata for a single property in a multipart/form-data request.
@immutable
class MultipartPropertyEncoding {
  const MultipartPropertyEncoding({
    this.contentType,
    this.rawContentType,
    this.headers,
    this.style,
    this.explode,
    this.allowReserved,
  });

  /// Typed content type for this property's part.
  final ContentType? contentType;

  /// Raw content type string for this property's part (e.g. 'application/json').
  final String? rawContentType;

  /// Per-part headers, resolved from encoding header refs.
  final Map<String, ResponseHeader>? headers;

  /// Serialization style for this property.
  final MultipartEncodingStyle? style;

  /// Whether arrays/objects generate separate values.
  final bool? explode;

  /// Whether reserved characters are allowed without encoding.
  final bool? allowReserved;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MultipartPropertyEncoding &&
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
      'MultipartPropertyEncoding(contentType: $contentType, '
      'rawContentType: $rawContentType, '
      'headers: $headers, style: $style, explode: $explode, '
      'allowReserved: $allowReserved)';
}
