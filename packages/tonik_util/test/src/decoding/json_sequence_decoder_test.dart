import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test(
    'completes empty input and ignores consecutive record separators',
    () async {
      expect(await decodeJsonSequence(const Stream.empty()).toList(), isEmpty);
      expect(
        await decodeJsonSequence(Stream.value([0x1e, 0x1e])).toList(),
        isEmpty,
      );
    },
  );

  test(
    'preserves multiline objects, arrays, strings, and scalar values',
    () async {
      final values = await decodeJsonSequence(
        Stream.value(
          utf8.encode(
            '\x1e{\n"items": [1,\n2], "text": "[\\"}]"\n}\n'
            '\x1e[\n3\n]\n\x1e"text\\n\\u001e"\n'
            '\x1e42\n\x1e1.5\n\x1etrue\n\x1efalse\n\x1enull\n',
          ),
        ),
      ).toList();
      expect(values, [
        {
          'items': [1, 2],
          'text': '["}]',
        },
        [3],
        'text\n\x1e',
        42,
        1.5,
        isTrue,
        isFalse,
        null,
      ]);
    },
  );

  test(
    'preserves UTF-8, escapes and RS across arbitrary byte chunks',
    () async {
      final values = await decodeJsonSequence(
        Stream.fromIterable([
          [0x1e],
          [0x22, 0xe2],
          [0x82],
          [0xac, 0x5c],
          [0x22, 0x22],
          [0x0a, 0x1e, 0x31],
          [0x0a],
        ]),
      ).toList();
      expect(values, ['€"', 1]);
    },
  );

  test(
    'recovers from invalid JSON and truncated UTF-8 at the next RS',
    () async {
      await expectLater(
        decodeJsonSequence(
          Stream.fromIterable([
            utf8.encode('\x1e{"broken":\n\x1e{"value":2}\n'),
            [0x1e, 0x22, 0xe2, 0x82, 0x1e],
            utf8.encode('3\n'),
          ]),
        ),
        emitsInOrder([
          emitsError(isA<FormatException>()),
          {'value': 2},
          emitsError(isA<FormatException>()),
          3,
          emitsDone,
        ]),
      );
    },
  );

  test(
    'drops potentially truncated scalars and resumes at the next RS',
    () async {
      await expectLater(
        decodeJsonSequence(
          Stream.value(utf8.encode('\x1e123\x1etrue\x1efalse\x1enull\x1e2\n')),
        ),
        emitsInOrder([
          emitsError(isA<FormatException>()),
          emitsError(isA<FormatException>()),
          emitsError(isA<FormatException>()),
          emitsError(isA<FormatException>()),
          2,
          emitsDone,
        ]),
      );
    },
  );

  test('accepts JSON whitespace after scalars without LF', () async {
    final values = await decodeJsonSequence(
      Stream.value(utf8.encode('\x1e123 \x1etrue\t\x1efalse\r\x1enull ')),
    ).toList();
    expect(values, [123, isTrue, isFalse, null]);
  });

  test('accepts self-delimited values at RS and EOF without LF', () async {
    final values = await decodeJsonSequence(
      Stream.value(utf8.encode('\x1e{}\x1e[]\x1e"last"')),
    ).toList();
    expect(values, [<String, Object?>{}, <Object?>[], 'last']);
  });

  test('reports a truncated last record at EOF', () async {
    await expectLater(
      decodeJsonSequence(Stream.value(utf8.encode('\x1e1\n\x1e{"value":'))),
      emitsInOrder([1, emitsError(isA<FormatException>()), emitsDone]),
    );
  });

  test('reports an unterminated last scalar at EOF', () async {
    await expectLater(
      decodeJsonSequence(Stream.value(utf8.encode('\x1e123'))),
      emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
    );
  });

  test('rejects unframed input and recovers at the first RS', () async {
    await expectLater(
      decodeJsonSequence(Stream.value(utf8.encode('1\n\x1e2\n'))),
      emitsInOrder([emitsError(isA<FormatException>()), 2, emitsDone]),
    );
  });

  test(
    'rejects BOM and whitespace-only records but ignores empty records',
    () async {
      await expectLater(
        decodeJsonSequence(
          Stream.value(utf8.encode('\x1e\ufeff1\n\x1e \t\n\x1e\x1e2\n')),
        ),
        emitsInOrder([
          emitsError(isA<FormatException>()),
          emitsError(isA<FormatException>()),
          2,
          emitsDone,
        ]),
      );
    },
  );

  test('reports trailing non-whitespace once and recovers at RS', () async {
    await expectLater(
      decodeJsonSequence(
        Stream.value(utf8.encode('\x1e"first"\n456\n789\n\x1e"last"\n')),
      ),
      emitsInOrder([
        'first',
        emitsError(isA<FormatException>()),
        'last',
        emitsDone,
      ]),
    );
  });

  test('emits a completed multiline record before another RS or EOF', () async {
    final source = StreamController<List<int>>();
    addTearDown(source.close);
    final item = Completer<Object?>();
    final subscription = decodeJsonSequence(source.stream)
        .listen(item.complete);
    source.add(utf8.encode('\x1e{\n"value":1,\n"text":"ok"\n}\n'));
    expect(await item.future, {'value': 1, 'text': 'ok'});
    await subscription.cancel();
  });

  test(
    'pauses on a recoverable error and resumes within the same chunk',
    () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);
      final first = Completer<void>();
      final last = Completer<void>();
      final events = <Object?>[];
      late StreamSubscription<Object?> subscription;
      subscription = decodeJsonSequence(source.stream).listen(
        (value) {
          events.add(value);
          last.complete();
        },
        onError: (Object error) {
          events.add(error);
          subscription.pause();
          first.complete();
        },
      );
      source.add(utf8.encode('\x1e{bad}\n\x1e2\n'));
      await first.future;
      await Future<void>.delayed(Duration.zero);
      expect(events, [isA<FormatException>()]);
      expect(source.isPaused, isTrue);
      subscription.resume();
      await last.future;
      expect(events, [isA<FormatException>(), 2]);
      await subscription.cancel();
    },
  );

  test('cancelling after one item discards buffered records', () async {
    var cancelled = false;
    final source = StreamController<List<int>>(
      onCancel: () => cancelled = true,
    );
    addTearDown(source.close);
    final first = Completer<void>();
    final values = <Object?>[];
    late StreamSubscription<Object?> subscription;
    subscription = decodeJsonSequence(source.stream).listen((value) {
      values.add(value);
      unawaited(subscription.cancel());
      first.complete();
    });
    source.add(utf8.encode('\x1e1\n\x1e2\n'));
    await first.future;
    expect(values, [1]);
    expect(cancelled, isTrue);
  });

  test(
    'transport failure retains its stack and cancels further consumption',
    () async {
      var cancelled = false;
      final source = StreamController<List<int>>(
        onCancel: () => cancelled = true,
      );
      addTearDown(source.close);
      const error = FormatException('transport');
      final stack = StackTrace.current;
      final done = Completer<void>();
      final events = <Object?>[];
      final stacks = <StackTrace>[];
      decodeJsonSequence(source.stream).listen(
        events.add,
        onError: (Object failure, StackTrace trace) {
          events.add(failure);
          stacks.add(trace);
        },
        onDone: done.complete,
      );
      source
        ..add(utf8.encode('\x1e1\n'))
        ..addError(error, stack)
        ..add(utf8.encode('\x1e2\n'));
      await done.future;
      expect(events, [1, same(error)]);
      expect(stacks, [same(stack)]);
      expect(cancelled, isTrue);
    },
  );
}
