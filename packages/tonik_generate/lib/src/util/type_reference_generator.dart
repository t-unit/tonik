import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';

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
            ..symbol = 'Date'
            ..url = 'package:tonik_util/tonik_util.dart'
            ..isNullable = isNullableOverride,
    ),
    DecimalModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'BigDecimal'
            ..url = 'package:big_decimal/big_decimal.dart'
            ..isNullable = isNullableOverride,
    ),
    UriModel _ => TypeReference(
      (b) =>
          b
            ..symbol = 'Uri'
            ..url = 'dart:core'
            ..isNullable = isNullableOverride,
    ),
    final CompositeModel m => TypeReference(
      (b) =>
          b
            ..symbol = nameManager.modelName(m)
            ..url = package
            ..isNullable = isNullableOverride,
    ),
  };
}

/// Returns a TypeReference for [Map<String, Object?>].
///
/// This can be used with Code.scope to create properly
/// qualified type references in generated code.
TypeReference buildMapStringObjectType() => TypeReference(
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
                  ..symbol = 'Object?'
                  ..url = 'dart:core',
          ),
        ]),
);

/// Returns a TypeReference for [Map<String, String>].
TypeReference buildMapStringStringType() => TypeReference(
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
                  ..symbol = 'String'
                  ..url = 'dart:core',
          ),
        ]),
);

/// Returns a Parameter for a boolean named parameter with default value.
Parameter buildBoolParameter(
  String name, {
  bool defaultValue = false,
  bool required = false,
}) =>
    Parameter(
      (b) =>
          b
            ..name = name
            ..type = refer('bool', 'dart:core')
            ..named = true
            ..required = required
            ..defaultTo = required ? null : literalBool(defaultValue).code,
    );

/// Returns a Parameter for a String named parameter with default value.
Parameter buildStringParameter(
  String name, {
  String? defaultValue,
  bool required = false,
}) =>
    Parameter(
      (b) =>
          b
            ..name = name
            ..type = refer('String', 'dart:core')
            ..named = true
            ..required = required
            ..defaultTo = required || defaultValue == null
                ? null
                : literalString(defaultValue).code,
    );

/// Returns a list of common encoding parameters (explode and allowEmpty).
List<Parameter> buildEncodingParameters() => [
      buildBoolParameter('explode', required: true),
      buildBoolParameter('allowEmpty', required: true),
    ];

/// Returns a LiteralMapExpression for an empty [Map<String, String>] literal.
///
/// This can be used with Code.scope to create properly
/// qualified empty map literals in generated code.
LiteralMapExpression buildEmptyMapStringString() => literalMap(
  {},
  TypeReference(
    (b) =>
        b
          ..symbol = 'String'
          ..url = 'dart:core',
  ),
  TypeReference(
    (b) =>
        b
          ..symbol = 'String'
          ..url = 'dart:core',
  ),
);
