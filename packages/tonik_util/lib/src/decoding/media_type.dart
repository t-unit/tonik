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

/// Returns whether [actual] belongs to the declared media type or range.
///
/// Supports exact matches, `type/*`, and `*/*` after applying the same
/// parameter stripping and lowercasing as [extractMediaType].
bool matchesMediaTypeRange(String? actual, String declared) {
  final actualMediaType = extractMediaType(actual);
  final declaredMediaType = extractMediaType(declared);

  if (!_isConcreteMediaType(actualMediaType)) return false;
  if (declaredMediaType == null || !_hasTypeSubtype(declaredMediaType)) {
    return false;
  }

  if (!_isMediaTypeRange(declaredMediaType)) {
    return actualMediaType == declaredMediaType;
  }

  if (declaredMediaType == '*/*') return true;

  final slashIndex = declaredMediaType.indexOf('/');
  final declaredType = declaredMediaType.substring(0, slashIndex);
  return actualMediaType!.startsWith('$declaredType/');
}

bool _hasTypeSubtype(String mediaType) {
  final slashIndex = mediaType.indexOf('/');
  return slashIndex > 0 && slashIndex < mediaType.length - 1;
}

bool _isConcreteMediaType(String? mediaType) {
  if (mediaType == null || !_hasTypeSubtype(mediaType)) return false;
  return !mediaType.contains('*');
}

bool _isMediaTypeRange(String mediaType) {
  if (mediaType == '*/*') return true;

  final slashIndex = mediaType.indexOf('/');
  if (slashIndex <= 0 || slashIndex == mediaType.length - 1) return false;

  final type = mediaType.substring(0, slashIndex);
  final subtype = mediaType.substring(slashIndex + 1);
  return subtype == '*' && type != '*' && !type.contains('*');
}
