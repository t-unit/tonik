/// Base class for all decoding related exceptions.
class DecodingException implements Exception {
  /// Creates a new [DecodingException] with the specified [message].
  const DecodingException(this.message);

  /// The error message.
  final String message;
}

/// Exception thrown when a value has invalid format for the expected type.
class InvalidFormatException extends DecodingException {
  /// Creates a new [InvalidFormatException] with the specified [value] and
  /// expected [format].
  const InvalidFormatException({required this.value, required this.format})
    : super('Invalid format for value "$value". Expected format: $format');

  /// The value that couldn't be decoded.
  final String value;

  /// The expected format description.
  final String format;

  @override
  String toString() => 'InvalidFormatException: $message';
}

/// Exception thrown when a value cannot be converted to the target type.
class InvalidTypeException extends DecodingException {
  /// Creates a new [InvalidTypeException] with the specified [value],
  /// [targetType] and optional [cause].
  const InvalidTypeException({
    required this.value,
    required this.targetType,
    this.cause,
  }) : super(
         'Cannot convert "$value" to type '
         '$targetType${cause != null ? ': $cause' : ''}',
       );

  /// The value that couldn't be converted.
  final String value;

  /// The target type that was requested.
  final Type targetType;

  /// The underlying cause of the conversion failure, if any.
  final Object? cause;

  @override
  String toString() => 'InvalidTypeException: $message';
}
