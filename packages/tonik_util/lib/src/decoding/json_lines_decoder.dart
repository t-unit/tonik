import 'dart:async';
import 'dart:convert';

Stream<Object?> decodeNdjson(Stream<List<int>> source) =>
    _decodeJsonLines(source, rejectRawCarriageReturns: true);

Stream<Object?> decodeJsonLines(Stream<List<int>> source) =>
    _decodeJsonLines(source, rejectRawCarriageReturns: false);

Stream<Object?> _decodeJsonLines(
  Stream<List<int>> source, {
  required bool rejectRawCarriageReturns,
}) {
  late final StreamController<Object?> controller;
  late final StreamSubscription<List<int>> subscription;
  var record = <int>[];
  List<int>? chunk;
  var offset = 0;
  var stopped = false;
  Future<void>? failureCancellation;

  void fail(Object error, StackTrace stack) {
    if (stopped) return;
    stopped = true;
    chunk = null;
    record = <int>[];
    // Cleanup must not report a second error outside the failed item stream.
    failureCancellation = subscription.cancel().onError<Object>((_, _) {});
    controller.addError(error, stack);
    unawaited(controller.close());
  }

  void drain() {
    final current = chunk;
    if (current == null || stopped) return;

    while (offset < current.length && !controller.isPaused && !stopped) {
      final byte = current[offset++];
      if (byte != 0x0a) {
        record.add(byte);
        continue;
      }

      if (record.isNotEmpty && record.last == 0x0d) {
        record.removeLast();
      }
      if (record.isEmpty) continue;

      final Object? value;
      try {
        value = _decodeRecord(record, rejectRawCarriageReturns);
      } on FormatException catch (error, stack) {
        record.clear();
        controller.addError(error, stack);
        continue;
      }
      record.clear();
      controller.add(value);
    }
    if (offset == current.length) chunk = null;
  }

  controller = StreamController<Object?>(
    sync: true,
    onListen: () {
      subscription = source.listen(
        (bytes) {
          chunk = bytes;
          offset = 0;
          drain();
        },
        onError: fail,
        onDone: () {
          if (record.isNotEmpty) {
            final Object? value;
            try {
              value = _decodeRecord(record, rejectRawCarriageReturns);
            } on FormatException catch (error, stack) {
              record.clear();
              controller.addError(error, stack);
              unawaited(controller.close());
              return;
            }
            record.clear();
            controller.add(value);
          }
          unawaited(controller.close());
        },
      );
    },
    onPause: () => subscription.pause(),
    onResume: () {
      // Resume outside the controller callback so item delivery stays legal for
      // a synchronous controller and listeners can pause between records.
      scheduleMicrotask(() {
        drain();
        if (!stopped) subscription.resume();
      });
    },
    onCancel: () {
      stopped = true;
      chunk = null;
      record = <int>[];
      return failureCancellation ?? subscription.cancel();
    },
  );
  return controller.stream;
}

Object? _decodeRecord(List<int> record, bool rejectRawCarriageReturns) {
  if (rejectRawCarriageReturns && record.contains(0x0d)) {
    throw const FormatException('NDJSON records cannot contain a raw CR.');
  }
  // The standard UTF-8 decoder silently removes an initial BOM.
  if (record.length >= 3 &&
      record[0] == 0xef &&
      record[1] == 0xbb &&
      record[2] == 0xbf) {
    throw const FormatException('JSON Lines records cannot start with a BOM.');
  }
  return jsonDecode(utf8.decode(record));
}
