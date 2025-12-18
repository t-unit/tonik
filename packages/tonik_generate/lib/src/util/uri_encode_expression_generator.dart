import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';

Expression buildUriEncodeExpression(
  Expression valueExpression,
  Model model, {
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
    EnumModel() => valueExpression.property('uriEncode').call(
      [],
      {'allowEmpty': allowEmpty},
    ),
    ListModel(:final content) => _buildListUriEncodeExpression(
      valueExpression,
      content,
      allowEmpty: allowEmpty,
    ),
    AliasModel() => buildUriEncodeExpression(
      valueExpression,
      model.model,
      allowEmpty: allowEmpty,
    ),
    _ => throw UnimplementedError(
      'Unsupported model type for URI encoding: $model',
    ),
  };
}

Expression _buildListUriEncodeExpression(
  Expression valueExpression,
  Model contentModel, {
  required Expression allowEmpty,
}) {
  return switch (contentModel) {
    StringModel() => valueExpression.property('uriEncode').call(
      [],
      {'allowEmpty': allowEmpty},
    ),
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    EnumModel() =>
      valueExpression
          .property('map')
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body = buildUriEncodeExpression(
                  refer('e'),
                  contentModel,
                  allowEmpty: allowEmpty,
                ).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('uriEncode')
          .call(
            [],
            {'allowEmpty': allowEmpty},
          ),
    AliasModel() => _buildListUriEncodeExpression(
      valueExpression,
      contentModel.model,
      allowEmpty: allowEmpty,
    ),
    _ => throw UnimplementedError(
      'Unsupported list content type for URI encoding: $contentModel',
    ),
  };
}
