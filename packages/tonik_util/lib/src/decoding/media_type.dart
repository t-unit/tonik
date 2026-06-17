/// Extracts the bare `type/subtype` portion of an HTTP `Content-Type` header.
///
/// Servers commonly append `charset=utf-8`; ignoring parameters is required to
/// match standard responses against generated case patterns.
///
/// Returns:
/// - `null` when [header] is `null`, empty, or whitespace-only.
/// - The lowercased `type/subtype` for well-formed headers (parameters
///   stripped, surrounding whitespace trimmed).
/// - The trimmed header for malformed values that lack a `type/subtype`
///   (e.g. `;charset=utf-8`, `garbage`), so error messages can surface the
///   original input.
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
