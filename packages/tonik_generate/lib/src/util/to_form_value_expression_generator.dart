import 'package:tonik_core/tonik_core.dart';

/// Creates a Dart expression string that correctly serializes a property
/// to its form-encoded representation.
String buildToFormPropertyExpression(String fieldName, Property property) {
  final model = property.model;
  final isNullable = property.isNullable || !property.isRequired;

  final resolvedModel = _resolveModel(model);
  if (!_supportsFormEncoding(resolvedModel)) {
    throw UnsupportedError('Form encoding not supported for complex types');
  }

  final baseExpression =
      '$fieldName${isNullable ? '?' : ''}'
      '.toForm(explode: explode, allowEmpty: allowEmpty)';

  if (property.isRequired && property.isNullable) {
    return "$baseExpression ?? ''";
  }

  return baseExpression;
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
