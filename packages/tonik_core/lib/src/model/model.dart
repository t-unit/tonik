import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/src/model/additional_properties_policy.dart';
import 'package:tonik_core/src/model/effective_default.dart';
import 'package:tonik_core/src/model/example.dart';
import 'package:tonik_core/src/util/context.dart';
import 'package:tonik_util/tonik_util.dart';

final Logger _aliasModelLog = Logger('AliasModel');

sealed class Model({required final Context context}) {
  EncodingShape get encodingShape;

  /// The terminal model after resolving through any [AliasModel] chains.
  ///
  /// For non-alias models this returns `this`. For [AliasModel] it walks
  /// the chain until a non-alias model is reached.
  Model get resolved => this; // ignore: avoid_returning_this

  /// Whether this model produces a nullable Dart type, including through
  /// typedef/alias chains.
  bool get isEffectivelyNullable => switch (this) {
    AliasModel(:final isNullable, :final model) =>
      isNullable || model.isEffectivelyNullable,
    ClassModel(:final isNullable) => isNullable,
    EnumModel(:final isNullable) => isNullable,
    ListModel(:final isNullable) => isNullable,
    MapModel(:final isNullable) => isNullable,
    AllOfModel(:final isNullable) => isNullable,
    OneOfModel(:final isNullable) => isNullable,
    AnyOfModel(:final isNullable) => isNullable,
    NeverModel(:final isNullable) => isNullable,
    _ => false,
  };

  /// Short non-recursive label for use in other models' [toString] output.
  String get _ref => switch (this) {
    AliasModel(:final name) => 'AliasModel($name)',
    ListModel(:final name) => 'ListModel($name)',
    MapModel(:final name) => 'MapModel($name)',
    ClassModel(:final name) => 'ClassModel($name)',
    EnumModel(:final name) => 'EnumModel($name)',
    AllOfModel(:final name) => 'AllOfModel($name)',
    OneOfModel(:final name) => 'OneOfModel($name)',
    AnyOfModel(:final name) => 'AnyOfModel($name)',
    IntegerModel() => 'IntegerModel',
    DoubleModel() => 'DoubleModel',
    NumberModel() => 'NumberModel',
    StringModel() => 'StringModel',
    BooleanModel() => 'BooleanModel',
    DateTimeModel() => 'DateTimeModel',
    DateModel() => 'DateModel',
    DecimalModel() => 'DecimalModel',
    UriModel() => 'UriModel',
    BinaryModel() => 'BinaryModel',
    Base64Model() => 'Base64Model',
    AnyModel() => 'AnyModel',
    NeverModel() => 'NeverModel',
    _ => 'Model',
  };
}

mixin NamedModel on Model {
  String? get name;
  String? get nameOverride;
  set nameOverride(String? value);
}

mixin CompositeModel on Model {
  List<Model> get containedModels;

  @override
  EncodingShape get encodingShape {
    final shapes = containedModels.map((m) => m.encodingShape).toSet();
    if (shapes.length == 1) {
      return shapes.first;
    }
    return EncodingShape.mixed;
  }

  /// Returns true if any contained model has simple encoding shape.
  bool get hasSimpleTypes {
    return containedModels.any(
      (model) => model.encodingShape == EncodingShape.simple,
    );
  }

  /// Returns true if any contained model has complex encoding shape.
  bool get hasComplexTypes {
    return containedModels.any(
      (model) => model.encodingShape == EncodingShape.complex,
    );
  }

  /// Returns true if any contained model has mixed encoding shape.
  bool get hasMixedTypes {
    return containedModels.any(
      (model) => model.encodingShape == EncodingShape.mixed,
    );
  }

  /// Returns true if the combination of contained models cannot be simply
  /// encoded. This happens when there are mixed types, or both simple and
  /// complex types.
  bool get cannotBeSimplyEncoded {
    return hasMixedTypes || (hasComplexTypes && hasSimpleTypes);
  }
}

class MapModel({
  required var Model valueModel,
  required super.context,
  required var List<Example> examples,
  @override final String? name,
  @override var String? nameOverride,
  var bool isNullable = false,

  /// Describes the value, not the map itself, so it does not affect
  /// [isEffectivelyNullable] — mirrors [Property.isNullable].
  var bool isValueNullable = false,
  var bool isReadOnly = false,
  var bool isWriteOnly = false,
}) extends Model with NamedModel {
  @override
  EncodingShape get encodingShape => EncodingShape.complex;

  @override
  String toString() =>
      'MapModel{name: $name, nameOverride: $nameOverride, '
      'valueModel: ${valueModel._ref}, isValueNullable: $isValueNullable, '
      'examples: $examples}';
}

class AliasModel._({
  required var Model model,
  required super.context,
  required var List<Example> examples,
  required final Object? _localDefault,
  @override final String? name,
  @override var String? nameOverride,
  var String? description,
  var bool isDeprecated = false,
  var bool isNullable = false,
  var bool isReadOnly = false,
  var bool isWriteOnly = false,
}) extends Model with NamedModel {
  new({
    required Model model,
    required Context context,
    required List<Example> examples,
    required Object? defaultValue,
    String? name,
    String? nameOverride,
    String? description,
    bool isDeprecated = false,
    bool isNullable = false,
    bool isReadOnly = false,
    bool isWriteOnly = false,
  }) : this._(
         model: model,
         context: context,
         examples: examples,
         localDefault: defaultValue,
         name: name,
         nameOverride: nameOverride,
         description: description,
         isDeprecated: isDeprecated,
         isNullable: isNullable,
         isReadOnly: isReadOnly,
         isWriteOnly: isWriteOnly,
       );

  /// The locally declared default if set, otherwise the first one found
  /// while walking nested [AliasModel]s.
  Object? get defaultValue => _resolveDefault(this, <AliasModel>{});

  static Object? _resolveDefault(AliasModel alias, Set<AliasModel> visited) {
    if (!visited.add(alias)) {
      _aliasModelLog.warning(
        'Cycle detected resolving default on alias chain rooted at '
        '${alias.name ?? '(unnamed)'}; returning null.',
      );
      return null;
    }
    if (alias._localDefault != null) return alias._localDefault;
    final inner = alias.model;
    if (inner is AliasModel) return _resolveDefault(inner, visited);
    return null;
  }

  @override
  Model get resolved => _resolveResolved(this, <AliasModel>{});

  static Model _resolveResolved(AliasModel alias, Set<AliasModel> visited) {
    if (!visited.add(alias)) {
      _aliasModelLog.warning(
        'Cycle detected resolving terminal model on alias chain rooted at '
        '${alias.name ?? '(unnamed)'}; returning current alias.',
      );
      return alias;
    }
    final inner = alias.model;
    if (inner is AliasModel) return _resolveResolved(inner, visited);
    return inner;
  }

  @override
  EncodingShape get encodingShape => resolved.encodingShape;

  @override
  String toString() =>
      'AliasModel{name: $name, nameOverride: $nameOverride, '
      'model: ${model._ref}, description: $description, '
      'isDeprecated: $isDeprecated, defaultValue: $defaultValue, '
      'examples: $examples}';
}

class ListModel({
  required var Model content,
  required super.context,
  required var List<Example> examples,
  @override final String? name,
  @override var String? nameOverride,
  var bool isNullable = false,

  /// Describes the item, not the list itself, so it does not affect
  /// [isEffectivelyNullable] — mirrors [Property.isNullable].
  var bool isContentNullable = false,
  var bool isReadOnly = false,
  var bool isWriteOnly = false,
}) extends Model with NamedModel {
  @override
  EncodingShape get encodingShape => EncodingShape.complex;

  bool get hasSimpleContent => content.encodingShape == EncodingShape.simple;

  @override
  String toString() =>
      'ListModel{name: $name, nameOverride: $nameOverride, '
      'content: ${content._ref}, isContentNullable: $isContentNullable, '
      'examples: $examples}';
}

class ClassModel({
  required var List<Property> properties,
  required super.context,
  required var bool isDeprecated,
  required var List<Example> examples,
  @override final String? name,
  @override var String? nameOverride,
  var String? description,
  AdditionalPropertiesPolicy? additionalPropertiesPolicy,
  var bool isNullable = false,
  var bool isReadOnly = false,
  var bool isWriteOnly = false,
}) extends Model with NamedModel {
  this {
    this.additionalPropertiesPolicy =
        additionalPropertiesPolicy ??
        AllowedAdditionalProperties(
          valueModel: AnyModel(context: context),
          origin: AdditionalPropertiesOrigin.implicitDefault,
        );
  }

  late AdditionalPropertiesPolicy additionalPropertiesPolicy;
  @override
  EncodingShape get encodingShape => EncodingShape.complex;

  @override
  String toString() =>
      'ClassModel{name: $name, nameOverride: $nameOverride, '
      'properties: [${properties.map((p) => p.name).join(', ')}], '
      'additionalPropertiesPolicy: $additionalPropertiesPolicy, '
      'description: $description, isDeprecated: $isDeprecated, '
      'examples: $examples}';
}

/// Represents an individual value within an enum, with optional name override.
@immutable
class const EnumEntry<T>({required final T value, final String? nameOverride}) {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnumEntry<T> &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          nameOverride == other.nameOverride;

  @override
  int get hashCode => Object.hash(value, nameOverride);

  @override
  String toString() =>
      'EnumEntry<$T>{value: $value, nameOverride: $nameOverride}';
}

class EnumModel<T>({
  required var Set<EnumEntry<T>> values,
  required var bool isNullable,
  required super.context,
  required var bool isDeprecated,
  required var List<Example> examples,
  @override final String? name,
  @override var String? nameOverride,
  var String? description,

  /// Optional fallback value if no other value matches.
  var EnumEntry<T>? fallbackValue,
  var bool isReadOnly = false,
  var bool isWriteOnly = false,
}) extends Model with NamedModel {
  @override
  EncodingShape get encodingShape => EncodingShape.simple;

  @override
  String toString() =>
      'EnumModel<$T>{name: $name, nameOverride: $nameOverride, '
      'values: $values, isNullable: $isNullable, description: $description, '
      'isDeprecated: $isDeprecated, fallbackValue: $fallbackValue, '
      'examples: $examples}';
}

class AllOfModel({
  required var List<Model> models,
  required super.context,
  required var bool isDeprecated,
  required var List<Example> examples,
  @override final String? name,
  @override var String? nameOverride,
  var String? description,
  AdditionalPropertiesPolicy? additionalPropertiesPolicy,
  var bool isNullable = false,
  var bool isReadOnly = false,
  var bool isWriteOnly = false,
}) extends Model with NamedModel, CompositeModel {
  this {
    this.additionalPropertiesPolicy =
        additionalPropertiesPolicy ??
        AllowedAdditionalProperties(
          valueModel: AnyModel(context: context),
          origin: AdditionalPropertiesOrigin.implicitDefault,
        );
  }

  late AdditionalPropertiesPolicy additionalPropertiesPolicy;
  @override
  List<Model> get containedModels => models;

  @override
  String toString() =>
      'AllOfModel{name: $name, nameOverride: $nameOverride, '
      'models: {${models.map((m) => m._ref).join(', ')}}, '
      'additionalPropertiesPolicy: $additionalPropertiesPolicy, '
      'description: $description, isDeprecated: $isDeprecated, '
      'examples: $examples}';
}

typedef DiscriminatedModel = ({String? discriminatorValue, Model model});

class OneOfModel({
  required var List<DiscriminatedModel> models,
  required super.context,
  required var bool isDeprecated,
  required var List<Example> examples,
  @override final String? name,
  @override var String? nameOverride,
  var String? description,
  var String? discriminator,
  var bool isNullable = false,
  var bool isReadOnly = false,
  var bool isWriteOnly = false,
}) extends Model with NamedModel, CompositeModel {
  @override
  List<Model> get containedModels => models.map((m) => m.model).toList();

  @override
  String toString() =>
      'OneOfModel{name: $name, nameOverride: $nameOverride, '
      'models: {${models.map((m) => m.model._ref).join(', ')}}, '
      'discriminator: $discriminator, description: $description, '
      'isDeprecated: $isDeprecated, examples: $examples}';
}

class AnyOfModel({
  required var List<DiscriminatedModel> models,
  required super.context,
  required var bool isDeprecated,
  required var List<Example> examples,
  @override final String? name,
  @override var String? nameOverride,
  var String? description,
  var String? discriminator,
  var bool isNullable = false,
  var bool isReadOnly = false,
  var bool isWriteOnly = false,
}) extends Model with NamedModel, CompositeModel {
  @override
  List<Model> get containedModels => models.map((m) => m.model).toList();

  @override
  String toString() =>
      'AnyOfModel{name: $name, nameOverride: $nameOverride, '
      'models: {${models.map((m) => m.model._ref).join(', ')}}, '
      'discriminator: $discriminator, description: $description, '
      'isDeprecated: $isDeprecated, examples: $examples}';
}

sealed class PrimitiveModel({required super.context}) extends Model {
  @override
  EncodingShape get encodingShape => EncodingShape.simple;
}

class IntegerModel({required super.context}) extends PrimitiveModel {
  @override
  String toString() => 'IntegerModel';
}

class DoubleModel({required super.context}) extends PrimitiveModel {
  @override
  String toString() => 'DoubleModel';
}

class NumberModel({required super.context}) extends PrimitiveModel {
  @override
  String toString() => 'NumberModel';
}

class StringModel({required super.context}) extends PrimitiveModel {
  @override
  String toString() => 'StringModel';
}

class BooleanModel({required super.context}) extends PrimitiveModel {
  @override
  String toString() => 'BooleanModel';
}

class DateTimeModel({required super.context}) extends PrimitiveModel {
  @override
  String toString() => 'DateTimeModel';
}

class DateModel({required super.context}) extends PrimitiveModel {
  @override
  String toString() => 'DateModel';
}

class DecimalModel({required super.context}) extends PrimitiveModel {
  @override
  String toString() => 'DecimalModel';
}

class UriModel({required super.context}) extends PrimitiveModel {
  @override
  String toString() => 'UriModel';
}

class BinaryModel({required super.context}) extends PrimitiveModel {
  @override
  String toString() => 'BinaryModel';
}

class Base64Model({required super.context}) extends PrimitiveModel {
  @override
  String toString() => 'Base64Model';
}

class AnyModel({required super.context}) extends Model {
  @override
  EncodingShape get encodingShape => EncodingShape.mixed;

  @override
  String toString() => 'AnyModel';
}

class NeverModel({required super.context, required final bool isNullable})
    extends Model {
  @override
  EncodingShape get encodingShape => EncodingShape.simple;

  @override
  String toString() => 'NeverModel';
}

class Property({
  required final String name,
  required var Model model,
  required var bool isRequired,
  required var bool isNullable,
  required var bool isDeprecated,
  required var List<Example> examples,
  required var Object? defaultValue,
  var bool isReadOnly = false,
  var bool isWriteOnly = false,
  var String? nameOverride,
  var String? description,
}) {
  /// The property's own [defaultValue] when set, otherwise the default
  /// carried by its [model] when that model is an [AliasModel] chain.
  Object? get effectiveDefaultValue => effectiveDefault(defaultValue, model);

  @override
  String toString() =>
      'Property{name: $name, nameOverride: $nameOverride, '
      'model: ${model._ref}, isRequired: $isRequired, '
      'isNullable: $isNullable, isDeprecated: $isDeprecated, '
      'isReadOnly: $isReadOnly, isWriteOnly: $isWriteOnly, '
      'description: $description, defaultValue: $defaultValue, '
      'examples: $examples}';
}
