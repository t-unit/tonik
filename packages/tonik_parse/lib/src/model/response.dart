import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/reference.dart';

class Response {
  Response({
    required this.description,
    required this.headers,
    required this.content,
  });

  factory Response.fromJson(Map<String, dynamic> json) => Response(
    description: json['description'] as String,
    headers: (json['headers'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ReferenceWrapper<Header>.fromJson(e)),
    ),
    content: (json['content'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, MediaType.fromJson(e as Map<String, dynamic>)),
    ),
  );

  final String description;
  final Map<String, ReferenceWrapper<Header>>? headers;
  final Map<String, MediaType>? content;

  // We ignore the links property.

  @override
  String toString() =>
      'Response{description: $description, headers: $headers, '
      'content: $content}';
}
