import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

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
    // MapModel: convert to Map<String, String> via toParameterMap(), then
    // call toLabel() on the resulting map.
    MapModel() => (isNullable
            ? valueExpression.nullSafeProperty('toParameterMap').call([])
            : valueExpression.property('toParameterMap').call([]))
        .property('toLabel')
        .call(
          [],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),

    // Base64Model: convert to base64 string via toBase64String(), then
    // call toLabel() on the resulting string.
    Base64Model() => (isNullable
            ? valueExpression.nullSafeProperty('toBase64String').call([])
            : valueExpression.property('toBase64String').call([]))
        .property('toLabel')
        .call(
          [],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),

    // BinaryModel (format: binary) cannot be label-encoded.
    BinaryModel() => generateEncodingExceptionExpression(
      'Binary data cannot be label-encoded',
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
    // List<Map<String, V>>: map each item through
    // toParameterMap().uriEncode() then call toLabel().
    MapModel() =>
      listMapAccess
          .call([
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
    // List<TonikFile> (base64): map each item through
    // toBase64String().uriEncode() then call toLabel().
    Base64Model() =>
      listMapAccess
          .call([
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
