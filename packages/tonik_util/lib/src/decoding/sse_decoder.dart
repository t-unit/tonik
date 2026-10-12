import 'dart:async';
import 'dart:convert';

Stream<Map<String, Object>> decodeSse(Stream<List<int>> source) {
  late final StreamController<Map<String, Object>> controller;
  late final StreamSubscription<String> subscription;
  var line = StringBuffer();
  var data = <String>[];
  String? event;
  String? id;
  String? retry;
  String? chunk;
  var offset = 0;
  var skipLf = false;
  var stopped = false;
  Future<void>? failureCancellation;

  void resetEvent() {
    data = <String>[];
    event = null;
    id = null;
    retry = null;
  }

  void fail(Object error, StackTrace stack) {
    if (stopped) return;
    stopped = true;
    chunk = null;
    line = StringBuffer();
    resetEvent();
    // Cleanup must not report a second error outside the failed item stream.
    failureCancellation = subscription.cancel().onError<Object>((_, _) {});
    controller.addError(error, stack);
    unawaited(controller.close());
  }

  void finishLine() {
    final text = line.toString();
    line = StringBuffer();
    if (text.isEmpty) {
      if (data.isEmpty) {
        resetEvent();
        return;
      }
      final value = <String, Object>{
        'data': data.join('\n'),
        if (event != null) 'event': event!,
        if (id != null) 'id': id!,
        if (retry != null) 'retry': _parseRetry(retry!),
      };
      resetEvent();
      controller.add(value);
      return;
    }

    final colon = text.indexOf(':');
    final field = colon == -1 ? text : text.substring(0, colon);
    var value = colon == -1 ? '' : text.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'data':
        data.add(value);
      case 'event':
        event = value;
      case 'id':
        if (!value.contains('\u0000')) id = value;
      case 'retry':
        if (RegExp(r'^[0-9]+$').hasMatch(value)) retry = value;
    }
  }

  void drain() {
    final current = chunk;
    if (current == null || stopped) return;
    while (offset < current.length && !controller.isPaused && !stopped) {
      final character = current.codeUnitAt(offset++);
      if (skipLf && character == 0x0a) {
        skipLf = false;
        continue;
      }
      skipLf = character == 0x0d;
      if (character == 0x0a || character == 0x0d) {
        try {
          finishLine();
        } on FormatException catch (error, stack) {
          resetEvent();
          controller.addError(error, stack);
        }
      } else {
        line.writeCharCode(character);
      }
    }
    if (offset == current.length) chunk = null;
  }

  controller = StreamController<Map<String, Object>>(
    sync: true,
    onListen: () {
      // Dart's decoder strips exactly one initial BOM across byte chunks.
      subscription = const Utf8Decoder(allowMalformed: true)
          .bind(source)
          .listen(
            (text) {
              chunk = text;
              offset = 0;
              drain();
            },
            onError: fail,
            onDone: () {
              line = StringBuffer();
              resetEvent();
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
      line = StringBuffer();
      resetEvent();
      return failureCancellation ?? subscription.cancel();
    },
  );
  return controller.stream;
}

int _parseRetry(String value) {
  final digits = value.replaceFirst(RegExp('^0+'), '');
  if (digits.isEmpty) return 0;
  // Keep the result exact on both native Dart and JavaScript runtimes.
  const maximum = '9007199254740991';
  if (digits.length > maximum.length ||
      (digits.length == maximum.length && digits.compareTo(maximum) > 0)) {
    throw const FormatException('SSE retry exceeds the maximum exact integer.');
  }
  return int.parse(digits);
}
