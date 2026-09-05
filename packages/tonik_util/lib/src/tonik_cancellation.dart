import 'dart:async';

/// A backend-neutral signal used to cancel an API operation.
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
