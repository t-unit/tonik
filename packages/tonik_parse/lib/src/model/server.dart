import 'package:json_annotation/json_annotation.dart';

part 'server.g.dart';

@JsonSerializable()
class Server {
  Server({required this.url, required this.description});

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);

  final String url;
  final String? description;

  // We ignore the variables property.

  @override
  String toString() => 'Server{url: $url, description: $description}';
}
