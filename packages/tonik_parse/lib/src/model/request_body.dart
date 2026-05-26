import 'package:tonik_parse/src/model/media_type.dart';

class RequestBody {
  RequestBody({
    required this.description,
    required this.content,
    required this.isRequired,
  });

  factory RequestBody.fromJson(Map<String, dynamic> json) => RequestBody(
    description: json['description'] as String?,
    content: (json['content'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, MediaType.fromJson(e as Map<String, dynamic>)),
    ),
    isRequired: json['required'] as bool?,
  );

  final String? description;
  final Map<String, MediaType> content;
  final bool? isRequired;

  @override
  String toString() =>
      'RequestBody{description: $description, content: $content, '
      'isRequired: $isRequired}';
}
