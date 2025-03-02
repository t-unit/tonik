import 'package:meta/meta.dart';
import 'package:tonic_core/src/util/context.dart';

@immutable
sealed class Model {
  const Model({required this.context});

  final Context context;
}

mixin NamedModel on Model {
  String? get name;
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

  @override
  String toString() => 'AliasModel{name: $name, model: $model}';
}

class ListModel extends Model {
  const ListModel({required this.content, required super.context});

  final Model content;

  @override
  String toString() => 'ListModel{content: $content}';
}

class ClassModel extends Model with NamedModel {
  const ClassModel({
    required this.properties,
    required super.context,
    this.name,
  });

  @override
  final String? name;
  final Set<Property> properties;

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
  String toString() =>
      'EnumModel{name: $name, values: $values isNullable: $isNullable}';
}

class AllOfModel extends Model with NamedModel {
  const AllOfModel({
    required this.models,
    required this.name,
    required super.context,
  });

  @override
  final String? name;
  final Set<Model> models;

  @override
  String toString() => 'AllOfModel{models: $models}';
}

typedef DiscriminatedModel = ({String? discriminatorValue, Model model});

class OneOfModel extends Model with NamedModel {
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
  String toString() =>
      'OneOfModel{models: $models, discriminator: $discriminator}';
}

class AnyOfModel extends Model with NamedModel {
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
  String toString() =>
      'AnyOfModel{models: $models, discriminator: $discriminator}';
}

sealed class PrimitiveModel extends Model {
  const PrimitiveModel({required super.context});
}

class IntegerModel extends PrimitiveModel {
  const IntegerModel({required super.context});
}

class DoubleModel extends PrimitiveModel {
  const DoubleModel({required super.context});
}

class NumberModel extends PrimitiveModel {
  const NumberModel({required super.context});
}

class StringModel extends PrimitiveModel {
  const StringModel({required super.context});
}

class BooleanModel extends PrimitiveModel {
  const BooleanModel({required super.context});
}

class DateTimeModel extends PrimitiveModel {
  const DateTimeModel({required super.context});
}

class DateModel extends PrimitiveModel {
  const DateModel({required super.context});
}

class DecimalModel extends PrimitiveModel {
  const DecimalModel({required super.context});
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
