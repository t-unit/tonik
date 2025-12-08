import 'package:tonik_core/src/transformer/name_override_applier.dart';
import 'package:tonik_core/tonik_core.dart';

/// Applies configuration to an ApiDocument, returning a transformed document.
class ConfigTransformer {
  const ConfigTransformer();

  /// Applies all configuration overrides to the given [ApiDocument].
  /// Mutates models, operations, and tags in place.
  /// Returns the same document.
  ApiDocument apply(ApiDocument document, TonikConfig config) {
    final overrides = config.nameOverrides;
    final hasAnyOverrides =
        overrides.schemas.isNotEmpty ||
        overrides.properties.isNotEmpty ||
        overrides.operations.isNotEmpty ||
        overrides.parameters.isNotEmpty ||
        overrides.enums.isNotEmpty ||
        overrides.tags.isNotEmpty;

    if (!hasAnyOverrides) {
      return document;
    }

    final applier = NameOverrideApplier();

    // Mutate models in place
    if (overrides.schemas.isNotEmpty) {
      applier.applySchemaOverrides(document.models, overrides.schemas);
    }
    if (overrides.properties.isNotEmpty) {
      applier.applyPropertyOverrides(document.models, overrides.properties);
    }
    if (overrides.enums.isNotEmpty) {
      applier.applyEnumValueOverrides(document.models, overrides.enums);
    }

    // Mutate operations in place
    if (overrides.operations.isNotEmpty) {
      applier.applyOperationOverrides(
        document.operations,
        overrides.operations,
      );
    }

    // Mutate tags and parameters
    if (overrides.tags.isNotEmpty || overrides.parameters.isNotEmpty) {
      for (final op in document.operations) {
        if (overrides.tags.isNotEmpty) {
          applier.applyTagOverrides(op.tags, overrides.tags);
        }
        if (overrides.parameters.isNotEmpty) {
          final opId = op.operationId;
          // Mutate parameters/headers in place
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

    return document;
  }
}
