import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';

/// Returns the `dart:convert` codec selected at the semantic parse boundary.
Expression textEncodingExpression(TextEncoding encoding) => switch (encoding) {
  TextEncoding.utf8 => refer('utf8', 'dart:convert'),
  TextEncoding.latin1 => refer('latin1', 'dart:convert'),
  TextEncoding.ascii => refer('ascii', 'dart:convert'),
};

/// Encodes request text with the semantic codec.
Expression requestTextBytesExpression(
  TextEncoding encoding,
  Expression text,
) => textEncodingExpression(encoding).property('encode').call([text]);
