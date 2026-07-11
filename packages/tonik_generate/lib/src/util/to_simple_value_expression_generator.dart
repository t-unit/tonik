import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/map_value_to_string_expression_builder.dart';

/// Returns a non-null reason if simple-encoding [model] would produce a
/// throw expression rather than a real value. Path-generator pre-flight
/// guards must use this — a parallel switch would drift and re-introduce
/// the bug where a throw is concatenated with a literal path suffix.
String? simpleEncodingThrowReason(Model model) {
  return switch (model) {
    NeverModel() => 'never-typed values',
    BinaryModel() => 'binary values',
    ListModel(:final content) => _listContentThrowReason(content),
    MapModel(:final valueModel)
        when !isMapValueTypeSimplyEncodable(valueModel) =>
      'map with complex value types',
    MapModel() => null,
    AliasModel(:final model) => simpleEncodingThrowReason(model),
    ClassModel() ||
    EnumModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() ||
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() ||
    Base64Model() ||
    AnyModel() => null,
    // Catch-all throws so a newly-added Model subtype surfaces at runtime
    // instead of silently returning null (drift protection). NamedModel and
    // CompositeModel are mixins on the sealed Model, so the analyzer does
    // not let us enumerate "every concrete subtype" exhaustively here.
    _ => _unreachableModelType('simpleEncodingThrowReason'),
  };
}

Never _unreachableModelType(String fn) =>
    throw UnsupportedError('Unreachable Model subtype in $fn');

String? _listContentThrowReason(Model content) {
  const unsupported = 'lists with unsupported element types';
  return switch (content) {
    // _handleListExpression's AnyModel branch would emit
    // `list.toSimple(...)` which has no extension on `List<Object?>` — the
    // predicate intercepts before codegen so the bad code never lands.
    NeverModel() || BinaryModel() || ListModel() || AnyModel() => unsupported,
    MapModel(:final valueModel)
        when !isMapValueTypeSimplyEncodable(valueModel) =>
      unsupported,
    MapModel() => null,
    AliasModel(:final model) => _listContentThrowReason(model),
    ClassModel() ||
    EnumModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() ||
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() ||
    Base64Model() => null,
    // Catch-all throws (same drift-protection rationale as
    // simpleEncodingThrowReason).
    _ => _unreachableModelType('_listContentThrowReason'),
  };
}

/// Path parameters are always required: if the underlying model is
/// nullable (e.g. `typedef X = String?`), assert non-null via `!` rather
/// than `?.`, which would produce `String?` output.
BuiltExpression buildToSimplePathParameterExpression(
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
  return BuiltExpression.simple(
    _buildSimpleSerializationExpression(
      receiver,
      model,
      isNullable: false,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
  );
}

/// [isNullChecked] suppresses null-aware access for callers already
/// inside an `if (param != null)` block.
///
/// Every supported header model is encoded literally, since HTTP header
/// field-values are transmitted as-is.
BuiltExpression buildToSimpleHeaderParameterExpression(
  String parameterName,
  RequestHeaderObject parameter, {
  bool explode = false,
  bool allowEmpty = true,
  bool isNullChecked = false,
}) {
  final model = parameter.model;
  return BuiltExpression.simple(
    _buildSimpleSerializationExpression(
      refer(parameterName),
      model,
      isNullable: !isNullChecked && model.isEffectivelyNullable,
      explode: explode,
      allowEmpty: allowEmpty,
      literal: true,
    ),
  );
}

BuiltExpression buildSimpleValueExpression(
  Expression accessor,
  Model model, {
  required bool explode,
  required bool allowEmpty,
  bool isNullable = false,
}) {
  return BuiltExpression.simple(
    _buildSimpleSerializationExpression(
      accessor,
      model,
      isNullable: isNullable,
      explode: explode,
      allowEmpty: allowEmpty,
    ),
  );
}

Expression _buildSimpleSerializationExpression(
  Expression receiver,
  Model model, {
  required bool isNullable,
  required bool explode,
  required bool allowEmpty,
  bool literal = false,
}) {
  final useNullAware = isNullable;

  Expression callToSimple(Expression target, {required bool asLiteral}) {
    const methodName = 'toSimple';
    final args = <String, Expression>{
      'explode': literalBool(explode),
      'allowEmpty': literalBool(allowEmpty),
      if (asLiteral) 'literal': literalBool(true),
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
    UriModel() ||
    DateModel() => callToSimple(receiver, asLiteral: literal),

    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => callToSimple(receiver, asLiteral: literal),

    // MapModel: convert values to strings, then call toSimple
    MapModel() => _buildMapSimpleExpression(
      receiver,
      model,
      isNullable: isNullable,
      explode: explode,
      allowEmpty: allowEmpty,
      literal: literal,
    ),

    // Base64Model: convert to base64 string, then call toSimple
    Base64Model() => () {
      final base64Expr = useNullAware
          ? receiver.nullSafeProperty('toBase64String').call([])
          : receiver.property('toBase64String').call([]);
      final args = <String, Expression>{
        'explode': literalBool(explode),
        'allowEmpty': literalBool(allowEmpty),
        if (literal) 'literal': literalBool(true),
      };
      return base64Expr.property('toSimple').call([], args);
    }(),

    // Lists need special handling
    final ListModel m => _handleListExpression(
      receiver,
      m.content,
      isNullable: isNullable,
      explode: explode,
      allowEmpty: allowEmpty,
      isContentNullable: m.isContentNullable || m.content.isEffectivelyNullable,
      literal: literal,
    ),

    AliasModel() => _buildSimpleSerializationExpression(
      receiver,
      model.model,
      isNullable: isNullable,
      explode: explode,
      allowEmpty: allowEmpty,
      literal: literal,
    ),

    AnyModel() =>
      refer('encodeAnyToSimple', 'package:tonik_util/tonik_util.dart').call(
        [receiver],
        {
          'explode': literalBool(explode),
          'allowEmpty': literalBool(allowEmpty),
          if (literal) 'literal': literalBool(true),
        },
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
  required bool isContentNullable,
  bool literal = false,
}) {
  final toSimpleArgs = <String, Expression>{
    'explode': literalBool(explode),
    'allowEmpty': literalBool(allowEmpty),
    if (literal) 'literal': literalBool(true),
  };

  Expression callToSimpleOnList(Expression listExpr) {
    if (isNullable) {
      return listExpr.nullSafeProperty('toSimple').call([], toSimpleArgs);
    } else {
      return listExpr.property('toSimple').call([], toSimpleArgs);
    }
  }

  Expression mapAccess() =>
      isNullable ? receiver.nullSafeProperty('map') : receiver.property('map');

  // A null array element encodes to the empty string, coercing the element type
  // back to non-null `String` so the whole-list extension call matches.
  Expression nullGuard(Expression encoded) => isContentNullable
      ? refer('e').equalTo(literalNull).conditional(literalString(''), encoded)
      : encoded;

  Expression mappedList(Expression body) => mapAccess()
      .call([
        Method(
          (b) => b
            ..requiredParameters.add(Parameter((p) => p..name = 'e'))
            ..body = body.code,
        ).closure,
      ])
      .property('toList')
      .call([]);

  Expression mappedSerialize({required bool asLiteral}) => mappedList(
    nullGuard(
      _buildSimpleSerializationExpression(
        refer('e'),
        contentModel,
        isNullable: false,
        explode: explode,
        allowEmpty: allowEmpty,
        literal: asLiteral,
      ),
    ),
  ).property('toSimple').call([], {
    'explode': literalBool(explode),
    'allowEmpty': literalBool(allowEmpty),
    if (asLiteral) 'literal': literalBool(true),
  });

  return switch (contentModel) {
    NeverModel() => generateEncodingExceptionExpression(
      'Cannot encode List<NeverModel> - this type does not permit any value.',
    ),

    ListModel() => generateEncodingExceptionExpression(
      'Nested lists are not supported for simple encoding.',
    ),

    StringModel() when !isContentNullable => callToSimpleOnList(receiver),

    StringModel() => mappedList(
      refer('e').ifNullThen(literalString('')),
    ).property('toSimple').call([], toSimpleArgs),

    IntegerModel() || DoubleModel() || NumberModel() || BooleanModel() =>
      mappedList(
        nullGuard(
          refer('e').property('uriEncode').call([], {
            'allowEmpty': literalBool(allowEmpty),
            if (literal) 'literal': literalBool(true),
          }),
        ),
      ).property('toSimple').call([], {
        ...toSimpleArgs,
        'alreadyEncoded': literalBool(true),
      }),

    DateTimeModel() || DecimalModel() || UriModel() || DateModel() =>
      mappedSerialize(asLiteral: literal),

    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => mappedSerialize(asLiteral: literal),

    AliasModel() => _handleListExpression(
      receiver,
      contentModel.model,
      isNullable: isNullable,
      explode: explode,
      allowEmpty: allowEmpty,
      isContentNullable: isContentNullable,
      literal: literal,
    ),

    AnyModel() => callToSimpleOnList(receiver),
    Base64Model() => mappedList(
      refer('e').property('toBase64String').call([]),
    ).property('toSimple').call([], {
      ...toSimpleArgs,
      'alreadyEncoded': literalBool(true),
    }),

    MapModel() => _buildListMapContentSimpleExpression(
      receiver,
      contentModel,
      isNullable: isNullable,
      explode: explode,
      allowEmpty: allowEmpty,
      literal: literal,
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
  bool literal = false,
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
      if (literal) 'literal': literalBool(true),
    },
  );
}

Expression _buildListMapContentSimpleExpression(
  Expression receiver,
  MapModel contentModel, {
  required bool isNullable,
  required bool explode,
  required bool allowEmpty,
  bool literal = false,
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
            ..body = converted.property('toSimple').call(
              [],
              {
                'explode': literalBool(explode),
                'allowEmpty': literalBool(allowEmpty),
                if (literal) 'literal': literalBool(true),
              },
            ).code,
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
          if (literal) 'literal': literalBool(true),
        },
      );
}
