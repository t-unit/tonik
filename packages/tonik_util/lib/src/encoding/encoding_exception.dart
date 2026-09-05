/// Base class for all encoding related exceptions.
class const EncodingException(
  /// The error message.
  final String message,
) implements Exception {
  /// Creates a new [EncodingException] with the specified [message].
  this;
}

/// Exception thrown when an unsupported type is passed to an encoder.
class const UnsupportedEncodingTypeException({
  /// The type of the value that couldn't be encoded.
  required final Type valueType,
}) extends EncodingException {
  /// Creates a new [UnsupportedEncodingTypeException] with the
  /// specified [valueType].
  this : super('Unsupported type $valueType');

  @override
  String toString() => 'UnsupportedEncodingTypeException: $message';
}

/// Exception thrown when a value is empty and empty values are not allowed.
class const EmptyValueException() extends EncodingException {
  /// Creates a new [EmptyValueException].
  this : super('Empty values are not allowed when allowEmpty is false');

  @override
  String toString() => 'EmptyValueException: $message';
}
