import 'package:tonik_core/tonik_core.dart';

/// Collects all known JSON property keys for a model.
///
/// For ClassModel, these are the property names.
/// For AllOfModel, this is the union of all member known keys.
Set<String> collectKnownKeys(Model model) {
  return switch (model) {
    ClassModel(:final properties) => properties.map((p) => p.name).toSet(),
    AllOfModel(:final models) => models.expand(collectKnownKeys).toSet(),
    OneOfModel(:final discriminator, :final models) => {
      ?discriminator,
      ...models.expand((m) => collectKnownKeys(m.model)),
    },
    AnyOfModel(:final discriminator, :final models) => {
      ?discriminator,
      ...models.expand((m) => collectKnownKeys(m.model)),
    },
    AliasModel(:final model) => collectKnownKeys(model),
    _ => <String>{},
  };
}

/// Collects all property keys that correspond to list models.
///
/// For ClassModel, these are properties whose model is a [ListModel].
/// For AllOfModel, this is the union across all members.
Set<String> collectListKeys(Model model) {
  return switch (model) {
    ClassModel(:final properties) =>
      properties.where((p) => p.model is ListModel).map((p) => p.name).toSet(),
    AllOfModel(:final models) => models.expand(collectListKeys).toSet(),
    AliasModel(:final model) => collectListKeys(model),
    _ => <String>{},
  };
}
