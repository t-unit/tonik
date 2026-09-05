import 'package:meta/meta.dart';
import 'package:tonik_core/src/model/effective_default.dart';
import 'package:tonik_core/tonik_core.dart';

/// Encoding styles supported for query parameters.
enum QueryParameterEncoding() {
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

sealed class const QueryParameter({required final Context context}) {
  /// The description of the parameter.
  /// For aliases, this may override the referenced parameter's description.
  String? get description;

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
          examples: param.examples,
          defaultValue: param.defaultValue,
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
class const QueryParameterAlias({
  required final String name,
  required final QueryParameter parameter,
  required super.context,
  @override final String? description,
}) extends QueryParameter {
  @override
  String toString() =>
      'QueryParameterAlias{name: $name, parameter: $parameter, '
      'description: $description}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryParameterAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          parameter == other.parameter &&
          description == other.description &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, parameter, description, context);
}

class QueryParameterObject({
  required final String? name,
  required final String rawName,
  @override required var String? description,
  required var bool isRequired,
  required var bool isDeprecated,
  required var bool allowEmptyValue,
  required var bool allowReserved,
  required var bool explode,
  required var Model model,
  required var QueryParameterEncoding encoding,
  required super.context,
  required var List<Example> examples,
  required var Object? defaultValue,
  var String? nameOverride,
}) extends QueryParameter {
  Object? get effectiveDefaultValue => effectiveDefault(defaultValue, model);

  @override
  String toString() =>
      'QueryParameter{name: $name, nameOverride: $nameOverride, '
      'rawName: $rawName, description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, allowEmptyValue: $allowEmptyValue, '
      'allowReserved: $allowReserved, explode: $explode, '
      'model: $model, encoding: $encoding, defaultValue: $defaultValue, '
      'examples: $examples}';
}
