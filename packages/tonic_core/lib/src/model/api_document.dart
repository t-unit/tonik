import 'package:meta/meta.dart';
import 'package:tonic_core/src/model/header.dart';
import 'package:tonic_core/src/model/model.dart';
import 'package:tonic_core/src/model/server.dart';
import 'package:tonic_core/src/model/tagged_operations.dart';

@immutable
class ApiDocument {
  const ApiDocument({
    required this.title,
    required this.version,
    required this.models,
    required this.headers,
    required this.servers,
    required this.taggedOperations,
    this.description,
  });

  final String title;
  final String? description;
  final String version;

  final Set<Model> models;
  final Set<Header> headers;
  final Set<Server> servers;

  final Set<TaggedOperations> taggedOperations;

  @override
  String toString() => 'ApiDocument{title: $title, description: $description, '
      'version: $version, models: $models, headers: $headers, '
      'servers: $servers, taggedOperations: $taggedOperations}';
}
