import 'package:tonik_parse/src/model/server_variable.dart';

class Server({
  required final String url,
  final String? description,
  final Map<String, ServerVariable>? variables,
}) {
  factory fromJson(Map<String, dynamic> json) => Server(
    url: json['url'] as String,
    description: json['description'] as String?,
    variables: (json['variables'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, ServerVariable.fromJson(e as Map<String, dynamic>)),
    ),
  );

  @override
  String toString() =>
      'Server{url: $url, description: $description, '
      'variables: $variables}';
}
