import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('decodeNdjson', () {
    test('completes an empty source without items', () async {
      final values = await decodeNdjson(const Stream.empty()).toList();

      expect(values, isEmpty);
    });

    test('emits ordered objects across chunks', () async {
      final values = await decodeNdjson(
        Stream.fromIterable([
          utf8.encode('{"id":1}\n{"id":'),
          utf8.encode('2}\n{"id":3}\n'),
        ]),
      ).toList();

      expect(values, [
        {'id': 1},
        {'id': 2},
        {'id': 3},
      ]);
    });

    test('preserves arrays, scalar values, and null', () async {
      final values = await decodeNdjson(
        Stream.value(utf8.encode('[1,"two"]\n"hello"\n42\n1.5\ntrue\nnull\n')),
      ).toList();

      expect(values, [
        [1, 'two'],
        'hello',
        42,
        1.5,
        isTrue,
        null,
      ]);
    });

    test('accepts UTF-8 and CRLF split across chunks', () async {
      final values = await decodeNdjson(
        Stream.fromIterable([
          [0x22, 0xe2],
          [0x82, 0xac, 0x22, 0x0d],
          [0x0a, 0x32, 0x0d, 0x0a],
        ]),
      ).toList();

      expect(values, ['€', 2]);
    });

    test('skips empty LF and CRLF records', () async {
      final values = await decodeNdjson(
        Stream.value(utf8.encode('\n\r\n1\n\n')),
      ).toList();

      expect(values, [1]);
    });

    test('rejects whitespace-only records', () async {
      await expectLater(
        decodeNdjson(Stream.value(utf8.encode(' \t\n2\n'))),
        emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
      );
    });

    test('accepts a final record without a newline', () async {
      final values = await decodeNdjson(
        Stream.value(utf8.encode('1\n{"last":true}')),
      ).toList();

      expect(values, [
        1,
        {'last': isTrue},
      ]);
    });

    test('rejects a BOM split across chunks', () async {
      await expectLater(
        decodeNdjson(
          Stream.fromIterable([
            [0xef],
            [0xbb, 0xbf, 0x31, 0x0a],
          ]),
        ),
        emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
      );
    });

    test('rejects malformed UTF-8 before a valid record', () async {
      await expectLater(
        decodeNdjson(Stream.value([0x22, 0xff, 0x22, 0x0a, 0x31, 0x0a])),
        emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
      );
    });

    test('rejects truncated UTF-8 at EOF', () async {
      await expectLater(
        decodeNdjson(Stream.value([0x22, 0xe2, 0x82])),
        emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
      );
    });

    test('rejects a raw CR before trailing JSON whitespace', () async {
      await expectLater(
        decodeNdjson(Stream.value(utf8.encode('1\r \n'))),
        emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
      );
    });

    test('rejects a CR at EOF without LF', () async {
      await expectLater(
        decodeNdjson(Stream.value(utf8.encode('1\r'))),
        emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
      );
    });

    test('accepts escaped CR inside a JSON string', () async {
      final values = await decodeNdjson(
        Stream.value(utf8.encode('"one\\rtwo"\n')),
      ).toList();

      expect(values, ['one\rtwo']);
    });
  });

  group('decodeJsonLines', () {
    test('accepts CRLF split across chunks', () async {
      final values = await decodeJsonLines(
        Stream.fromIterable([utf8.encode('1\r'), utf8.encode('\n2\r\n')]),
      ).toList();

      expect(values, [1, 2]);
    });

    test('accepts a raw CR as JSON whitespace', () async {
      final values = await decodeJsonLines(Stream.value(utf8.encode('1\r \n')))
          .toList();

      expect(values, [1]);
    });

    test('rejects two values separated by CR in one record', () async {
      await expectLater(
        decodeJsonLines(Stream.value(utf8.encode('1\r2\n'))),
        emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
      );
    });

    test('accepts a raw CR at EOF as JSON whitespace', () async {
      final values = await decodeJsonLines(Stream.value(utf8.encode('1\r')))
          .toList();

      expect(values, [1]);
    });

    test('skips empty records but rejects whitespace-only records', () async {
      await expectLater(
        decodeJsonLines(Stream.value(utf8.encode('\n\r\n1\n \t\n2\n'))),
        emitsInOrder([1, emitsError(isA<FormatException>()), emitsDone]),
      );
    });

    test('rejects a BOM after an earlier record', () async {
      await expectLater(
        decodeJsonLines(Stream.value(utf8.encode('1\n\ufeff2\n'))),
        emitsInOrder([1, emitsError(isA<FormatException>()), emitsDone]),
      );
    });
  });

  group('subscription behavior', () {
    test('only subscribes to the source when listened to', () async {
      var listened = false;
      var cancelled = false;
      final source = StreamController<List<int>>(
        onListen: () => listened = true,
        onCancel: () => cancelled = true,
      );
      final stream = decodeNdjson(source.stream);
      addTearDown(source.close);

      expect(listened, isFalse);
      expect(stream.isBroadcast, isFalse);

      final subscription = stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(listened, isTrue);
      expect(() => stream.listen((_) {}), throwsStateError);
      await subscription.cancel();
      expect(cancelled, isTrue);
    });

    test('cancels upstream while awaiting the next byte chunk', () async {
      var cancelled = false;
      final source = StreamController<List<int>>(
        onCancel: () => cancelled = true,
      );
      addTearDown(source.close);
      final first = Completer<void>();
      final values = <Object?>[];
      final subscription = decodeNdjson(source.stream).listen((value) {
        values.add(value);
        first.complete();
      });

      source.add(utf8.encode('1\n'));
      await first.future;
      await subscription.cancel();

      expect(values, [1]);
      expect(cancelled, isTrue);
    });

    test('stops after invalid JSON and cancels upstream', () async {
      var cancelled = false;
      final source = StreamController<List<int>>(
        onCancel: () => cancelled = true,
      );
      addTearDown(source.close);
      final values = <Object?>[];
      final errors = <Object>[];
      final stacks = <StackTrace>[];
      final done = Completer<void>();
      decodeNdjson(source.stream).listen(
        values.add,
        onError: (Object error, StackTrace stack) {
          errors.add(error);
          stacks.add(stack);
        },
        onDone: done.complete,
        cancelOnError: false,
      );

      source
        ..add(utf8.encode('1\n{broken}\n2\n'))
        ..add(utf8.encode('3\n'));
      await done.future;

      expect(values, [1]);
      expect(errors, hasLength(1));
      expect(
        errors.single,
        isA<FormatException>().having(
          (error) => error.source,
          'source',
          '{broken}',
        ),
      );
      expect(stacks.single.toString(), isNotEmpty);
      expect(cancelled, isTrue);
    });

    test('preserves source errors and their stack trace', () async {
      var cancelled = false;
      final source = StreamController<List<int>>(
        onCancel: () => cancelled = true,
      );
      addTearDown(source.close);
      final failure = StateError('source failed');
      final stack = StackTrace.fromString('original source stack');
      final values = <Object?>[];
      final errors = <Object>[];
      final stacks = <StackTrace>[];
      final done = Completer<void>();
      decodeJsonLines(source.stream).listen(
        values.add,
        onError: (Object error, StackTrace stack) {
          errors.add(error);
          stacks.add(stack);
        },
        onDone: done.complete,
        cancelOnError: false,
      );

      source
        ..add(utf8.encode('1\n'))
        ..addError(failure, stack)
        ..add(utf8.encode('2\n'));
      await done.future;

      expect(values, [1]);
      expect(errors, [same(failure)]);
      expect(stacks, [same(stack)]);
      expect(cancelled, isTrue);
    });

    test('contains cleanup rejection after a decoding failure', () async {
      final cleanupError = StateError('cleanup failed');
      final values = <Object?>[];
      final errors = <Object>[];
      final stacks = <StackTrace>[];
      final zoneErrors = <Object>[];
      final done = Completer<void>();

      runZonedGuarded(() {
        final source = StreamController<List<int>>(
          onCancel: () => Future<void>.error(cleanupError),
        );
        addTearDown(source.close);
        decodeNdjson(source.stream).listen(
          values.add,
          onError: (Object error, StackTrace stack) {
            errors.add(error);
            stacks.add(stack);
          },
          onDone: done.complete,
          cancelOnError: false,
        );
        source.add(utf8.encode('1\n{broken}\n2\n'));
      }, (error, stack) => zoneErrors.add(error));
      await done.future;
      await Future<void>.delayed(Duration.zero);

      expect(values, [1]);
      expect(errors, hasLength(1));
      expect(
        errors.single,
        isA<FormatException>().having(
          (error) => error.source,
          'source',
          '{broken}',
        ),
      );
      expect(stacks.single.toString(), isNotEmpty);
      expect(zoneErrors, isEmpty);
    });

    test('preserves explicit caller cancellation rejection', () async {
      final cleanupError = StateError('cleanup failed');
      final source = StreamController<List<int>>(
        onCancel: () => Future<void>.error(cleanupError),
      );
      addTearDown(source.close);
      final subscription = decodeNdjson(source.stream).listen((_) {});

      await expectLater(subscription.cancel(), throwsA(same(cleanupError)));
    });

    test('pauses and resumes while processing one chunk', () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);
      final values = <Object?>[];
      final first = Completer<void>();
      final last = Completer<void>();
      late StreamSubscription<Object?> subscription;
      subscription = decodeNdjson(source.stream).listen((value) {
        values.add(value);
        if (value == 1) {
          subscription.pause();
          first.complete();
        }
        if (value == 3) last.complete();
      });

      source.add(utf8.encode('1\n2\n3\n'));
      await first.future;
      await Future<void>.delayed(Duration.zero);

      expect(values, [1]);
      expect(source.isPaused, isTrue);
      subscription.resume();
      await last.future;
      await Future<void>.delayed(Duration.zero);

      expect(values, [1, 2, 3]);
      expect(source.isPaused, isFalse);
      await subscription.cancel();
    });

    test('does not decode later records in a chunk while paused', () async {
      var cancelled = false;
      final source = StreamController<List<int>>(
        onCancel: () => cancelled = true,
      );
      addTearDown(source.close);
      final first = Completer<void>();
      final done = Completer<void>();
      final values = <Object?>[];
      final errors = <Object>[];
      late StreamSubscription<Object?> subscription;
      subscription = decodeJsonLines(source.stream).listen(
        (value) {
          values.add(value);
          subscription.pause();
          first.complete();
        },
        onError: errors.add,
        onDone: done.complete,
        cancelOnError: false,
      );

      source.add(utf8.encode('1\ninvalid\n2\n'));
      await first.future;
      await Future<void>.delayed(Duration.zero);

      expect(values, [1]);
      expect(errors, isEmpty);
      expect(cancelled, isFalse);
      subscription.resume();
      await done.future;

      expect(values, [1]);
      expect(errors, [isA<FormatException>()]);
      expect(cancelled, isTrue);
      await subscription.cancel();
    });

    test('cancels upstream when a paused subscriber cancels', () async {
      var cancelled = false;
      final source = StreamController<List<int>>(
        onCancel: () => cancelled = true,
      );
      addTearDown(source.close);
      final first = Completer<void>();
      final values = <Object?>[];
      late StreamSubscription<Object?> subscription;
      subscription = decodeNdjson(source.stream).listen((value) {
        values.add(value);
        subscription.pause();
        first.complete();
      });

      source.add(utf8.encode('1\n2\n3\n'));
      await first.future;
      await subscription.cancel();

      expect(values, [1]);
      expect(cancelled, isTrue);
    });
  });
}
