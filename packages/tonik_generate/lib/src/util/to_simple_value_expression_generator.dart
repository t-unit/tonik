import 'package:tonik_core/tonik_core.dart';

/// Creates a Dart expression string that correctly serializes a property
/// to its simple parameter encoding representation.
String buildToSimplePropertyExpression(
  String propertyName,
  Property property, {
  bool explode = false,
  bool allowEmpty = true,
}) {
  final model = property.model;
  final isNullable = property.isNullable || !property.isRequired;
  final suffix = _getSimpleSerializationSuffix(
    model,
    isNullable,
    explode,
    allowEmpty,
  );
  return suffix == null ? propertyName : '$propertyName$suffix';
}

/// Creates a Dart expression string that correctly serializes a path parameter
/// to its simple parameter encoding representation.
String buildToSimplePathParameterExpression(
  String parameterName,
  PathParameterObject parameter, {
  bool explode = false,
  bool allowEmpty = true,
}) {
  final model = parameter.model;
  final suffix = _getSimpleSerializationSuffix(
    model,
    false,
    explode,
    allowEmpty,
  );
  return suffix == null ? parameterName : '$parameterName$suffix';
}

/// Creates a Dart expression string that correctly serializes a query parameter
/// to its simple parameter encoding representation.
String buildToSimpleQueryParameterExpression(
  String parameterName,
  QueryParameterObject parameter, {
  bool explode = false,
  bool allowEmpty = true,
}) {
  final model = parameter.model;
  final suffix = _getSimpleSerializationSuffix(
    model,
    false,
    explode,
    allowEmpty,
  );
  return suffix == null ? parameterName : '$parameterName$suffix';
}

/// Creates a Dart expression string that correctly serializes a
/// header parameter to its simple parameter encoding representation.
String buildToSimpleHeaderParameterExpression(
  String parameterName,
  RequestHeaderObject parameter, {
  bool explode = false,
  bool allowEmpty = true,
}) {
  final model = parameter.model;
  final suffix = _getSimpleSerializationSuffix(
    model,
    false,
    explode,
    allowEmpty,
  );
  return suffix == null ? parameterName : '$parameterName$suffix';
}

String? _getSimpleSerializationSuffix(
  Model model,
  bool isNullable,
  bool explode,
  bool allowEmpty,
) {
  final nullablePart =
      isNullable || (model is EnumModel && model.isNullable) ? '?' : '';
  final paramString = 'explode: $explode, allowEmpty: $allowEmpty';

  return switch (model) {
    // Primitive types that have toSimple extensions
    StringModel() ||
    IntegerModel() ||
    DoubleModel() ||
    NumberModel() ||
    BooleanModel() ||
    DateTimeModel() ||
    DecimalModel() ||
    UriModel() => '$nullablePart.toSimple($paramString)',

    // Complex types that should have toSimple methods
    DateModel() ||
    EnumModel() ||
    ClassModel() ||
    AllOfModel() ||
    OneOfModel() ||
    AnyOfModel() => '$nullablePart.toSimple($paramString)',

    // Lists need special handling
    ListModel() => _handleListExpression(
      model.content,
      isNullable,
      explode,
      allowEmpty,
    ),

    // Alias models delegate to their underlying type
    AliasModel() => _getSimpleSerializationSuffix(
      model.model,
      isNullable,
      explode,
      allowEmpty,
    ),

    _ =>
      throw UnimplementedError(
        'Unsupported model type for simple encoding: $model',
      ),
  };
}

String? _handleListExpression(
  Model contentModel,
  bool isNullable,
  bool explode,
  bool allowEmpty,
) {
  final paramString = 'explode: $explode, allowEmpty: $allowEmpty';

  // Handle different content models
  return switch (contentModel) {
    // For List<String>, use the extension directly
    StringModel() => '${isNullable ? '?' : ''}.toSimple($paramString)',

    // For primitive lists (int, double, num, bool), convert to strings first
    IntegerModel() || DoubleModel() || NumberModel() || BooleanModel() =>
      '${isNullable ? '?' : ''}.map((e) => e.toString())'
      ' .toList().toSimple($paramString)',

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
      final suffix = _getSimpleSerializationSuffix(
        contentModel,
        false,
        explode,
        allowEmpty,
      );
      final elementMapBody = '(e) => e$suffix';
      return '${isNullable ? '?' : ''}.map($elementMapBody)'
          ' .toList().toSimple($paramString)';
    }(),

    // For alias models, delegate to the underlying type
    AliasModel() => _handleListExpression(
      contentModel.model,
      isNullable,
      explode,
      allowEmpty,
    ),

    // Default fallback
    _ =>
      '${isNullable ? '?' : ''}.map((e) => e.toString())'
      ' .toList().toSimple($paramString)',
  };
}
