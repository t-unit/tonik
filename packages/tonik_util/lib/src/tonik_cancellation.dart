import 'dart:async';

/// A backend-neutral signal used to cancel an API operation.
///
/// Create a separate instance for each operation; do not reuse it or share it
/// across operations. Tonik can cancel the signal during response cleanup,
/// including after a successful response with no body.
final class TonikCancellation._(
  final Completer<void> _completer,
  var Object? _reason,
) {
  factory() => TonikCancellation._(Completer<void>(), null);

  /// Whether cancellation has been requested.
  bool get isCancelled => _completer.isCompleted;

  /// The reason supplied by the first call to [cancel].
  Object? get reason => _reason;

  /// Completes when cancellation is first requested.
  Future<void> get whenCancelled => _completer.future;

  /// Requests cancellation with an optional [reason].
  ///
  /// Only the first call has an effect, including when its [reason] is null.
  void cancel([Object? reason]) {
    if (_completer.isCompleted) return;

    _reason = reason;
    _completer.complete();
  }
}
