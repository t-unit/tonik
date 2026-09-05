import 'package:tonik_core/src/model/additional_properties_policy.dart';
import 'package:tonik_core/src/model/model.dart';

/// Computes and caches stable sort keys for models.
///
/// Stable keys are string representations of model structure that are
/// deterministic for a given model declaration. Compound member order is part
/// of the key, while unordered values such as enum entries are normalized.
///
/// Keys are cached per-instance so that repeated comparisons during sorting
/// (O(n log n) comparator calls) don't recompute the key each time. This is
/// critical for specs with deeply circular model graphs (e.g. Stripe's 90+
/// cyclic schemas), where uncached computation effectively hangs.
class StableModelSorter {
  static const _maxDepth = 5;

  final _cache = <Model, String>{};
  final _semanticCache = <Model, String>{};

  /// Returns the stable key for [model], computing and caching it if needed.
  String stableKeyOf(Model model) {
    return _cache[model] ??= _computeKey(
      model,
      {},
      0,
      preserveCompoundOrder: true,
    );
  }

  String _semanticKeyOf(Model model) => _semanticCache[model] ??= _computeKey(
    model,
    {},
    0,
    preserveCompoundOrder: false,
  );

  String stableAliasKey({required Model model}) {
    final modelKey = _computeKey(
      model,
      {},
      1,
      preserveCompoundOrder: true,
    );
    return 'AliasModel{null,$modelKey}';
  }

  String stableObjectKey({
    required String? name,
    required Iterable<(String, Model)> properties,
    required AdditionalPropertiesPolicy additionalPropertiesPolicy,
  }) => _objectKey(
    name,
    properties,
    additionalPropertiesPolicy,
    {},
    0,
    preserveCompoundOrder: true,
  );

  String _objectKey(
    String? name,
    Iterable<(String, Model)> properties,
    AdditionalPropertiesPolicy policy,
    Set<Model> visited,
    int depth, {
    required bool preserveCompoundOrder,
  }) =>
      'ClassModel{$name,'
      '${properties.map((p) => '${p.$1}:'
          '${_computeKey(
            p.$2,
            visited,
            depth + 1,
            preserveCompoundOrder: preserveCompoundOrder,
          )}').join(',')},'
      'ap:${_policyKey(
        policy,
        visited,
        depth,
        preserveCompoundOrder: preserveCompoundOrder,
      )}}';

  /// Returns a deterministically sorted list of [models].
  ///
  /// Sort order:
  /// 1. Context path length (shorter first)
  /// 2. Context path string (lexicographic)
  /// 3. Stable model structure key
  List<Model> sortModels(Iterable<Model> models) {
    return models.toList()..sort(_compareModelsStably);
  }

  /// Returns a deterministically sorted list of discriminated [models].
  ///
  /// Sort order:
  /// 1. Discriminator value (if both present)
  /// 2. Model comparison (via context path then stable key)
  List<DiscriminatedModel> sortDiscriminatedModels(
    Iterable<DiscriminatedModel> models,
  ) {
    return models.toList()..sort(_compareDiscriminatedModelsStably);
  }

  int _compareModelsStably(Model a, Model b) {
    final aLen = a.context.path.length;
    final bLen = b.context.path.length;
    if (aLen != bLen) return aLen.compareTo(bLen);

    final contextComp = a.context.toString().compareTo(b.context.toString());
    if (contextComp != 0) return contextComp;

    return _semanticKeyOf(a).compareTo(_semanticKeyOf(b));
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
  /// Compound members are traversed in declaration order.
  String _computeKey(
    Model model,
    Set<Model> visited,
    int depth, {
    required bool preserveCompoundOrder,
  }) {
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
      AllOfModel(:final models, :final additionalPropertiesPolicy) => _allOfKey(
        models,
        additionalPropertiesPolicy,
        visited,
        depth,
        preserveCompoundOrder: preserveCompoundOrder,
      ),
      OneOfModel(:final models, :final discriminator) => _discriminatedKey(
        'OneOfModel',
        discriminator,
        models,
        visited,
        depth,
        preserveCompoundOrder: preserveCompoundOrder,
      ),
      AnyOfModel(:final models, :final discriminator) => _discriminatedKey(
        'AnyOfModel',
        discriminator,
        models,
        visited,
        depth,
        preserveCompoundOrder: preserveCompoundOrder,
      ),
      ListModel(:final content, :final name) =>
        'ListModel{$name,${_computeKey(
          content,
          visited,
          depth + 1,
          preserveCompoundOrder: preserveCompoundOrder,
        )}}',
      ClassModel(
        :final name,
        :final properties,
        :final additionalPropertiesPolicy,
      ) =>
        _objectKey(
          name,
          properties.map((p) => (p.name, p.model)),
          additionalPropertiesPolicy,
          visited,
          depth,
          preserveCompoundOrder: preserveCompoundOrder,
        ),
      EnumModel(:final name, :final values) =>
        'EnumModel{$name,${_stableSortedEnumValues(values)}}',
      AliasModel(:final name, :final model) =>
        'AliasModel{$name,${_computeKey(
          model,
          visited,
          depth + 1,
          preserveCompoundOrder: preserveCompoundOrder,
        )}}',
      MapModel(:final name, :final valueModel) =>
        'MapModel{$name,'
            '${_computeKey(
              valueModel,
              visited,
              depth + 1,
              preserveCompoundOrder: preserveCompoundOrder,
            )}}',
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

  String _allOfKey(
    List<Model> models,
    AdditionalPropertiesPolicy policy,
    Set<Model> visited,
    int depth, {
    required bool preserveCompoundOrder,
  }) {
    final modelsKey = preserveCompoundOrder
        ? _orderedModels(models, visited, depth)
        : _stableSortedModels(models, visited, depth);
    final policyKey = _policyKey(
      policy,
      visited,
      depth,
      preserveCompoundOrder: preserveCompoundOrder,
    );
    return 'AllOfModel{$modelsKey,ap:$policyKey}';
  }

  String _discriminatedKey(
    String type,
    String? discriminator,
    List<DiscriminatedModel> models,
    Set<Model> visited,
    int depth, {
    required bool preserveCompoundOrder,
  }) {
    final modelsKey = preserveCompoundOrder
        ? _orderedDiscriminatedModels(models, visited, depth)
        : _stableSortedDiscriminatedModels(models, visited, depth);
    return '$type{$discriminator,$modelsKey}';
  }

  String _policyKey(
    AdditionalPropertiesPolicy policy,
    Set<Model> visited,
    int depth, {
    required bool preserveCompoundOrder,
  }) => switch (policy) {
    ForbiddenAdditionalProperties() => 'forbidden',
    AllowedAdditionalProperties(:final valueModel, :final origin) =>
      'allowed(${origin.name},'
          '${_computeKey(
            valueModel,
            visited,
            depth + 1,
            preserveCompoundOrder: preserveCompoundOrder,
          )})',
  };

  /// Computes compound member keys in declaration order.
  String _orderedModels(
    List<Model> models,
    Set<Model> visited,
    int depth,
  ) {
    return models
        .map(
          (m) => _computeKey(
            m,
            visited,
            depth + 1,
            preserveCompoundOrder: true,
          ),
        )
        .join(',');
  }

  /// Computes discriminated member keys in declaration order.
  String _orderedDiscriminatedModels(
    List<DiscriminatedModel> models,
    Set<Model> visited,
    int depth,
  ) {
    return models
        .map(
          (dm) =>
              '${dm.discriminatorValue}:'
              '${_computeKey(
                dm.model,
                visited,
                depth + 1,
                preserveCompoundOrder: true,
              )}',
        )
        .join(',');
  }

  String _stableSortedModels(
    Iterable<Model> models,
    Set<Model> visited,
    int depth,
  ) {
    final sorted = models.toList()..sort(_cheapModelCompare);
    return sorted
        .map(
          (model) => _computeKey(
            model,
            visited,
            depth + 1,
            preserveCompoundOrder: false,
          ),
        )
        .join(',');
  }

  String _stableSortedDiscriminatedModels(
    Iterable<DiscriminatedModel> models,
    Set<Model> visited,
    int depth,
  ) {
    final sorted = models.toList()..sort(_cheapDiscriminatedModelCompare);
    return sorted
        .map(
          (model) =>
              '${model.discriminatorValue}:'
              '${_computeKey(
                model.model,
                visited,
                depth + 1,
                preserveCompoundOrder: false,
              )}',
        )
        .join(',');
  }

  String _stableSortedEnumValues<T>(Set<EnumEntry<T>> values) {
    final sorted = values.toList()
      ..sort((a, b) => a.value.toString().compareTo(b.value.toString()));
    return sorted.map((v) => v.value.toString()).join(',');
  }

  static int _cheapModelCompare(Model a, Model b) {
    final typeComp = a.runtimeType.toString().compareTo(
      b.runtimeType.toString(),
    );
    if (typeComp != 0) return typeComp;
    return a.context.toString().compareTo(b.context.toString());
  }

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
