import 'package:code_builder/code_builder.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

final _identifierPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');

/// Generates a throw expression for FormatException.
Expression generateFormatExceptionExpression(
  String message, {
  bool raw = false,
}) {
  return _generateExceptionExpression('FormatException', message, raw: raw);
}

/// Generates a throw expression for SimpleDecodingException.
Expression generateSimpleDecodingExceptionExpression(
  String message, {
  bool raw = false,
}) {
  return _generateExceptionExpression(
    'SimpleDecodingException',
    message,
    importUrl: 'package:tonik_util/tonik_util.dart',
    raw: raw,
  );
}

/// Generates a throw expression for JsonDecodingException.
Expression generateJsonDecodingExceptionExpression(
  String message, {
  bool raw = false,
}) {
  return _generateExceptionExpression(
    'JsonDecodingException',
    message,
    importUrl: 'package:tonik_util/tonik_util.dart',
    raw: raw,
  );
}

/// Generates a throw expression for ResponseDecodingException.
Expression generateResponseDecodingExceptionExpression(
  String message, {
  bool raw = false,
}) {
  return _generateExceptionExpression(
    'ResponseDecodingException',
    message,
    importUrl: 'package:tonik_util/tonik_util.dart',
    raw: raw,
  );
}

/// Generates a throw expression for FormDecodingException.
Expression generateFormDecodingExceptionExpression(
  String message, {
  bool raw = false,
}) {
  return _generateExceptionExpression(
    'FormDecodingException',
    message,
    importUrl: 'package:tonik_util/tonik_util.dart',
    raw: raw,
  );
}

/// Generates a throw expression for EncodingException.
Expression generateEncodingExceptionExpression(
  String message, {
  bool raw = false,
}) {
  return _generateExceptionExpression(
    'EncodingException',
    message,
    importUrl: 'package:tonik_util/tonik_util.dart',
    raw: raw,
  );
}

/// Generates a `throw JsonDecodingException(...)` whose message interpolates a
/// runtime Dart expression.
///
/// [literalPrefix] may contain spec-derived text and is escaped so it cannot
/// break out of the string literal or be reinterpreted as interpolation.
/// [interpolationExpression] is generator-controlled Dart source (e.g.
/// `value.runtimeType`) that is interpolated into the message at runtime via
/// `$`/`${...}` and never escaped; it must never receive spec-derived text.
Expression generateInterpolatedJsonDecodingExceptionExpression(
  String literalPrefix,
  String interpolationExpression,
) {
  final interpolation = _identifierPattern.hasMatch(interpolationExpression)
      ? '\$$interpolationExpression'
      : '\${$interpolationExpression}';
  final source =
      "'${escapeSingleQuotedDartString(literalPrefix)}$interpolation'";
  return refer(
    'JsonDecodingException',
    'package:tonik_util/tonik_util.dart',
  ).call([CodeExpression(Code(source))]).thrown;
}

Expression _generateExceptionExpression(
  String type,
  String message, {
  String importUrl = 'dart:core',
  bool raw = false,
}) {
  final ref = refer(type, importUrl);
  final stringExpr = raw ? specLiteralString(message) : literalString(message);
  return ref.call([stringExpr]).thrown;
}
