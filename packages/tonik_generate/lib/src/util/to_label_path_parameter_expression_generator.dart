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
/// Example output: `userId.toLabel(explode: false, allowEmpty: true)`
String buildToLabelPathParameterExpression(
  String parameterName,
  PathParameterObject parameter,
) {
  final nullablePart = parameter.isRequired ? '' : '?';
  return '$parameterName$nullablePart.toLabel('
      'explode: ${parameter.explode}, '
      'allowEmpty: ${parameter.allowEmptyValue})';
}
