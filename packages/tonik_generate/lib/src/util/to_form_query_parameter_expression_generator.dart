import 'package:tonik_core/tonik_core.dart';

/// Creates a Dart expression string that correctly serializes a query parameter
/// to its form-encoded representation.
String buildToFormQueryParameterExpression(
  String parameterName,
  QueryParameterObject parameter, {
  bool explode = false,
  bool allowEmpty = true,
}) {
  final model = parameter.model;
  final suffix = _getFormSerializationSuffix(
    model,
    explode: explode,
    allowEmpty: allowEmpty,
  );
  return suffix == null ? parameterName : '$parameterName$suffix';
}

String? _getFormSerializationSuffix(
  Model model, {
  required bool explode,
  required bool allowEmpty,
}) {
  final paramString = 'explode: $explode, allowEmpty: $allowEmpty';

  return switch (model) {
    // Primitive types that have toForm extensions:
    StringModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() => '.toForm($paramString)',

    // Numeric primitives that need toString() for lists:
    IntegerModel() || DoubleModel() || NumberModel() => '.toForm($paramString)',

    // Complex types that should have toForm methods:
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => '.toForm($paramString)',

    // Lists need special handling:
    ListModel() => _handleListExpression(
      model.content,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    // Alias models delegate to their underlying type:
    AliasModel() => _getFormSerializationSuffix(
      model.model,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    _ => throw UnimplementedError(
      'Unsupported model type for form encoding: $model',
    ),
  };
}

String? _handleListExpression(
  Model contentModel, {
  required bool explode,
  required bool allowEmpty,
}) {
  final paramString = 'explode: $explode, allowEmpty: $allowEmpty';

  // Handle different content models:
  return switch (contentModel) {
    ListModel() => () {
      // Nested list - recursively handle inner list:
      final innerSuffix = _handleListExpression(
        contentModel.content,
        explode: explode,
        allowEmpty: allowEmpty,
      );
      final elementMapBody = '(e) => e$innerSuffix';
      return '.map($elementMapBody).toList().toForm($paramString)';
    }(),

    // For List<String>, use the extension directly:
    StringModel() => '.toForm($paramString)',

    // For numeric primitives (int, double, num), convert to strings first:
    IntegerModel() || DoubleModel() || NumberModel() =>
      '.map((e) => e.toString()).toList().toForm($paramString)',

    // For boolean, convert to string:
    BooleanModel() => '.map((e) => e.toString()).toList().toForm($paramString)',

    // For complex types (DateTime, BigDecimal, Uri, Date, Enum, Class, etc.),
    // use toForm method:
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() ||
    DateModel() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => () {
      final suffix = _getFormSerializationSuffix(
        contentModel,
        explode: explode,
        allowEmpty: allowEmpty,
      );
      final elementMapBody = '(e) => e$suffix';
      return '.map($elementMapBody).toList().toForm($paramString)';
    }(),

    // For alias models, delegate to the underlying type:
    AliasModel() => _handleListExpression(
      contentModel.model,
      explode: explode,
      allowEmpty: allowEmpty,
    ),

    _ => throw UnimplementedError(
      'Unsupported list content type for form encoding: $contentModel',
    ),
  };
}
