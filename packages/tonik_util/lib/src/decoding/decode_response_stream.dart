import 'dart:async';

import 'package:tonik_util/src/tonik_cancellation.dart';
import 'package:tonik_util/src/tonik_result.dart';

Stream<TonikResult<T, R>> decodeResponseStream<T, R extends Object>(
  Stream<List<int>> source,
  Stream<Object?> Function(Stream<List<int>>) frame,
  T Function(Object?) decode, {
  required TonikCancellation cancellation,
  required R response,
  required TonikErrorType Function(Object) sourceErrorType,
}) {
  late final StreamController<TonikResult<T, R>> controller;
  StreamSubscription<Object?>? subscription;
  var finished = false;
  Future<void>? cleanup;

  Future<void> cancelSource() =>
      cleanup ??= Future<void>.sync(() => subscription?.cancel())
          .onError<Object>((_, _) {});

  void fail(Object error, StackTrace stack, TonikErrorType type) {
    if (finished) return;
    finished = true;
    cancellation.cancel(error);
    unawaited(cancelSource());
    controller.add(
      TonikError<T, R>(
        error,
        stackTrace: stack,
        type: type,
        response: response,
      ),
    );
    unawaited(controller.close());
  }

  final markedSource = StreamTransformer<List<int>, List<int>>.fromHandlers(
    handleError: (error, stack, sink) {
      sink.addError(
        _SourceFailure(error, stack, sourceErrorType(error)),
        stack,
      );
    },
  ).bind(source);

  controller = StreamController<TonikResult<T, R>>(
    sync: true,
    onListen: () {
      final Stream<Object?> framed;
      try {
        framed = frame(markedSource);
      } on Object catch (error, stack) {
        fail(error, stack, TonikErrorType.decoding);
        return;
      }
      try {
        subscription = framed.listen(
          (json) {
            if (finished || cancellation.isCancelled) return;
            final T value;
            try {
              value = decode(json);
            } on Object catch (error, stack) {
              fail(error, stack, TonikErrorType.decoding);
              return;
            }
            controller.add(TonikSuccess<T, R>(value, response));
          },
          onError: (Object error, StackTrace stack) {
            if (error is _SourceFailure) {
              fail(error.error, error.stack, error.type);
            } else {
              fail(error, stack, TonikErrorType.decoding);
            }
          },
          onDone: () {
            finished = true;
            unawaited(controller.close());
          },
        );
      } on Object catch (error, stack) {
        fail(error, stack, TonikErrorType.other);
      }
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () {
      if (!finished) {
        finished = true;
        cancellation.cancel();
      }
      return cancelSource();
    },
  );
  return controller.stream;
}

final class const _SourceFailure(
  final Object error,
  final StackTrace stack,
  final TonikErrorType type,
);
