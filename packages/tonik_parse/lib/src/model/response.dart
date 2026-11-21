import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/reference.dart';

class Response({
  required final Map<String, ReferenceWrapper<Header>>? headers,
  required final Map<String, ReferenceWrapper<MediaType>>? content,
  final String? summary,
  final String? description,
}) {
  factory fromJson(Map<String, dynamic> json) => Response(
    summary: json['summary'] as String?,
    description: json['description'] as String?,
    headers: (json['headers'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<Header>.fromJson(e)),
    ),
    content: (json['content'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<MediaType>.fromJson(e)),
    ),
  );

  // We ignore the links property.

  @override
  String toString() =>
      'Response{summary: $summary, description: $description, '
      'headers: $headers, content: $content}';
}
