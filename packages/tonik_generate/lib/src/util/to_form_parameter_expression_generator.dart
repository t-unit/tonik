import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';

Expression buildFormParameterExpression(
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
    AnyOfModel() => valueExpression.property('toForm').call(
      [],
      {
        'explode': explode,
        'allowEmpty': allowEmpty,
      },
    ),
    ListModel(:final content) => _buildListFormExpression(
      valueExpression,
      content,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    AliasModel() => buildFormParameterExpression(
      valueExpression,
      model.model,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    _ => throw UnimplementedError(
      'Unsupported model type for form encoding: $model',
    ),
  };
}

Expression _buildListFormExpression(
  Expression valueExpression,
  Model contentModel, {
  required Expression explode,
  required Expression allowEmpty,
}) {
  return switch (contentModel) {
    StringModel() => valueExpression.property('toForm').call(
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
                ..body = buildFormParameterExpression(
                  refer('e'),
                  contentModel,
                  explode: explode,
                  allowEmpty: allowEmpty,
                ).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toForm')
          .call(
            [],
            {
              'explode': explode,
              'allowEmpty': allowEmpty,
              'alreadyEncoded': literalBool(true),
            },
          ),
    AliasModel() => _buildListFormExpression(
      valueExpression,
      contentModel.model,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    ClassModel() || ListModel() => valueExpression.property('toForm').call(
      [],
      {
        'explode': explode,
        'allowEmpty': allowEmpty,
      },
    ),
    _ => throw UnimplementedError(
      'Unsupported list content type for form encoding: $contentModel',
    ),
  };
}
