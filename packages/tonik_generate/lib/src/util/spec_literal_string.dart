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
  if (!value.contains("'")) {
    return literalString(value, raw: true);
  }
  if (!value.contains('"')) {
    return CodeExpression(Code('r"$value"'));
  }
  return CodeExpression(Code('r"""$value"""'));
}
