import 'package:code_builder/code_builder.dart';

/// Generates a raw string literal for a value from an OpenAPI spec.
///
/// Always emits a raw string to prevent `$` from being interpreted as
/// Dart interpolation. Picks the quoting style based on what the value
/// contains:
/// - No single quotes → `r'value'`
/// - Has `'` but no `"` → `r"value"`
/// - Has both `'` and `"` → `r"""value"""`
Expression specLiteralString(String value) {
  return CodeExpression(Code(specLiteralStringCode(value)));
}

/// Returns a raw string literal source code snippet for [value].
///
/// Same quoting logic as [specLiteralString] but returns a plain [String]
/// that can be embedded directly in [Code] templates.
String specLiteralStringCode(String value) {
  if (!value.contains("'")) {
    return "r'$value'";
  }
  if (!value.contains('"')) {
    return 'r"$value"';
  }
  return 'r"""$value"""';
}
