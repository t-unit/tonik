import 'package:tonik_core/tonik_core.dart';

/// Generates a String expression for encoding a path parameter using
/// label style.
///
/// Label encoding is used for path parameters in OpenAPI and follows the
/// simple encoding style with dot-prefixed values.
///
/// The generated expression calls the appropriate `toLabel` method on the
/// parameter value with the correct explode and allowEmpty settings.
///
/// For lists of non-string primitives, enums, or composite types (OneOf,
/// AnyOf), the items are first mapped to their URI-encoded string
/// representation before calling `toLabel` on the resulting `List<String>`.
String buildToLabelPathParameterExpression(
  String parameterName,
  PathParameterObject parameter,
) {
  final nullablePart = parameter.isRequired ? '' : '?';
  final explode = parameter.explode;
  final allowEmpty = parameter.allowEmptyValue;

  final model = parameter.model;

  // Quick fix: AnyModel (Object?) needs special handling
  // Proper support will come with encoding refactor
  if (model is AnyModel) {
    return '''($parameterName$nullablePart?.toString() ?? '').toLabel(explode: $explode, allowEmpty: $allowEmpty)''';
  }

  if (model is ListModel) {
    final content = model.content;
    final contentModel = content is AliasModel ? content.resolved : content;

    if (contentModel is StringModel) {
      return '$parameterName$nullablePart.toLabel('
          'explode: $explode, '
          'allowEmpty: $allowEmpty)';
    }

    return '''$parameterName$nullablePart.map((e) => e.uriEncode(allowEmpty: $allowEmpty)).toList().toLabel(explode: $explode, allowEmpty: $allowEmpty, alreadyEncoded: true)''';
  }

  return '$parameterName$nullablePart.toLabel('
      'explode: $explode, '
      'allowEmpty: $allowEmpty)';
}
