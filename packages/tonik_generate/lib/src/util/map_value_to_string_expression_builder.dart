import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/raw_string_expression_generator.dart';

/// Lets callers add encoder-specific context for unsupported map values.
Expression? buildMapToStringMapExpression(
  Expression receiver,
  MapModel model, {
  required bool isNullable,
}) {
  final valueModel = model.valueModel;
  final valueIsNullable =
      model.isValueNullable || valueModel.isEffectivelyNullable;
  return _buildConversion(
    receiver,
    valueModel,
    isNullable: isNullable,
    valueIsNullable: valueIsNullable,
  );
}

/// Keeps path-generator guards and map conversion from drifting apart.
bool isMapValueTypeSimplyEncodable(Model valueModel) {
  return switch (valueModel) {
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    DateTimeModel() ||
    EnumModel() ||
    Base64Model() ||
    AnyModel() => true,
    AliasModel(:final model) => isMapValueTypeSimplyEncodable(model),
    NeverModel() ||
    BinaryModel() ||
    ListModel() ||
    MapModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => false,
    // Mixins keep this switch from being analyzer-exhaustive.
    _ => _unreachableModelType('isMapValueTypeSimplyEncodable'),
  };
}

Never _unreachableModelType(String fn) =>
    throw UnsupportedError('Unreachable Model subtype in $fn');

Expression? _buildConversion(
  Expression receiver,
  Model valueModel, {
  required bool isNullable,
  required bool valueIsNullable,
}) {
  if (!isMapValueTypeSimplyEncodable(valueModel)) return null;

  return switch (valueModel) {
    StringModel() => receiver,
    AnyModel() => _buildMapCall(
      receiver,
      refer(
        'encodeAnyValueToString',
        'package:tonik_util/tonik_util.dart',
      ).call([refer('v')], {'allowEmpty': literalBool(false)}),
      isNullable: isNullable,
    ),
    AliasModel(:final model) => _buildConversion(
      receiver,
      model,
      isNullable: isNullable,
      valueIsNullable: valueIsNullable,
    ),
    _ => _buildMapCall(
      receiver,
      _wrapNullable(
        buildRawStringExpression(refer('v'), valueModel),
        valueIsNullable,
      ),
      isNullable: isNullable,
    ),
  };
}

Expression _wrapNullable(Expression conversion, bool valueIsNullable) {
  if (!valueIsNullable) return conversion;
  return refer(
    'v',
  ).equalTo(literalNull).conditional(literalString(''), conversion);
}

Expression _buildMapCall(
  Expression receiver,
  Expression valueExpression, {
  required bool isNullable,
}) {
  final mapAccess = isNullable
      ? receiver.nullSafeProperty('map')
      : receiver.property('map');

  final mapEntryClosure = Method(
    (b) => b
      ..requiredParameters.addAll([
        Parameter((p) => p..name = 'k'),
        Parameter((p) => p..name = 'v'),
      ])
      ..body = refer(
        'MapEntry',
        'dart:core',
      ).newInstance([refer('k'), valueExpression]).code,
  ).closure;

  return mapAccess.call([mapEntryClosure]);
}
