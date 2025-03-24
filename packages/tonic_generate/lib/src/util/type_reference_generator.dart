import 'package:code_builder/code_builder.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

/// Generates a TypeReference from a model.
TypeReference getTypeReference(
  Model model,
  NameManger nameManger,
  String package,
) {
  return switch (model) {
    final ListModel m => TypeReference(
      (b) =>
          b
            ..symbol = 'List'
            ..url = 'dart:core'
            ..types.add(getTypeReference(m.content, nameManger, package)),
    ),
    final NamedModel m => TypeReference(
      (b) =>
          b
            ..symbol = nameManger.modelName(m)
            ..url = package,
    ),
    StringModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'String'
            ..url = 'dart:core',
    ),
    IntegerModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'int'
            ..url = 'dart:core',
    ),
    DoubleModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'double'
            ..url = 'dart:core',
    ),
    NumberModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'num'
            ..url = 'dart:core',
    ),
    BooleanModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'bool'
            ..url = 'dart:core',
    ),
    DateTimeModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'DateTime'
            ..url = 'dart:core',
    ),
    DateModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'DateTime'
            ..url = 'dart:core',
    ),
    DecimalModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'BigDecimal'
            ..url = 'package:big_decimal/big_decimal.dart',
    ),
  };
}
