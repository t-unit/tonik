import 'package:tonik_util/src/decoding/decoding_exception.dart';

final _headerWhitespace = RegExp(r'^[ \t]+|[ \t]+$');

/// Splits header tokens without interpreting quoted text or escaped pairs.
List<String> splitHeaderValue(
  String value, {
  String separator = ',',
  bool trimWhitespace = true,
}) => headerValueTokens(
  value,
  separator: separator,
  trimWhitespace: trimWhitespace,
).toList();

/// Yields complete header tokens before validating the remaining input.
Iterable<String> headerValueTokens(
  String value, {
  String separator = ',',
  bool trimWhitespace = true,
}) sync* {
  var start = 0;
  var quoted = false;
  var escaped = false;
  for (var i = 0; i < value.length; i++) {
    final character = value.codeUnitAt(i);
    if (escaped) {
      escaped = false;
    } else if (quoted && character == 0x5c) {
      escaped = true;
    } else if (character == 0x22) {
      quoted = !quoted;
    } else if (!quoted && character == separator.codeUnitAt(0)) {
      final token = value.substring(start, i);
      yield trimWhitespace ? token.replaceAll(_headerWhitespace, '') : token;
      start = i + 1;
    }
  }
  if (quoted) {
    throw const SimpleDecodingException(
      'Unterminated quoted header list item.',
    );
  }
  final token = value.substring(start);
  yield trimWhitespace ? token.replaceAll(_headerWhitespace, '') : token;
}
