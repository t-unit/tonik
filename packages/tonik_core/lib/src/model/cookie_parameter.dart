import 'package:meta/meta.dart';
import 'package:tonik_core/src/model/effective_default.dart';
import 'package:tonik_core/tonik_core.dart';

/// Encoding styles supported for cookie parameters.
enum CookieParameterEncoding() {
  /// Form style encoding. The only style for cookies.
  /// Example: sessionId=abc123
  form,
}

sealed class const CookieParameter({required final Context context}) {
  /// The description of the parameter.
  /// For aliases, this may override the referenced parameter's description.
  String? get description;

  CookieParameterObject resolve({String? name, String? nameOverride}) {
    switch (this) {
      case final CookieParameterObject param:
        return CookieParameterObject(
          name: name ?? param.name,
          nameOverride: nameOverride ?? param.nameOverride,
          rawName: param.rawName,
          description: param.description,
          isRequired: param.isRequired,
          isDeprecated: param.isDeprecated,
          explode: param.explode,
          model: param.model,
          encoding: param.encoding,
          context: context,
          examples: param.examples,
          defaultValue: param.defaultValue,
        );
      case final CookieParameterAlias alias:
        return alias.parameter.resolve(
          name: name ?? alias.name,
          nameOverride: nameOverride,
        );
    }
  }
}

@immutable
class const CookieParameterAlias({
  required final String name,
  required final CookieParameter parameter,
  required super.context,
  @override final String? description,
}) extends CookieParameter {
  @override
  String toString() =>
      'CookieParameterAlias{name: $name, parameter: $parameter, '
      'description: $description}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookieParameterAlias &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          parameter == other.parameter &&
          description == other.description &&
          context == other.context;

  @override
  int get hashCode => Object.hash(name, parameter, description, context);
}

class CookieParameterObject({
  required final String? name,

  /// The name used inside the HTTP request to identify the cookie.
  required final String rawName,
  @override required var String? description,
  required var bool isRequired,
  required var bool isDeprecated,
  required var bool explode,
  required var Model model,
  required var CookieParameterEncoding encoding,
  required super.context,
  required var List<Example> examples,
  required var Object? defaultValue,
  var String? nameOverride,
}) extends CookieParameter {
  Object? get effectiveDefaultValue => effectiveDefault(defaultValue, model);

  @override
  String toString() =>
      'CookieParameter{name: $name, nameOverride: $nameOverride, '
      'rawName: $rawName, description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, explode: $explode, '
      'model: $model, encoding: $encoding, defaultValue: $defaultValue, '
      'examples: $examples}';
}
