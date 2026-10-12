import 'package:logging/logging.dart';
import 'package:tonik_core/tonik_core.dart' as core;

core.ContentType resolveContentType(
  String mediaType, {
  required Map<String, core.ContentTypeMapping> contentTypes,
  required Logger log,
}) => switch (resolveContentTypeMapping(
  mediaType,
  contentTypes: contentTypes,
  log: log,
)) {
  final core.ContentType contentType => contentType,
  core.StreamingContentType() => core.ContentType.bytes,
};

core.ContentTypeMapping resolveContentTypeMapping(
  String mediaType, {
  required Map<String, core.ContentTypeMapping> contentTypes,
  required Logger log,
}) {
  final lowerMediaType = mediaType.toLowerCase().split(';').first.trim();

  // Overrides may target either the raw media type or its parameter-stripped
  // form.
  if (contentTypes.containsKey(mediaType)) {
    return contentTypes[mediaType]!;
  }
  if (contentTypes.containsKey(lowerMediaType)) {
    return contentTypes[lowerMediaType]!;
  }
  switch (lowerMediaType) {
    case 'application/x-ndjson':
      return core.StreamingContentType.ndjson;
    case 'application/jsonl':
      return core.StreamingContentType.jsonLines;
    case 'application/json-seq':
      return core.StreamingContentType.jsonSequence;
    case 'text/event-stream':
      return core.StreamingContentType.sse;
    case 'application/json':
      return core.ContentType.json;
    case 'text/plain':
      return core.ContentType.text;
    case 'application/octet-stream':
      return core.ContentType.bytes;
    case 'application/x-www-form-urlencoded':
      return core.ContentType.form;
    case 'multipart/form-data':
      return core.ContentType.multipart;
    // "+json" suffix types like vnd.api+json or problem+json carry a JSON
    // payload despite not being literally application/json.
    case final type when type.endsWith('+json'):
      return core.ContentType.json;
    default:
      log.warning(
        'Unknown content type "$mediaType", defaulting to bytes. '
        'Configure explicit content type in tonik.yaml if needed.',
      );
      return core.ContentType.bytes;
  }
}
