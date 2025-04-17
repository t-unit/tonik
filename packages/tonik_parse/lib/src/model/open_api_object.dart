import 'package:json_annotation/json_annotation.dart';
import 'package:tonik_parse/src/model/components.dart';
import 'package:tonik_parse/src/model/info.dart';
import 'package:tonik_parse/src/model/path_item.dart';
import 'package:tonik_parse/src/model/server.dart';
import 'package:tonik_parse/src/model/tag.dart';

part 'open_api_object.g.dart';

/// Based on https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.4.md
@JsonSerializable()
class OpenApiObject {
  OpenApiObject({
    required this.info,
    required this.servers,
    required this.paths,
    required this.components,
    required this.tags,
  });

  factory OpenApiObject.fromJson(Map<String, dynamic> json) =>
      _$OpenApiObjectFromJson(json);

  final Info info;
  final List<Server>? servers;
  final Map<String, PathItem> paths;
  final Components? components;
  final List<Tag>? tags;

  // We ignore openapi, security and externalDocs properties.

  @override
  String toString() =>
      'OpenApiObject{info: $info, servers: $servers, paths: $paths, '
      'components: $components, tags: $tags}';
}
