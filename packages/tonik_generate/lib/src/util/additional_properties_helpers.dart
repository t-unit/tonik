import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Whether the given [model] resolves to a collection type (list or map).
bool isCollectionModel(Model model) {
  if (model is ListModel || model is MapModel) return true;
  if (model is AliasModel) return isCollectionModel(model.resolved);
  return false;
}

/// Whether the given [additionalProperties] specification is active, meaning
/// it should result in a `Map` field being generated.
bool hasActiveAdditionalProperties(
  AdditionalProperties? additionalProperties,
) =>
    additionalProperties is UnrestrictedAdditionalProperties ||
    additionalProperties is TypedAdditionalProperties;

/// Picks a field name for the additional-properties map that does not collide
/// with any of the already-normalised property names.
String pickAdditionalPropertiesFieldName(
  List<({String normalizedName, Property property})> normalizedProperties,
) {
  final usedNames = normalizedProperties.map((p) => p.normalizedName).toSet();
  var candidate = 'additionalProperties';
  var counter = 2;
  while (usedNames.contains(candidate)) {
    candidate = 'additionalProperties$counter';
    counter++;
  }
  return candidate;
}

/// Builds the `TypeReference` for the additional-properties map field.
///
/// - Typed AP → `Map<String, T>` where `T` comes from the value model.
/// - Unrestricted AP → `Map<String, Object?>`.
TypeReference additionalPropertiesType(
  AdditionalProperties? additionalProperties,
  NameManager nameManager,
  String package,
) {
  if (additionalProperties is TypedAdditionalProperties) {
    return TypeReference(
      (b) => b
        ..symbol = 'Map'
        ..url = 'dart:core'
        ..types.addAll([
          refer('String', 'dart:core'),
          typeReference(additionalProperties.valueModel, nameManager, package),
        ]),
    );
  }
  return TypeReference(
    (b) => b
      ..symbol = 'Map'
      ..url = 'dart:core'
      ..types.addAll([
        refer('String', 'dart:core'),
        refer('Object?', 'dart:core'),
      ]),
  );
}
