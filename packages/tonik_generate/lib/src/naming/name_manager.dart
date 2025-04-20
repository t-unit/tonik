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
  @visibleForTesting
  final responseNames = <Response, String>{};
  @protected
  final operationNames = <Operation, String>{};
  @protected
  final tagNames = <Tag, String>{};
  @protected
  @visibleForTesting
  final requestBodyNames = <RequestBody, String>{};

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
        final name = responseName(response);
        _logResponseName(name, response);
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
        requestBodyName(requestBody);
      }
    }
  }

  /// Gets a cached or generates a new unique class name for a model.
  String modelName(Model model) =>
      modelNames.putIfAbsent(model, () => generator.generateModelName(model));

  /// Gets a cached or generates a new unique response class name.
  String responseName(Response response) => responseNames.putIfAbsent(
    response,
    () => generator.generateResponseName(response),
  );

  /// Gets a cached or generates a new unique operation name.
  String operationName(Operation operation) => operationNames.putIfAbsent(
    operation,
    () => generator.generateOperationName(operation),
  );

  /// Gets a cached or generates a new unique API class name for a tag.
  String tagName(Tag tag) =>
      tagNames.putIfAbsent(tag, () => generator.generateTagName(tag));

  /// Gets a cached or generates a new unique request body class name.
  String requestBodyName(RequestBody requestBody) =>
      requestBodyNames.putIfAbsent(
        requestBody,
        () => generator.generateRequestBodyName(requestBody),
      );

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
}
