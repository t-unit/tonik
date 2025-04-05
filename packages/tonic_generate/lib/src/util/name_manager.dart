import 'package:logging/logging.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_generator.dart';

/// Manages name generation and caches results for consistent naming.
class NameManager {
  NameManager({required this.generator});

  final NameGenerator generator;

  final _modelNames = <Model, String>{};
  final _responseNames = <Response, String>{};
  final _responseHeaderNames = <ResponseHeader, String>{};
  final _requestHeaderNames = <RequestHeader, String>{};
  final _queryParameterNames = <QueryParameter, String>{};
  final _pathParameterNames = <PathParameter, String>{};
  final _operationNames = <Operation, String>{};
  final _tagNames = <Tag, String>{};

  final log = Logger('NameManager');

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
      final name = modelName(model);
      _logModelName(name, model);
    }
    for (final response in responses) {
      final name = responseName(response);
      _logResponseName(name, response);
    }
    for (final header in responseHeaders) {
      final name = responseHeaderName(header);
      _logResponseHeaderName(name, header);
    }
    for (final operation in operations) {
      final name = operationName(operation);
      _logOperationName(name, operation);
    }
    for (final header in requestHeaders) {
      final name = requestHeaderName(header);
      _logRequestHeaderName(name, header);
    }
    for (final parameter in queryParameters) {
      final name = queryParameterName(parameter);
      _logQueryParameterName(name, parameter);
    }
    for (final parameter in pathParameters) {
      final name = pathParameterName(parameter);
      _logPathParameterName(name, parameter);
    }
    for (final tag in tags) {
      final name = tagName(tag);
      _logTagName(name, tag);
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
  String responseHeaderName(ResponseHeader header) => _responseHeaderNames
      .putIfAbsent(header, () => generator.generateResponseHeaderName(header));

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
  String operationName(Operation operation) => _operationNames.putIfAbsent(
    operation,
    () => generator.generateOperationName(operation),
  );

  /// Gets a cached or generates a new unique API class name for a tag.
  String tagName(Tag tag) =>
      _tagNames.putIfAbsent(tag, () => generator.generateTagName(tag));

  void _logModelName(String name, Model model) {
    final modelName =
        model is NamedModel && model.name != null ? model.name : model.context;
    log.fine('Name for model $modelName: $name');
  }

  void _logResponseName(String name, Response response) {
    final responseName = response.name ?? response.context;
    log.fine('Name for response $responseName: $name');
  }

  void _logResponseHeaderName(String name, ResponseHeader header) {
    final responseHeaderName = header.name ?? header.context;
    log.fine('Name for response header $responseHeaderName: $name');
  }

  void _logOperationName(String name, Operation operation) {
    final operationName = operation.operationId ??
        '${operation.method}:${operation.path}';
    log.fine('Name for operation $operationName: $name');
  }

  void _logRequestHeaderName(String name, RequestHeader header) {
    final requestHeaderName = switch (header) {
      RequestHeaderAlias(:final name) => name,
      RequestHeaderObject() => header.name ?? header.rawName,
    };
    log.fine('Name for request header $requestHeaderName: $name');
  }

  void _logQueryParameterName(String name, QueryParameter parameter) {
    final queryParameterName = switch (parameter) {
      QueryParameterAlias(:final name) => name,
      QueryParameterObject() => parameter.name ?? parameter.rawName,
    };
    log.fine('Name for query parameter $queryParameterName: $name');
  }

  void _logPathParameterName(String name, PathParameter parameter) {
    final pathParameterName = switch (parameter) {
      PathParameterAlias(:final name) => name,
      PathParameterObject() => parameter.name ?? parameter.rawName,
    };
    log.fine('Name for path parameter $pathParameterName: $name');
  }

  void _logTagName(String name, Tag tag) {
    final tagName = tag.name;
    log.fine('Name for tag $tagName: $name');
  }
}
