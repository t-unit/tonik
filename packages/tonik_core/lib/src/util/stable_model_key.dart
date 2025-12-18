import 'package:tonik_core/src/model/model.dart';

/// Extension on `Model` providing stable key generation for sorting.
extension StableModelKey on Model {
  /// Creates a stable string representation of a model for sorting purposes.
  ///
  /// This ensures models with the same structure but different Set iteration
  /// orders produce the same string.
  String get stableKey {
    return switch (this) {
      AllOfModel(:final models) => 'AllOfModel{${_stableSortedModels(models)}}',
      OneOfModel(:final models, :final discriminator) =>
        'OneOfModel{$discriminator,'
            '${_stableSortedDiscriminatedModels(models)}}',
      AnyOfModel(:final models, :final discriminator) =>
        'AnyOfModel{$discriminator,'
            '${_stableSortedDiscriminatedModels(models)}}',
      ListModel(:final content, :final name) =>
        'ListModel{$name,${content.stableKey}}',
      ClassModel(:final name, :final properties) =>
        'ClassModel{'
            '$name,'
            '${properties.map(
              (p) => '${p.name}:${p.model.stableKey}',
            ).join(',')}'
            '}',
      EnumModel(:final name, :final values) =>
        'EnumModel{$name,${_stableSortedEnumValues(values)}}',
      AliasModel(:final name, :final model) =>
        'AliasModel{$name,${model.stableKey}}',
      StringModel() => 'StringModel',
      IntegerModel() => 'IntegerModel',
      BooleanModel() => 'BooleanModel',
      NumberModel() => 'NumberModel',
      DoubleModel() => 'DoubleModel',
      DateModel() => 'DateModel',
      DateTimeModel() => 'DateTimeModel',
      DecimalModel() => 'DecimalModel',
      UriModel() => 'UriModel',
      _ =>
        throw UnimplementedError(
          'stableKey not implemented for $runtimeType',
        ),
    };
  }
}

String _stableSortedModels(Set<Model> models) {
  final sorted =
      models.toList()..sort((a, b) => a.stableKey.compareTo(b.stableKey));
  return sorted.map((m) => m.stableKey).join(',');
}

String _stableSortedDiscriminatedModels(Set<DiscriminatedModel> models) {
  final sorted =
      models.toList()..sort((a, b) {
        final aKey = '${a.discriminatorValue}:${a.model.stableKey}';
        final bKey = '${b.discriminatorValue}:${b.model.stableKey}';
        return aKey.compareTo(bKey);
      });
  return sorted
      .map((dm) => '${dm.discriminatorValue}:${dm.model.stableKey}')
      .join(',');
}

/// Creates a stable sorted string representation of enum values.
String _stableSortedEnumValues<T>(Set<EnumEntry<T>> values) {
  final sorted =
      values.toList()
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
