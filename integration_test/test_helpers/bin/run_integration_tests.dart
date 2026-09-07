import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test_helpers/src/imposter_server.dart';

/// Runs complete packages in one process, owning one fresh JVM at a time.
Future<void> main(List<String> arguments) async {
  final separator = arguments.indexOf('--');
  final packageArguments = separator < 0
      ? arguments
      : arguments.take(separator);
  final testArguments = separator < 0
      ? <String>[]
      : arguments.skip(separator + 1).toList();
  if (packageArguments.isEmpty) {
    stderr.writeln(
      'Usage: run_integration_tests.dart <package>... [-- <dart test arguments>...]',
    );
    exitCode = 64;
    return;
  }

  final initialDirectory = Directory.current;
  final packages = [
    for (final package in packageArguments)
      path.normalize(path.absolute(package)),
  ];
  try {
    for (final package in packages) {
      Directory.current = package;
      stdout.writeln(
        'Testing ${path.relative(package, from: initialDirectory.path)}',
      );
      await _runPackage(testArguments);
      if (exitCode != 0) return;
    }
  } finally {
    Directory.current = initialDirectory;
  }
}

/// Runs the current package with serial files and cleans up before returning.
Future<void> _runPackage(List<String> arguments) async {
  final server = ImposterServer();
  Process? tests;
  var cancelled = false;
  Future<void>? stopping;

  Future<void> cancel() => stopping ??= () async {
    cancelled = true;
    exitCode = 130;
    final child = tests;
    if (child != null) {
      child.kill(
        Platform.isWindows ? ProcessSignal.sigterm : ProcessSignal.sigint,
      );
      try {
        await child.exitCode.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        child.kill(ProcessSignal.sigkill);
        await child.exitCode;
      }
    }
    await server.stop();
  }();

  final interrupt = ProcessSignal.sigint.watch().listen(
    (_) => unawaited(cancel()),
  );
  final terminate = Platform.isWindows
      ? null
      : ProcessSignal.sigterm.watch().listen((_) => unawaited(cancel()));
  final environment = <String, String>{};
  final elapsed = Stopwatch()..start();
  try {
    if (Directory('imposter').existsSync()) {
      await server.start();
      if (cancelled) return;
      environment.addAll({
        'TONIK_IMPOSTER_PORT': '${server.port}',
        'TONIK_IMPOSTER_PACKAGE': path.normalize(Directory.current.path),
      });
      stdout.writeln('Imposter started in ${elapsed.elapsedMilliseconds}ms');
    }
    tests = await Process.start(
      Platform.resolvedExecutable,
      ['test', ...arguments, '--concurrency=1'],
      environment: environment,
      mode: ProcessStartMode.inheritStdio,
    );
    if (cancelled) tests.kill();
    final result = await tests.exitCode;
    if (!cancelled) {
      exitCode = result;
      stdout.writeln(
        'Tests finished in ${elapsed.elapsedMilliseconds}ms (exit $result)',
      );
    }
  } on Object {
    if (!cancelled) rethrow;
  } finally {
    await stopping;
    await server.stop();
    await interrupt.cancel();
    await terminate?.cancel();
  }
}
