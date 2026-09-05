/// A class representing the result of an API call.
///
/// This class is used to handle the result of an API call, whether it is a
/// success or an error.
sealed class const TonikResult<T, Response extends Object>();

/// A class representing a successful API call.
class const TonikSuccess<T, Response extends Object>(
  /// The value returned by the API call.
  final T value,

  /// The backend-native response from the API call.
  final Response response,
) extends TonikResult<T, Response>;

/// A class representing an error that occurred during an API call.
class const TonikError<T, Response extends Object>(
  /// The error that occurred during the API call.
  final Object error, {

  /// The stack trace of the error.
  required final StackTrace stackTrace,

  /// The type of error that occurred during the API call.
  required final TonikErrorType type,

  /// The backend-native response from the API call. Might be null if the error
  /// occurred before the response was received.
  required final Response? response,
}) extends TonikResult<T, Response>;

/// The type of error that occurred during an API call.
enum TonikErrorType() {
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
