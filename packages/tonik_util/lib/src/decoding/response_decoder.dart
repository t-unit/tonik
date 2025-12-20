import 'dart:convert';

import 'package:tonik_util/src/decoding/decoding_exception.dart';

/// Decodes raw response bytes as JSON.
///
/// Input is always `List<int>` (from ResponseType.bytes).
/// Returns the decoded JSON (Map, List, primitive, etc.)
T decodeResponseJson<T>(List<int>? bytes) {
  if (bytes == null) {
    throw const ResponseDecodingException(
      'Response bytes are null, cannot decode JSON.',
    );
  }

  final jsonString = utf8.decode(bytes, allowMalformed: true);
  final decoded = jsonDecode(jsonString);

  if (decoded is! T) {
    throw ResponseDecodingException(
      'Expected JSON to decode to type $T, but got ${decoded.runtimeType}',
    );
  }
  return decoded;
}

/// Decodes raw response bytes as text (UTF-8).
///
/// Input is always `List<int>` (from ResponseType.bytes).
/// Returns the decoded String.
String decodeResponseText(List<int>? bytes) {
  if (bytes == null) {
    throw const ResponseDecodingException(
      'Response bytes are null, cannot decode text.',
    );
  }
  return utf8.decode(bytes, allowMalformed: true);
}

/// Returns raw response bytes as-is.
///
/// Input is always `List<int>` (from ResponseType.bytes).
/// Returns the raw bytes as `List<int>`.
List<int> decodeResponseBytes(List<int>? bytes) {
  if (bytes == null) {
    throw const ResponseDecodingException(
      'Response bytes are null.',
    );
  }
  return bytes;
}
