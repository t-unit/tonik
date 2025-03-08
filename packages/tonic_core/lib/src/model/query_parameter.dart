import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';

sealed class QueryParameter {
  const QueryParameter({required this.context});

  final Context context;
}

@immutable
class QueryParameterAlias extends QueryParameter {
  const QueryParameterAlias({
    required this.name,
    required this.parameter,
    required super.context,
  });

  final String name;
  final QueryParameter parameter;

  @override
  String toString() =>
      'QueryParameterAlias{name: $name, parameter: $parameter}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryParameterAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          parameter == other.parameter &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, parameter);
}

@immutable
class QueryParameterObject extends QueryParameter {
  const QueryParameterObject({
    required this.name,
    required this.rawName,
    required this.description,
    required this.isRequired,
    required this.isDeprecated,
    required this.allowEmptyValue,
    required this.allowReserved,
    required this.explode,
    required this.model,
    required this.encoding,
    required super.context,
  });

  final String? name;

  /// The name used inside the HTTP request to identify the query parameter.
  final String rawName;
  final String? description;
  final bool isRequired;
  final bool isDeprecated;
  final bool allowEmptyValue;
  final bool allowReserved;
  final bool explode;
  final Model model;
  final ParameterEncoding encoding;

  @override
  String toString() => 'QueryParameter{name: $name, rawName: $rawName, '
      'description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, allowEmptyValue: $allowEmptyValue, '
      'allowReserved: $allowReserved, explode: $explode, '
      'model: $model, encoding: $encoding}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryParameterObject &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          isRequired == other.isRequired &&
          isDeprecated == other.isDeprecated &&
          allowEmptyValue == other.allowEmptyValue &&
          allowReserved == other.allowReserved &&
          explode == other.explode &&
          model == other.model &&
          encoding == other.encoding &&
          context == other.context &&
          rawName == other.rawName;

  @override
  int get hashCode => Object.hash(
        name,
        description,
        isRequired,
        isDeprecated,
        allowEmptyValue,
        allowReserved,
        explode,
        model,
        encoding,
        context,
        rawName,
      );
}
