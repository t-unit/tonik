/// Base class for all decoding related exceptions.
abstract class const DecodingException(
  /// The error message.
  final String message,
) implements Exception {
  /// Creates a new [DecodingException] with the specified [message].
  this;

  @override
  String toString() => 'DecodingException: $message';
}

/// Exception thrown when a value has invalid format for the expected type.
class const InvalidFormatException({
  /// The value that couldn't be decoded.
  required final String value,

  /// The expected format description.
  required final String format,
}) extends DecodingException {
  /// Creates a new [InvalidFormatException] with the specified [value] and
  /// expected [format].
  this : super('Invalid format for value "$value". Expected format: $format');

  @override
  String toString() => 'InvalidFormatException: $message';
}

/// Exception thrown when a value cannot be converted to the target type.
class const InvalidTypeException({
  /// The value that couldn't be converted.
  required final String value,

  /// The target type that was requested.
  required final Type targetType,

  /// The context of the conversion failure, if any.
  final String? context,
}) extends DecodingException {
  /// Creates a new [InvalidTypeException] with the specified [value],
  /// [targetType] and optional [context].
  this
    : super(
        'Cannot convert "$value" to type '
        '$targetType${context != null ? ': $context' : ''}',
      );

  @override
  String toString() => 'InvalidTypeException: $message';
}

/// Exception thrown when a value cannot be decoded using fromSimple.
class const SimpleDecodingException(super.message) extends DecodingException {
  /// Creates a new [SimpleDecodingException] with the specified [message].
  this;
}

/// Exception thrown when a value cannot be decoded using fromJson.
class const JsonDecodingException(super.message) extends DecodingException {
  /// Creates a new [JsonDecodingException] with the specified [message].
  this;
}

/// Exception thrown when a value cannot be decoded using fromFormat.
class const FormDecodingException(super.message) extends DecodingException {
  /// Creates a new [FormDecodingException] with the specified [message].
  this;
}

/// Exception thrown when a response body cannot be decoded due to
/// content-type mismatch or decoding failure.
class const ResponseDecodingException(super.message) extends DecodingException {
  /// Creates a new [ResponseDecodingException] with the specified [message].
  this;
}
