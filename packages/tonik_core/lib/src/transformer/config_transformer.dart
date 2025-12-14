import 'package:tonik_core/src/transformer/filter_applier.dart';
import 'package:tonik_core/src/transformer/name_override_applier.dart';
import 'package:tonik_core/tonik_core.dart';

/// Applies configuration to an ApiDocument, returning a transformed document.
class ConfigTransformer {
  const ConfigTransformer();

  /// Applies all configuration to the given [ApiDocument].
  ApiDocument apply(ApiDocument document, TonikConfig config) {
    final overrides = config.nameOverrides;
    final filter = config.filter;
    final hasAnyOverrides =
        overrides.schemas.isNotEmpty ||
        overrides.properties.isNotEmpty ||
        overrides.operations.isNotEmpty ||
        overrides.parameters.isNotEmpty ||
        overrides.enums.isNotEmpty ||
        overrides.tags.isNotEmpty;

    final hasAnyFilters =
        filter.includeTags.isNotEmpty ||
        filter.excludeTags.isNotEmpty ||
        filter.excludeOperations.isNotEmpty ||
        filter.excludeSchemas.isNotEmpty;

    if (!hasAnyOverrides && !hasAnyFilters) {
      return document;
    }

    if (hasAnyFilters) {
      const filterApplier = FilterApplier();

      if (filter.includeTags.isNotEmpty || filter.excludeTags.isNotEmpty) {
        document.operations = filterApplier.filterByTags(
          operations: document.operations,
          includeTags: filter.includeTags,
          excludeTags: filter.excludeTags,
        );
      }

      if (filter.excludeOperations.isNotEmpty) {
        document.operations = filterApplier.filterByOperationId(
          operations: document.operations,
          excludeOperations: filter.excludeOperations,
        );
      }

      if (filter.excludeSchemas.isNotEmpty) {
        document.models = filterApplier.filterSchemas(
          models: document.models,
          excludeSchemas: filter.excludeSchemas,
        );
      }
    }

    if (hasAnyOverrides) {
      final applier = NameOverrideApplier();

      if (overrides.schemas.isNotEmpty) {
        applier.applySchemaOverrides(document.models, overrides.schemas);
      }
      if (overrides.properties.isNotEmpty) {
        applier.applyPropertyOverrides(document.models, overrides.properties);
      }
      if (overrides.enums.isNotEmpty) {
        applier.applyEnumValueOverrides(document.models, overrides.enums);
      }

      if (overrides.operations.isNotEmpty) {
        applier.applyOperationOverrides(
          document.operations,
          overrides.operations,
        );
      }

      if (overrides.tags.isNotEmpty || overrides.parameters.isNotEmpty) {
        for (final op in document.operations) {
          if (overrides.tags.isNotEmpty) {
            applier.applyTagOverrides(op.tags, overrides.tags);
          }
          if (overrides.parameters.isNotEmpty) {
            final opId = op.operationId;
            applier
              ..applyQueryParameterOverrides(
                op.queryParameters,
                opId,
                overrides.parameters,
              )
              ..applyPathParameterOverrides(
                op.pathParameters,
                opId,
                overrides.parameters,
              )
              ..applyHeaderOverrides(
                op.headers,
                opId,
                overrides.parameters,
              );
          }
        }
      }
    }

    return document;
  }
}
