import 'package:tonik_parse/src/model/media_type.dart';

class RequestBody({
  required final String? description,
  required final Map<String, MediaType> content,
  required final bool? isRequired,
}) {
  factory fromJson(Map<String, dynamic> json) => RequestBody(
    description: json['description'] as String?,
    content: (json['content'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, MediaType.fromJson(e as Map<String, dynamic>)),
    ),
    isRequired: json['required'] as bool?,
  );

  @override
  String toString() =>
      'RequestBody{description: $description, content: $content, '
      'isRequired: $isRequired}';
}
