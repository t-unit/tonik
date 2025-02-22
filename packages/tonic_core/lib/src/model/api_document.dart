import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';

@immutable
class ApiDocument {
  const ApiDocument({
    required this.title,
    required this.version,
    required this.models,
    required this.headers,
    required this.servers,
    required this.operations,
    this.description,
  });

  final String title;
  final String? description;
  final String version;

  final Set<Model> models;
  final Set<Header> headers;
  final Set<Server> servers;

  final Set<Operation> operations;

  Map<Tag, Set<Operation>> get operationsByTag {
    final taggedOperations = <Tag, Set<Operation>>{};

    for (final operation in operations) {
      for (final tag in operation.tags) {
        taggedOperations.update(
          tag,
          (ops) => ops..add(operation),
          ifAbsent: () => {operation},
        );
      }
    }

    return taggedOperations;
  }

  @override
  String toString() => 'ApiDocument{title: $title, description: $description, '
      'version: $version, models: $models, headers: $headers, '
      'servers: $servers, operations: $operations}';
}
