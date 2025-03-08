import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';

@immutable
class ApiDocument {
  const ApiDocument({
    required this.title,
    required this.version,
    required this.models,
    required this.responseHeaders,
    required this.requestHeaders,
    required this.servers,
    required this.operations,
    required this.responses,
    required this.queryParameters,
    this.description,
  });

  final String title;
  final String? description;
  final String version;

  final Set<Model> models;
  final Set<ResponseHeader> responseHeaders;
  final Set<RequestHeader> requestHeaders;
  final Set<QueryParameter> queryParameters;

  final Set<Server> servers;

  final Set<Operation> operations;
  final Set<Response> responses;

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
      'version: $version, models: $models, responseHeaders: $responseHeaders, '
      'requestHeaders: $requestHeaders, servers: $servers, '
      'queryParameters: $queryParameters, operations: $operations, '
      'responses: $responses}';
}
