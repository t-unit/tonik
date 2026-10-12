import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test(
    'converts items with native metadata without cancelling at EOF',
    () async {
      final cancellation = TonikCancellation();
      final response = Object();
      final stream = decodeResponseStream(
        Stream.value(utf8.encode('1\n2\n')),
        decodeNdjson,
        (value) => (value! as int) + 10,
        cancellation: cancellation,
        response: response,
        sourceErrorType: (_) => TonikErrorType.network,
      );
      final items = await stream.toList();
      expect(items, hasLength(2));
      expect((items[0] as TonikSuccess<int, Object>).value, 11);
      expect((items[1] as TonikSuccess<int, Object>).value, 12);
      expect((items[0] as TonikSuccess<int, Object>).response, same(response));
      expect(cancellation.isCancelled, isFalse);
    },
  );

  test(
    'conversion failure is one terminal result retaining cause and stack',
    () async {
      final cancellation = TonikCancellation();
      final stopped = Completer<void>();
      final source = StreamController<List<int>>(onCancel: stopped.complete);
      final error = StateError('conversion');
      final stack = StackTrace.current;
      final response = Object();
      var conversions = 0;
      final items = decodeResponseStream<int, Object>(
        source.stream,
        decodeNdjson,
        (value) {
          conversions++;
          Error.throwWithStackTrace(error, stack);
        },
        cancellation: cancellation,
        response: response,
        sourceErrorType: (_) => TonikErrorType.network,
      ).toList();
      source.add(utf8.encode('1\n2\n'));
      final failure = (await items).single as TonikError<int, Object>;
      await stopped.future;
      expect(failure.error, same(error));
      expect(failure.stackTrace, same(stack));
      expect(failure.response, same(response));
      expect(failure.type, TonikErrorType.decoding);
      expect(conversions, 1);
      expect(cancellation.reason, same(error));
    },
  );

  test('framing failure is decoding after earlier successful items', () async {
    final cancellation = TonikCancellation();
    final items = await decodeResponseStream(
      Stream.value(utf8.encode('1\ninvalid\n2\n')),
      decodeNdjson,
      (value) => value! as int,
      cancellation: cancellation,
      response: 'response',
      sourceErrorType: (_) => TonikErrorType.network,
    ).toList();
    expect(items, hasLength(2));
    expect((items.first as TonikSuccess<int, String>).value, 1);
    final failure = items.last as TonikError<int, String>;
    expect(failure.error, isA<FormatException>());
    expect(failure.type, TonikErrorType.decoding);
    expect(failure.response, 'response');
    expect(cancellation.reason, same(failure.error));
  });

  test(
    'source FormatException retains network provenance and original stack',
    () async {
      final cancellation = TonikCancellation();
      const error = FormatException('transport');
      final stack = StackTrace.current;
      final items = await decodeResponseStream(
        Stream<List<int>>.error(error, stack),
        decodeNdjson,
        (value) => value,
        cancellation: cancellation,
        response: 'response',
        sourceErrorType: (_) => cancellation.isCancelled
            ? TonikErrorType.cancelled
            : TonikErrorType.network,
      ).toList();
      final failure = items.single as TonikError<Object?, String>;
      expect(failure.error, same(error));
      expect(failure.stackTrace, same(stack));
      expect(failure.type, TonikErrorType.network);
      expect(cancellation.reason, same(error));
    },
  );

  test(
    'pending cancellation is classified before listening and cleanup',
    () async {
      final cancellation = TonikCancellation()..cancel();
      final error = StateError('aborted');
      final stream = decodeResponseStream(
        Stream<List<int>>.error(error),
        decodeNdjson,
        (value) => value,
        cancellation: cancellation,
        response: 'response',
        sourceErrorType: (_) => cancellation.isCancelled
            ? TonikErrorType.cancelled
            : TonikErrorType.network,
      );
      final failure =
          (await stream.toList()).single as TonikError<Object?, String>;
      expect(failure.error, same(error));
      expect(failure.type, TonikErrorType.cancelled);
    },
  );

  test(
    'subscription cancellation contains cleanup failure without more events',
    () async {
      final cancellation = TonikCancellation();
      final source = StreamController<List<int>>(
        onCancel: () => Future<void>.error(StateError('cleanup')),
      );
      final items = <TonikResult<Object?, String>>[];
      final subscription = decodeResponseStream(
        source.stream,
        decodeNdjson,
        (value) => value,
        cancellation: cancellation,
        response: 'response',
        sourceErrorType: (_) => TonikErrorType.network,
      ).listen(items.add);
      await expectLater(subscription.cancel(), completes);
      source.add(utf8.encode('1\n'));
      await source.close();
      expect(items, isEmpty);
      expect(cancellation.isCancelled, isTrue);
    },
  );

  test('decoding failure survives failing source cleanup', () async {
    final source = StreamController<List<int>>(
      onCancel: () => Future<void>.error(StateError('cleanup')),
    );
    final items = decodeResponseStream(
      source.stream,
      decodeNdjson,
      (value) => value,
      cancellation: TonikCancellation(),
      response: 'response',
      sourceErrorType: (_) => TonikErrorType.network,
    ).toList();
    source.add(utf8.encode('invalid\n'));
    final failure = (await items).single as TonikError<Object?, String>;
    expect(failure.error, isA<FormatException>());
    expect(failure.type, TonikErrorType.decoding);
    await source.close();
  });

  test('request cancellation suppresses buffered successful items', () async {
    final cancellation = TonikCancellation();
    final source = StreamController<List<int>>();
    final stream = decodeResponseStream(
      source.stream,
      decodeNdjson,
      (value) => value,
      cancellation: cancellation,
      response: 'response',
      sourceErrorType: (_) => TonikErrorType.network,
    );
    final items = stream.toList();
    source.add(utf8.encode('1\n'));
    cancellation.cancel();
    await source.close();
    expect(await items, isEmpty);
  });

  test('pause prevents conversion until resumed', () async {
    final source = StreamController<List<int>>();
    final converted = <Object?>[];
    final values = <Object?>[];
    final first = Completer<void>();
    late StreamSubscription<TonikResult<Object?, String>> subscription;
    subscription =
        decodeResponseStream(
          source.stream,
          decodeNdjson,
          (value) {
            converted.add(value);
            return value;
          },
          cancellation: TonikCancellation(),
          response: 'response',
          sourceErrorType: (_) => TonikErrorType.network,
        ).listen((result) {
          final value = (result as TonikSuccess<Object?, String>).value;
          values.add(value);
          if (value == 1) {
            subscription.pause();
            first.complete();
          }
        });
    source.add(utf8.encode('1\n2\n'));
    await first.future;
    await Future<void>.delayed(Duration.zero);
    expect(converted, [1]);
    expect(values, [1]);
    subscription.resume();
    await source.close();
    expect(converted, [1, 2]);
    expect(values, [1, 2]);
    await subscription.cancel();
  });
}
