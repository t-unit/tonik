import 'package:meta/meta.dart';
import 'package:tonik_core/src/util/context.dart';
import 'package:tonik_util/tonik_util.dart';

@immutable
sealed class Model {
  const Model({required this.context});

  final Context context;

  EncodingShape get encodingShape;
}

mixin NamedModel on Model {
  String? get name;
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
  const AliasModel({
    required this.name,
    required this.model,
    required super.context,
  });

  @override
  final String name;
  final Model model;

  Model get resolved => switch (model) {
    final AliasModel alias => alias.resolved,
    _ => model,
  };

  @override
  EncodingShape get encodingShape => resolved.encodingShape;

  @override
  String toString() => 'AliasModel{name: $name, model: $model}';
}

class ListModel extends Model with NamedModel {
  const ListModel({required this.content, required super.context, this.name});

  final Model content;

  @override
  final String? name;

  @override
  EncodingShape get encodingShape => EncodingShape.complex;

  bool get hasSimpleContent => content.encodingShape == EncodingShape.simple;

  @override
  String toString() => 'ListModel{name: $name, content: $content}';
}

class ClassModel extends Model with NamedModel {
  const ClassModel({
    required this.properties,
    required super.context,
    required this.description,
    required this.isDeprecated,
    this.name,
  });

  @override
  final String? name;
  final List<Property> properties;
  final String? description;
  final bool isDeprecated;

  @override
  EncodingShape get encodingShape => EncodingShape.complex;

  @override
  String toString() =>
      'ClassModel{name: $name, properties: $properties, '
      'description: $description, isDeprecated: $isDeprecated}';
}

class EnumModel<T> extends Model with NamedModel {
  const EnumModel({
    required this.values,
    required this.isNullable,
    required super.context,
    required this.description,
    required this.isDeprecated,
    this.name,
  });

  @override
  final String? name;
  final Set<T> values;
  final bool isNullable;
  final String? description;
  final bool isDeprecated;

  @override
  EncodingShape get encodingShape => EncodingShape.simple;

  @override
  String toString() =>
      'EnumModel<$T>{name: $name, values: $values, isNullable: $isNullable, '
      'description: $description, isDeprecated: $isDeprecated}';
}

class AllOfModel extends Model with NamedModel, CompositeModel {
  const AllOfModel({
    required this.models,
    required this.name,
    required super.context,
    required this.description,
    required this.isDeprecated,
  });

  @override
  final String? name;
  final Set<Model> models;
  final String? description;
  final bool isDeprecated;

  @override
  Set<Model> get containedModels => models;

  @override
  String toString() =>
      'AllOfModel{name: $name, models: $models, description: $description, '
      'isDeprecated: $isDeprecated}';
}

typedef DiscriminatedModel = ({String? discriminatorValue, Model model});

class OneOfModel extends Model with NamedModel, CompositeModel {
  const OneOfModel({
    required this.models,
    required this.name,
    required this.discriminator,
    required super.context,
    required this.description,
    required this.isDeprecated,
  });

  @override
  final String? name;
  final Set<DiscriminatedModel> models;
  final String? discriminator;
  final String? description;
  final bool isDeprecated;

  @override
  Set<Model> get containedModels => models.map((m) => m.model).toSet();

  @override
  String toString() =>
      'OneOfModel{name: $name, models: $models, discriminator: $discriminator, '
      'description: $description, isDeprecated: $isDeprecated}';
}

class AnyOfModel extends Model with NamedModel, CompositeModel {
  const AnyOfModel({
    required this.models,
    required this.name,
    required this.discriminator,
    required super.context,
    required this.description,
    required this.isDeprecated,
  });

  @override
  final String? name;
  final Set<DiscriminatedModel> models;
  final String? discriminator;
  final String? description;
  final bool isDeprecated;

  @override
  Set<Model> get containedModels => models.map((m) => m.model).toSet();

  @override
  String toString() =>
      'AnyOfModel{name: $name, models: $models, discriminator: $discriminator, '
      'description: $description, isDeprecated: $isDeprecated}';
}

sealed class PrimitiveModel extends Model {
  const PrimitiveModel({required super.context});

  @override
  EncodingShape get encodingShape => EncodingShape.simple;
}

class IntegerModel extends PrimitiveModel {
  const IntegerModel({required super.context});

  @override
  String toString() => 'IntegerModel';
}

class DoubleModel extends PrimitiveModel {
  const DoubleModel({required super.context});

  @override
  String toString() => 'DoubleModel';
}

class NumberModel extends PrimitiveModel {
  const NumberModel({required super.context});

  @override
  String toString() => 'NumberModel';
}

class StringModel extends PrimitiveModel {
  const StringModel({required super.context});

  @override
  String toString() => 'StringModel';
}

class BooleanModel extends PrimitiveModel {
  const BooleanModel({required super.context});

  @override
  String toString() => 'BooleanModel';
}

class DateTimeModel extends PrimitiveModel {
  const DateTimeModel({required super.context});

  @override
  String toString() => 'DateTimeModel';
}

class DateModel extends PrimitiveModel {
  const DateModel({required super.context});

  @override
  String toString() => 'DateModel';
}

class DecimalModel extends PrimitiveModel {
  const DecimalModel({required super.context});

  @override
  String toString() => 'DecimalModel';
}

class UriModel extends PrimitiveModel {
  const UriModel({required super.context});

  @override
  String toString() => 'UriModel';
}

@immutable
class Property {
  const Property({
    required this.name,
    required this.model,
    required this.isRequired,
    required this.isNullable,
    required this.isDeprecated,
    required this.description,
  });

  final String name;
  final Model model;
  final bool isRequired;
  final bool isNullable;
  final bool isDeprecated;
  final String? description;

  @override
  String toString() =>
      'Property{name: $name, model: $model, isRequired: $isRequired, '
      'isNullable: $isNullable, isDeprecated: $isDeprecated, '
      'description: $description}';
}
