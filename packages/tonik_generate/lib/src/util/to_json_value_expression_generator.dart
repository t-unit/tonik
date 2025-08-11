import 'package:tonik_core/tonik_core.dart';

/// Creates a Dart expression string that correctly serializes a property
/// to its JSON representation.
String buildToJsonPropertyExpression(
  String propertyName,
  Property property, {
  bool forceNonNullReceiver = false,
}) {
  final model = property.model;
  final isNullable = property.isNullable || !property.isRequired;
  final suffix = _getSerializationSuffix(
    model,
    isNullable,
    forceNonNullReceiver: forceNonNullReceiver,
  );
  // For primitives (suffix == null), keep bare name even if forcing non-null.
  return suffix == null ? propertyName : '$propertyName$suffix';
}

/// Creates a Dart expression string that correctly serializes a path parameter
/// to its JSON representation.
String buildToJsonPathParameterExpression(
  String parameterName,
  PathParameterObject parameter,
) {
  final model = parameter.model;
  final suffix = _getSerializationSuffix(model, false);
  return suffix == null ? parameterName : '$parameterName$suffix';
}

/// Creates a Dart expression string that correctly serializes a query parameter
/// to its JSON representation.
String buildToJsonQueryParameterExpression(
  String parameterName,
  QueryParameterObject parameter,
) {
  final model = parameter.model;
  final suffix = _getSerializationSuffix(model, false);
  return suffix == null ? parameterName : '$parameterName$suffix';
}

/// Creates a Dart expression string that correctly serializes a
/// header parameter to its JSON representation.
String buildToJsonHeaderParameterExpression(
  String parameterName,
  RequestHeaderObject parameter,
) {
  final model = parameter.model;
  final suffix = _getSerializationSuffix(model, false);
  return suffix == null ? parameterName : '$parameterName$suffix';
}

String? _getSerializationSuffix(
  Model model,
  bool isNullable, {
  bool forceNonNullReceiver = false,
}) {
  final receiverOp =
      forceNonNullReceiver
          ? '!'
          : (isNullable || (model is EnumModel && model.isNullable) ? '?' : '');

  return switch (model) {
    DateTimeModel() => '$receiverOp.toTimeZonedIso8601String()',
    DecimalModel() => '$receiverOp.toString()',
    UriModel() => '$receiverOp.toString()',
    DateModel() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => '$receiverOp.toJson()',
    ListModel() => _handleListExpression(
      model.content,
      isNullable,
      forceNonNullReceiver: forceNonNullReceiver,
    ),
    AliasModel() => _getSerializationSuffix(
      model.model,
      isNullable,
      forceNonNullReceiver: forceNonNullReceiver,
    ),
    PrimitiveModel() => null,
    _ => throw UnimplementedError('Unsupported model type: $model'),
  };
}

String? _handleListExpression(
  Model contentModel,
  bool isNullable, {
  bool forceNonNullReceiver = false,
}) {
  final suffix = _getSerializationSuffix(
    contentModel,
    false,
    forceNonNullReceiver: forceNonNullReceiver,
  );
  if (suffix == null) {
    return null;
  }

  final elementMapBody = '(e) => e$suffix';
  final op = forceNonNullReceiver ? '!' : (isNullable ? '?' : '');
  return '$op.map($elementMapBody).toList()';
}
