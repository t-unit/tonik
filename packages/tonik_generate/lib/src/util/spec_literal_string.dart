import 'package:code_builder/code_builder.dart';

/// Generates a string literal [Expression] for a value from an OpenAPI spec.
///
/// Prefers raw strings to prevent `$` from being interpreted as Dart
/// interpolation. When the value contains newline characters (`\n` or `\r`),
/// single-line raw strings are avoided because they cannot represent literal
/// newlines. Falls back to an escaped non-raw string when no raw quoting style
/// is viable.
///
/// Quoting strategy:
/// - No newlines, no single quotes → `r'value'`
/// - No newlines, has `'` but no `"` → `r"value"`
/// - No `\r`, can use triple-double-quotes (no `"""`, doesn't end with `"`) →
///   `r"""value"""`
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
/// When [value] contains newline characters (`\n` or `\r`), single-line raw
/// strings are avoided because they cannot contain literal newlines.
/// Values with `\n` (but no `\r`) use triple-quoted raw strings.
/// Values with `\r` always use the escaped fallback to avoid embedding
/// literal carriage-return bytes in generated source files.
String specLiteralStringCode(String value) {
  final hasNewline = value.contains('\n') || value.contains('\r');
  final hasCarriageReturn = value.contains('\r');

  if (!hasNewline) {
    // Single-line raw strings are safe when there are no newlines.
    if (!value.contains("'")) {
      return "r'$value'";
    }
    if (!value.contains('"')) {
      return 'r"$value"';
    }
  }

  // Use raw triple-double-quoted string when possible. Avoid this for values
  // containing \r — literal CR bytes in source files cause issues with
  // formatters, diffs, and editors.
  if (!hasCarriageReturn && !value.contains('"""') && !value.endsWith('"')) {
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
