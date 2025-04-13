import 'package:dio/dio.dart';

/// A class representing the result of an API call.
///
/// This class is used to handle the result of an API call, whether it is a
/// success or an error.
sealed class TonicResult<T> {
  const TonicResult();
}

/// A class representing a successful API call.
class TonicSuccess<T> extends TonicResult<T> {
  /// Creates a new [TonicSuccess] instance.
  const TonicSuccess(this.value, this.response);

  /// The value returned by the API call.
  final T value;

  /// The response from the API call.
  final Response<dynamic> response;
}

/// A class representing an error that occurred during an API call.
class TonicError<T> extends TonicResult<T> {
  /// Creates a new [TonicError] instance.
  const TonicError(
    this.error, {
    required this.stackTrace,
    required this.type,
    required this.response,
  });

  /// The error that occurred during the API call.
  final Exception error;

  /// The stack trace of the error.
  final StackTrace stackTrace;

  /// The type of error that occurred during the API call.
  final TonicErrorType type;

  /// The response from the API call. Might be null if the error occurred
  /// before the response was received.
  final Response<dynamic>? response;
}

/// The type of error that occurred during an API call.
enum TonicErrorType {
  /// An error occurred while encoding the request.
  encoding,

  /// An error occurred while decoding the response.
  decoding,

  /// An error occurred while sending the request.
  network,

  /// Any other error occurred.
  other,
}
