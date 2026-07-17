/// Formats a single string as a doc comment.
///
/// If the string is multiline, each line will be prefixed with '/// '.
/// Returns an empty list if the input is null or empty.
List<String> formatDocComment(String? text) {
  // Dart treats a lone CR as a line terminator, so any CR surviving into a
  // doc-comment line lets the rest of the text escape the `///` prefix.
  final normalized = text?.replaceAll('\r', '');
  if (normalized == null || normalized.isEmpty) {
    return [];
  }

  return normalized.split('\n').map((line) => '/// $line').toList();
}

/// Formats a string as a doc comment with a prefix on the first line.
///
/// The [prefix] is prepended to the first line only. If the text is
/// multiline, continuation lines get the `/// ` prefix without [prefix].
/// Returns an empty list if [text] is null or empty.
List<String> formatDocCommentWithPrefix(String prefix, String? text) {
  final normalized = text?.replaceAll('\r', '');
  if (normalized == null || normalized.isEmpty) return [];
  final lines = normalized.split('\n');
  return [
    '/// $prefix${lines.first}',
    for (var i = 1; i < lines.length; i++) '/// ${lines[i]}',
  ];
}

/// Formats a list of strings as doc comments.
///
/// Each string in the list is processed with [formatDocComment],
/// and the results are flattened into a single list.
/// Null and empty strings are filtered out.
/// Returns an empty list if the input is null or empty.
List<String> formatDocComments(List<String?>? texts) {
  if (texts == null || texts.isEmpty) {
    return [];
  }

  final result = <String>[];

  for (final text in texts) {
    if (text != null && text.isNotEmpty) {
      result.addAll(formatDocComment(text));
    }
  }

  return result;
}
