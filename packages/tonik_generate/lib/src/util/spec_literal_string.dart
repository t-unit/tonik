import 'package:code_builder/code_builder.dart';

/// Generates a string literal [Expression] for a value from an OpenAPI spec.
///
/// Prefers raw strings to prevent `$` from being interpreted as Dart
/// interpolation. Values containing `\n` or `\r` use escaped non-raw strings
/// because Dart discards a leading whitespace-only line in multiline literals.
/// Escaping also avoids literal carriage-return bytes in generated source.
///
/// Quoting strategy:
/// - No newlines, no single quotes → `r'value'`
/// - No newlines, has `'` but no `"` → `r"value"`
/// - No newlines, no `"""`, and doesn't end with `"` → `r"""value"""`
/// - Otherwise → `'escaped value'` (non-raw, with `\`, `'`, `$`, `\n`, `\r`
///   escaped)
Expression specLiteralString(String value) {
  return CodeExpression(Code(specLiteralStringCode(value)));
}

/// Returns a string literal source code snippet for [value].
///
/// Same quoting logic as [specLiteralString] but returns a plain [String]
/// that can be embedded directly in [Code] templates. Prefers raw strings
/// but falls back to an escaped non-raw string for edge cases.
///
/// Values containing `\n` or `\r` use escaped strings to preserve every
/// character, including a leading whitespace-only line.
String specLiteralStringCode(String value) {
  final hasNewline = value.contains('\n') || value.contains('\r');

  if (!hasNewline) {
    // Single-line raw strings are safe when there are no newlines.
    if (!value.contains("'")) {
      return "r'$value'";
    }
    if (!value.contains('"')) {
      return 'r"$value"';
    }
    if (!value.contains('"""') && !value.endsWith('"')) {
      return 'r"""$value"""';
    }
  }

  final escaped = _escapeForSingleQuotedDartString(value);
  return "'$escaped'";
}

String _escapeForSingleQuotedDartString(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r');
}
