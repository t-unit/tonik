import 'package:tonik_core/tonik_core.dart';

/// Applies name overrides from configuration to ApiDocument components.
///
/// This class is responsible for setting the `nameOverride` field on
/// models, operations, tags, and parameters based on the configuration
/// mappings.
class NameOverrideApplier {
  NameOverrideApplier();

  /// Applies schema name overrides to models.
  ///
  /// [models] - The set of models to apply overrides to.
  /// [overrides] - Map of original schema name to new name.
  ///
  /// Mutates models in place by setting their nameOverride field.
  void applySchemaOverrides(Set<Model> models, Map<String, String> overrides) {
    if (overrides.isEmpty) return;

    for (final model in models) {
      if (model is! NamedModel) continue;

      final name = model.name;
      final override = name == null ? null : overrides[name];
      if (override != null) {
        model.nameOverride = override;
      }
    }
  }

  /// Applies property name overrides to class models.
  ///
  /// [models] - The set of models to apply overrides to.
  /// [overrides] - Map of "SchemaName.propertyName" to new name.
  ///
  /// Mutates properties in place by setting their nameOverride field.
  void applyPropertyOverrides(
    Set<Model> models,
    Map<String, String> overrides,
  ) {
    if (overrides.isEmpty) return;

    for (final model in models) {
      if (model case final ClassModel classModel) {
        final schemaName = classModel.name;
        if (schemaName == null) continue;

        for (final prop in classModel.properties) {
          final key = '$schemaName.${prop.name}';
          final override = overrides[key];
          if (override != null) {
            prop.nameOverride = override;
          }
        }
      }
    }
  }

  /// Applies operation name overrides.
  ///
  /// [operations] - The set of operations to apply overrides to.
  /// [overrides] - Map of operationId to new method name.
  ///
  /// Mutates operations in place by setting their nameOverride field.
  void applyOperationOverrides(
    Set<Operation> operations,
    Map<String, String> overrides,
  ) {
    if (overrides.isEmpty) return;

    for (final op in operations) {
      final opId = op.operationId;
      final override = opId == null ? null : overrides[opId];
      if (override != null) {
        op.nameOverride = override;
      }
    }
  }

  /// Applies tag name overrides.
  ///
  /// [tags] - The set of tags to apply overrides to.
  /// [overrides] - Map of tag name to new API class name.
  ///
  /// Mutates tags in place by setting their nameOverride field.
  void applyTagOverrides(Set<Tag> tags, Map<String, String> overrides) {
    if (overrides.isEmpty) return;

    for (final tag in tags) {
      final override = overrides[tag.name];
      if (override != null) {
        tag.nameOverride = override;
      }
    }
  }

  /// Applies parameter name overrides to query parameters.
  ///
  /// [parameters] - The set of parameters to apply overrides to.
  /// [operationId] - The operation ID for matching "operationId.paramName".
  /// [overrides] - Map of "operationId.parameterName" to new name.
  ///
  /// Mutates QueryParameterObject instances in place by setting their
  /// nameOverride field.
  void applyQueryParameterOverrides(
    Set<QueryParameter> parameters,
    String? operationId,
    Map<String, String> overrides,
  ) {
    if (overrides.isEmpty || operationId == null) return;

    for (final param in parameters) {
      if (param is! QueryParameterObject) continue;

      final name = param.name;
      final key = name == null ? null : '$operationId.$name';
      final override = key == null ? null : overrides[key];
      if (override != null) {
        param.nameOverride = override;
      }
    }
  }

  /// Applies parameter name overrides to path parameters.
  ///
  /// [parameters] - The set of parameters to apply overrides to.
  /// [operationId] - The operation ID for matching "operationId.paramName".
  /// [overrides] - Map of "operationId.parameterName" to new name.
  ///
  /// Mutates PathParameterObject instances in place by setting their
  /// nameOverride field.
  void applyPathParameterOverrides(
    Set<PathParameter> parameters,
    String? operationId,
    Map<String, String> overrides,
  ) {
    if (overrides.isEmpty || operationId == null) return;

    for (final param in parameters) {
      if (param is! PathParameterObject) continue;

      final name = param.name;
      final key = name == null ? null : '$operationId.$name';
      final override = key == null ? null : overrides[key];
      if (override != null) {
        param.nameOverride = override;
      }
    }
  }

  /// Applies parameter name overrides to request headers.
  ///
  /// [headers] - The set of headers to apply overrides to.
  /// [operationId] - The operation ID for matching "operationId.headerName".
  /// [overrides] - Map of "operationId.headerName" to new name.
  ///
  /// Mutates RequestHeaderObject instances in place by setting their
  /// nameOverride field.
  void applyHeaderOverrides(
    Set<RequestHeader> headers,
    String? operationId,
    Map<String, String> overrides,
  ) {
    if (overrides.isEmpty || operationId == null) return;

    for (final header in headers) {
      if (header is! RequestHeaderObject) continue;

      final name = header.name;
      final key = name == null ? null : '$operationId.$name';
      final override = key == null ? null : overrides[key];
      if (override != null) {
        header.nameOverride = override;
      }
    }
  }

  /// Applies enum value name overrides.
  ///
  /// [models] - The set of models to apply overrides to.
  /// [overrides] - Map of "EnumName.VALUE" to new value name.
  ///
  /// Mutates enum models in place by updating their values set.
  void applyEnumValueOverrides(
    Set<Model> models,
    Map<String, String> overrides,
  ) {
    if (overrides.isEmpty) return;

    for (final model in models) {
      if (model is EnumModel<String>) {
        _applyEnumOverrides<String>(model, overrides);
      } else if (model is EnumModel<int>) {
        _applyEnumOverrides<int>(model, overrides);
      }
    }
  }

  void _applyEnumOverrides<T>(
    EnumModel<T> model,
    Map<String, String> overrides,
  ) {
    final name = model.name;
    if (name == null) return;

    var anyChanged = false;
    final newValues = <EnumEntry<T>>{};

    for (final entry in model.values) {
      final key = '$name.${entry.value}';
      final override = overrides[key];
      if (override == null || entry.nameOverride == override) {
        newValues.add(entry);
        continue;
      }

      anyChanged = true;
      newValues.add(EnumEntry<T>(value: entry.value, nameOverride: override));
    }

    if (anyChanged) {
      model.values = newValues;
    }
  }
}
