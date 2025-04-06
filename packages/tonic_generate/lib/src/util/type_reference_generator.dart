import 'package:code_builder/code_builder.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_manager.dart';

/// Generates a TypeReference from a model.
TypeReference typeReference(
  Model model,
  NameManager nameManager,
  String package, {
  bool isNullableOverride = false,
}) {
  return switch (model) {
    final ListModel m => TypeReference(
      (b) =>
          b
            ..symbol = 'List'
            ..url = 'dart:core'
            ..types.add(typeReference(m.content, nameManager, package))
            ..isNullable = isNullableOverride,
    ),
    final NamedModel m => TypeReference(
      (b) =>
          b
            ..symbol = nameManager.modelName(m)
            ..url = package
            ..isNullable =
                isNullableOverride || ((m is EnumModel) && m.isNullable),
    ),
    StringModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'String'
            ..url = 'dart:core'
            ..isNullable = isNullableOverride,
    ),
    IntegerModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'int'
            ..url = 'dart:core'
            ..isNullable = isNullableOverride,
    ),
    DoubleModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'double'
            ..url = 'dart:core'
            ..isNullable = isNullableOverride,
    ),
    NumberModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'num'
            ..url = 'dart:core'
            ..isNullable = isNullableOverride,
    ),
    BooleanModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'bool'
            ..url = 'dart:core'
            ..isNullable = isNullableOverride,
    ),
    DateTimeModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'DateTime'
            ..url = 'dart:core'
            ..isNullable = isNullableOverride,
    ),
    DateModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'DateTime'
            ..url = 'dart:core'
            ..isNullable = isNullableOverride,
    ),
    DecimalModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'BigDecimal'
            ..url = 'package:big_decimal/big_decimal.dart'
            ..isNullable = isNullableOverride,
    ),
  };
}

/// Returns a TypeReference for [Map<String, dynamic>].
///
/// This can be used with Code.scope to create properly
/// qualified type references in generated code.
TypeReference buildMapStringDynamicType() => TypeReference(
  (b) =>
      b
        ..symbol = 'Map'
        ..url = 'dart:core'
        ..types.addAll([
          TypeReference(
            (b) =>
                b
                  ..symbol = 'String'
                  ..url = 'dart:core',
          ),
          TypeReference(
            (b) =>
                b
                  ..symbol = 'dynamic'
                  ..url = 'dart:core',
          ),
        ]),
);
