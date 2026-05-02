import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';

/// Builds an expression that converts a `Map<String, V>` to
/// `Map<String, String>` based on the [MapModel]'s value type.
///
/// For StringModel values, returns the [receiver] unchanged (already
/// `Map<String, String>`). For primitive values, emits a `.map()` call
/// with the correct type-specific conversion. For unsupported values
/// (see [isMapValueTypeSimplyEncodable] for the authoritative list),
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

/// Single source of truth for which map value types simple encoding
/// supports. Path-generator guards must use this — a parallel switch
/// would drift and re-introduce the `throw + r'.json'` invalid-Dart bug.
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
    // Catch-all throws so a newly-added Model subtype surfaces at runtime
    // instead of silently returning false (drift protection). NamedModel and
    // CompositeModel are mixins on the sealed Model, so the analyzer does
    // not let us enumerate "every concrete subtype" exhaustively here.
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
    // Catch-all throws so a model type the predicate forgot to filter
    // surfaces at runtime instead of returning a wrong/null expression.
    // The early-return guard above already rejects every model type not
    // explicitly handled here; this arm is the drift-protection backstop.
    _ => _unreachableModelType('_buildConversion'),
  };
}

Expression _wrapNullable(Expression conversion, bool valueIsNullable) {
  if (!valueIsNullable) return conversion;
  return refer('v')
      .equalTo(literalNull)
      .conditional(literalString(''), conversion);
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
