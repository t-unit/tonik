import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/encoding_policy.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';

/// Creates a Dart expression that correctly serializes a path parameter
/// to its simple parameter encoding representation.
///
/// Path parameters are always required, so even if the underlying model type
/// is nullable (e.g., `typedef X = String?`), we assert non-null via `!`
/// rather than using `?.` which would produce `String?` output.
Expression buildToSimplePathParameterExpression(
  String parameterName,
  PathParameterObject parameter, {
  bool explode = false,
  bool allowEmpty = true,
}) {
  final model = parameter.model;
  final isNullable = model.isEffectivelyNullable;
  final receiver = isNullable
      ? refer(parameterName).nullChecked
      : refer(parameterName);
  return _buildSimpleSerializationExpression(
    receiver,
    model,
    isNullable: false,
    explode: explode,
    allowEmpty: allowEmpty,
  );
}

/// Creates a Dart expression that correctly serializes a
/// header parameter to its simple parameter encoding representation.
///
/// When [isNullChecked] is true, the expression is already inside a
/// null-check block (`if (param != null)`), so null-aware access is
/// unnecessary even for nullable models.
Expression buildToSimpleHeaderParameterExpression(
  String parameterName,
  RequestHeaderObject parameter, {
  bool explode = false,
  bool allowEmpty = true,
  bool isNullChecked = false,
}) {
  final model = parameter.model;
  return _buildSimpleSerializationExpression(
    refer(parameterName),
    model,
    isNullable: !isNullChecked && model.isEffectivelyNullable,
    explode: explode,
    allowEmpty: allowEmpty,
  );
}

/// Creates a Dart expression that serializes a value using simple style
/// encoding, accepting a [Model] directly.
///
/// This is the model-based variant that works independently of the parameter
/// type (request header, response header, per-part header, etc.).
Expression buildSimpleValueExpression(
  Expression accessor,
  Model model, {
  required bool explode,
  required bool allowEmpty,
  bool isNullable = false,
}) {
  return _buildSimpleSerializationExpression(
    accessor,
    model,
    isNullable: isNullable,
    explode: explode,
    allowEmpty: allowEmpty,
  );
}

Expression _buildSimpleSerializationExpression(
  Expression receiver,
  Model model, {
  required bool isNullable,
  required bool explode,
  required bool allowEmpty,
}) {
  final useNullAware = isNullable;

  Expression callToSimple(Expression target) {
    const methodName = 'toSimple';
    final args = <String, Expression>{
      'explode': literalBool(explode),
      'allowEmpty': literalBool(allowEmpty),
    };
    if (useNullAware) {
      return target.nullSafeProperty(methodName).call([], args);
    } else {
      return target.property(methodName).call([], args);
    }
  }

  return switch (model) {
    NeverModel() => generateEncodingExceptionExpression(
      'Cannot encode NeverModel - this type does not permit any value.',
    ),
    // Primitive types that have toSimple extensions
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() => callToSimple(receiver),

    // Complex types that should have toSimple methods
    DateModel() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => callToSimple(receiver),

    // MapModel: convert values to strings, then call toSimple
    MapModel() => _buildMapSimpleExpression(
      receiver,
      model,
      isNullable: isNullable,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    // Base64Model: convert to base64 string, then call toSimple
    Base64Model() => () {
      final base64Expr = useNullAware
          ? receiver.nullSafeProperty('toBase64String').call([])
          : receiver.property('toBase64String').call([]);
      final args = <String, Expression>{
        'explode': literalBool(explode),
        'allowEmpty': literalBool(allowEmpty),
      };
      return base64Expr.property('toSimple').call([], args);
    }(),

    // Lists need special handling
    ListModel() => _handleListExpression(
      receiver,
      model.content,
      isNullable: isNullable,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    // Alias models delegate to their underlying type
    AliasModel() => _buildSimpleSerializationExpression(
      receiver,
      model.model,
      isNullable: isNullable,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    AnyModel() => encodeAnyToSimpleExpression(
      receiver,
      explode: literalBool(explode),
      allowEmpty: literalBool(allowEmpty),
    ),

    _ => generateEncodingExceptionExpression(
      'Unsupported model type for simple encoding.',
    ),
  };
}

Expression _handleListExpression(
  Expression receiver,
  Model contentModel, {
  required bool isNullable,
  required bool explode,
  required bool allowEmpty,
}) {
  final toSimpleArgs = <String, Expression>{
    'explode': literalBool(explode),
    'allowEmpty': literalBool(allowEmpty),
  };

  Expression callToSimpleOnList(Expression listExpr) {
    if (isNullable) {
      return listExpr.nullSafeProperty('toSimple').call([], toSimpleArgs);
    } else {
      return listExpr.property('toSimple').call([], toSimpleArgs);
    }
  }

  // Handle different content models
  return switch (contentModel) {
    NeverModel() => generateEncodingExceptionExpression(
      'Cannot encode List<NeverModel> - this type does not permit any value.',
    ),

    ListModel() => generateEncodingExceptionExpression(
      'Nested lists are not supported for simple encoding.',
    ),

    // For List<String>, use the extension directly
    StringModel() => callToSimpleOnList(receiver),

    // For primitive lists (int, double, num, bool), convert to strings first
    IntegerModel() || DoubleModel() || NumberModel() || BooleanModel() => () {
      final mapClosure = Method(
        (b) => b
          ..requiredParameters.add(Parameter((p) => p..name = 'e'))
          ..body = refer('e').property('toString').call([]).code,
      ).closure;

      final mappedList = isNullable
          ? receiver
                .nullSafeProperty('map')
                .call([mapClosure])
                .property('toList')
                .call([])
          : receiver
                .property('map')
                .call([mapClosure])
                .property('toList')
                .call([]);

      return mappedList.property('toSimple').call([], toSimpleArgs);
    }(),

    // For complex types (DateTime, BigDecimal, Uri, etc.), use toSimple method
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => () {
      final innerExpr = _buildSimpleSerializationExpression(
        refer('e'),
        contentModel,
        isNullable: false,
        explode: explode,
        allowEmpty: allowEmpty,
      );

      final mapClosure = Method(
        (b) => b
          ..requiredParameters.add(Parameter((p) => p..name = 'e'))
          ..body = innerExpr.code,
      ).closure;

      final mappedList = isNullable
          ? receiver
                .nullSafeProperty('map')
                .call([mapClosure])
                .property('toList')
                .call([])
          : receiver
                .property('map')
                .call([mapClosure])
                .property('toList')
                .call([]);

      return mappedList.property('toSimple').call([], toSimpleArgs);
    }(),

    // For alias models, delegate to the underlying type
    AliasModel() => _handleListExpression(
      receiver,
      contentModel.model,
      isNullable: isNullable,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    AnyModel() => callToSimpleOnList(receiver), // Pass through list as-is

    // Base64Model: each element → toBase64String(), then list toSimple
    Base64Model() => () {
      final mapClosure = Method(
        (b) => b
          ..requiredParameters.add(Parameter((p) => p..name = 'e'))
          ..body = refer('e').property('toBase64String').call([]).code,
      ).closure;

      final mappedList = isNullable
          ? receiver
                .nullSafeProperty('map')
                .call([mapClosure])
                .property('toList')
                .call([])
          : receiver
                .property('map')
                .call([mapClosure])
                .property('toList')
                .call([]);

      return mappedList.property('toSimple').call([], {
        ...toSimpleArgs,
        'alreadyEncoded': literalBool(true),
      });
    }(),

    // MapModel: each element → convert to string map, then simple-encode
    MapModel() => _buildListMapContentSimpleExpression(
      receiver,
      contentModel,
      isNullable: isNullable,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    _ => generateEncodingExceptionExpression(
      'Unsupported content model for simple encoding.',
    ),
  };
}

Expression _buildMapSimpleExpression(
  Expression receiver,
  MapModel model, {
  required bool isNullable,
  required bool explode,
  required bool allowEmpty,
}) {
  final converted = buildMapToStringMapExpression(
    receiver,
    model,
    isNullable: isNullable,
  );

  if (converted == null) {
    return generateEncodingExceptionExpression(
      'Map with complex value types cannot be simple-encoded.',
    );
  }

  // For StringModel values, converted == receiver (identity).
  // For other types, converted is the .map() call result.
  final toSimpleAccess = (isNullable && converted == receiver)
      ? converted.nullSafeProperty('toSimple')
      : converted.property('toSimple');

  return toSimpleAccess.call(
    [],
    {
      'explode': literalBool(explode),
      'allowEmpty': literalBool(allowEmpty),
    },
  );
}

Expression _buildListMapContentSimpleExpression(
  Expression receiver,
  MapModel contentModel, {
  required bool isNullable,
  required bool explode,
  required bool allowEmpty,
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
      ? receiver.nullSafeProperty('map')
      : receiver.property('map');

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
                    'explode': literalBool(explode),
                    'allowEmpty': literalBool(allowEmpty),
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
          'explode': literalBool(explode),
          'allowEmpty': literalBool(allowEmpty),
          'alreadyEncoded': literalBool(true),
        },
      );
}
