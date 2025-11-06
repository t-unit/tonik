/// Base class for all decoding related exceptions.
abstract class DecodingException implements Exception {
  /// Creates a new [DecodingException] with the specified [message].
  const DecodingException(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => 'DecodingException: $message';
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
  /// [targetType] and optional [context].
  const InvalidTypeException({
    required this.value,
    required this.targetType,
    this.context,
  }) : super(
         'Cannot convert "$value" to type '
         '$targetType${context != null ? ': $context' : ''}',
       );

  /// The value that couldn't be converted.
  final String value;

  /// The target type that was requested.
  final Type targetType;

  /// The context of the conversion failure, if any.
  final String? context;

  @override
  String toString() => 'InvalidTypeException: $message';
}

/// Exception thrown when a value cannot be decoded using fromSimple.
class SimpleDecodingException extends DecodingException {
  /// Creates a new [SimpleDecodingException] with the specified [message].
  const SimpleDecodingException(super.message);
}

/// Exception thrown when a value cannot be decoded using fromJson.
class JsonDecodingException extends DecodingException {
  /// Creates a new [JsonDecodingException] with the specified [message].
  const JsonDecodingException(super.message);
}

/// Exception thrown when a value cannot be decoded using fromFormat.
class FormatDecodingException extends DecodingException {
  /// Creates a new [FormatDecodingException] with the specified [message].
  const FormatDecodingException(super.message);
}
