import 'package:tonik_core/src/model/model.dart';

/// Extension on `Model` providing stable key generation for sorting.
extension StableModelKey on Model {
  /// Creates a stable string representation of a model for sorting purposes.
  ///
  /// This ensures models with the same structure but different Set iteration
  /// orders produce the same string.
  ///
  /// Cycle detection is handled via a visited set — circular references produce
  /// the sentinel string `'<cycle>'`.
  String get stableKey => _computeStableKey(this, {});
}

String _computeStableKey(Model model, Set<Model> visiting) {
  if (!visiting.add(model)) return '<cycle>';
  try {
    return switch (model) {
      AllOfModel(:final models) =>
        'AllOfModel{${_stableSortedModels(models, visiting)}}',
      OneOfModel(:final models, :final discriminator) =>
        'OneOfModel{$discriminator,'
            '${_stableSortedDiscriminatedModels(models, visiting)}}',
      AnyOfModel(:final models, :final discriminator) =>
        'AnyOfModel{$discriminator,'
            '${_stableSortedDiscriminatedModels(models, visiting)}}',
      ListModel(:final content, :final name) =>
        'ListModel{$name,${_computeStableKey(content, visiting)}}',
      ClassModel(:final name, :final properties) =>
        'ClassModel{'
            '$name,'
            '${properties.map(
              (p) => '${p.name}:${_computeStableKey(p.model, visiting)}',
            ).join(',')}'
            '}',
      EnumModel(:final name, :final values) =>
        'EnumModel{$name,${_stableSortedEnumValues(values)}}',
      AliasModel(:final name, :final model) =>
        'AliasModel{$name,${_computeStableKey(model, visiting)}}',
      StringModel() => 'StringModel',
      IntegerModel() => 'IntegerModel',
      BooleanModel() => 'BooleanModel',
      NumberModel() => 'NumberModel',
      DoubleModel() => 'DoubleModel',
      DateModel() => 'DateModel',
      DateTimeModel() => 'DateTimeModel',
      DecimalModel() => 'DecimalModel',
      UriModel() => 'UriModel',
      BinaryModel() => 'BinaryModel',
      Base64Model() => 'Base64Model',
      AnyModel() => 'AnyModel',
      NeverModel() => 'NeverModel',
      _ => throw UnimplementedError(
        'stableKey not implemented for ${model.runtimeType}',
      ),
    };
  } finally {
    visiting.remove(model);
  }
}

String _stableSortedModels(Set<Model> models, Set<Model> visiting) {
  final keys = {for (final m in models) m: _computeStableKey(m, visiting)};
  final sorted = keys.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  return sorted.map((e) => e.value).join(',');
}

String _stableSortedDiscriminatedModels(
  Set<DiscriminatedModel> models,
  Set<Model> visiting,
) {
  final keys = {
    for (final dm in models)
      dm: '${dm.discriminatorValue}:${_computeStableKey(dm.model, visiting)}',
  };
  final sorted = keys.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  return sorted.map((e) => e.value).join(',');
}

/// Creates a stable sorted string representation of enum values.
String _stableSortedEnumValues<T>(Set<EnumEntry<T>> values) {
  final sorted = values.toList()
    ..sort((a, b) => a.value.toString().compareTo(b.value.toString()));
  return sorted.map((v) => v.value.toString()).join(',');
}

/// Compares two models for stable sorting.
///
/// Sort order:
/// 1. Context path length (shorter first)
/// 2. Context path string (lexicographic)
/// 3. Stable model structure key
int _compareModelsStably(Model a, Model b) {
  final aLen = a.context.path.length;
  final bLen = b.context.path.length;
  if (aLen != bLen) return aLen.compareTo(bLen);

  final contextComp = a.context.toString().compareTo(b.context.toString());
  if (contextComp != 0) return contextComp;

  return a.stableKey.compareTo(b.stableKey);
}

/// Compares two discriminated models for stable sorting.
///
/// Sort order:
/// 1. Discriminator value (if both present)
/// 2. Model comparison (via _compareModelsStably)
int _compareDiscriminatedModelsStably(
  DiscriminatedModel a,
  DiscriminatedModel b,
) {
  if (a.discriminatorValue != null && b.discriminatorValue != null) {
    final discComp = a.discriminatorValue!.compareTo(b.discriminatorValue!);
    if (discComp != 0) return discComp;
  }
  return _compareModelsStably(a.model, b.model);
}

/// Extension on `Set<Model>` to provide stable sorted lists.
extension StableSortedModels on Set<Model> {
  /// Returns a list of models sorted in a stable, deterministic order.
  ///
  /// This ensures that the same set of models always produces the same
  /// ordering, regardless of Set iteration order.
  List<Model> toSortedList() {
    return toList()..sort(_compareModelsStably);
  }
}

/// Extension on `Set<DiscriminatedModel>` to provide stable sorted lists.
extension StableSortedDiscriminatedModels on Set<DiscriminatedModel> {
  /// Returns a list of discriminated models sorted in a stable,
  /// deterministic order.
  ///
  /// This ensures that the same set of discriminated models always produces
  /// the same ordering, regardless of Set iteration order.
  List<DiscriminatedModel> toSortedList() {
    return toList()..sort(_compareDiscriminatedModelsStably);
  }
}
