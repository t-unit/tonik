import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';

Expression buildMatrixParameterExpression(
  Expression valueExpression,
  Model model, {
  required Expression paramName,
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
    AnyOfModel() => valueExpression
        .property('toMatrix')
        .call(
          [paramName],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),
    ListModel(:final content) => _buildListMatrixExpression(
      valueExpression,
      content,
      paramName: paramName,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    AliasModel() => buildMatrixParameterExpression(
      valueExpression,
      model.model,
      paramName: paramName,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    _ =>
      throw UnimplementedError(
        'Unsupported model type for matrix encoding: $model',
      ),
  };
}

Expression _buildListMatrixExpression(
  Expression valueExpression,
  Model contentModel, {
  required Expression paramName,
  required Expression explode,
  required Expression allowEmpty,
}) {
  return switch (contentModel) {
    StringModel() => valueExpression
        .property('toMatrix')
        .call(
          [paramName],
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
    AnyOfModel() => valueExpression
        .property('map')
        .call([
          Method(
            (b) =>
                b
                  ..requiredParameters.add(
                    Parameter((b) => b..name = 'e'),
                  )
                  ..body =
                      refer('e').property('uriEncode').call(
                        [],
                        {'allowEmpty': allowEmpty},
                      ).code,
          ).closure,
        ])
        .property('toList')
        .call([])
        .property('toMatrix')
        .call(
          [paramName],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
            'alreadyEncoded': literalTrue,
          },
        ),
    AliasModel() => _buildListMatrixExpression(
      valueExpression,
      contentModel.model,
      paramName: paramName,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    ClassModel() || ListModel() => valueExpression
        .property('toMatrix')
        .call(
          [paramName],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),
    _ =>
      throw UnimplementedError(
        'Unsupported list content type for matrix encoding: $contentModel',
      ),
  };
}
