import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

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

    // MapModel: convert to Map<String, String> via toParameterMap(), then
    // call toSimple() on the resulting map.
    MapModel() => callToSimple(
      useNullAware
          ? receiver.nullSafeProperty('toParameterMap').call([])
          : receiver.property('toParameterMap').call([]),
    ),

    // Base64Model: convert to base64 string via toBase64String(), then
    // call toSimple() on the resulting string.
    Base64Model() => callToSimple(
      useNullAware
          ? receiver.nullSafeProperty('toBase64String').call([])
          : receiver.property('toBase64String').call([]),
    ),

    // BinaryModel (format: binary) cannot be simple-encoded — it represents
    // raw binary uploads, not a string-encodable value.
    BinaryModel() => generateEncodingExceptionExpression(
      'Binary data cannot be simple-encoded.',
    ),

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

    // AnyModel (Object?) - convert to String representation
    AnyModel() =>
      receiver
          .nullSafeProperty('toString')
          .call([])
          .ifNullThen(literalString('')),

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

    // For List<Map<String, V>>, map each item through toParameterMap()
    // then toSimple(), collecting into a List<String>.
    MapModel() => () {
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

    // For List<TonikFile> (base64), map each item through toBase64String()
    // then toSimple(), collecting into a List<String>.
    Base64Model() => () {
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

    // BinaryModel (format: binary) cannot be simple-encoded in lists.
    BinaryModel() => generateEncodingExceptionExpression(
      'Binary data cannot be simple-encoded.',
    ),

    AnyModel() => callToSimpleOnList(receiver), // Pass through list as-is

    _ => generateEncodingExceptionExpression(
      'Unsupported content model for simple encoding.',
    ),
  };
}
