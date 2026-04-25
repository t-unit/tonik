import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';

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
    MapModel() => _buildMapUriEncodeExpression(
      valueExpression,
      model,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
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
    _ => generateEncodingExceptionExpression(
      'Unsupported model type for URI encoding.',
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
  // The .uriEncode() extension is defined on List, not IList.
  // Unlock first to get a regular List that has the extension method.
  final listExpr = useImmutableCollections
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
    MapModel() => _buildListMapContentUriEncodeExpression(
      listExpr,
      contentModel,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
    ),
    AliasModel() => _buildListUriEncodeExpression(
      valueExpression,
      contentModel.model,
      allowEmpty: allowEmpty,
      useQueryComponent: useQueryComponent,
      useImmutableCollections: useImmutableCollections,
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported list content type for URI encoding.',
    ),
  };
}

Expression _buildMapUriEncodeExpression(
  Expression valueExpression,
  MapModel model, {
  required Expression allowEmpty,
  Expression? useQueryComponent,
}) {
  final converted = buildMapToStringMapExpression(
    valueExpression,
    model,
    isNullable: false,
  );

  if (converted == null) {
    return generateEncodingExceptionExpression(
      'Map with complex value types cannot be URI-encoded.',
    );
  }

  return converted.property('uriEncode').call(
    [],
    {
      'allowEmpty': allowEmpty,
      'useQueryComponent': ?useQueryComponent,
    },
  );
}

Expression _buildListMapContentUriEncodeExpression(
  Expression listExpression,
  MapModel contentModel, {
  required Expression allowEmpty,
  Expression? useQueryComponent,
}) {
  final converted = buildMapToStringMapExpression(
    refer('e'),
    contentModel,
    isNullable: false,
  );

  if (converted == null) {
    return generateEncodingExceptionExpression(
      'List of maps with complex value types cannot be URI-encoded.',
    );
  }

  return listExpression
      .property('map')
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(
              Parameter((b) => b..name = 'e'),
            )
            ..body = converted
                .property('uriEncode')
                .call(
                  [],
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
      );
}
