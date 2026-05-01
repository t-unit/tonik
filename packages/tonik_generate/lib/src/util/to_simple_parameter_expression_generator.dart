import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/encoding_policy.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';

Expression buildSimpleParameterExpression(
  Expression valueExpression,
  Model model, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  final propertyAccess = isNullable
      ? valueExpression.nullSafeProperty('toSimple')
      : valueExpression.property('toSimple');

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
    ListModel(:final content) => _buildListSimpleExpression(
      valueExpression,
      content,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    AliasModel() => buildSimpleParameterExpression(
      valueExpression,
      model.model,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    AnyModel() => simpleEncodingPolicy(
      explode: explode,
      allowEmpty: allowEmpty,
    ).encodeAny(valueExpression),
    Base64Model() => (isNullable
            ? valueExpression.nullSafeProperty('toBase64String')
            : valueExpression.property('toBase64String'))
        .call([])
        .property('toSimple')
        .call(
          [],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
          },
        ),
    BinaryModel() => generateEncodingExceptionExpression(
      'Binary data cannot be simple-encoded',
    ),
    MapModel() => _buildMapSimpleExpression(
      valueExpression,
      model,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported model type for simple encoding.',
    ),
  };
}

Expression _buildListSimpleExpression(
  Expression valueExpression,
  Model contentModel, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
}) {
  final listPropertyAccess = isNullable
      ? valueExpression.nullSafeProperty('toSimple')
      : valueExpression.property('toSimple');

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
                ..body = buildSimpleParameterExpression(
                  refer('e'),
                  contentModel,
                  explode: explode,
                  allowEmpty: allowEmpty,
                ).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toSimple')
          .call(
            [],
            {
              'explode': explode,
              'allowEmpty': allowEmpty,
              'alreadyEncoded': literalBool(true),
            },
          ),
    AliasModel() => _buildListSimpleExpression(
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
          .property('toSimple')
          .call(
            [],
            {
              'explode': explode,
              'allowEmpty': allowEmpty,
              'alreadyEncoded': literalBool(true),
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
        .property('toSimple')
        .call(
          [],
          {
            'explode': explode,
            'allowEmpty': allowEmpty,
            'alreadyEncoded': literalBool(true),
          },
        ),
    MapModel() => _buildListMapContentSimpleExpression(
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
      'Binary data cannot be simple-encoded',
    ),
    _ => generateEncodingExceptionExpression(
      'Unsupported list content type for simple encoding.',
    ),
  };
}

Expression _buildMapSimpleExpression(
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
      'Map with complex value types cannot be simple-encoded.',
    );
  }

  // For StringModel values, converted == valueExpression (identity).
  // For other types, converted is the .map() call result.
  final toSimpleAccess = (isNullable && converted == valueExpression)
      ? converted.nullSafeProperty('toSimple')
      : converted.property('toSimple');

  return toSimpleAccess.call(
    [],
    {
      'explode': explode,
      'allowEmpty': allowEmpty,
    },
  );
}

Expression _buildListMapContentSimpleExpression(
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
      'List of maps with complex value types cannot be simple-encoded.',
    );
  }

  final listMapAccess = isNullable
      ? valueExpression.nullSafeProperty('map')
      : valueExpression.property('map');

  // Each element is converted to Map<String, String>, then simple-encoded.
  return listMapAccess
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(
              Parameter((b) => b..name = 'e'),
            )
            ..body = converted
                .property('toSimple')
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
      .property('toSimple')
      .call(
        [],
        {
          'explode': explode,
          'allowEmpty': allowEmpty,
          'alreadyEncoded': literalBool(true),
        },
      );
}
