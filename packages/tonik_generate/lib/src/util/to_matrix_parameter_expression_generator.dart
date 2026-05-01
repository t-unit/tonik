import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/encoding_policy.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';

Expression buildMatrixParameterExpression(
  Expression valueExpression,
  Model model, {
  required Expression paramName,
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  final propertyAccess = isNullable
      ? valueExpression.nullSafeProperty('toMatrix')
      : valueExpression.property('toMatrix');

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
      isNullable: isNullable,
    ),
    AliasModel() => buildMatrixParameterExpression(
      valueExpression,
      model.model,
      paramName: paramName,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    AnyModel() => encodeAnyToMatrixExpression(
      valueExpression,
      paramName: paramName,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    Base64Model() => (isNullable
            ? valueExpression.nullSafeProperty('toBase64String')
            : valueExpression.property('toBase64String'))
        .call([])
        .property('toMatrix')
        .call(
          [paramName],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),
    BinaryModel() => generateEncodingExceptionExpression(
      'Binary data cannot be matrix-encoded',
    ),
    MapModel() => _buildMapMatrixExpression(
      valueExpression,
      model,
      paramName: paramName,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported model type for matrix encoding.',
    ),
  };
}

/// Returns true if the matrix encoding expression for [model] uses the value
/// (i.e., does not unconditionally throw).
///
/// Used by OneOf/AnyOf generators to decide whether to destructure the variant.
bool matrixParameterExpressionUsesValue(Model model) {
  return switch (model) {
    BinaryModel() => false,
    MapModel() => _mapMatrixUsesValue(model),
    ListModel(:final content) => _listMatrixContentUsesValue(content),
    _ => true,
  };
}

bool _mapMatrixUsesValue(MapModel model) {
  final converted = buildMapToStringMapExpression(
    refer('_'),
    model,
    isNullable: false,
  );
  return converted != null;
}

bool _listMatrixContentUsesValue(Model content) {
  return switch (content) {
    ClassModel() || ListModel() => false,
    AliasModel(:final model) => _listMatrixContentUsesValue(model),
    _ => true,
  };
}

Expression _buildListMatrixExpression(
  Expression valueExpression,
  Model contentModel, {
  required Expression paramName,
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  final listPropertyAccess = isNullable
      ? valueExpression.nullSafeProperty('toMatrix')
      : valueExpression.property('toMatrix');

  final listMapAccess = isNullable
      ? valueExpression.nullSafeProperty('map')
      : valueExpression.property('map');

  return switch (contentModel) {
    StringModel() => listPropertyAccess.call(
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
    EnumModel() =>
      listMapAccess
          .call(
            [
              Method(
                (b) => b
                  ..requiredParameters.add(
                    Parameter((b) => b..name = 'e'),
                  )
                  ..body = refer('e').property('uriEncode').call(
                    [],
                    {'allowEmpty': allowEmpty},
                  ).code,
              ).closure,
            ],
            {},
            [refer('String', 'dart:core')],
          )
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
      isNullable: isNullable,
    ),
    AnyModel() || AllOfModel() || OneOfModel() || AnyOfModel() =>
      listMapAccess
          .call(
            [
              Method(
                (b) => b
                  ..requiredParameters.add(
                    Parameter((b) => b..name = 'e'),
                  )
                  ..body = encodeAnyToUriExpression(
                    refer('e'),
                    allowEmpty: allowEmpty,
                  ).code,
              ).closure,
            ],
            {},
            [refer('String', 'dart:core')],
          )
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
    Base64Model() => listMapAccess
        .call(
          [
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
          ],
          {},
          [refer('String', 'dart:core')],
        )
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
    MapModel() => _buildListMapContentMatrixExpression(
      valueExpression,
      contentModel,
      paramName: paramName,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    ClassModel() || ListModel() => generateEncodingExceptionExpression(
      'Lists with complex content cannot be matrix-encoded',
    ),
    BinaryModel() => generateEncodingExceptionExpression(
      'Binary data cannot be matrix-encoded',
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported list content type for matrix encoding.',
    ),
  };
}

Expression _buildMapMatrixExpression(
  Expression valueExpression,
  MapModel model, {
  required Expression paramName,
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
      'Map with complex value types cannot be matrix-encoded.',
    );
  }

  final toMatrixAccess = (isNullable && converted == valueExpression)
      ? converted.nullSafeProperty('toMatrix')
      : converted.property('toMatrix');

  return toMatrixAccess.call(
    [paramName],
    {
      'explode': explode,
      'allowEmpty': allowEmpty,
    },
  );
}

Expression _buildListMapContentMatrixExpression(
  Expression valueExpression,
  MapModel contentModel, {
  required Expression paramName,
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
      'List of maps with complex value types cannot be matrix-encoded.',
    );
  }

  final listMapAccess = isNullable
      ? valueExpression.nullSafeProperty('map')
      : valueExpression.property('map');

  return listMapAccess
      .call(
        [
          Method(
            (b) => b
              ..requiredParameters.add(
                Parameter((b) => b..name = 'e'),
              )
              ..body = converted
                  .property('toMatrix')
                  .call(
                    [paramName],
                    {
                      'explode': explode,
                      'allowEmpty': allowEmpty,
                    },
                  )
                  .code,
          ).closure,
        ],
        {},
        [refer('String', 'dart:core')],
      )
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
      );
}
