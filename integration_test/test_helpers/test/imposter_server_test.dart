import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_helpers/src/imposter_server.dart';

void main() {
  test('ordinary test runs do not attach to a shared server', () {
    expect(sharedImposterPort({}, '/fixture'), isNull);
  });

  test('a matching package can attach', () {
    expect(
      sharedImposterPort({
        'TONIK_IMPOSTER_PORT': '8123',
        'TONIK_IMPOSTER_PACKAGE': path.normalize('/fixture'),
      }, '/fixture'),
      8123,
    );
  });

  test('a different package cannot attach', () {
    expect(
      () => sharedImposterPort({
        'TONIK_IMPOSTER_PORT': '8123',
        'TONIK_IMPOSTER_PACKAGE': path.normalize('/other'),
      }, '/fixture'),
      throwsStateError,
    );
  });

  test('shared setup refuses a failed state reset', () async {
    final http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => http.close(force: true));
    http.listen((request) async {
      expect(request.method, 'DELETE');
      expect(request.uri.path, '/system/store/tonik');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    });
    final server = ImposterServer(sharedPort: http.port);
    await expectLater(server.start(), throwsStateError);
  });

  test(
    'wrapper forces serial files and resets the shared JVM between them',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'imposter-reuse-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final fixture = path.join(
        Directory.current.parent.path,
        'simple_encoding',
        'simple_encoding_test',
      );
      final result = await Process.run(
        Platform.resolvedExecutable,
        [
          path.join(
            Directory.current.path,
            'bin',
            'run_integration_tests.dart',
          ),
          fixture,
          '--',
          path.join(
            Directory.current.path,
            'test',
            'fixtures',
            'reuse_first.dart',
          ),
          path.join(
            Directory.current.path,
            'test',
            'fixtures',
            'reuse_second.dart',
          ),
          '--reporter=expanded',
          '--concurrency=2',
        ],
        environment: {
          'TONIK_TEST_PORT_FILE': path.join(temporary.path, 'port'),
        },
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('+2: All tests passed!'));
      final port = int.parse(
        await File(path.join(temporary.path, 'port')).readAsString(),
      );
      await expectLater(
        Socket.connect('localhost', port),
        throwsA(isA<SocketException>()),
      );
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test('one file still runs directly with a private server', () async {
    final fixture = path.join(
      Directory.current.parent.path,
      'simple_encoding',
      'simple_encoding_test',
    );
    final result = await Process.run(Platform.resolvedExecutable, [
      'test',
      path.join(Directory.current.path, 'test', 'fixtures', 'standalone.dart'),
      '--plain-name',
      'start a private server for a direct test invocation',
      '--reporter=expanded',
    ], workingDirectory: fixture);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('+1: All tests passed!'));
  }, timeout: const Timeout(Duration(seconds: 60)));

  test(
    'cancelling during failed-start cleanup prevents another JVM attempt',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'imposter-retry-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final java = File(path.join(temporary.path, 'java'));
      await java.writeAsString(r'''#!/bin/sh
printf 'start\n' >> "$TONIK_TEST_STARTS"
trap 'touch "$TONIK_TEST_STOPPING"; sleep 1; exit 0' TERM
while :; do sleep 0.05; done
''');
      expect((await Process.run('chmod', ['+x', java.path])).exitCode, 0);
      final result = await Process.run(
        Platform.resolvedExecutable,
        [
          'test',
          path.join(
            Directory.current.path,
            'test',
            'fixtures',
            'retry_cancellation.dart',
          ),
          '--reporter=expanded',
        ],
        workingDirectory: path.join(
          Directory.current.parent.path,
          'simple_encoding',
          'simple_encoding_test',
        ),
        environment: {
          'PATH': '${temporary.path}:${Platform.environment['PATH']}',
          'TONIK_TEST_STARTS': path.join(temporary.path, 'starts'),
          'TONIK_TEST_STOPPING': path.join(temporary.path, 'stopping'),
        },
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(
        await File(path.join(temporary.path, 'starts')).readAsString(),
        'start\n',
      );
    },
    skip: Platform.isWindows
        ? 'This regression requires POSIX process signals.'
        : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test('runner preserves a failing test exit status', () async {
    final fixture = path.join(
      Directory.current.parent.path,
      'simple_encoding',
      'simple_encoding_test',
    );
    final result = await Process.run(Platform.resolvedExecutable, [
      path.join(Directory.current.path, 'bin', 'run_integration_tests.dart'),
      fixture,
      '.',
      '--',
      path.join(Directory.current.path, 'test', 'fixtures', 'failure.dart'),
      '--reporter=expanded',
    ]);
    expect(result.exitCode, 1);
    expect(result.stdout, contains('intentional runner failure'));
    expect(result.stdout, isNot(contains('\nTesting .\n')));
  }, timeout: const Timeout(Duration(seconds: 60)));

  test(
    'cancelling a run stops its owned server',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'imposter-cancel-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final fixture = path.join(
        Directory.current.parent.path,
        'simple_encoding',
        'simple_encoding_test',
      );
      final runner = await Process.start(
        Platform.resolvedExecutable,
        [
          path.join(
            Directory.current.path,
            'bin',
            'run_integration_tests.dart',
          ),
          fixture,
          '--',
          path.join(Directory.current.path, 'test', 'fixtures', 'hold.dart'),
          '--reporter=expanded',
        ],
        environment: {
          'TONIK_TEST_PORT_FILE': path.join(temporary.path, 'port'),
        },
      );
      addTearDown(() async {
        runner.kill(ProcessSignal.sigterm);
        await runner.exitCode;
      });
      final errors = runner.stderr.transform(utf8.decoder).join();
      final ready = Completer<void>();
      final output = runner.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (line.contains('READY TO CANCEL') && !ready.isCompleted) {
              ready.complete();
            }
          });
      addTearDown(output.cancel);
      await ready.future.timeout(const Duration(seconds: 30));
      final port = int.parse(
        await File(path.join(temporary.path, 'port')).readAsString(),
      );
      runner.kill(ProcessSignal.sigterm);
      expect(
        await runner.exitCode.timeout(const Duration(seconds: 15)),
        130,
        reason: await errors,
      );
      await expectLater(
        Socket.connect('localhost', port),
        throwsA(isA<SocketException>()),
      );
    },
    skip: Platform.isWindows
        ? 'Process.kill does not deliver console signals on Windows.'
        : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test('relative package paths resolve before changing directories', () async {
    final result = await Process.run(Platform.resolvedExecutable, [
      'bin/run_integration_tests.dart',
      '../../packages/tonik_core',
      '.',
      '--',
      '--help',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('tonik_core\n'));
    expect(result.stdout, contains('\nTesting .\n'));
  }, timeout: const Timeout(Duration(seconds: 60)));
}
