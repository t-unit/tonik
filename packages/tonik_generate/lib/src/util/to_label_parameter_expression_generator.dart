import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';

Expression buildLabelParameterExpression(
  Expression valueExpression,
  Model model, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  final propertyAccess = isNullable
      ? valueExpression.nullSafeProperty('toLabel')
      : valueExpression.property('toLabel');

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
    AnyOfModel() => propertyAccess.call(
      [],
      {
        'explode': explode,
        'allowEmpty': allowEmpty,
      },
    ),
    ListModel(:final content) => _buildListLabelExpression(
      valueExpression,
      content,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    AliasModel() => buildLabelParameterExpression(
      valueExpression,
      model.model,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    AnyModel() => _buildAnyModelLabelExpression(
      valueExpression,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    Base64Model() => (isNullable
            ? valueExpression.nullSafeProperty('toBase64String')
            : valueExpression.property('toBase64String'))
        .call([])
        .property('toLabel')
        .call(
          [],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),
    BinaryModel() => generateEncodingExceptionExpression(
      'Binary data cannot be label-encoded',
    ),
    MapModel() => _buildMapLabelExpression(
      valueExpression,
      model,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported model type for label encoding.',
    ),
  };
}

Expression _buildListLabelExpression(
  Expression valueExpression,
  Model contentModel, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  final listPropertyAccess = isNullable
      ? valueExpression.nullSafeProperty('toLabel')
      : valueExpression.property('toLabel');

  final listMapAccess = isNullable
      ? valueExpression.nullSafeProperty('map')
      : valueExpression.property('map');

  return switch (contentModel) {
    StringModel() => listPropertyAccess.call(
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
    EnumModel() =>
      listMapAccess
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body = refer('e').property('uriEncode').call([], {
                  'allowEmpty': allowEmpty,
                }).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toLabel')
          .call(
            [],
            {
              'explode': explode,
              'allowEmpty': allowEmpty,
              'alreadyEncoded': literalTrue,
            },
          ),
    AliasModel() => _buildListLabelExpression(
      valueExpression,
      contentModel.model,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    AnyModel() || AllOfModel() || OneOfModel() || AnyOfModel() =>
      listMapAccess
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body = refer(
                  'encodeAnyToUri',
                  'package:tonik_util/tonik_util.dart',
                ).call([refer('e')], {'allowEmpty': allowEmpty}).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toLabel')
          .call(
            [],
            {
              'explode': explode,
              'allowEmpty': allowEmpty,
              'alreadyEncoded': literalTrue,
            },
          ),
    Base64Model() => listMapAccess
        .call([
          Method(
            (b) => b
              ..requiredParameters.add(
                Parameter((b) => b..name = 'e'),
              )
              ..body = refer('e')
                  .property('toBase64String')
                  .call([])
                  .code,
          ).closure,
        ])
        .property('toList')
        .call([])
        .property('toLabel')
        .call(
          [],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
            'alreadyEncoded': literalTrue,
          },
        ),
    MapModel() => _buildListMapContentLabelExpression(
      valueExpression,
      contentModel,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    ClassModel() || ListModel() => listPropertyAccess.call(
      [],
      {
        'explode': explode,
        'allowEmpty': allowEmpty,
      },
    ),
    BinaryModel() => generateEncodingExceptionExpression(
      'Binary data cannot be label-encoded',
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported list content type for label encoding.',
    ),
  };
}

Expression _buildMapLabelExpression(
  Expression valueExpression,
  MapModel model, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  final converted = buildMapToStringMapExpression(
    valueExpression,
    model,
    isNullable: isNullable,
  );

  if (converted == null) {
    return generateEncodingExceptionExpression(
      'Map with complex value types cannot be label-encoded.',
    );
  }

  final toLabelAccess = (isNullable && converted == valueExpression)
      ? converted.nullSafeProperty('toLabel')
      : converted.property('toLabel');

  return toLabelAccess.call(
    [],
    {
      'explode': explode,
      'allowEmpty': allowEmpty,
    },
  );
}

Expression _buildListMapContentLabelExpression(
  Expression valueExpression,
  MapModel contentModel, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  final converted = buildMapToStringMapExpression(
    refer('e'),
    contentModel,
    isNullable: false,
  );

  if (converted == null) {
    return generateEncodingExceptionExpression(
      'List of maps with complex value types cannot be label-encoded.',
    );
  }

  final listMapAccess = isNullable
      ? valueExpression.nullSafeProperty('map')
      : valueExpression.property('map');

  return listMapAccess
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(
              Parameter((b) => b..name = 'e'),
            )
            ..body = converted
                .property('toLabel')
                .call(
                  [],
                  {
                    'explode': explode,
                    'allowEmpty': allowEmpty,
                  },
                )
                .code,
        ).closure,
      ])
      .property('toList')
      .call([])
      .property('toLabel')
      .call(
        [],
        {
          'explode': explode,
          'allowEmpty': allowEmpty,
          'alreadyEncoded': literalTrue,
        },
      );
}

Expression _buildAnyModelLabelExpression(
  Expression valueExpression, {
  required Expression explode,
  required Expression allowEmpty,
}) {
  return refer('encodeAnyToLabel', 'package:tonik_util/tonik_util.dart').call(
    [valueExpression],
    {
      'explode': explode,
      'allowEmpty': allowEmpty,
    },
  );
}
