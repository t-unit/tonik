import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/reference.dart';

class Response({
  required final String description,
  required final Map<String, ReferenceWrapper<Header>>? headers,
  required final Map<String, ReferenceWrapper<MediaType>>? content,
}) {
  factory fromJson(Map<String, dynamic> json) => Response(
    description: json['description'] as String,
    headers: _parseHeaders(json['headers']),
    content: (json['content'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<MediaType>.fromJson(e)),
    ),
  );

  // We ignore the links property.

  @override
  String toString() =>
      'Response{description: $description, headers: $headers, '
      'content: $content}';
}

Map<String, ReferenceWrapper<Header>>? _parseHeaders(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final headers = <String, ReferenceWrapper<Header>>{};
  for (final entry in value.entries) {
    try {
      headers[entry.key] = ReferenceWrapper<Header>.fromJson(entry.value);
      // Optional header definitions use casts and format checks.
      // ignore: avoid_catching_errors
    } on TypeError catch (error) {
      if (error is MalformedReferenceError) rethrow;
    } on FormatException {
      continue;
    }
  }
  return headers;
}
