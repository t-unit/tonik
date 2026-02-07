import 'package:code_builder/code_builder.dart';

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

/// Generates a throw expression for JsonDecodingException.
///
/// This is used for enum fromJson errors.
Expression generateDecodingExceptionExpression(
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

Expression _generateExceptionExpression(
  String type,
  String message, {
  String importUrl = 'dart:core',
  bool raw = false,
}) {
  final ref = refer(type, importUrl);
  return ref.call([literalString(message, raw: raw)]).thrown;
}
