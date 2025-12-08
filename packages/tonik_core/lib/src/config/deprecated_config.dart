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

/// Configuration for handling deprecated operations and schemas.
@immutable
class DeprecatedConfig {
  const DeprecatedConfig({
    this.operations = DeprecatedHandling.annotate,
    this.schemas = DeprecatedHandling.annotate,
  });

  final DeprecatedHandling operations;
  final DeprecatedHandling schemas;

  @override
  String toString() =>
      'DeprecatedConfig{operations: $operations, schemas: $schemas}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeprecatedConfig &&
          runtimeType == other.runtimeType &&
          operations == other.operations &&
          schemas == other.schemas;

  @override
  int get hashCode => Object.hash(operations, schemas);
}
