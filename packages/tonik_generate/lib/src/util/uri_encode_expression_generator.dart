import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

Expression buildUriEncodeExpression(
  Expression valueExpression,
  Model model, {
  required Expression allowEmpty,
  Expression? useQueryComponent,
  bool useImmutableCollections = false,
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
    BinaryModel() ||
    Base64Model() ||
    EnumModel() => valueExpression.property('uriEncode').call(
      [],
      {
        'allowEmpty': allowEmpty,
        'useQueryComponent': ?useQueryComponent,
      },
    ),
    AnyModel() || AnyOfModel() || OneOfModel() || AllOfModel() =>
      refer(
        'encodeAnyToUri',
        'package:tonik_util/tonik_util.dart',
      ).call(
        [valueExpression],
        {
          'allowEmpty': allowEmpty,
          'useQueryComponent': ?useQueryComponent,
        },
      ),
    MapModel() => generateEncodingExceptionExpression(
      'Map types cannot be URI-encoded.',
    ),
    ListModel(:final content) => _buildListUriEncodeExpression(
      valueExpression,
      content,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      useImmutableCollections: useImmutableCollections,
    ),
    AliasModel() => buildUriEncodeExpression(
      valueExpression,
      model.model,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      useImmutableCollections: useImmutableCollections,
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
  Expression? useQueryComponent,
  bool useImmutableCollections = false,
}) {
  // When using immutable collections, the value is an IList which does not
  // have .uriEncode() or .map(). Unlock it first to get a regular List.
  final listExpr =
      useImmutableCollections
          ? valueExpression.property('unlock')
          : valueExpression;

  return switch (contentModel) {
    StringModel() => listExpr.property('uriEncode').call(
      [],
      {
        'allowEmpty': allowEmpty,
        'useQueryComponent': ?useQueryComponent,
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
    BinaryModel() ||
    Base64Model() ||
    EnumModel() =>
      listExpr
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
                  useQueryComponent: useQueryComponent,
                ).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('uriEncode')
          .call(
            [],
            {
              'allowEmpty': allowEmpty,
              'useQueryComponent': ?useQueryComponent,
            },
          ),
    AnyModel() || AnyOfModel() || OneOfModel() || AllOfModel() =>
      listExpr
          .property('map')
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body =
                    refer(
                          'encodeAnyToUri',
                          'package:tonik_util/tonik_util.dart',
                        )
                        .call(
                          [refer('e')],
                          {
                            'allowEmpty': allowEmpty,
                            'useQueryComponent': ?useQueryComponent,
                          },
                        )
                        .code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('uriEncode')
          .call(
            [],
            {
              'allowEmpty': allowEmpty,
              'useQueryComponent': ?useQueryComponent,
            },
          ),
    AliasModel() => _buildListUriEncodeExpression(
      valueExpression,
      contentModel.model,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      useImmutableCollections: useImmutableCollections,
    ),
    _ => throw UnimplementedError(
      'Unsupported list content type for URI encoding: $contentModel',
    ),
  };
}
