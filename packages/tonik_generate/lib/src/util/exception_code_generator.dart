import 'package:code_builder/code_builder.dart';



/// Generates a throw expression for ArgumentError.
Expression generateArgumentErrorExpression(String message) {
  return _generateExceptionExpression('ArgumentError', message);
}

/// Generates a throw expression for FormatException.
Expression generateFormatExceptionExpression(String message) {
  return _generateExceptionExpression('FormatException', message);
}

/// Generates a throw expression for UnimplementedError.
Expression generateUnimplementedErrorExpression(String message) {
  return _generateExceptionExpression('UnimplementedError', message);
}

/// Generates a throw expression for SimpleDecodingException.
Expression generateSimpleDecodingExceptionExpression(String message) {
  return _generateExceptionExpression(
    'SimpleDecodingException',
    message,
    importUrl: 'package:tonik_util/tonik_util.dart',
  );
}

/// Generates a throw expression for JsonDecodingException.
Expression generateJsonDecodingExceptionExpression(String message) {
  return _generateExceptionExpression(
    'JsonDecodingException',
    message,
    importUrl: 'package:tonik_util/tonik_util.dart',
  );
}

/// Generates a throw expression for DecodingException.
Expression generateDecodingExceptionExpression(String message) {
  return _generateExceptionExpression(
    'DecodingException',
    message,
    importUrl: 'package:tonik_util/tonik_util.dart',
  );
}

Expression _generateExceptionExpression(
  String type,
  String message, {
  String importUrl = 'dart:core',
}) {
  final ref = refer(type, importUrl);
  return ref.call([literalString(message)]).thrown;
}
