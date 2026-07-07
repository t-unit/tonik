/// With [allowReserved] false the result is byte-identical to
/// [Uri.encodeQueryComponent] / [Uri.encodeComponent] — call sites rely on
/// this. With [allowReserved] true reserved chars including `[ ]` pass through
/// literally; the form delimiters `& =`, along with `+`, `%`, and non-ASCII,
/// stay encoded, and a space becomes `%20` (or `+` under [useQueryComponent]).
String encodeUriValue(
  String value, {
  required bool allowReserved,
  required bool useQueryComponent,
}) {
  if (!allowReserved) {
    return useQueryComponent
        ? Uri.encodeQueryComponent(value)
        : Uri.encodeComponent(value);
  }

  // Uri.encodeFull keeps reserved chars literal, but & and = are data here,
  // not delimiters, so they must stay encoded. A literal + must become %2B
  // before a space is rendered as +, otherwise a data + and a space would be
  // indistinguishable. encodeFull predates RFC 3986 treating [ ] as reserved
  // and still percent-encodes them, so restore those to literal.
  var encoded = Uri.encodeFull(value)
      .replaceAll('+', '%2B')
      .replaceAll('&', '%26')
      .replaceAll('=', '%3D')
      .replaceAll('%5B', '[')
      .replaceAll('%5D', ']');
  if (useQueryComponent) {
    encoded = encoded.replaceAll('%20', '+');
  }
  return encoded;
}
