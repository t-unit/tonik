import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/tonic_generate.dart';

/// Manages name generation and caches results for consistent naming.
class NameManger {
  NameManger({required this.generator});

  final NameGenerator generator;

  final _modelNames = <Model, String>{};
  final _responseNames = <Response, String>{};
  final _responseHeaderNames = <ResponseHeader, String>{};
  final _requestHeaderNames = <RequestHeader, String>{};
  final _queryParameterNames = <QueryParameter, String>{};
  final _pathParameterNames = <PathParameter, String>{};
  final _operationNames = <Operation, String>{};
  final _tagNames = <Tag, String>{};

  /// Primes the name generator with all names from the given objects.
  /// This ensures consistent naming across multiple calls.
  void prime({
    required Iterable<Model> models,
    required Iterable<Response> responses,
    required Iterable<ResponseHeader> responseHeaders,
    required Iterable<Operation> operations,
    required Iterable<RequestHeader> requestHeaders,
    required Iterable<QueryParameter> queryParameters,
    required Iterable<PathParameter> pathParameters,
    required Iterable<Tag> tags,
  }) {
    for (final model in models) {
      modelName(model);
    }
    for (final response in responses) {
      responseName(response);
    }
    for (final header in responseHeaders) {
      responseHeaderName(header);
    }
    for (final operation in operations) {
      operationName(operation);
    }
    for (final header in requestHeaders) {
      requestHeaderName(header);
    }
    for (final parameter in queryParameters) {
      queryParameterName(parameter);
    }
    for (final parameter in pathParameters) {
      pathParameterName(parameter);
    }
    for (final tag in tags) {
      tagName(tag);
    }
  }

  /// Gets a cached or generates a new unique class name for a model.
  String modelName(Model model) =>
      _modelNames.putIfAbsent(model, () => generator.generateModelName(model));

  /// Gets a cached or generates a new unique response class name.
  String responseName(Response response) => _responseNames.putIfAbsent(
    response,
    () => generator.generateResponseName(response),
  );

  /// Gets a cached or generates a new unique response header name.
  String responseHeaderName(ResponseHeader header) =>
      _responseHeaderNames.putIfAbsent(
        header,
        () => generator.generateResponseHeaderName(header),
      );

  /// Gets a cached or generates a new unique request header name.
  String requestHeaderName(RequestHeader header) => _requestHeaderNames
      .putIfAbsent(header, () => generator.generateRequestHeaderName(header));

  /// Gets a cached or generates a new unique query parameter name.
  String queryParameterName(QueryParameter parameter) =>
      _queryParameterNames.putIfAbsent(
        parameter,
        () => generator.generateQueryParameterName(parameter),
      );

  /// Gets a cached or generates a new unique path parameter name.
  String pathParameterName(PathParameter parameter) =>
      _pathParameterNames.putIfAbsent(
        parameter,
        () => generator.generatePathParameterName(parameter),
      );

  /// Gets a cached or generates a new unique operation name.
  String operationName(Operation operation) => _operationNames
      .putIfAbsent(operation, () => generator.generateOperationName(operation));

  /// Gets a cached or generates a new unique API class name for a tag.
  String tagName(Tag tag) =>
      _tagNames.putIfAbsent(tag, () => generator.generateTagName(tag));
}
