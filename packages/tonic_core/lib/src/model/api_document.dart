import 'package:meta/meta.dart';
import 'package:tonic_core/src/model/model.dart';
import 'package:tonic_core/src/model/server.dart';

@immutable
class ApiDocument {
  const ApiDocument({
    required this.title,
    required this.version,
    required this.models,
    required this.servers,
    this.description,
  });

  final String title;
  final String? description;
  final String version;

  final Set<Model> models;
  final Set<Server> servers;

  @override
  String toString() => 'ApiDocument{title: $title, description: $description, '
      'version: $version, models: $models, servers: $servers}';
}
