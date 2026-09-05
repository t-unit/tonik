import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Configuration for overriding generated names.
@immutable
class const NameOverridesConfig({
  /// Schema name overrides: `originalName -> newName`.
  final Map<String, String> schemas = const {},

  /// Property name overrides: `"SchemaName.propertyName" -> newName`.
  final Map<String, String> properties = const {},

  /// Operation name overrides: `operationId -> newMethodName`.
  final Map<String, String> operations = const {},

  /// Parameter name overrides: `"operationId.parameterName" -> newName`.
  final Map<String, String> parameters = const {},

  /// Enum value name overrides: `"EnumName.VALUE" -> newValue`.
  final Map<String, String> enums = const {},

  /// Tag to API class name overrides: `tagName -> ApiClassName`.
  final Map<String, String> tags = const {},
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
