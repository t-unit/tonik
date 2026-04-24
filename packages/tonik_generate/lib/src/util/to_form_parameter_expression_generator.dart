import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

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
    // MapModel: convert to Map<String, String> via toParameterMap(), then
    // call toForm() on the resulting map.
    MapModel() => (isNullable
            ? valueExpression.nullSafeProperty('toParameterMap').call([])
            : valueExpression.property('toParameterMap').call([]))
        .property('toForm')
        .call(
          [],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),

    // Base64Model: convert to base64 string via toBase64String(), then
    // call toForm() on the resulting string.
    Base64Model() => (isNullable
            ? valueExpression.nullSafeProperty('toBase64String').call([])
            : valueExpression.property('toBase64String').call([]))
        .property('toForm')
        .call(
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
    // List<Map<String, V>>: map each item through
    // toParameterMap().toForm()
    MapModel() =>
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
    // List<TonikFile> (base64): map each item through
    // toBase64String().toForm()
    Base64Model() =>
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
