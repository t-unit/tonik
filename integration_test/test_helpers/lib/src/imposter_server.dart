import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Manages the lifecycle of an Imposter mock server for integration
/// tests.
class ImposterServer {
  ImposterServer();

  Process? _process;
  int _port = 0;
  Completer<void> _readyCompleter = Completer<void>();

  int get port => _port;

  /// Finds an available port by binding to port 0 and immediately closing.
  static Future<int> _findAvailablePort() async {
    final serverSocket = await ServerSocket.bind('127.0.0.1', 0);
    final port = serverSocket.port;
    await serverSocket.close();
    return port;
  }

  /// Starts the Imposter server and waits for it to be ready.
  ///
  /// Each attempt waits up to [timeoutSec] seconds for the JVM/Imposter
  /// plugins to come up. If an attempt times out we kill the (potentially
  /// hung) process and retry on a fresh port, up to [maxAttempts] times.
  /// JVMs running concurrent integration suites occasionally hang during
  /// cold start; retrying recovers without paying the full timeout per
  /// stuck process.
  ///
  /// Throws an [Exception] if imposter.jar cannot be found, or if every
  /// attempt times out.
  Future<void> start({
    int timeoutSec = 90,
    int maxAttempts = 2,
    List<String> jvmArgs = const [],
  }) async {
    final imposterJar = path.join(
      Directory.current.parent.parent.path,
      'imposter.jar',
    );

    if (!File(imposterJar).existsSync()) {
      throw Exception(
        'Imposter JAR not found at $imposterJar. Please download it first.',
      );
    }

    Exception? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _startOnce(
          imposterJar: imposterJar,
          jvmArgs: jvmArgs,
          timeoutSec: timeoutSec,
        );
        return;
      } on Exception catch (e) {
        lastError = e;
        _process?.kill();
        _process = null;
        _readyCompleter = Completer<void>();
        if (attempt < maxAttempts) {
          print(
            'Imposter start attempt $attempt/$maxAttempts failed: $e. '
            'Retrying on a fresh port...',
          );
        }
      }
    }
    throw lastError!;
  }

  Future<void> _startOnce({
    required String imposterJar,
    required List<String> jvmArgs,
    required int timeoutSec,
  }) async {
    _port = await _findAvailablePort();

    _process = await Process.start(
      'java',
      [
        ...jvmArgs,
        '-jar',
        imposterJar,
        '--listenPort',
        _port.toString(),
        '--configDir',
        path.join(Directory.current.path, 'imposter'),
        '--plugin',
        'openapi',
        '--plugin',
        'rest',
      ],
      environment: {
        ...Platform.environment,
        'IMPOSTER_LOG_LEVEL': 'INFO',
      },
    );

    _process!.stdout.transform(const Utf8Decoder()).listen((data) {
      // Signal readiness when we see the startup message.
      if (data.contains('Mock engine up and running') &&
          !_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    });
    _process!.stderr.transform(const Utf8Decoder()).listen((data) {
      print(data);
    });

    final ready = await _waitForImposterReady(timeoutSec: timeoutSec);
    if (!ready) {
      throw Exception(
        'Imposter server failed to start within $timeoutSec seconds '
        'on port $_port. Check Java/Imposter logs above for details.',
      );
    }
  }

  /// Waits for the Imposter server to be fully ready.
  ///
  /// This uses a multi-step approach to handle the race condition where
  /// the server port is open but the OpenAPI plugin isn't fully initialized:
  /// 1. Wait for the stdout "Mock engine up and running" message
  /// 2. Add a 500ms delay for OpenAPI plugin initialization
  /// 3. Verify the server responds to HTTP requests (up to 5s)
  ///
  /// Returns `true` if the server is ready, `false` if timeout occurs.
  Future<bool> _waitForImposterReady({int timeoutSec = 30}) async {
    try {
      await _readyCompleter.future.timeout(Duration(seconds: timeoutSec));
    } on TimeoutException {
      print('Timeout waiting for Imposter startup message');
      return false;
    }

    // Add a small delay to allow OpenAPI plugin to fully initialize
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Then verify the server is actually responding
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    final client = HttpClient();

    while (DateTime.now().isBefore(deadline)) {
      try {
        final request = await client.getUrl(
          Uri.parse('http://localhost:$_port'),
        );
        final response = await request.close();
        await response.drain<void>();

        return true; // Server is ready and responding
      } on SocketException catch (_) {
        // ignore
      } on HttpException catch (_) {
        // ignore
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  /// Stops the Imposter server process.
  ///
  /// Kills the process and waits for it to exit. Safe to call multiple times.
  Future<void> stop() async {
    if (_process != null) {
      _process!.kill();
      await _process!.exitCode;
      _process = null;
    }
  }
}

/// Sets up an Imposter server for tests.
///
/// Finds an available port dynamically (safe for parallel execution).
///
/// Returns the [ImposterServer] instance with the actual port assigned.
Future<ImposterServer> setupImposterServer({
  int timeoutSec = 90,
  int maxAttempts = 2,
  List<String> jvmArgs = const [],
}) async {
  final server = ImposterServer();
  await server.start(
    timeoutSec: timeoutSec,
    maxAttempts: maxAttempts,
    jvmArgs: jvmArgs,
  );
  addTearDown(() => server.stop());
  return server;
}
