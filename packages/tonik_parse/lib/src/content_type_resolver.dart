import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;

/// Resolves media types to [core.ContentType] values.
///
/// This resolver handles standard OpenAPI 3.x media types and allows
/// for custom overrides via configuration.
core.ContentType resolveContentType(
  String mediaType, {
  required Map<String, core.ContentType> contentTypes,
  required Logger log,
}) {
  if (contentTypes.containsKey(mediaType)) {
    return contentTypes[mediaType]!;
  }

  final lowerMediaType = mediaType.toLowerCase();
  switch (lowerMediaType) {
    case 'application/json':
      return core.ContentType.json;
    case 'text/plain':
      return core.ContentType.text;
    case 'application/octet-stream':
      return core.ContentType.bytes;
    case 'application/x-www-form-urlencoded':
      return core.ContentType.form;
    default:
      log.warning(
        'Unknown content type "$mediaType", defaulting to bytes. '
        'Configure explicit content type in tonik.yaml if needed.',
      );
      return core.ContentType.bytes;
  }
}
