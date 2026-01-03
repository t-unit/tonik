import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';

/// Creates a Dart expression that correctly serializes a property
/// to its JSON representation.
Expression buildToJsonPropertyExpression(
  String propertyName,
  Property property, {
  bool forceNonNullReceiver = false,
}) {
  final model = property.model;
  final isNullable = property.isNullable || !property.isRequired;
  return _buildSerializationExpression(
    refer(propertyName),
    model,
    isNullable,
    forceNonNullReceiver: forceNonNullReceiver,
  );
}

/// Creates a Dart expression that correctly serializes a path parameter
/// to its JSON representation.
Expression buildToJsonPathParameterExpression(
  String parameterName,
  PathParameterObject parameter,
) {
  final model = parameter.model;
  return _buildSerializationExpression(
    refer(parameterName),
    model,
    false,
  );
}

/// Creates a Dart expression that correctly serializes a query parameter
/// to its JSON representation.
Expression buildToJsonQueryParameterExpression(
  String parameterName,
  QueryParameterObject parameter,
) {
  final model = parameter.model;
  return _buildSerializationExpression(
    refer(parameterName),
    model,
    false,
  );
}

Expression _buildSerializationExpression(
  Expression receiver,
  Model model,
  bool isNullable, {
  bool forceNonNullReceiver = false,
}) {
  final useNullAware =
      !forceNonNullReceiver &&
      (isNullable || (model is EnumModel && model.isNullable));

  Expression callMethod(String methodName) {
    if (forceNonNullReceiver) {
      return receiver.nullChecked.property(methodName).call([]);
    } else if (useNullAware) {
      return receiver.nullSafeProperty(methodName).call([]);
    } else {
      return receiver.property(methodName).call([]);
    }
  }

  return switch (model) {
    NeverModel() => generateEncodingExceptionExpression(
      'Cannot encode NeverModel - this type does not permit any value.',
    ),
    DateTimeModel() => callMethod('toTimeZonedIso8601String'),
    DecimalModel() || UriModel() => callMethod('toString'),
    BinaryModel() => callMethod('decodeToString'),
    DateModel() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => callMethod('toJson'),
    ListModel() => _handleListExpression(
      receiver,
      model.content,
      isNullable,
      forceNonNullReceiver: forceNonNullReceiver,
    ),
    AliasModel() => _buildSerializationExpression(
      receiver,
      model.model,
      isNullable,
      forceNonNullReceiver: forceNonNullReceiver,
    ),
    PrimitiveModel() => receiver,
    AnyModel() => refer(
      'encodeAnyToJson',
      'package:tonik_util/tonik_util.dart',
    ).call([receiver]),
    _ => throw UnimplementedError('Unsupported model type: $model'),
  };
}

Expression _handleListExpression(
  Expression receiver,
  Model contentModel,
  bool isNullable, {
  bool forceNonNullReceiver = false,
}) {
  if (!_needsTransformation(contentModel)) {
    return receiver;
  }

  final innerExpr = _buildSerializationExpression(
    refer('e'),
    contentModel,
    false,
  );

  final mapClosure = Method(
    (b) => b
      ..requiredParameters.add(Parameter((p) => p..name = 'e'))
      ..body = innerExpr.code,
  ).closure;

  if (forceNonNullReceiver) {
    return receiver.nullChecked
        .property('map')
        .call([mapClosure])
        .property('toList')
        .call([]);
  } else if (isNullable) {
    return receiver
        .nullSafeProperty('map')
        .call([mapClosure])
        .property('toList')
        .call([]);
  } else {
    return receiver
        .property('map')
        .call([mapClosure])
        .property('toList')
        .call([]);
  }
}

bool _needsTransformation(Model model) {
  return switch (model) {
    // These primitive types serialize as-is
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    AnyModel() => false,
    // All other primitives need transformation
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    BinaryModel() ||
    DateModel() => true,
    // Aliases delegate to their underlying model
    AliasModel() => _needsTransformation(model.model),
    // Lists delegate to their content model
    ListModel() => _needsTransformation(model.content),
    // Complex types always need transformation
    _ => true,
  };
}
