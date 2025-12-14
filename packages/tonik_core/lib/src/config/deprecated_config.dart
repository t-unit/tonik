import 'package:meta/meta.dart';

/// How to handle deprecated elements during code generation.
enum DeprecatedHandling {
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
class DeprecatedConfig {
  const DeprecatedConfig({
    this.operations = DeprecatedHandling.annotate,
    this.schemas = DeprecatedHandling.annotate,
    this.parameters = DeprecatedHandling.annotate,
    this.properties = DeprecatedHandling.annotate,
  });

  final DeprecatedHandling operations;
  final DeprecatedHandling schemas;
  final DeprecatedHandling parameters;
  final DeprecatedHandling properties;

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
