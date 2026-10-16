import 'package:meta/meta.dart';

/// How to handle deprecated elements during code generation.
enum DeprecatedHandling() {
  /// Add @Deprecated annotation to the generated code.
  annotate,

  /// Exclude deprecated elements from generated code entirely.
  exclude,

  /// Generate code without any deprecation indication.
  ignore,
}

/// Configuration for handling deprecated operations, schemas, parameters,
/// and properties.
@immutable
class const DeprecatedConfig({
  required final DeprecatedHandling operations,
  required final DeprecatedHandling schemas,
  required final DeprecatedHandling parameters,
  required final DeprecatedHandling properties,
}) {
  @override
  String toString() =>
      'DeprecatedConfig{operations: $operations, schemas: $schemas, '
      'parameters: $parameters, properties: $properties}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeprecatedConfig &&
          runtimeType == other.runtimeType &&
          operations == other.operations &&
          schemas == other.schemas &&
          parameters == other.parameters &&
          properties == other.properties;

  @override
  int get hashCode => Object.hash(operations, schemas, parameters, properties);
}
