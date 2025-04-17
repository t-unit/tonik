import 'package:tonik_core/tonik_core.dart';

/// Creates a Dart expression string that correctly serializes a property
/// to its JSON representation.
String buildToJsonPropertyExpression(String propertyName, Property property) {
  final model = property.model;
  final isNullable = property.isNullable || !property.isRequired;
  final suffix = _getSerializationSuffix(model, isNullable);
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

String? _getSerializationSuffix(Model model, bool isNullable) {
  final nullablePart =
      isNullable || (model is EnumModel && model.isNullable) ? '?' : '';

  return switch (model) {
    DateTimeModel() || DateModel() => '$nullablePart.toIso8601String()',
    DecimalModel() => '$nullablePart.toString()',
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => '$nullablePart.toJson()',
    ListModel() => _handleListExpression(model.content, isNullable),
    AliasModel() => _getSerializationSuffix(model.model, isNullable),
    PrimitiveModel() => null,
    _ => throw UnimplementedError('Unsupported model type: $model'),
  };
}

String? _handleListExpression(Model contentModel, bool isNullable) {
  final suffix = _getSerializationSuffix(contentModel, false);
  if (suffix == null) {
    return null;
  }

  final elementMapBody = '(e) => e$suffix';
  return '${isNullable ? '?' : ''}.map($elementMapBody).toList()';
}
