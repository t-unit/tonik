import 'package:logging/logging.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_generator.dart';

/// Manages name generation and caches results for consistent naming.
class NameManager {
  NameManager({required this.generator});

  final NameGenerator generator;

  final _modelNames = <Model, String>{};
  final _responseNames = <Response, String>{};
  final _operationNames = <Operation, String>{};
  final _tagNames = <Tag, String>{};

  final log = Logger('NameManager');

  /// Primes the name generator with all names from the given objects.
  /// This ensures consistent naming across multiple calls.
  void prime({
    required Iterable<Model> models,
    required Iterable<Response> responses,
    required Iterable<Operation> operations,
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
    for (final operation in operations) {
      final name = operationName(operation);
      _logOperationName(name, operation);
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

  void _logOperationName(String name, Operation operation) {
    final operationName = operation.operationId ??
        '${operation.method}:${operation.path}';
    log.fine('Name for operation $operationName: $name');
  }

  void _logTagName(String name, Tag tag) {
    final tagName = tag.name;
    log.fine('Name for tag $tagName: $name');
  }
}
