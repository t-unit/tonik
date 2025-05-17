/// Formats a single string as a doc comment.
/// 
/// If the string is multiline, each line will be prefixed with '/// '.
/// Returns an empty list if the input is null or empty.
List<String> formatDocComment(String? text) {
  if (text == null || text.isEmpty) {
    return [];
  }
  
  // Split by newlines and prefix each line with '/// '
  return text.split('\n').map((line) => '/// $line').toList();
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
