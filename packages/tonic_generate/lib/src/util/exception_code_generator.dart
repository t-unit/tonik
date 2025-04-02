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

/// Base function to generate a throw expression for any exception type.
Expression _generateExceptionExpression(String type, String message) {
  return refer(type, 'dart:core')
      .call([literalString(message)])
      .thrown;
}
