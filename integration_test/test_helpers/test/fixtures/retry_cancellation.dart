import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_helpers/src/imposter_server.dart';

void main() {
  test('do not retry when cancelled during process cleanup', () async {
    final server = ImposterServer();
    addTearDown(server.stop);
    final starting = expectLater(server.start(timeoutSec: 1), throwsException);
    final stopping = File(Platform.environment['TONIK_TEST_STOPPING']!);
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!stopping.existsSync() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(stopping.existsSync(), isTrue);
    await server.stop();
    await starting;
  });
}
