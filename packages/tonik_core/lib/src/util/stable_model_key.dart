import 'package:tonik_core/src/model/model.dart';

/// Computes and caches stable sort keys for models.
///
/// Stable keys are string representations of model structure that are
/// deterministic regardless of Set iteration order. They are used to sort
/// models consistently across runs.
///
/// Keys are cached per-instance so that repeated comparisons during sorting
/// (O(n log n) comparator calls) don't recompute the key each time. This is
/// critical for specs with deeply circular model graphs (e.g. Stripe's 90+
/// cyclic schemas), where uncached computation effectively hangs.
class StableModelSorter {
  static const _maxDepth = 5;

  final _cache = <Model, String>{};

  /// Returns the stable key for [model], computing and caching it if needed.
  String stableKeyOf(Model model) {
    return _cache[model] ??= _computeStableKey(model, {}, 0);
  }

  /// Returns a deterministically sorted list of [models].
  ///
  /// Sort order:
  /// 1. Context path length (shorter first)
  /// 2. Context path string (lexicographic)
  /// 3. Stable model structure key
  List<Model> sortModels(Set<Model> models) {
    return models.toList()..sort(_compareModelsStably);
  }

  /// Returns a deterministically sorted list of discriminated [models].
  ///
  /// Sort order:
  /// 1. Discriminator value (if both present)
  /// 2. Model comparison (via context path then stable key)
  List<DiscriminatedModel> sortDiscriminatedModels(
    Set<DiscriminatedModel> models,
  ) {
    return models.toList()..sort(_compareDiscriminatedModelsStably);
  }

  int _compareModelsStably(Model a, Model b) {
    final aLen = a.context.path.length;
    final bLen = b.context.path.length;
    if (aLen != bLen) return aLen.compareTo(bLen);

    final contextComp = a.context.toString().compareTo(b.context.toString());
    if (contextComp != 0) return contextComp;

    return stableKeyOf(a).compareTo(stableKeyOf(b));
  }

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

  /// Computes a stable key for [model].
  ///
  /// The [visited] set tracks all models already seen in the current
  /// traversal. Unlike a traditional "visiting" set, models are NOT removed
  /// when unwinding — this turns the traversal into a DFS tree walk where
  /// each model is visited at most once, giving O(V+E) complexity instead
  /// of exponential path enumeration in dense cyclic graphs.
  ///
  /// [depth] bounds recursion so that keys stay compact even in large,
  /// densely connected graphs. Beyond [_maxDepth], only the runtime type
  /// is emitted instead of a full structural traversal.
  ///
  /// For Set-based children (AllOf, OneOf, AnyOf), children are sorted by a
  /// cheap deterministic key before traversal so the result is independent
  /// of Set iteration order.
  String _computeStableKey(Model model, Set<Model> visited, int depth) {
    if (depth > _maxDepth) {
      return switch (model) {
        ClassModel(:final name) => 'ClassModel{$name}',
        EnumModel(:final name) => 'EnumModel{$name}',
        AliasModel(:final name) => 'AliasModel{$name}',
        ListModel(:final name) => 'ListModel{$name}',
        MapModel(:final name) => 'MapModel{$name}',
        _ => model.runtimeType.toString(),
      };
    }

    if (!visited.add(model)) return '<cycle>';

    return switch (model) {
      AllOfModel(:final models) =>
        'AllOfModel{${_stableSortedModels(models, visited, depth)}}',
      OneOfModel(:final models, :final discriminator) =>
        'OneOfModel{$discriminator,'
            '${_stableSortedDiscriminatedModels(models, visited, depth)}}',
      AnyOfModel(:final models, :final discriminator) =>
        'AnyOfModel{$discriminator,'
            '${_stableSortedDiscriminatedModels(models, visited, depth)}}',
      ListModel(:final content, :final name) =>
        'ListModel{$name,${_computeStableKey(content, visited, depth + 1)}}',
      ClassModel(:final name, :final properties) =>
        'ClassModel{'
            '$name,'
            '${properties.map(
              (p) => '${p.name}:'
                  '${_computeStableKey(p.model, visited, depth + 1)}',
            ).join(',')}'
            '}',
      EnumModel(:final name, :final values) =>
        'EnumModel{$name,${_stableSortedEnumValues(values)}}',
      AliasModel(:final name, :final model) =>
        'AliasModel{$name,${_computeStableKey(model, visited, depth + 1)}}',
      MapModel(:final name, :final valueModel) =>
        'MapModel{$name,'
            '${_computeStableKey(valueModel, visited, depth + 1)}}',
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
  }

  /// Sorts models by a cheap deterministic key, then computes full keys
  /// in that fixed order.
  String _stableSortedModels(
    Set<Model> models,
    Set<Model> visited,
    int depth,
  ) {
    final sorted = models.toList()..sort(_cheapModelCompare);
    return sorted
        .map((m) => _computeStableKey(m, visited, depth + 1))
        .join(',');
  }

  /// Sorts discriminated models by discriminator value first, then by a
  /// cheap model key, before computing full keys in that fixed order.
  String _stableSortedDiscriminatedModels(
    Set<DiscriminatedModel> models,
    Set<Model> visited,
    int depth,
  ) {
    final sorted = models.toList()..sort(_cheapDiscriminatedModelCompare);
    return sorted
        .map(
          (dm) =>
              '${dm.discriminatorValue}:'
              '${_computeStableKey(dm.model, visited, depth + 1)}',
        )
        .join(',');
  }

  String _stableSortedEnumValues<T>(Set<EnumEntry<T>> values) {
    final sorted = values.toList()
      ..sort((a, b) => a.value.toString().compareTo(b.value.toString()));
    return sorted.map((v) => v.value.toString()).join(',');
  }

  /// Cheap, non-recursive comparator for pre-sorting Set children.
  static int _cheapModelCompare(Model a, Model b) {
    final typeComp = a.runtimeType.toString().compareTo(
      b.runtimeType.toString(),
    );
    if (typeComp != 0) return typeComp;
    return a.context.toString().compareTo(b.context.toString());
  }

  /// Cheap, non-recursive comparator for pre-sorting discriminated models.
  static int _cheapDiscriminatedModelCompare(
    DiscriminatedModel a,
    DiscriminatedModel b,
  ) {
    if (a.discriminatorValue != null && b.discriminatorValue != null) {
      final discComp = a.discriminatorValue!.compareTo(b.discriminatorValue!);
      if (discComp != 0) return discComp;
    }
    return _cheapModelCompare(a.model, b.model);
  }
}
