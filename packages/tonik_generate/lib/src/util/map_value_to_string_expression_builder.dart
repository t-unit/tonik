import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';

/// Builds an expression that converts a `Map<String, V>` to
/// `Map<String, String>` based on the [MapModel]'s value type.
///
/// For StringModel values, returns the [receiver] unchanged (already
/// `Map<String, String>`). For primitive values, emits a `.map()` call
/// with the correct type-specific conversion. For unsupported values
/// (ClassModel, ListModel, nested MapModel, BinaryModel, NeverModel),
/// returns `null` -- the caller is responsible for throwing an
/// `EncodingException`.
///
/// The [isNullable] parameter tracks whether the map itself is nullable
/// (i.e. `Map<String, V>?`). Value-level nullability comes from
/// `model.valueModel` and is checked separately inside this function.
Expression? buildMapToStringMapExpression(
  Expression receiver,
  MapModel model, {
  required bool isNullable,
}) {
  final valueModel = model.valueModel;
  final valueIsNullable = valueModel.isEffectivelyNullable;
  return _buildConversion(
    receiver,
    valueModel,
    isNullable: isNullable,
    valueIsNullable: valueIsNullable,
  );
}

Expression? _buildConversion(
  Expression receiver,
  Model valueModel, {
  required bool isNullable,
  required bool valueIsNullable,
}) {
  return switch (valueModel) {
    StringModel() => receiver,
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() =>
      _buildMapCall(
        receiver,
        _wrapNullable(
          refer('v').property('toString').call([]),
          valueIsNullable,
        ),
        isNullable: isNullable,
      ),
    DateTimeModel() => _buildMapCall(
      receiver,
      _wrapNullable(
        refer('v').property('toTimeZonedIso8601String').call([]),
        valueIsNullable,
      ),
      isNullable: isNullable,
    ),
    EnumModel<String>() => _buildMapCall(
      receiver,
      _wrapNullable(
        refer('v').property('toJson').call([]),
        valueIsNullable,
      ),
      isNullable: isNullable,
    ),
    EnumModel() => _buildMapCall(
      receiver,
      _wrapNullable(
        refer('v').property('toJson').call([]).property('toString').call([]),
        valueIsNullable,
      ),
      isNullable: isNullable,
    ),
    Base64Model() => _buildMapCall(
      receiver,
      _wrapNullable(
        refer('v').property('toBase64String').call([]),
        valueIsNullable,
      ),
      isNullable: isNullable,
    ),
    AnyModel() => _buildMapCall(
      receiver,
      refer(
        'encodeAnyValueToString',
        'package:tonik_util/tonik_util.dart',
      ).call(
        [refer('v')],
        {'allowEmpty': literalBool(false)},
      ),
      isNullable: isNullable,
    ),
    AliasModel(:final model) => _buildConversion(
      receiver,
      model,
      isNullable: isNullable,
      valueIsNullable: valueIsNullable,
    ),
    ClassModel() ||
    ListModel() ||
    MapModel() ||
    BinaryModel() ||
    NeverModel() =>
      null,
    _ => null,
  };
}

/// Wraps a conversion expression with a null check when the value
/// is nullable: `v == null ? '' : <conversion>`.
Expression _wrapNullable(Expression conversion, bool valueIsNullable) {
  if (!valueIsNullable) return conversion;
  return refer('v')
      .equalTo(literalNull)
      .conditional(literalString(''), conversion);
}

/// Builds a `.map((k, v) => MapEntry(k, <valueExpr>))` call on the
/// [receiver].
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
