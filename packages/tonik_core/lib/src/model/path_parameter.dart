import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Encoding styles supported for path parameters.
enum PathParameterEncoding {
  /// Comma-separated values. Default style.
  /// Example: /users/3,4,5
  simple,

  /// Dot-prefixed values (.param).
  /// Example: /users/.3,4,5
  label,

  /// Semicolon-prefixed values (;param).
  /// Example: /users/;id=3,4,5
  matrix,
}

sealed class PathParameter {
  const PathParameter({required this.context});

  final Context context;

  /// The description of the parameter.
  /// For aliases, this may override the referenced parameter's description.
  String? get description;

  PathParameterObject resolve({String? name, String? nameOverride}) {
    switch (this) {
      case final PathParameterObject param:
        return PathParameterObject(
          name: name ?? param.name,
          nameOverride: nameOverride ?? param.nameOverride,
          rawName: param.rawName,
          description: param.description,
          isRequired: param.isRequired,
          isDeprecated: param.isDeprecated,
          allowEmptyValue: param.allowEmptyValue,
          explode: param.explode,
          model: param.model,
          encoding: param.encoding,
          context: context,
          examples: param.examples,
          defaultValue: param.defaultValue,
        );
      case final PathParameterAlias alias:
        return alias.parameter.resolve(
          name: name ?? alias.name,
          nameOverride: nameOverride,
        );
    }
  }
}

@immutable
class PathParameterAlias extends PathParameter {
  const PathParameterAlias({
    required this.name,
    required this.parameter,
    required super.context,
    this.description,
  });

  final String name;
  final PathParameter parameter;

  @override
  final String? description;

  @override
  String toString() =>
      'PathParameterAlias{name: $name, parameter: $parameter, '
      'description: $description}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathParameterAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          parameter == other.parameter &&
          description == other.description &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, parameter, description, context);
}

class PathParameterObject extends PathParameter {
  PathParameterObject({
    required this.name,
    required this.rawName,
    required this.description,
    required this.isRequired,
    required this.isDeprecated,
    required this.allowEmptyValue,
    required this.explode,
    required this.model,
    required this.encoding,
    required super.context,
    required this.examples,
    required this.defaultValue,
    this.nameOverride,
  });

  final String? name;
  final String rawName;

  String? nameOverride;

  @override
  String? description;
  bool isRequired;
  bool isDeprecated;
  bool allowEmptyValue;
  bool explode;
  Model model;
  PathParameterEncoding encoding;
  List<Example> examples;

  /// Raw OpenAPI `default` value declared on the parameter's schema.
  ///
  /// Not validated against the parameter's resolved type. `null` is
  /// overloaded: it means both "no `default` keyword" and `default: null`
  /// and the two are treated identically downstream by design.
  Object? defaultValue;

  @override
  String toString() =>
      'PathParameterObject{name: $name, nameOverride: $nameOverride, '
      'description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, allowEmptyValue: $allowEmptyValue, '
      'explode: $explode, model: $model, encoding: $encoding, '
      'defaultValue: $defaultValue, examples: $examples}';
}
