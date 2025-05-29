import 'package:meta/meta.dart';
import 'package:tonik_core/src/util/context.dart';

enum EncodingShape {
  simple,
  complex,
  mixed,
}

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

  @override
  String toString() => 'ListModel{name: $name, content: $content}';
}

class ClassModel extends Model with NamedModel {
  const ClassModel({
    required this.properties,
    required super.context,
    this.name,
  });

  @override
  final String? name;
  final List<Property> properties;

  @override
  EncodingShape get encodingShape => EncodingShape.complex;

  @override
  String toString() => 'ClassModel{name: $name, properties: $properties}';
}

class EnumModel<T> extends Model with NamedModel {
  const EnumModel({
    required this.values,
    required this.isNullable,
    required super.context,
    this.name,
  });

  @override
  final String? name;
  final Set<T> values;
  final bool isNullable;

  @override
  EncodingShape get encodingShape => EncodingShape.simple;

  @override
  String toString() =>
      'EnumModel<$T>{name: $name, values: $values isNullable: $isNullable}';
}

class AllOfModel extends Model with NamedModel, CompositeModel {
  const AllOfModel({
    required this.models,
    required this.name,
    required super.context,
  });

  @override
  final String? name;
  final Set<Model> models;

  @override
  Set<Model> get containedModels => models;

  @override
  String toString() => 'AllOfModel{models: $models}';
}

typedef DiscriminatedModel = ({String? discriminatorValue, Model model});

class OneOfModel extends Model with NamedModel, CompositeModel {
  const OneOfModel({
    required this.models,
    required this.name,
    required this.discriminator,
    required super.context,
  });

  @override
  final String? name;
  final Set<DiscriminatedModel> models;
  final String? discriminator;

  @override
  Set<Model> get containedModels => models.map((m) => m.model).toSet();

  @override
  String toString() =>
      'OneOfModel{models: $models, discriminator: $discriminator}';
}

class AnyOfModel extends Model with NamedModel, CompositeModel {
  const AnyOfModel({
    required this.models,
    required this.name,
    required this.discriminator,
    required super.context,
  });

  @override
  final String? name;
  final Set<DiscriminatedModel> models;
  final String? discriminator;

  @override
  Set<Model> get containedModels => models.map((m) => m.model).toSet();

  @override
  String toString() =>
      'AnyOfModel{models: $models, discriminator: $discriminator}';
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

@immutable
class Property {
  const Property({
    required this.name,
    required this.model,
    required this.isRequired,
    required this.isNullable,
    required this.isDeprecated,
  });

  final String name;
  final Model model;
  final bool isRequired;
  final bool isNullable;
  final bool isDeprecated;

  @override
  String toString() =>
      'Property{name: $name, model: $model, isRequired: $isRequired, '
      'isNullable: $isNullable, isDeprecated: $isDeprecated}';
}
