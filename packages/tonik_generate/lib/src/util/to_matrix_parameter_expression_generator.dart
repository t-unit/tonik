import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

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
    AnyModel() => _buildAnyModelMatrixExpression(
      valueExpression,
      paramName: paramName,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
    // MapModel: convert to Map<String, String> via toParameterMap(), then
    // call toMatrix() on the resulting map.
    MapModel() => (isNullable
            ? valueExpression.nullSafeProperty('toParameterMap').call([])
            : valueExpression.property('toParameterMap').call([]))
        .property('toMatrix')
        .call(
          [paramName],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),

    // Base64Model: convert to base64 string via toBase64String(), then
    // call toMatrix() on the resulting string.
    Base64Model() => (isNullable
            ? valueExpression.nullSafeProperty('toBase64String').call([])
            : valueExpression.property('toBase64String').call([]))
        .property('toMatrix')
        .call(
          [paramName],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),

    // BinaryModel (format: binary) cannot be matrix-encoded.
    BinaryModel() => generateEncodingExceptionExpression(
      'Binary data cannot be matrix-encoded',
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
    ListModel(:final content) => _listMatrixContentUsesValue(content),
    _ => true,
  };
}

bool _listMatrixContentUsesValue(Model content) {
  return switch (content) {
    ClassModel() || ListModel() => false,
    AliasModel(:final model) => _listMatrixContentUsesValue(model),
    _ => true,
  };
}

Expression _buildAnyModelMatrixExpression(
  Expression valueExpression, {
  required Expression paramName,
  required Expression explode,
  required Expression allowEmpty,
}) {
  return refer('encodeAnyToMatrix', 'package:tonik_util/tonik_util.dart').call(
    [valueExpression, paramName],
    {
      'explode': explode,
      'allowEmpty': allowEmpty,
    },
  );
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
                  ..body =
                      refer(
                            'encodeAnyToUri',
                            'package:tonik_util/tonik_util.dart',
                          )
                          .call(
                            [refer('e')],
                            {'allowEmpty': allowEmpty},
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
          ),
    // List<Map<String, V>>: map each item through
    // toParameterMap().uriEncode() then call toMatrix().
    MapModel() =>
      listMapAccess
          .call(
            [
              Method(
                (b) => b
                  ..requiredParameters.add(
                    Parameter((b) => b..name = 'e'),
                  )
                  ..body = refer('e')
                      .property('toParameterMap')
                      .call([])
                      .property('uriEncode')
                      .call([], {'allowEmpty': allowEmpty})
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
    // List<TonikFile> (base64): map each item through
    // toBase64String().uriEncode() then call toMatrix().
    Base64Model() =>
      listMapAccess
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
                      .property('uriEncode')
                      .call([], {'allowEmpty': allowEmpty})
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
