import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/server_variable.dart';

part 'server.g.dart';

@JsonSerializable(createToJson: false)
class Server {
  Server({required this.url, this.description, this.variables});

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);
  final String url;
  final String? description;
  final Map<String, ServerVariable>? variables;

  @override
  String toString() =>
      'Server{url: $url, description: $description, '
      'variables: $variables}';
}
