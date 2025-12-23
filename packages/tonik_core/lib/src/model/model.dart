import 'package:meta/meta.dart';
import 'package:tonik_core/src/util/context.dart';
import 'package:tonik_util/tonik_util.dart';

sealed class Model {
  Model({required this.context});

  final Context context;
  EncodingShape get encodingShape;
}

mixin NamedModel on Model {
  String? get name;
  String? get nameOverride;
  set nameOverride(String? value);
}

mixin CompositeModel on Model {
  Set<Model> get containedModels;

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

class AliasModel extends Model with NamedModel {
  AliasModel({
    required this.name,
    required this.model,
    required super.context,
    this.nameOverride,
    this.isNullable = false,
  });

  @override
  final String name;
  @override
  String? nameOverride;
  Model model;
  bool isNullable;

  Model get resolved => switch (model) {
    final AliasModel alias => alias.resolved,
    _ => model,
  };

  @override
  EncodingShape get encodingShape => resolved.encodingShape;

  @override
  String toString() =>
      'AliasModel{name: $name, nameOverride: $nameOverride, model: $model}';
}

class ListModel extends Model with NamedModel {
  ListModel({
    required this.content,
    required super.context,
    this.name,
    this.nameOverride,
    this.isNullable = false,
  });

  Model content;

  @override
  final String? name;
  @override
  String? nameOverride;
  bool isNullable;

  @override
  EncodingShape get encodingShape => EncodingShape.complex;

  bool get hasSimpleContent => content.encodingShape == EncodingShape.simple;

  @override
  String toString() =>
      'ListModel{name: $name, nameOverride: $nameOverride, content: $content}';
}

class ClassModel extends Model with NamedModel {
  ClassModel({
    required this.properties,
    required super.context,
    required this.isDeprecated,
    this.name,
    this.nameOverride,
    this.description,
    this.isNullable = false,
  });

  @override
  final String? name;

  @override
  String? nameOverride;
  List<Property> properties;
  String? description;
  bool isDeprecated;
  bool isNullable;

  @override
  EncodingShape get encodingShape => EncodingShape.complex;

  @override
  String toString() =>
      'ClassModel{name: $name, nameOverride: $nameOverride, '
      'properties: $properties, description: $description, '
      'isDeprecated: $isDeprecated}';
}

/// Represents an individual value within an enum, with optional name override.
@immutable
class EnumEntry<T> {
  const EnumEntry({required this.value, this.nameOverride});

  final T value;

  final String? nameOverride;

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

class EnumModel<T> extends Model with NamedModel {
  EnumModel({
    required this.values,
    required this.isNullable,
    required super.context,
    required this.isDeprecated,
    this.name,
    this.nameOverride,
    this.description,
    this.fallbackValue,
  });

  @override
  final String? name;

  @override
  String? nameOverride;
  Set<EnumEntry<T>> values;

  /// Optional fallback value if no other value matches.
  EnumEntry<T>? fallbackValue;
  String? description;
  bool isDeprecated;
  bool isNullable;

  @override
  EncodingShape get encodingShape => EncodingShape.simple;

  @override
  String toString() =>
      'EnumModel<$T>{name: $name, nameOverride: $nameOverride, '
      'values: $values, isNullable: $isNullable, description: $description, '
      'isDeprecated: $isDeprecated, fallbackValue: $fallbackValue}';
}

class AllOfModel extends Model with NamedModel, CompositeModel {
  AllOfModel({
    required this.models,
    required super.context,
    required this.isDeprecated,
    this.name,
    this.nameOverride,
    this.description,
    this.isNullable = false,
  });

  @override
  final String? name;

  @override
  String? nameOverride;
  String? description;
  bool isDeprecated;
  bool isNullable;
  Set<Model> models;

  @override
  Set<Model> get containedModels => models;

  @override
  String toString() =>
      'AllOfModel{name: $name, nameOverride: $nameOverride, models: $models, '
      'description: $description, isDeprecated: $isDeprecated}';
}

typedef DiscriminatedModel = ({String? discriminatorValue, Model model});

class OneOfModel extends Model with NamedModel, CompositeModel {
  OneOfModel({
    required this.models,
    required super.context,
    required this.isDeprecated,
    this.name,
    this.nameOverride,
    this.description,
    this.discriminator,
    this.isNullable = false,
  });

  @override
  final String? name;

  @override
  String? nameOverride;
  String? description;
  bool isDeprecated;
  bool isNullable;
  Set<DiscriminatedModel> models;
  String? discriminator;

  @override
  Set<Model> get containedModels => models.map((m) => m.model).toSet();

  @override
  String toString() =>
      'OneOfModel{name: $name, nameOverride: $nameOverride, models: $models, '
      'discriminator: $discriminator, description: $description, '
      'isDeprecated: $isDeprecated}';
}

class AnyOfModel extends Model with NamedModel, CompositeModel {
  AnyOfModel({
    required this.models,
    required super.context,
    required this.isDeprecated,
    this.name,
    this.nameOverride,
    this.description,
    this.discriminator,
    this.isNullable = false,
  });

  @override
  final String? name;

  @override
  String? nameOverride;
  String? description;
  bool isDeprecated;
  bool isNullable;
  Set<DiscriminatedModel> models;
  String? discriminator;

  @override
  Set<Model> get containedModels => models.map((m) => m.model).toSet();

  @override
  String toString() =>
      'AnyOfModel{name: $name, nameOverride: $nameOverride, models: $models, '
      'discriminator: $discriminator, description: $description, '
      'isDeprecated: $isDeprecated}';
}

sealed class PrimitiveModel extends Model {
  PrimitiveModel({required super.context});

  @override
  EncodingShape get encodingShape => EncodingShape.simple;
}

class IntegerModel extends PrimitiveModel {
  IntegerModel({required super.context});

  @override
  String toString() => 'IntegerModel';
}

class DoubleModel extends PrimitiveModel {
  DoubleModel({required super.context});

  @override
  String toString() => 'DoubleModel';
}

class NumberModel extends PrimitiveModel {
  NumberModel({required super.context});

  @override
  String toString() => 'NumberModel';
}

class StringModel extends PrimitiveModel {
  StringModel({required super.context});

  @override
  String toString() => 'StringModel';
}

class BooleanModel extends PrimitiveModel {
  BooleanModel({required super.context});

  @override
  String toString() => 'BooleanModel';
}

class DateTimeModel extends PrimitiveModel {
  DateTimeModel({required super.context});

  @override
  String toString() => 'DateTimeModel';
}

class DateModel extends PrimitiveModel {
  DateModel({required super.context});

  @override
  String toString() => 'DateModel';
}

class DecimalModel extends PrimitiveModel {
  DecimalModel({required super.context});

  @override
  String toString() => 'DecimalModel';
}

class UriModel extends PrimitiveModel {
  UriModel({required super.context});

  @override
  String toString() => 'UriModel';
}

class BinaryModel extends PrimitiveModel {
  BinaryModel({required super.context});

  @override
  String toString() => 'BinaryModel';
}

class Property {
  Property({
    required this.name,
    required this.model,
    required this.isRequired,
    required this.isNullable,
    required this.isDeprecated,
    this.nameOverride,
    this.description,
  });

  final String name;

  String? nameOverride;
  String? description;
  bool isDeprecated;
  Model model;
  bool isRequired;
  bool isNullable;

  @override
  String toString() =>
      'Property{name: $name, nameOverride: $nameOverride, model: $model, '
      'isRequired: $isRequired, isNullable: $isNullable, '
      'isDeprecated: $isDeprecated, description: $description}';
}
