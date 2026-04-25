import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';

Expression buildFormParameterExpression(
  Expression valueExpression,
  Model model, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  final propertyAccess = isNullable
      ? valueExpression.nullSafeProperty('toForm')
      : valueExpression.property('toForm');

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
    Base64Model() => (isNullable
            ? valueExpression.nullSafeProperty('toBase64String')
            : valueExpression.property('toBase64String'))
        .call([])
        .property('toForm')
        .call(
          [],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),
    MapModel() => _buildMapFormExpression(
      valueExpression,
      model,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    ListModel(:final content) => _buildListFormExpression(
      valueExpression,
      content,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    AliasModel() => buildFormParameterExpression(
      valueExpression,
      model.model,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    AnyModel() =>
      refer('encodeAnyToForm', 'package:tonik_util/tonik_util.dart').call(
        [valueExpression],
        {
          'explode': explode,
          'allowEmpty': allowEmpty,
        },
      ),
    BinaryModel() => generateEncodingExceptionExpression(
      'Binary data cannot be form-encoded',
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported model type for form encoding.',
    ),
  };
}

Expression _buildListFormExpression(
  Expression valueExpression,
  Model contentModel, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  final listPropertyAccess = isNullable
      ? valueExpression.nullSafeProperty('toForm')
      : valueExpression.property('toForm');

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
    EnumModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() =>
      listMapAccess
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
      isNullable: isNullable,
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
        .property('toForm')
        .call(
          [],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
            'alreadyEncoded': literalBool(true),
          },
        ),
    MapModel() => _buildListMapContentFormExpression(
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
      'Binary data cannot be form-encoded',
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported list content type for form encoding.',
    ),
  };
}

Expression _buildMapFormExpression(
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
      'Map with complex value types cannot be form-encoded.',
    );
  }

  final toFormAccess = (isNullable && converted == valueExpression)
      ? converted.nullSafeProperty('toForm')
      : converted.property('toForm');

  return toFormAccess.call(
    [],
    {
      'explode': explode,
      'allowEmpty': allowEmpty,
    },
  );
}

Expression _buildListMapContentFormExpression(
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
      'List of maps with complex value types cannot be form-encoded.',
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
                .property('toForm')
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
      .property('toForm')
      .call(
        [],
        {
          'explode': explode,
          'allowEmpty': allowEmpty,
          'alreadyEncoded': literalBool(true),
        },
      );
}
