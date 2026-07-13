import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/flat_value_codec_plan.dart';
import 'package:tonik_generate/src/util/property_value_expression_generator.dart';

sealed class MapPropertyValueConversion {
  const MapPropertyValueConversion();
}

final class SupportedMapPropertyValueConversion
    extends MapPropertyValueConversion {
  const SupportedMapPropertyValueConversion(this.expression);

  final Expression expression;
}

final class UnsupportedMapPropertyValueConversion
    extends MapPropertyValueConversion {
  const UnsupportedMapPropertyValueConversion(this.reason);

  final String reason;
}

MapPropertyValueConversion buildMapPropertyValueConversion(
  Expression receiver,
  MapModel model, {
  required bool isNullable,
  required String context,
}) {
  final omitsNull =
      model.isValueNullable ||
      model.valueModel.isEffectivelyNullable ||
      model.valueModel.resolved is AnyModel;
  final value = omitsNull
      ? refer('e').property('value').nullChecked
      : refer('v');
  final plan = buildFlatEncodePlan(
    value,
    model.valueModel,
    context: context,
  );

  final propertyValue = switch (plan) {
    FlatScalarEncodePlan(:final value) => propertyValueScalar(value),
    FlatArrayEncodePlan() => null,
    UnsupportedFlatEncodePlan() => null,
  };
  if (propertyValue == null) {
    final reason = switch (plan) {
      FlatArrayEncodePlan() =>
        '${model.valueModel.runtimeType} values have no flat map '
            'representation',
      UnsupportedFlatEncodePlan(:final reason) => reason,
      FlatScalarEncodePlan() => throw StateError('Unreachable scalar plan'),
    };
    return UnsupportedMapPropertyValueConversion(reason);
  }

  final converted = omitsNull
      ? _buildOmittingNullEntries(receiver, propertyValue)
      : _buildMappedEntries(receiver, propertyValue);
  return SupportedMapPropertyValueConversion(
    isNullable
        ? receiver.equalTo(literalNull).conditional(literalNull, converted)
        : converted,
  );
}

Expression _buildMappedEntries(
  Expression receiver,
  Expression propertyValue,
) => receiver.property('map').call([
  Method(
    (b) => b
      ..requiredParameters.addAll([
        Parameter((p) => p..name = 'k'),
        Parameter((p) => p..name = 'v'),
      ])
      ..body = refer('MapEntry', 'dart:core').newInstance([
        refer('k'),
        propertyValue,
      ]).code,
  ).closure,
]);

Expression _buildOmittingNullEntries(
  Expression receiver,
  Expression propertyValue,
) {
  final definedEntries = receiver
      .property('entries')
      .property('where')
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(Parameter((p) => p..name = 'e'))
            ..body = refer(
              'e',
            ).property('value').notEqualTo(literalNull).code,
        ).closure,
      ])
      .property('map')
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(Parameter((p) => p..name = 'e'))
            ..body = refer('MapEntry', 'dart:core').newInstance([
              refer('e').property('key'),
              propertyValue,
            ]).code,
        ).closure,
      ]);
  return refer('Map', 'dart:core').property('fromEntries').call([
    definedEntries,
  ]);
}
