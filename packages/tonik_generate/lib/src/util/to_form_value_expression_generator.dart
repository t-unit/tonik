import 'package:tonik_core/tonik_core.dart';

/// Creates a Dart expression string that correctly serializes a property
/// to its form-encoded representation.
///
/// The [useQueryComponent] parameter controls whether to use query component
/// encoding with spaces as + (for form-urlencoded bodies).
String buildToFormPropertyExpression(
  String fieldName,
  Property property, {
  bool useQueryComponent = false,
}) {
  final model = property.model;
  final isNullable = property.isNullable || !property.isRequired;

  final resolvedModel = _resolveModel(model);
  if (!_supportsFormEncoding(resolvedModel)) {
    throw UnsupportedError('Form encoding not supported for complex types');
  }

  final useQueryComponentArg = useQueryComponent
      ? ', useQueryComponent: true'
      : '';
  final baseExpression =
      '$fieldName${isNullable ? '?' : ''}'
      '.toForm(explode: explode, allowEmpty: allowEmpty$useQueryComponentArg)';

  if (property.isRequired && property.isNullable) {
    return "$baseExpression ?? ''";
  }

  return baseExpression;
}

/// Creates a Dart expression string that correctly serializes any model
/// to its form-encoded representation, including complex types.
///
/// The [useQueryComponent] parameter controls whether to use query component
/// encoding with spaces as + (for form-urlencoded bodies).
String buildToFormValueExpression(
  String valueExpression,
  Model model, {
  required bool useQueryComponent,
}) {
  final useQueryComponentArg = useQueryComponent
      ? ', useQueryComponent: true'
      : '';

  return switch (model) {
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() ||
    ListModel() => '$valueExpression.toForm(explode: true, allowEmpty: true'
        '$useQueryComponentArg)',
    AliasModel() => buildToFormValueExpression(
      valueExpression,
      model.model,
      useQueryComponent: useQueryComponent,
    ),
    BinaryModel() => throw UnsupportedError(
      'Form encoding not supported for binary types',
    ),
    _ => throw UnimplementedError(
      'Unsupported model type for form encoding: $model',
    ),
  };
}

Model _resolveModel(Model model) {
  return switch (model) {
    AliasModel() => _resolveModel(model.model),
    _ => model,
  };
}

bool _supportsFormEncoding(Model model) {
  return switch (model) {
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DateModel() ||
    DecimalModel() ||
    UriModel() => true,
    _ => false,
  };
}
