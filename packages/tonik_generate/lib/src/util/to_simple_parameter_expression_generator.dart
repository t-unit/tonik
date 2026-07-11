import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';

/// [literal], when supplied, is forwarded as the `literal:` named argument to
/// every leaf `toSimple` (and to `encodeAnyToSimple` for the
/// AnyModel/composite-list branch) so composite header field-values are
/// transmitted without URI encoding. It is omitted for path/query callers.
BuiltExpression buildSimpleParameterExpression(
  Expression valueExpression,
  Model model, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
  Expression? literal,
}) {
  return BuiltExpression.simple(
    _buildSimpleParameterExpression(
      valueExpression,
      model,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
      literal: literal,
    ),
  );
}

Map<String, Expression> _simpleArgs(
  Expression explode,
  Expression allowEmpty,
  Expression? literal, {
  bool alreadyEncoded = false,
}) => {
  'explode': explode,
  'allowEmpty': allowEmpty,
  if (alreadyEncoded) 'alreadyEncoded': literalBool(true),
  'literal': ?literal,
};

Expression _buildSimpleParameterExpression(
  Expression valueExpression,
  Model model, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
  Expression? literal,
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
      _simpleArgs(explode, allowEmpty, literal),
    ),
    final ListModel m => _buildListSimpleExpression(
      valueExpression,
      m.content,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
      isContentNullable: m.isContentNullable || m.content.isEffectivelyNullable,
      literal: literal,
    ),
    AliasModel() => _buildSimpleParameterExpression(
      valueExpression,
      model.model,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
      literal: literal,
    ),
    AnyModel() =>
      refer('encodeAnyToSimple', 'package:tonik_util/tonik_util.dart').call(
        [valueExpression],
        _simpleArgs(explode, allowEmpty, literal),
      ),
    Base64Model() =>
      (isNullable
              ? valueExpression.nullSafeProperty('toBase64String')
              : valueExpression.property('toBase64String'))
          .call([])
          .property('toSimple')
          .call(
            [],
            _simpleArgs(explode, allowEmpty, literal),
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
      literal: literal,
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
  bool isContentNullable = false,
  Expression? literal,
}) {
  final listPropertyAccess = isNullable
      ? valueExpression.nullSafeProperty('toSimple')
      : valueExpression.property('toSimple');

  final listMapAccess = isNullable
      ? valueExpression.nullSafeProperty('map')
      : valueExpression.property('map');

  // A null array element encodes to the empty string, coercing the element
  // type back to non-null `String` for the whole-list `toSimple` extension.
  Expression nullGuard(Expression encoded) => isContentNullable
      ? refer('e').equalTo(literalNull).conditional(literalString(''), encoded)
      : encoded;

  return switch (contentModel) {
    StringModel() when !isContentNullable => listPropertyAccess.call(
      [],
      _simpleArgs(explode, allowEmpty, literal),
    ),
    StringModel() =>
      listMapAccess
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body = refer('e').ifNullThen(literalString('')).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toSimple')
          .call(
            [],
            _simpleArgs(explode, allowEmpty, literal),
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
                ..body = nullGuard(
                  _buildSimpleParameterExpression(
                    refer('e'),
                    contentModel,
                    explode: explode,
                    allowEmpty: allowEmpty,
                    literal: literal,
                  ),
                ).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toSimple')
          .call(
            [],
            _simpleArgs(explode, allowEmpty, literal, alreadyEncoded: true),
          ),
    AliasModel() => _buildListSimpleExpression(
      valueExpression,
      contentModel.model,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
      isContentNullable: isContentNullable,
      literal: literal,
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
                  'encodeAnyToSimple',
                  'package:tonik_util/tonik_util.dart',
                ).call([refer('e')], _simpleArgs(
                  explode,
                  allowEmpty,
                  literal,
                )).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toSimple')
          .call(
            [],
            _simpleArgs(explode, allowEmpty, literal, alreadyEncoded: true),
          ),
    Base64Model() =>
      listMapAccess
          .call([
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'e'),
                )
                ..body = refer('e').property('toBase64String').call([]).code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .property('toSimple')
          .call(
            [],
            _simpleArgs(explode, allowEmpty, literal, alreadyEncoded: true),
          ),
    MapModel() => _buildListMapContentSimpleExpression(
      valueExpression,
      contentModel,
      explode: explode,
      allowEmpty: allowEmpty,
      isNullable: isNullable,
      literal: literal,
    ),
    ClassModel() || ListModel() => listPropertyAccess.call(
      [],
      _simpleArgs(explode, allowEmpty, literal),
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
  Expression? literal,
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
    _simpleArgs(explode, allowEmpty, literal),
  );
}

Expression _buildListMapContentSimpleExpression(
  Expression valueExpression,
  MapModel contentModel, {
  required Expression explode,
  required Expression allowEmpty,
  bool isNullable = false,
  Expression? literal,
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
            ..body = converted.property('toSimple').call(
              [],
              _simpleArgs(explode, allowEmpty, literal),
            ).code,
        ).closure,
      ])
      .property('toList')
      .call([])
      .property('toSimple')
      .call(
        [],
        _simpleArgs(explode, allowEmpty, literal, alreadyEncoded: true),
      );
}
