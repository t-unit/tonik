import 'package:code_builder/code_builder.dart';

/// Generates a string literal [Expression] for a value from an OpenAPI spec.
///
/// Prefers raw strings to prevent `$` from being interpreted as Dart
/// interpolation. Falls back to an escaped non-raw string when the value
/// contains both quote styles and triple-double-quotes (or ends with `"`).
///
/// Quoting strategy:
/// - No single quotes → `r'value'`
/// - Has `'` but no `"` → `r"value"`
/// - Has both `'` and `"` (not ending in `"`, no `"""`) → `r"""value"""`
/// - Otherwise → `'escaped value'` (non-raw, with `\`, `'`, `$` escaped)
Expression specLiteralString(String value) {
  return CodeExpression(Code(specLiteralStringCode(value)));
}

/// Returns a string literal source code snippet for [value].
///
/// Same quoting logic as [specLiteralString] but returns a plain [String]
/// that can be embedded directly in [Code] templates. Prefers raw strings
/// but falls back to an escaped non-raw string for edge cases.
///
/// When [value] contains newline characters (`\n` or `\r`), single-line raw
/// strings are avoided because they cannot contain literal newlines. Instead
/// a triple-quoted raw string is used when possible, or the escaped fallback
/// path handles the newlines.
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
  }

  // Use raw triple-double-quoted string when possible.
  // This handles both newline and non-newline cases where single-line raw
  // strings were not viable.
  if (!value.contains('"""') && !value.endsWith('"')) {
    return 'r"""$value"""';
  }

  // Fall back to a regular single-quoted string with escaping.
  final escaped = escapeForSingleQuotedDartString(value);
  return "'$escaped'";
}

/// Escapes a string for embedding inside a Dart single-quoted (non-raw) string.
///
/// Handles `\`, `'`, `$`, `\n`, and `\r` — the characters that are special
/// or invalid inside single-quoted Dart strings. This is useful both for the
/// fallback path in [specLiteralStringCode] and for building interpolated
/// strings like templated server URLs.
String escapeForSingleQuotedDartString(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r');
}
