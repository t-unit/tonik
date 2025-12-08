import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Encoding styles supported for query parameters.
enum QueryParameterEncoding {
  /// Ampersand-separated values. Default style.
  /// Example: ?id=3&id=4&id=5 (with explode: true)
  /// Example: ?id=3,4,5 (with explode: false)
  form,

  /// Space-separated array values (only for non-exploded arrays).
  /// Example: ?id=3%204%205
  spaceDelimited,

  /// Pipe-separated array values (only for non-exploded arrays).
  /// Example: ?id=3|4|5
  pipeDelimited,

  /// Objects are serialized as `paramName[property]=value`.
  /// Example: `?id[role]=admin&id[firstName]=Alex`
  deepObject,
}

sealed class QueryParameter {
  const QueryParameter({required this.context});

  final Context context;

  QueryParameterObject resolve({String? name, String? nameOverride}) {
    switch (this) {
      case final QueryParameterObject param:
        return QueryParameterObject(
          name: name ?? param.name,
          nameOverride: nameOverride ?? param.nameOverride,
          rawName: param.rawName,
          description: param.description,
          isRequired: param.isRequired,
          isDeprecated: param.isDeprecated,
          allowEmptyValue: param.allowEmptyValue,
          allowReserved: param.allowReserved,
          explode: param.explode,
          model: param.model,
          encoding: param.encoding,
          context: context,
        );
      case final QueryParameterAlias alias:
        return alias.parameter.resolve(
          name: name ?? alias.name,
          nameOverride: nameOverride,
        );
    }
  }
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

class QueryParameterObject extends QueryParameter {
  QueryParameterObject({
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
    this.nameOverride,
  });

  // ID fields (immutable)
  final String? name;
  final String rawName;

  // Mutable fields
  String? nameOverride;
  String? description;
  bool isRequired;
  bool isDeprecated;
  bool allowEmptyValue;
  bool allowReserved;
  bool explode;
  Model model;
  QueryParameterEncoding encoding;

  @override
  String toString() =>
      'QueryParameter{name: $name, nameOverride: $nameOverride, '
      'rawName: $rawName, description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, allowEmptyValue: $allowEmptyValue, '
      'allowReserved: $allowReserved, explode: $explode, '
      'model: $model, encoding: $encoding}';
}
