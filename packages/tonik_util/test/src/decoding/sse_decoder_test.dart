import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('completes an empty source without events', () async {
    expect(await decodeSse(const Stream.empty()).toList(), isEmpty);
  });

  test('accepts a byte stream with a narrower runtime type', () async {
    final events = await decodeSse(
      Stream<Uint8List>.value(Uint8List.fromList(utf8.encode('data: x\n\n'))),
    ).toList();
    expect(events, [
      {'data': 'x'},
    ]);
  });

  test('a colonless data field emits empty string data', () async {
    final events = await decodeSse(Stream.value(utf8.encode('data\n\n')))
        .toList();
    expect(events, [
      {'data': ''},
    ]);
  });

  test('removes one space and splits only at the first colon', () async {
    final events = await decodeSse(Stream.value(utf8.encode('data:  a:b\n\n')))
        .toList();
    expect(events, [
      {'data': ' a:b'},
    ]);
  });

  test('field names are case sensitive', () async {
    final events = await decodeSse(
      Stream.value(utf8.encode('Data: ignored\ndata: x\n\n')),
    ).toList();
    expect(events, [
      {'data': 'x'},
    ]);
  });

  test('parses leading zeros in retry as decimal', () async {
    final events = await decodeSse(
      Stream.value(utf8.encode('retry: 0010\ndata: x\n\n')),
    ).toList();
    expect(events, [
      {'data': 'x', 'retry': 10},
    ]);
  });

  test('ignored retry fields preserve the previous valid value', () async {
    final events = await decodeSse(
      Stream.value(
        utf8.encode(
          'retry: 5\nretry:\nretry: +1\nretry: 1.0\nretry: ١\ndata: x\n\n',
        ),
      ),
    ).toList();
    expect(events, [
      {'data': 'x', 'retry': 5},
    ]);
  });

  test('NUL in an id preserves the previous valid id', () async {
    final events = await decodeSse(
      Stream.value(utf8.encode('id: good\nid: bad\u0000id\ndata: x\n\n')),
    ).toList();
    expect(events, [
      {'data': 'x', 'id': 'good'},
    ]);
  });

  test('an explicit empty id replaces an earlier id', () async {
    final events = await decodeSse(
      Stream.value(utf8.encode('id: old\nid:\ndata: x\n\n')),
    ).toList();
    expect(events, [
      {'data': 'x', 'id': ''},
    ]);
  });

  test('joins multiple data fields including empty fields with LF', () async {
    final events = await decodeSse(
      Stream.value(utf8.encode('data: first\ndata\ndata: third\n\n')),
    ).toList();
    expect(events, [
      {'data': 'first\n\nthird'},
    ]);
  });

  test('ignores comments and unknown fields and blocks without data', () async {
    final events = await decodeSse(
      Stream.value(
        utf8.encode(
          ': comment\nunknown: ignored\nevent: discarded\nid: discarded\n'
          'retry: 6\n\n: comment\ndata: x\nunknown\n\n',
        ),
      ),
    ).toList();
    expect(events, [
      {'data': 'x'},
    ]);
  });

  test(
    'uses last valid optional fields without inheriting across blocks',
    () async {
      final events = await decodeSse(
        Stream.value(
          utf8.encode(
            'event: old\nevent: update\nid: old\nid: new\nretry: 1\nretry: 2\n'
            'data: first\n\ndata: second\n\n',
          ),
        ),
      ).toList();
      expect(events, [
        {'data': 'first', 'event': 'update', 'id': 'new', 'retry': 2},
        {'data': 'second'},
      ]);
    },
  );

  test('preserves explicit empty event and zero retry', () async {
    final events = await decodeSse(
      Stream.value(utf8.encode('event: old\nevent\nretry: 000\ndata\n\n')),
    ).toList();
    expect(events, [
      {'data': '', 'event': '', 'retry': 0},
    ]);
  });

  test(
    'accepts split UTF-8, initial BOM and CRLF alongside CR and LF',
    () async {
      final events = await decodeSse(
        Stream.fromIterable([
          [0xef],
          [0xbb, 0xbf, 0x64, 0x61, 0x74, 0x61, 0x3a, 0x20, 0xe2],
          [0x82, 0xac, 0x0d],
          utf8.encode('\n\r'),
          utf8.encode('\ndata: second\r\rdata: third\n\n'),
        ]),
      ).toList();
      expect(events, [
        {'data': '€'},
        {'data': 'second'},
        {'data': 'third'},
      ]);
    },
  );

  test('removes only one initial BOM and preserves later BOMs', () async {
    final events = await decodeSse(
      Stream.value(
        utf8.encode(
          '\ufeff\ufeffdata: ignored\ndata: \ufeffkept\n\n'
          '\ufeffdata: ignored\ndata: next\n\n',
        ),
      ),
    ).toList();
    expect(events, [
      {'data': '\ufeffkept'},
      {'data': 'next'},
    ]);
  });

  test('replaces malformed UTF-8 inside data', () async {
    final events = await decodeSse(
      Stream.fromIterable([
        utf8.encode('data: '),
        [0xff, 0xe2],
        [0x0a, 0x0a],
      ]),
    ).toList();
    expect(events, [
      {'data': '\ufffd\ufffd'},
    ]);
  });

  test('discards unterminated data at EOF', () async {
    final events = await decodeSse(
      Stream.value(utf8.encode('data: sent\n\ndata: incomplete')),
    ).toList();
    expect(events, [
      {'data': 'sent'},
    ]);
  });

  test('discards a terminated data line without a blank line at EOF', () async {
    final events = await decodeSse(
      Stream.value(utf8.encode('data: incomplete\r\n')),
    ).toList();
    expect(events, isEmpty);
  });

  test('accepts the maximum exact retry integer with leading zeros', () async {
    final events = await decodeSse(
      Stream.value(utf8.encode('retry: 0009007199254740991\ndata: x\n\n')),
    ).toList();
    expect(events, [
      {'data': 'x', 'retry': 9007199254740991},
    ]);
  });

  test('rejects retry above the supported range when dispatching', () async {
    await expectLater(
      decodeSse(
        Stream.value(
          utf8.encode('retry: 9007199254740992\ndata: x\n\ndata: later\n\n'),
        ),
      ),
      emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
    );
  });

  test('rejects an integer that JavaScript would round', () async {
    await expectLater(
      decodeSse(
        Stream.value(utf8.encode('retry: 9007199254740993\ndata: x\n\n')),
      ),
      emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
    );
  });

  test('a later valid retry overrides an oversized value', () async {
    final events = await decodeSse(
      Stream.value(
        utf8.encode('retry: 999999999999999999999999\nretry: 7\ndata: x\n\n'),
      ),
    ).toList();
    expect(events, [
      {'data': 'x', 'retry': 7},
    ]);
  });

  test('an ignored retry does not clear an oversized value', () async {
    await expectLater(
      decodeSse(
        Stream.value(
          utf8.encode(
            'retry: 999999999999999999999999\nretry: -1\ndata: x\n\n',
          ),
        ),
      ),
      emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
    );
  });

  test('discards oversized retry in a block without data', () async {
    final events = await decodeSse(
      Stream.value(
        utf8.encode('retry: 999999999999999999999999\n\ndata: x\n\n'),
      ),
    ).toList();
    expect(events, [
      {'data': 'x'},
    ]);
  });

  test('discards oversized retry in an unfinished event', () async {
    final events = await decodeSse(
      Stream.value(
        utf8.encode('retry: 999999999999999999999999\ndata: unfinished\n'),
      ),
    ).toList();
    expect(events, isEmpty);
  });

  test('only subscribes on listen and forwards paused cancellation', () async {
    var listened = false;
    var cancelled = false;
    final source = StreamController<List<int>>(
      onListen: () => listened = true,
      onCancel: () => cancelled = true,
    );
    addTearDown(source.close);
    final stream = decodeSse(source.stream);
    expect(listened, isFalse);
    expect(stream.isBroadcast, isFalse);
    final subscription = stream.listen((_) {});
    expect(() => stream.listen((_) {}), throwsStateError);
    expect(listened, isTrue);
    subscription.pause();
    await subscription.cancel();
    expect(cancelled, isTrue);
  });

  test(
    'pauses between events in one chunk and resumes remaining events',
    () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);
      final first = Completer<void>();
      final last = Completer<void>();
      final events = <Map<String, Object>>[];
      late StreamSubscription<Map<String, Object>> subscription;
      subscription = decodeSse(source.stream).listen((event) {
        events.add(event);
        if (event['data'] == 'first') {
          subscription.pause();
          first.complete();
        } else {
          last.complete();
        }
      });
      source.add(utf8.encode('data: first\r\n\r\ndata: second\n\n'));
      await first.future;
      await Future<void>.delayed(Duration.zero);
      expect(events, [
        {'data': 'first'},
      ]);
      expect(source.isPaused, isTrue);
      subscription.resume();
      await last.future;
      await Future<void>.delayed(Duration.zero);
      expect(events, [
        {'data': 'first'},
        {'data': 'second'},
      ]);
      expect(source.isPaused, isFalse);
      await subscription.cancel();
    },
  );

  test('defers parsing while paused and stops on failure', () async {
    var cancelled = false;
    final source = StreamController<List<int>>(
      onCancel: () => cancelled = true,
    );
    addTearDown(source.close);
    final first = Completer<void>();
    final done = Completer<void>();
    final events = <Object>[];
    late StreamSubscription<Map<String, Object>> subscription;
    subscription = decodeSse(source.stream).listen(
      (event) {
        events.add(event);
        subscription.pause();
        first.complete();
      },
      onError: events.add,
      onDone: done.complete,
      cancelOnError: false,
    );
    source.add(
      utf8.encode(
        'data: first\n\nretry: 9007199254740993\ndata: bad\n\ndata: later\n\n',
      ),
    );
    await first.future;
    await Future<void>.delayed(Duration.zero);
    expect(events, [
      {'data': 'first'},
    ]);
    expect(cancelled, isFalse);
    subscription.resume();
    await done.future;
    expect(events, [
      {'data': 'first'},
      isA<FormatException>(),
    ]);
    expect(cancelled, isTrue);
    await subscription.cancel();
  });

  test(
    'preserves source error and stack and cancels further consumption',
    () async {
      var cancelled = false;
      final source = StreamController<List<int>>(
        onCancel: () => cancelled = true,
      );
      addTearDown(source.close);
      final error = StateError('source failure');
      final stack = StackTrace.fromString('original source stack');
      final events = <Object>[];
      final stacks = <StackTrace>[];
      final done = Completer<void>();
      decodeSse(source.stream).listen(
        events.add,
        onError: (Object failure, StackTrace trace) {
          events.add(failure);
          stacks.add(trace);
        },
        onDone: done.complete,
        cancelOnError: false,
      );
      source
        ..add(utf8.encode('data: first\n\n'))
        ..addError(error, stack)
        ..add(utf8.encode('data: later\n\n'));
      await done.future;
      expect(events, [
        {'data': 'first'},
        same(error),
      ]);
      expect(stacks, [same(stack)]);
      expect(cancelled, isTrue);
    },
  );

  test('contains cleanup rejection after a decoding failure', () async {
    final cleanupError = StateError('cleanup failed');
    final errors = <Object>[];
    final zoneErrors = <Object>[];
    final done = Completer<void>();
    runZonedGuarded(() {
      final source = StreamController<List<int>>(
        onCancel: () => Future<void>.error(cleanupError),
      );
      addTearDown(source.close);
      decodeSse(source.stream).listen(
        (_) {},
        onError: errors.add,
        onDone: done.complete,
        cancelOnError: false,
      );
      source.add(utf8.encode('retry: 9007199254740993\ndata: x\n\n'));
    }, (error, stack) => zoneErrors.add(error));
    await done.future;
    await Future<void>.delayed(Duration.zero);
    expect(errors, [isA<FormatException>()]);
    expect(zoneErrors, isEmpty);
  });

  test('preserves explicit caller cancellation rejection', () async {
    final error = StateError('cleanup failed');
    final source = StreamController<List<int>>(
      onCancel: () => Future<void>.error(error),
    );
    addTearDown(source.close);
    final subscription = decodeSse(source.stream).listen((_) {});
    await expectLater(subscription.cancel(), throwsA(same(error)));
  });
}
