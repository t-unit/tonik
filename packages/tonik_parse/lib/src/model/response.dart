import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/reference.dart';

class Response({
  required final String description,
  required final Map<String, ReferenceWrapper<Header>>? headers,
  required final Map<String, MediaType>? content,
}) {
  factory fromJson(Map<String, dynamic> json) => Response(
    description: json['description'] as String,
    headers: (json['headers'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<Header>.fromJson(e)),
    ),
    content: (json['content'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, MediaType.fromJson(e as Map<String, dynamic>)),
    ),
  );

  // We ignore the links property.

  @override
  String toString() =>
      'Response{description: $description, headers: $headers, '
      'content: $content}';
}
