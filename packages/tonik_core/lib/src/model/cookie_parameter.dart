import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';

/// Encoding styles supported for cookie parameters.
enum CookieParameterEncoding {
  /// Form style encoding. The only style for cookies.
  /// Example: sessionId=abc123
  form,
}

sealed class CookieParameter {
  const CookieParameter({required this.context});

  final Context context;

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
class CookieParameterAlias extends CookieParameter {
  const CookieParameterAlias({
    required this.name,
    required this.parameter,
    required super.context,
    this.description,
  });

  final String name;
  final CookieParameter parameter;

  @override
  final String? description;

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
  int get hashCode => Object.hash(name, parameter, description);
}

class CookieParameterObject extends CookieParameter {
  CookieParameterObject({
    required this.name,
    required this.rawName,
    required this.description,
    required this.isRequired,
    required this.isDeprecated,
    required this.explode,
    required this.model,
    required this.encoding,
    required super.context,
    this.nameOverride,
  });

  final String? name;

  /// The name used inside the HTTP request to identify the cookie.
  final String rawName;

  String? nameOverride;

  @override
  String? description;
  bool isRequired;
  bool isDeprecated;
  bool explode;
  Model model;
  CookieParameterEncoding encoding;

  @override
  String toString() =>
      'CookieParameter{name: $name, nameOverride: $nameOverride, '
      'rawName: $rawName, description: $description, isRequired: $isRequired, '
      'isDeprecated: $isDeprecated, explode: $explode, '
      'model: $model, encoding: $encoding}';
}
