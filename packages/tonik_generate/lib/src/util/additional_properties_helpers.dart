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

const _ficUrl =
    'package:fast_immutable_collections/fast_immutable_collections.dart';

/// Builds the `TypeReference` for the additional-properties map field.
///
/// - Typed AP → `Map<String, T>` where `T` comes from the value model.
/// - Unrestricted AP → `Map<String, Object?>`.
///
/// When [useImmutableCollections] is `true`, `IMap` is used instead of `Map`.
TypeReference additionalPropertiesType(
  AdditionalProperties? additionalProperties,
  NameManager nameManager,
  String package, {
  bool useImmutableCollections = false,
}) {
  final mapSymbol = useImmutableCollections ? 'IMap' : 'Map';
  final mapUrl = useImmutableCollections ? _ficUrl : 'dart:core';

  if (additionalProperties is TypedAdditionalProperties) {
    return TypeReference(
      (b) => b
        ..symbol = mapSymbol
        ..url = mapUrl
        ..types.addAll([
          refer('String', 'dart:core'),
          typeReference(
            additionalProperties.valueModel,
            nameManager,
            package,
            useImmutableCollections: useImmutableCollections,
          ),
        ]),
    );
  }
  return TypeReference(
    (b) => b
      ..symbol = mapSymbol
      ..url = mapUrl
      ..types.addAll([
        refer('String', 'dart:core'),
        refer('Object?', 'dart:core'),
      ]),
  );
}
