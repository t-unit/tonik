/// A local URI-fragment JSON Pointer with decoded reference tokens.
class LocalJsonPointer._(final List<String> tokens) {
  factory parse(String reference) {
    if (!reference.startsWith('#')) {
      throw UnimplementedError(
        'Only local references are supported, found $reference',
      );
    }
    final fragment = Uri.decodeComponent(reference.substring(1));
    if (fragment.isEmpty) return LocalJsonPointer._(const []);
    if (!fragment.startsWith('/')) {
      throw UnimplementedError(
        'Only local JSON Pointer references are supported, found $reference',
      );
    }
    final tokens = fragment.substring(1).split('/').map((token) {
      if (RegExp(r'~(?:[^01]|$)').hasMatch(token)) {
        throw FormatException('Invalid JSON Pointer escape: $reference');
      }
      return token.replaceAll('~1', '/').replaceAll('~0', '~');
    }).toList();
    return LocalJsonPointer._(tokens);
  }

  new fromTokens(List<String> tokens) : this._(List.unmodifiable(tokens));

  String get reference {
    if (tokens.isEmpty) return '#';
    final encoded = tokens.map(
      (token) => Uri.encodeComponent(
        token.replaceAll('~', '~0').replaceAll('/', '~1'),
      ),
    );
    return '#/${encoded.join('/')}';
  }

  String? componentName(String kind) =>
      tokens.length == 3 && tokens[0] == 'components' && tokens[1] == kind
      ? tokens[2]
      : null;

  Object? resolve(Object? document) {
    var current = document;
    for (final token in tokens) {
      if (current is Map<String, dynamic> && current.containsKey(token)) {
        current = current[token];
      } else if (current is List &&
          RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(token)) {
        final index = int.tryParse(token);
        if (index == null || index >= current.length) {
          throw ArgumentError('Reference $reference not found');
        }
        current = current[index];
      } else {
        throw ArgumentError('Reference $reference not found');
      }
    }
    return current;
  }
}
