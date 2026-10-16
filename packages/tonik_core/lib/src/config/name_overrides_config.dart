import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Configuration for overriding generated names.
@immutable
class const NameOverridesConfig({
  /// Schema name overrides: `originalName -> newName`.
  required final Map<String, String> schemas,

  /// Property name overrides: `"SchemaName.propertyName" -> newName`.
  required final Map<String, String> properties,

  /// Operation name overrides: `operationId -> newMethodName`.
  required final Map<String, String> operations,

  /// Parameter name overrides: `"operationId.parameterName" -> newName`.
  required final Map<String, String> parameters,

  /// Enum value name overrides: `"EnumName.VALUE" -> newValue`.
  required final Map<String, String> enums,

  /// Tag to API class name overrides: `tagName -> ApiClassName`.
  required final Map<String, String> tags,
}) {
  static const _mapEquality = MapEquality<String, String>();

  @override
  String toString() =>
      'NameOverridesConfig{schemas: $schemas, properties: $properties, '
      'operations: $operations, parameters: $parameters, '
      'enums: $enums, tags: $tags}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NameOverridesConfig &&
          runtimeType == other.runtimeType &&
          _mapEquality.equals(schemas, other.schemas) &&
          _mapEquality.equals(properties, other.properties) &&
          _mapEquality.equals(operations, other.operations) &&
          _mapEquality.equals(parameters, other.parameters) &&
          _mapEquality.equals(enums, other.enums) &&
          _mapEquality.equals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
    _mapEquality.hash(schemas),
    _mapEquality.hash(properties),
    _mapEquality.hash(operations),
    _mapEquality.hash(parameters),
    _mapEquality.hash(enums),
    _mapEquality.hash(tags),
  );
}
