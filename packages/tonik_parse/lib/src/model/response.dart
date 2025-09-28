import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/header.dart';
import 'package:tonik_parse/src/model/media_type.dart';
import 'package:tonik_parse/src/model/reference.dart';

part 'response.g.dart';

@JsonSerializable(createToJson: false)
class Response {
  Response({
    required this.description,
    required this.headers,
    required this.content,
  });

  factory Response.fromJson(Map<String, dynamic> json) =>
      _$ResponseFromJson(json);

  final String description;
  final Map<String, ReferenceWrapper<Header>>? headers;
  final Map<String, MediaType>? content;

  // We ignore the links property.

  @override
  String toString() =>
      'Response{description: $description, headers: $headers, '
      'content: $content}';
}
