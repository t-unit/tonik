import 'package:tonik_parse/src/model/components.dart';
import 'package:tonik_parse/src/model/external_documentation.dart';
import 'package:tonik_parse/src/model/info.dart';
import 'package:tonik_parse/src/model/path_item.dart';
import 'package:tonik_parse/src/model/reference.dart';
import 'package:tonik_parse/src/model/server.dart';
import 'package:tonik_parse/src/model/tag.dart';

/// Based on https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.4.md
class OpenApiObject {
  OpenApiObject({
    required this.openapi,
    required this.info,
    required this.servers,
    required this.paths,
    required this.components,
    required this.tags,
    this.externalDocs,
  });

  factory OpenApiObject.fromJson(Map<String, dynamic> json) => OpenApiObject(
    openapi: json['openapi'] as String,
    info: Info.fromJson(json['info'] as Map<String, dynamic>),
    servers: (json['servers'] as List<dynamic>?)
        ?.map((e) => Server.fromJson(e as Map<String, dynamic>))
        .toList(),
    paths: (json['paths'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, ReferenceWrapper<PathItem>.fromJson(e)),
    ),
    components: json['components'] == null
        ? null
        : Components.fromJson(json['components'] as Map<String, dynamic>),
    tags: (json['tags'] as List<dynamic>?)
        ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
        .toList(),
    externalDocs: json['externalDocs'] == null
        ? null
        : ExternalDocumentation.fromJson(
            json['externalDocs'] as Map<String, dynamic>,
          ),
  );

  final String openapi;
  final Info info;
  final List<Server>? servers;
  final Map<String, ReferenceWrapper<PathItem>> paths;
  final Components? components;
  final List<Tag>? tags;
  final ExternalDocumentation? externalDocs;

  // We ignore security properties.

  @override
  String toString() =>
      'OpenApiObject{openapi: $openapi, info: $info, servers: $servers, '
      'paths: $paths, components: $components, tags: $tags, '
      'externalDocs: $externalDocs}';
}
