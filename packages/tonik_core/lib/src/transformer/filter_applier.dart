import 'package:tonik_core/tonik_core.dart';

/// Applies filtering rules to operations and models based on configuration.
class FilterApplier {
  const FilterApplier();

  /// Filters operations by tags.
  ///
  /// If [includeTags] is not empty, only operations with at least one tag
  /// matching the include list are kept.
  ///
  /// Then, if [excludeTags] is not empty, operations with any tag matching
  /// the exclude list are removed.
  ///
  /// Returns a new set of filtered operations.
  Set<Operation> filterByTags({
    required Set<Operation> operations,
    required List<String> includeTags,
    required List<String> excludeTags,
  }) {
    var filtered = operations;

    if (includeTags.isNotEmpty) {
      filtered =
          filtered.where((operation) {
            return operation.tags.any((tag) => includeTags.contains(tag.name));
          }).toSet();
    }

    if (excludeTags.isNotEmpty) {
      filtered =
          filtered.where((operation) {
            return !operation.tags.any((tag) => excludeTags.contains(tag.name));
          }).toSet();
    }

    return filtered;
  }

  /// Filters operations by their operation ID.
  ///
  /// Removes operations whose `operationId` matches any ID in
  /// [excludeOperations].
  ///
  /// Returns a new set of filtered operations.
  Set<Operation> filterByOperationId({
    required Set<Operation> operations,
    required List<String> excludeOperations,
  }) {
    if (excludeOperations.isEmpty) {
      return operations;
    }

    return operations.where((operation) {
      return operation.operationId == null ||
          !excludeOperations.contains(operation.operationId);
    }).toSet();
  }

  /// Filters schemas by their name.
  ///
  /// Removes models whose name matches any name in [excludeSchemas].
  ///
  /// Returns a new set of filtered models.
  Set<Model> filterSchemas({
    required Set<Model> models,
    required List<String> excludeSchemas,
  }) {
    if (excludeSchemas.isEmpty) {
      return models;
    }

    return models.where((model) {
      if (model is! NamedModel) return true;
      return model.name == null || !excludeSchemas.contains(model.name);
    }).toSet();
  }
}
