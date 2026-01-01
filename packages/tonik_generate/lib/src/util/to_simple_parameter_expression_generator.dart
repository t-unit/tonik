import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';

Expression buildSimpleParameterExpression(
  Expression valueExpression,
  Model model, {
  required Expression explode,
  required Expression allowEmpty,
}) {
  return switch (model) {
    StringModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => valueExpression.property('toSimple').call(
      [],
      {
        'explode': explode,
        'allowEmpty': allowEmpty,
      },
    ),
    ListModel(:final content) => _buildListSimpleExpression(
      valueExpression,
      content,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    AliasModel() => buildSimpleParameterExpression(
      valueExpression,
      model.model,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    AnyModel() =>
      refer('encodeAnyToSimple', 'package:tonik_util/tonik_util.dart').call(
        [valueExpression],
        {
          'explode': explode,
          'allowEmpty': allowEmpty,
        },
      ),
    _ => throw UnimplementedError(
      'Unsupported model type for simple encoding: $model',
    ),
  };
}

Expression _buildListSimpleExpression(
  Expression valueExpression,
  Model contentModel, {
  required Expression explode,
  required Expression allowEmpty,
}) {
  return switch (contentModel) {
    StringModel() => valueExpression.property('toSimple').call(
      [],
      {
        'explode': explode,
        'allowEmpty': allowEmpty,
      },
    ),
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    EnumModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() =>
      valueExpression
          .property('map')
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body = buildSimpleParameterExpression(
                  refer('e'),
                  contentModel,
                  explode: explode,
                  allowEmpty: allowEmpty,
                ).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toSimple')
          .call(
            [],
            {
              'explode': explode,
              'allowEmpty': allowEmpty,
              'alreadyEncoded': literalBool(true),
            },
          ),
    AliasModel() => _buildListSimpleExpression(
      valueExpression,
      contentModel.model,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    ClassModel() || ListModel() => valueExpression.property('toSimple').call(
      [],
      {
        'explode': explode,
        'allowEmpty': allowEmpty,
      },
    ),
    _ => throw UnimplementedError(
      'Unsupported list content type for simple encoding: $contentModel',
    ),
  };
}
