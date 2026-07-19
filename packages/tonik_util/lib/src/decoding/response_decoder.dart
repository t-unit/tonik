import 'dart:convert';

import 'package:charset/charset.dart' as charset;
import 'package:dio/dio.dart';
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

/// Decodes raw response bytes as text.
///
/// Input is always `List<int>` (from ResponseType.bytes).
/// The `charset` parameter in [contentType] selects the decoder. When the
/// parameter is absent, UTF-8 is used for backwards compatibility.
/// Returns the decoded String.
String decodeResponseText(List<int>? bytes, {String? contentType}) {
  if (bytes == null) {
    throw const ResponseDecodingException(
      'Response bytes are null, cannot decode text.',
    );
  }

  final charsetName = _extractCharset(contentType);
  if (charsetName == null) {
    return utf8.decode(bytes, allowMalformed: true);
  }

  final normalized = _normalizeCharsetName(charsetName);
  if (normalized == 'gb18030' || normalized == 'csgb18030') {
    throw ResponseDecodingException(
      'Unsupported response charset: "$charsetName".',
    );
  }

  try {
    return switch (normalized) {
      'utf-16le' ||
      'csutf16le' => const charset.Utf16Decoder().decodeUtf16Le(bytes),
      'utf-16be' ||
      'csutf16be' => const charset.Utf16Decoder().decodeUtf16Be(bytes),
      'utf-32le' ||
      'csutf32le' => const charset.Utf32Decoder().decodeUtf32Le(bytes),
      'utf-32be' ||
      'csutf32be' => const charset.Utf32Decoder().decodeUtf32Be(bytes),
      _ => _decodeUsingNamedCharset(bytes, charsetName, normalized),
    };
  } on ResponseDecodingException {
    rethrow;
  } on Object catch (error) {
    throw ResponseDecodingException(
      'Failed to decode response body using charset "$charsetName": $error',
    );
  }
}

String _decodeUsingNamedCharset(
  List<int> bytes,
  String charsetName,
  String normalized,
) {
  final encoding = charset.Charset.getByName(normalized);
  if (encoding == null) {
    throw ResponseDecodingException(
      'Unsupported response charset: "$charsetName".',
    );
  }
  if (identical(encoding, charset.eucKr)) {
    throw ResponseDecodingException(
      'Unsupported response charset: "$charsetName".',
    );
  }

  if (identical(encoding, utf8)) {
    return utf8.decode(bytes, allowMalformed: true);
  }
  return encoding.decode(bytes);
}

String _normalizeCharsetName(String charsetName) {
  final normalized = charsetName.toLowerCase();
  return switch (normalized) {
    'utf8' ||
    'utf_8' ||
    'unicode-1-1-utf-8' ||
    'unicode11utf8' ||
    'unicode20utf8' ||
    'x-unicode20utf8' => 'utf-8',
    'sjis' || 'windows-31j' || 'x-sjis' => 'shift-jis',
    'x-gbk' => 'gbk',
    _ => normalized,
  };
}

String? _extractCharset(String? contentType) {
  if (contentType == null || contentType.trim().isEmpty) return null;

  final DioMediaType mediaType;
  try {
    mediaType = DioMediaType.parse(contentType);
  } on FormatException catch (error) {
    throw ResponseDecodingException(
      'Invalid response Content-Type header "$contentType": $error',
    );
  }
  final charsetName = mediaType.parameters['charset']?.trim();
  if (charsetName == null) return null;
  if (charsetName.isEmpty) {
    throw const ResponseDecodingException(
      'Response charset must not be empty.',
    );
  }
  return charsetName;
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
