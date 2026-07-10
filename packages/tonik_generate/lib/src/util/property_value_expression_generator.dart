import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/raw_string_expression_generator.dart';

const _tonikUtilUrl = 'package:tonik_util/tonik_util.dart';

/// `PropertyValue.scalar(<raw>)`.
Expression propertyValueScalar(Expression raw) =>
    refer('PropertyValue', _tonikUtilUrl).property('scalar').call([raw]);

/// `PropertyValue.array(<rawList>)`.
Expression propertyValueArray(Expression rawList) =>
    refer('PropertyValue', _tonikUtilUrl).property('array').call([rawList]);

/// The raw scalar for an additional-property [value] of [valueModel], applying
/// the null → empty-string policy when the value is nullable.
Expression additionalPropertyRawScalar(Expression value, Model valueModel) {
  if (valueModel.isEffectivelyNullable) {
    return value
        .equalTo(literalNull)
        .conditional(
          literalString(''),
          buildRawStringExpression(value.nullChecked, valueModel),
        );
  }
  return buildRawStringExpression(value, valueModel);
}

/// Builds a `List<String>` of per-element strings for a simple-content list
/// whose element type is [contentModel].
///
/// Both scalar and composite content are raw (unescaped): the traversal mirrors
/// the URI-encode list handling minus the per-element percent-encoding, so
/// element boundaries reach the form encoder intact (`.unlock` for immutable
/// collections, a null-element to `''` guard for nullable content). The late
/// style/form encoder does the single percent-encode.
Expression buildRawStringListExpression(
  Expression valueExpression,
  Model contentModel, {
  required bool isContentNullable,
  bool useImmutableCollections = false,
}) {
  final listExpr = useImmutableCollections
      ? valueExpression.property('unlock')
      : valueExpression;

  Expression nullGuard(Expression raw) => isContentNullable
      ? refer('e').equalTo(literalNull).conditional(literalString(''), raw)
      : raw;

  Expression mapToRaw(Expression body) => listExpr
      .property('map')
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(Parameter((p) => p..name = 'e'))
            ..body = body.code,
        ).closure,
      ])
      .property('toList')
      .call([]);

  return switch (contentModel) {
    StringModel() when isContentNullable => mapToRaw(
      refer('e').ifNullThen(literalString('')),
    ),
    StringModel() => listExpr,
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    BinaryModel() ||
    Base64Model() ||
    EnumModel() => mapToRaw(
      nullGuard(buildRawStringExpression(refer('e'), contentModel)),
    ),
    AnyModel() || AnyOfModel() || OneOfModel() || AllOfModel() => mapToRaw(
      nullGuard(
        refer('encodeAnyValueToString', _tonikUtilUrl).call(
          [
            refer('e').property('toJson').call([]),
          ],
          {'allowEmpty': refer('allowEmpty')},
        ),
      ),
    ),
    AliasModel(:final model) => buildRawStringListExpression(
      valueExpression,
      model,
      isContentNullable: isContentNullable,
      useImmutableCollections: useImmutableCollections,
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported list content type for URI encoding.',
    ),
  };
}
