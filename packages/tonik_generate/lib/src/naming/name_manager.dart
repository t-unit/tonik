import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';

/// Manages name generation and caches results for consistent naming.
class NameManager {
  NameManager({required this.generator});

  final NameGenerator generator;

  @protected
  final modelNames = <Model, String>{};

  @protected
  final operationNames = <Operation, String>{};

  @protected
  final tagNames = <Tag, String>{};

  @protected
  @visibleForTesting
  final Map<RequestBody, (String baseName, Map<String, String> subclassNames)>
  requestBodyNameCache = {};

  @protected
  @visibleForTesting
  final Map<
    Operation,
    (String baseName, Map<ResponseStatus, String> subclassNames)
  >
  responseWrapperNameCache = {};

  @protected
  @visibleForTesting
  final Map<
    Response,
    ({String baseName, Map<String, String> implementationNames})
  >
  responsAndImplementationNames = {};

  final log = Logger('NameManager');

  /// Primes the name generator with all names from the given objects.
  /// This ensures consistent naming across multiple calls.
  void prime({
    required Iterable<Model> models,
    required Iterable<RequestBody> requestBodies,
    required Iterable<Response> responses,
    required Iterable<Operation> operations,
    required Iterable<Tag> tags,
  }) {
    for (final model in models) {
      final name = modelName(model);
      _logModelName(name, model);
    }
    for (final response in responses) {
      // Generate names for responses with headers or multiple bodies
      if (response.hasHeaders || response.bodyCount > 1) {
        final (:baseName, :implementationNames) = responseNames(response);
        _logResponseName(baseName, response);
      }
    }
    for (final operation in operations) {
      final name = operationName(operation);
      _logOperationName(name, operation);
    }
    for (final tag in tags) {
      final name = tagName(tag);
      _logTagName(name, tag);
    }
    for (final requestBody in requestBodies) {
      // Skip request bodies with only one content type as content
      // is used directly.
      if (requestBody.contentCount > 1) {
        requestBodyNames(requestBody);
        _logRequestBodyNames(requestBody);
      }
    }
  }

  /// Gets a cached or generates a new unique class name for a model.
  String modelName(Model model) =>
      modelNames.putIfAbsent(model, () => generator.generateModelName(model));

  /// Gets a cached or generates a new unique response class 
  /// name and implementation names.
  ///
  /// Returns a record with the base name and a map of content 
  /// types to implementation names.
  ({String baseName, Map<String, String> implementationNames}) responseNames(
    Response response,
  ) {
    return responsAndImplementationNames.putIfAbsent(response, () {
      final baseName = generator.generateResponseName(response);
      final implementationNames = <String, String>{};

      if (response is ResponseObject && response.bodies.length > 1) {
        for (final body in response.bodies) {
          implementationNames[body.rawContentType] = generator
              .generateResponseImplementationName(baseName, body);
        }
      }

      return (baseName: baseName, implementationNames: implementationNames);
    });
  }

  /// Gets a cached or generates a new unique operation name.
  String operationName(Operation operation) => operationNames.putIfAbsent(
    operation,
    () => generator.generateOperationName(operation),
  );

  /// Gets a cached or generates a new unique API class name for a tag.
  String tagName(Tag tag) =>
      tagNames.putIfAbsent(tag, () => generator.generateTagName(tag));

  /// Returns the base name and subclass names for a request body.
  ///
  /// The base name is used for the sealed class, while the subclass
  /// names are used for the concrete implementations for each content type.
  (String baseName, Map<String, String> subclassNames) requestBodyNames(
    RequestBody requestBody,
  ) {
    return requestBodyNameCache.putIfAbsent(
      requestBody,
      () => generator.generateRequestBodyNames(requestBody),
    );
  }

  /// Returns the base name and subclass names for a response wrapper.
  ///
  /// The base name is used for the sealed class, while the subclass
  /// names are used for the concrete implementations for each status.
  (String baseName, Map<ResponseStatus, String> subclassNames)
  responseWrapperNames(Operation operation) {
    return responseWrapperNameCache.putIfAbsent(
      operation,
      () => generator.generateResponseWrapperNames(
        operationName(operation),
        operation.responses,
      ),
    );
  }

  void _logModelName(String name, Model model) {
    final modelName =
        model is NamedModel && model.name != null ? model.name : model.context;
    log.fine('Name for model $modelName: $name');
  }

  void _logResponseName(String name, Response response) {
    final responseName = response.name ?? response.context;
    log.fine('Name for response $responseName: $name');
  }

  void _logOperationName(String name, Operation operation) {
    final operationName =
        operation.operationId ?? '${operation.method}:${operation.path}';
    log.fine('Name for operation $operationName: $name');
  }

  void _logTagName(String name, Tag tag) {
    final tagName = tag.name;
    log.fine('Name for tag $tagName: $name');
  }

  void _logRequestBodyNames(RequestBody requestBody) {
    final requestBodyName = requestBody.name ?? requestBody.context;
    log.fine('Name for request body $requestBodyName: $requestBodyName');
  }
}
