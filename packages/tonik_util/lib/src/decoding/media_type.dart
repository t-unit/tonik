/// Extracts the bare `type/subtype` portion of an HTTP `Content-Type` header.
///
/// Returns the lowercased `type/subtype`, trimmed of surrounding whitespace,
/// with any media-type parameters (e.g. `; charset=utf-8`) stripped. Returns
/// `null` only when [header] is `null`, empty, or whitespace-only — a missing
/// content type. Headers that contain a value but lack a recognisable
/// `type/subtype` (e.g. `;charset=utf-8`, `garbage`) are returned verbatim
/// (after trimming and parameter stripping where the value is non-empty) so
/// callers can surface the original header in error messages instead of
/// conflating malformed input with "no content type sent".
///
/// Servers commonly append `charset=utf-8`; ignoring parameters is required to
/// match standard responses against generated case patterns.
String? extractMediaType(String? header) {
  if (header == null) return null;

  final trimmed = header.trim();
  if (trimmed.isEmpty) return null;

  // Quoted-string parameter values containing `;` (e.g. `foo="a;b"`) are not
  // honoured; we split on the first literal `;` regardless of quoting.
  final semicolonIndex = trimmed.indexOf(';');
  final base = semicolonIndex == -1
      ? trimmed
      : trimmed.substring(0, semicolonIndex);
  final stripped = base.trim();

  if (stripped.isEmpty) return trimmed;
  if (!stripped.contains('/')) return stripped;

  return stripped.toLowerCase();
}
