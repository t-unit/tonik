/// A class representing the result of an API call.
///
/// This class is used to handle the result of an API call, whether it is a
/// success or an error.
sealed class TonikResult<T, Response extends Object> {
  const TonikResult();
}

/// A class representing a successful API call.
class TonikSuccess<T, Response extends Object>
    extends TonikResult<T, Response> {
  /// Creates a new [TonikSuccess] instance.
  const TonikSuccess(this.value, this.response);

  /// The value returned by the API call.
  final T value;

  /// The backend-native response from the API call.
  final Response response;
}

/// A class representing an error that occurred during an API call.
class TonikError<T, Response extends Object> extends TonikResult<T, Response> {
  /// Creates a new [TonikError] instance.
  const TonikError(
    this.error, {
    required this.stackTrace,
    required this.type,
    required this.response,
  });

  /// The error that occurred during the API call.
  final Object error;

  /// The stack trace of the error.
  final StackTrace stackTrace;

  /// The type of error that occurred during the API call.
  final TonikErrorType type;

  /// The backend-native response from the API call. Might be null if the error
  /// occurred before the response was received.
  final Response? response;
}

/// The type of error that occurred during an API call.
enum TonikErrorType {
  /// An error occurred while encoding the request.
  encoding,

  /// An error occurred while decoding the response.
  decoding,

  /// An error occurred while sending the request.
  network,

  /// The request was cancelled before it completed.
  cancelled,

  /// Any other error occurred.
  other,
}
