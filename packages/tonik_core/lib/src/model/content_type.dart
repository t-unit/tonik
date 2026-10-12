sealed class const ContentTypeMapping();

enum ContentType() implements ContentTypeMapping {
  json,
  text,
  bytes,
  form,
  multipart,
}

enum StreamingContentType() implements ContentTypeMapping {
  ndjson,
  jsonLines,
  jsonSequence,
  sse,
}
