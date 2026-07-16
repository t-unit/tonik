import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_property_value_expression_builder.dart';

BuiltExpression buildLabelParameterExpression(
  Expression valueExpression,
  Model model, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  return BuiltExpression.simple(
    _buildLabelParameterExpression(
      valueExpression,
      model,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
  );
}

Expression _buildLabelParameterExpression(
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
    final ListModel m => _buildListLabelExpression(
      valueExpression,
      m.content,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
      isContentNullable: m.isContentNullable || m.content.isEffectivelyNullable,
    ),
    AliasModel() => _buildLabelParameterExpression(
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
    Base64Model() =>
      (isNullable
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
  bool isContentNullable = false,
}) {
  final listPropertyAccess = isNullable
      ? valueExpression.nullSafeProperty('toLabel')
      : valueExpression.property('toLabel');

  final listMapAccess = isNullable
      ? valueExpression.nullSafeProperty('map')
      : valueExpression.property('map');

  // A null array element encodes to the empty string, coercing the element
  // type back to non-null `String` for the whole-list `toLabel` extension.
  Expression nullGuard(Expression encoded) => isContentNullable
      ? refer('e').equalTo(literalNull).conditional(literalString(''), encoded)
      : encoded;

  Expression base64Encode() => isContentNullable
      ? refer('e')
          .nullSafeProperty('toBase64String')
          .call([])
          .ifNullThen(literalString(''))
      : refer('e').property('toBase64String').call([]);

  return switch (contentModel) {
    StringModel() when !isContentNullable => listPropertyAccess.call(
      [],
      {
        'explode': explode,
        'allowEmpty': allowEmpty,
      },
    ),
    StringModel() ||
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
                ..body = nullGuard(
                  refer('e').property('uriEncode').call([], {
                    'allowEmpty': allowEmpty,
                  }),
                ).code,
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
      isContentNullable: isContentNullable,
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
    Base64Model() =>
      listMapAccess
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body = base64Encode().code,
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
  final conversion = buildMapPropertyValueConversion(
    valueExpression,
    model,
    isNullable: isNullable,
    context: model.name ?? 'map parameter value',
  );
  return switch (conversion) {
    SupportedMapPropertyValueConversion(:final expression) =>
      (isNullable
              ? expression.nullSafeProperty('toLabel')
              : expression.property('toLabel'))
          .call([], {'explode': explode, 'allowEmpty': allowEmpty}),
    UnsupportedMapPropertyValueConversion() =>
      generateEncodingExceptionExpression(
        'Map with complex value types cannot be label-encoded.',
      ),
  };
}

Expression _buildListMapContentLabelExpression(
  Expression valueExpression,
  MapModel contentModel, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  final conversion = buildMapPropertyValueConversion(
    refer('e'),
    contentModel,
    isNullable: false,
    context: contentModel.name ?? 'map parameter value',
  );
  if (conversion is UnsupportedMapPropertyValueConversion) {
    return generateEncodingExceptionExpression(
      'List of maps with complex value types cannot be label-encoded.',
    );
  }
  final converted =
      (conversion as SupportedMapPropertyValueConversion).expression;

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
            ..body = converted.property('toLabel').call(
              [],
              {
                'explode': explode,
                'allowEmpty': allowEmpty,
              },
            ).code,
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
