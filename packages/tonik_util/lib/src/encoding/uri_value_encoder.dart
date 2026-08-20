import 'dart:convert';

/// With [allowReserved] false the result is byte-identical to
/// [Uri.encodeQueryComponent] / [Uri.encodeComponent] — call sites rely on
/// this. With [allowReserved] true reserved chars including `[ ]` pass through
/// literally; the form delimiters `& =`, along with `+`, `%`, and non-ASCII,
/// stay encoded, and a space becomes `%20` (or `+` under [useQueryComponent]).
///
/// [textEncoding] selects the bytes that are percent-encoded. This keeps
/// charset handling at the raw-value boundary instead of rewriting an already
/// encoded component.
String encodeUriValue(
  String value, {
  required bool allowReserved,
  required bool useQueryComponent,
  Encoding textEncoding = utf8,
}) {
  final bytes = textEncoding.encode(value);
  final result = StringBuffer();
  const hex = '0123456789ABCDEF';

  for (final byte in bytes) {
    if (byte > 0x7f) {
      result
        ..write('%')
        ..write(hex[byte >> 4])
        ..write(hex[byte & 0x0f]);
      continue;
    }

    final character = String.fromCharCode(byte);
    if (!allowReserved) {
      result.write(
        useQueryComponent
            ? Uri.encodeQueryComponent(character)
            : Uri.encodeComponent(character),
      );
      continue;
    }

    // Uri.encodeFull keeps reserved chars literal, but & and = are data here,
    // not delimiters. A literal + must remain distinguishable from a space.
    var encoded = Uri.encodeFull(character)
        .replaceAll('+', '%2B')
        .replaceAll('&', '%26')
        .replaceAll('=', '%3D')
        .replaceAll('%5B', '[')
        .replaceAll('%5D', ']');
    if (useQueryComponent && encoded == '%20') {
      encoded = '+';
    }
    result.write(encoded);
  }

  return result.toString();
}
