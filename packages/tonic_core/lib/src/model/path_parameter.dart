import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';

sealed class PathParameter {
  const PathParameter({required this.context});

  final Context context;
}

@immutable
class PathParameterAlias extends PathParameter {
  const PathParameterAlias({
    required this.name,
    required this.parameter,
    required super.context,
  });

  final String name;
  final PathParameter parameter;

  @override
  String toString() => 'PathParameterAlias{name: $name, parameter: $parameter}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathParameterAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          parameter == other.parameter &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, parameter);
}

@immutable
class PathParameterObject extends PathParameter {
  const PathParameterObject({
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
  });

  final String? name;
  final String rawName;
  final String? description;
  final bool isRequired;
  final bool isDeprecated;
  final bool allowEmptyValue;
  final bool explode;
  final Model model;
  final ParameterEncoding encoding;

  @override
  String toString() => 'PathParameterObject{name: $name, '
      'description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, allowEmptyValue: $allowEmptyValue, '
      'explode: $explode, model: $model, encoding: $encoding}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathParameterObject &&
          runtimeType == other.runtimeType &&
          rawName == other.rawName &&
          name == other.name &&
          description == other.description &&
          isRequired == other.isRequired &&
          isDeprecated == other.isDeprecated &&
          allowEmptyValue == other.allowEmptyValue &&
          explode == other.explode &&
          model == other.model &&
          encoding == other.encoding &&
          context == other.context;

  @override
  int get hashCode => Object.hash(
        rawName,
        name,
        description,
        isRequired,
        isDeprecated,
        allowEmptyValue,
        explode,
        model,
        encoding,
        context,
      );
}
