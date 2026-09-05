import 'package:tonik_core/tonik_core.dart';

class ApiDocument({
  required final String title,
  required final String version,
  required var Set<Model> models,
  required var Set<ResponseHeader> responseHeaders,
  required var Set<RequestHeader> requestHeaders,
  required var Set<Server> servers,
  required var Set<Operation> operations,
  required var Set<Response> responses,
  required var Set<QueryParameter> queryParameters,
  required var Set<PathParameter> pathParameters,
  required var Set<CookieParameter> cookieParameters,
  required var Set<RequestBody> requestBodies,
  var String? summary,
  var String? description,
  var Contact? contact,
  var License? license,
  var String? termsOfService,
  var ExternalDocumentation? externalDocs,
}) {
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
      'ApiDocument{title: $title, summary: $summary, '
      'description: $description, version: $version, contact: $contact, '
      'license: $license, termsOfService: $termsOfService, '
      'externalDocs: $externalDocs, models: $models, '
      'responseHeaders: $responseHeaders, requestHeaders: $requestHeaders, '
      'servers: $servers, queryParameters: $queryParameters, '
      'pathParameters: $pathParameters, cookieParameters: $cookieParameters, '
      'operations: $operations, responses: $responses, '
      'requestBodies: $requestBodies}';
}
