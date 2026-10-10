import 'dart:async';
import 'dart:convert';

Stream<Object?> decodeJsonSequence(Stream<List<int>> source) {
  late final StreamController<Object?> controller;
  late final StreamSubscription<List<int>> subscription;
  var record = <int>[];
  List<int>? chunk;
  var offset = 0;
  var stopped = false;
  var inRecord = false;
  var discarded = false;
  var accepted = false;
  var started = false;
  var inString = false;
  var escaped = false;
  var depth = 0;
  Future<void>? failureCancellation;

  void resetRecord() {
    record = <int>[];
    discarded = false;
    accepted = false;
    started = false;
    inString = false;
    escaped = false;
    depth = 0;
  }

  void fail(Object error, StackTrace stack) {
    if (stopped) return;
    stopped = true;
    chunk = null;
    resetRecord();
    // Cleanup must not report a second error outside the failed item stream.
    failureCancellation = subscription.cancel().onError<Object>((_, _) {});
    controller.addError(error, stack);
    unawaited(controller.close());
  }

  void finishRecord() {
    if (record.isEmpty) return;
    final bytes = record;
    record = <int>[];
    discarded = true;
    final Object? value;
    try {
      value = _decodeRecord(bytes);
    } on FormatException catch (error, stack) {
      controller.addError(error, stack);
      return;
    }
    accepted = true;
    controller.add(value);
  }

  void drain() {
    final current = chunk;
    if (current == null || stopped) return;
    while (offset < current.length && !controller.isPaused && !stopped) {
      final byte = current[offset++];
      if (byte == 0x1e) {
        finishRecord();
        resetRecord();
        inRecord = true;
        continue;
      }
      if (!inRecord) {
        if (!discarded) {
          discarded = true;
          controller.addError(
            const FormatException('JSON sequence records must start with RS.'),
          );
        }
        continue;
      }
      if (discarded) {
        if (accepted && !_isWhitespace(byte)) {
          inRecord = false;
          controller.addError(
            const FormatException(
              'Unexpected data after a JSON sequence value.',
            ),
          );
        }
        continue;
      }

      record.add(byte);
      // Track only lexical boundaries; jsonDecode validates the complete text.
      // This lets a complete record arrive before the next RS without treating
      // pretty-printed internal newlines as malformed records.
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (byte == 0x5c) {
          escaped = true;
        } else if (byte == 0x22) {
          inString = false;
        }
      } else if (!_isWhitespace(byte)) {
        started = true;
        if (byte == 0x22) {
          inString = true;
        } else if (byte == 0x7b || byte == 0x5b) {
          depth++;
        } else if (byte == 0x7d || byte == 0x5d) {
          depth--;
        }
      }
      if (byte == 0x0a && started && !inString && depth == 0) {
        finishRecord();
      }
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
          finishRecord();
          unawaited(controller.close());
        },
      );
    },
    onPause: () => subscription.pause(),
    onResume: () {
      scheduleMicrotask(() {
        drain();
        if (!stopped) subscription.resume();
      });
    },
    onCancel: () {
      stopped = true;
      chunk = null;
      resetRecord();
      return failureCancellation ?? subscription.cancel();
    },
  );
  return controller.stream;
}

Object? _decodeRecord(List<int> record) {
  // Dart's UTF-8 decoder strips a BOM, which is not part of a JSON text.
  if (record.length >= 3 &&
      record[0] == 0xef &&
      record[1] == 0xbb &&
      record[2] == 0xbf) {
    throw const FormatException(
      'JSON sequence records cannot start with a BOM.',
    );
  }
  final value = jsonDecode(utf8.decode(record));
  if ((value is num || value is bool || value == null) &&
      !_isWhitespace(record.last)) {
    throw const FormatException(
      'JSON sequence scalars require trailing whitespace to detect truncation.',
    );
  }
  return value;
}

bool _isWhitespace(int byte) =>
    byte == 0x20 || byte == 0x09 || byte == 0x0a || byte == 0x0d;
