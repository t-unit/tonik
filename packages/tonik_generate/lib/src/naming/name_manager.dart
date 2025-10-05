import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_generator.dart';

/// Manages name generation and caches results for consistent naming.
class NameManager {
  NameManager({required this.generator});

  final NameGenerator generator;

  final modelNames = <Model, String>{};

  final operationNames = <Operation, String>{};

  final tagNames = <Tag, String>{};

  final variantNames = <String, String>{};

  @visibleForTesting
  final Map<
    String,
    ({String baseName, Map<Server, String> serverMap, String customName})
  >
  serverNamesCache = {};

  @visibleForTesting
  final Map<RequestBody, (String baseName, Map<String, String> subclassNames)>
  requestBodyNameCache = {};

  @visibleForTesting
  final Map<
    Operation,
    (String baseName, Map<ResponseStatus, String> subclassNames)
  >
  responseWrapperNameCache = {};

  @visibleForTesting
  final Map<
    Response,
    ({String baseName, Map<String, String> implementationNames})
  >
  responseAndImplementationNames = {};

  final log = Logger('NameManager');

  /// Primes the name generator with all names from the given objects.
  /// This ensures consistent naming across multiple calls.
  void prime({
    required Iterable<Model> models,
    required Iterable<RequestBody> requestBodies,
    required Iterable<Response> responses,
    required Iterable<Operation> operations,
    required Iterable<Tag> tags,
    required Iterable<Server> servers,
  }) {
    final result = serverNames(servers.toList());
    for (final entry in result.serverMap.entries) {
      _logServerName(entry.value, entry.key);
    }

    // Process models in order: root-level models first, then nested models
    // This prevents naming conflicts where nested models get processed
    // before root models
    final sortedModels =
        models.toList()..sort((a, b) {
          // First, sort by context path length (shorter paths first)
          final aPathLength = a.context.path.length;
          final bPathLength = b.context.path.length;
          if (aPathLength != bPathLength) {
            return aPathLength.compareTo(bPathLength);
          }

          // For models with the same path length, sort by name
          final aName = a is NamedModel ? (a.name ?? '') : '';
          final bName = b is NamedModel ? (b.name ?? '') : '';
          return aName.compareTo(bName);
        });

    for (final model in sortedModels.where(
      (m) => m is NamedModel && m.name != null,
    )) {
      final name = modelName(model);
      _logModelName(name, model);
    }

    for (final model in sortedModels.where(
      (m) => m is! NamedModel || m.name == null,
    )) {
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
    return responseAndImplementationNames.putIfAbsent(response, () {
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

  /// Generates a unique variant name for composite model variants.
  ///
  /// This method generates unique names for OneOf, AllOf, and AnyOf variants
  /// without creating dummy models. It uses the original model's name
  /// if available, falls back to discriminator values, and ensures uniqueness
  /// within the context.
  ///
  /// Parameters:
  /// - [parentClassName]: The name of the parent composite model
  /// - [model]: The model to generate a variant name for
  /// - [discriminatorValue]: Optional discriminator value to use as fallback
  String generateVariantName({
    required String parentClassName,
    required Model model,
    required String? discriminatorValue,
  }) {
    // Create a cache key for this variant
    final cacheKey =
        '$parentClassName:${model.hashCode}:${discriminatorValue ?? 'null'}';

    return variantNames.putIfAbsent(cacheKey, () {
      return generator.generateVariantName(
        parentClassName,
        model,
        discriminatorValue,
      );
    });
  }

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

  /// Helper method to create a cache key from a list of servers
  /// This ensures that lists with equal content generate the same key
  @visibleForTesting
  String createServerCacheKey(List<Server> servers) {
    return servers.map((s) => '${s.url}|${s.description ?? "null"}').join(',');
  }

  /// Generates names for a list of servers at once, using a smart algorithm
  /// that creates concise, intuitive names.
  ///
  /// This method caches results based on the content equality of servers,
  /// so lists with the same server content will always return the same result.
  ///
  /// Returns a record with a map of servers to names and a custom server name.
  ({String baseName, Map<Server, String> serverMap, String customName})
  serverNames(List<Server> servers) {
    // Create a cache key based on server content rather than list identity
    final cacheKey = createServerCacheKey(servers);

    // Check if we already have cached names for this content
    if (serverNamesCache.containsKey(cacheKey)) {
      return serverNamesCache[cacheKey]!;
    }

    // Generate names for all servers in the list
    final result = generator.generateServerNames(servers);

    // Cache the result using the content-based key
    serverNamesCache[cacheKey] = result;

    return result;
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

  void _logServerName(String name, Server server) {
    final serverDesc = server.description ?? server.url;
    log.fine('Name for server $serverDesc: $name');
  }
}
