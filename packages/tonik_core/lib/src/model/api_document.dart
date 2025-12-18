import 'package:tonik_core/tonik_core.dart';

class ApiDocument {
  ApiDocument({
    required this.title,
    required this.version,
    required this.models,
    required this.responseHeaders,
    required this.requestHeaders,
    required this.servers,
    required this.operations,
    required this.responses,
    required this.queryParameters,
    required this.pathParameters,
    required this.requestBodies,
    this.description,
    this.contact,
    this.license,
    this.termsOfService,
    this.externalDocs,
  });

  final String title;
  final String version;

  String? description;
  Contact? contact;
  License? license;
  String? termsOfService;
  ExternalDocumentation? externalDocs;

  Set<Model> models;
  Set<ResponseHeader> responseHeaders;
  Set<RequestHeader> requestHeaders;
  Set<QueryParameter> queryParameters;
  Set<PathParameter> pathParameters;

  Set<Server> servers;

  Set<Operation> operations;
  Set<Response> responses;
  Set<RequestBody> requestBodies;

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

  Set<SecurityScheme> get securitySchemes {
    final schemes = <SecurityScheme>{};
    for (final operation in operations) {
      schemes.addAll(operation.securitySchemes);
    }
    return schemes;
  }

  @override
  String toString() =>
      'ApiDocument{title: $title, description: $description, '
      'version: $version, contact: $contact, license: $license, '
      'termsOfService: $termsOfService, externalDocs: $externalDocs, '
      'models: $models, responseHeaders: $responseHeaders, '
      'requestHeaders: $requestHeaders, servers: $servers, '
      'queryParameters: $queryParameters, pathParameters: $pathParameters, '
      'operations: $operations, responses: $responses, '
      'requestBodies: $requestBodies}';
}
