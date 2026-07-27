import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('TonikCancellation', () {
    test('starts active without a reason', () {
      final cancellation = TonikCancellation();

      expect(cancellation.isCancelled, isFalse);
      expect(cancellation.reason, isNull);
    });

    test('cancels without a reason', () async {
      final cancellation = TonikCancellation();
      final whenCancelled = cancellation.whenCancelled;

      cancellation.cancel();
      await whenCancelled;

      expect(cancellation.isCancelled, isTrue);
      expect(cancellation.reason, isNull);
    });

    test('retains the cancellation reason by identity', () async {
      final cancellation = TonikCancellation();
      final reason = Object();

      cancellation.cancel(reason);
      await cancellation.whenCancelled;

      expect(cancellation.isCancelled, isTrue);
      expect(cancellation.reason, same(reason));
    });

    test('only the first cancellation has an effect', () async {
      final cancellation = TonikCancellation();
      final firstReason = Object();
      final secondReason = Object();
      final whenCancelled = cancellation.whenCancelled;
      var completionCount = 0;
      final countedCompletion = whenCancelled.then((_) {
        completionCount++;
      });

      cancellation
        ..cancel(firstReason)
        ..cancel(secondReason);
      await countedCompletion;

      expect(cancellation.reason, same(firstReason));
      expect(cancellation.whenCancelled, same(whenCancelled));
      expect(completionCount, 1);
    });

    test('an initial null reason cannot be replaced', () async {
      final cancellation = TonikCancellation();

      final whenCancelled =
          (cancellation
                ..cancel()
                ..cancel(Object()))
              .whenCancelled;
      await whenCancelled;

      expect(cancellation.reason, isNull);
    });
  });

  test('implementation is backend-neutral', () async {
    final libraryUri = await Isolate.resolvePackageUri(
      Uri.parse('package:tonik_util/tonik_util.dart'),
    );
    final source = File.fromUri(
      libraryUri!.resolve('src/tonik_cancellation.dart'),
    ).readAsStringSync();

    expect(source, isNot(contains("import 'package:dio/")));
    expect(source, isNot(contains("import 'package:http/")));
  });
}
