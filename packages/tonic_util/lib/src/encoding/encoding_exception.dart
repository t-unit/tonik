/// Base class for all encoding related exceptions.
class EncodingException implements Exception {
  /// Creates a new [EncodingException] with the specified [message].
  const EncodingException(this.message);

  /// The error message.
  final String message;
}

/// Exception thrown when an unsupported type is passed to an encoder.
class UnsupportedEncodingTypeException extends EncodingException {
  /// Creates a new [UnsupportedEncodingTypeException] with the
  /// specified [valueType].
  const UnsupportedEncodingTypeException({required this.valueType})
    : super('Unsupported type $valueType');

  /// The type of the value that couldn't be encoded.
  final Type valueType;

  @override
  String toString() => 'UnsupportedEncodingTypeException: $message';
}

/// Exception thrown when a value is empty and empty values are not allowed.
class EmptyValueException extends EncodingException {
  /// Creates a new [EmptyValueException].
  const EmptyValueException()
    : super('Empty values are not allowed when allowEmpty is false');

  @override
  String toString() => 'EmptyValueException: $message';
}
