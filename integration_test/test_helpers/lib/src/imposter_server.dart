import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Fast JVM cold-start flags. Start-up latency dominates over peak throughput
/// for these fixture servers: C1-only JIT and the
/// serial collector shave seconds off boot for these short-lived servers.
const _fastStartJvmArgs = ['-XX:TieredStopAtLevel=1', '-XX:+UseSerialGC'];

/// A request observed by Imposter at the HTTP server boundary.
final class const RecordedRequest(
  final Uri uri,
  final String method,
  final Map<String, String> headers,
  final String? body,
);

/// Manages the lifecycle of an Imposter mock server for integration
/// tests.
class ImposterServer({final int? sharedPort}) {
  Process? _process;
  int _port = sharedPort ?? 0;
  Completer<void> _readyCompleter = Completer<void>();
  bool _stopRequested = false;

  int get port => _port;

  /// Clears all request state before a sequential test file uses a shared JVM.
  Future<void> resetRequests() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.deleteUrl(
        Uri.parse('http://localhost:$_port/system/store/tonik'),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      await response.drain<void>().timeout(const Duration(seconds: 5));
      if (response.statusCode != HttpStatus.noContent) {
        throw StateError(
          'Unable to reset Imposter request state: ${response.statusCode}',
        );
      }
    } finally {
      client.close(force: true);
    }
  }

  /// Returns and removes the last request recorded by the Imposter fixture.
  Future<RecordedRequest> takeRequest() async {
    final storeUri = Uri.parse(
      'http://localhost:$_port/system/store/tonik/last',
    );
    final client = HttpClient();
    try {
      final getRequest = await client.getUrl(storeUri);
      final getResponse = await getRequest.close();
      final payload = await utf8.decoder.bind(getResponse).join();
      if (getResponse.statusCode != HttpStatus.ok) {
        throw StateError(
          'Unable to read the recorded request: '
          '${getResponse.statusCode} $payload',
        );
      }

      final deleteRequest = await client.deleteUrl(storeUri);
      final deleteResponse = await deleteRequest.close();
      await deleteResponse.drain<void>();
      if (deleteResponse.statusCode < HttpStatus.ok ||
          deleteResponse.statusCode >= HttpStatus.multipleChoices) {
        throw StateError(
          'Unable to delete the recorded request: '
          '${deleteResponse.statusCode}',
        );
      }

      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException(
          'Recorded request is not a JSON object.',
          payload,
        );
      }
      final uri = decoded['uri'];
      final method = decoded['method'];
      final rawHeaders = decoded['normalisedHeaders'];
      final body = decoded['body'];
      if (uri is! String ||
          method is! String ||
          rawHeaders is! Map<String, dynamic> ||
          body is! String?) {
        throw FormatException(
          'Recorded request has an unexpected shape.',
          payload,
        );
      }

      return RecordedRequest(
        Uri.parse(uri),
        method,
        Map.unmodifiable({
          for (final entry in rawHeaders.entries)
            entry.key.toLowerCase(): switch (entry.value) {
              Iterable<Object?> values => values.join(','),
              final value => '$value',
            },
        }),
        body,
      );
    } finally {
      client.close(force: true);
    }
  }

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
    List<String> jvmArgs = _fastStartJvmArgs,
  }) async {
    if (sharedPort != null) {
      await resetRequests();
      return;
    }
    _stopRequested = false;
    _readyCompleter = Completer<void>();
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
        await _stopProcess();
        if (_stopRequested) rethrow;
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
    if (_stopRequested) throw Exception('Imposter startup was cancelled.');

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
      environment: {...Platform.environment, 'IMPOSTER_LOG_LEVEL': 'INFO'},
    );

    if (_stopRequested) {
      await stop();
      throw Exception('Imposter startup was cancelled.');
    }

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
    if (!ready || _stopRequested) {
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
    if (_stopRequested) return false;

    // Then verify the server is actually responding
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);

    try {
      while (DateTime.now().isBefore(deadline) && !_stopRequested) {
        try {
          final request = await client
              .getUrl(Uri.parse('http://localhost:$_port'))
              .timeout(const Duration(seconds: 5));
          final response = await request.close().timeout(
            const Duration(seconds: 5),
          );
          await response.drain<void>().timeout(const Duration(seconds: 5));

          return true; // Server is ready and responding
        } on SocketException catch (_) {
          // ignore
        } on HttpException catch (_) {
          // ignore
        } on TimeoutException {
          return false;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Stops the Imposter server process.
  ///
  /// Kills the process and waits for it to exit. Safe to call multiple times.
  Future<void> stop() async {
    _stopRequested = true;
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    await _stopProcess();
  }

  Future<void> _stopProcess() async {
    final process = _process;
    if (process != null) {
      process.kill();
      try {
        await process.exitCode.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
        await process.exitCode;
      }
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
  List<String> jvmArgs = _fastStartJvmArgs,
}) async {
  final sharedPort = sharedImposterPort(
    Platform.environment,
    Directory.current.path,
  );
  final server = ImposterServer(sharedPort: sharedPort);
  await server.start(
    timeoutSec: timeoutSec,
    maxAttempts: maxAttempts,
    jvmArgs: jvmArgs,
  );
  addTearDown(() => server.stop());
  return server;
}

/// Accepts a run-owned server only for its matching package.
int? sharedImposterPort(Map<String, String> environment, String directory) {
  final rawPort = environment['TONIK_IMPOSTER_PORT'];
  if (rawPort == null) return null;
  final port = int.tryParse(rawPort);
  if (port == null ||
      port < 1 ||
      port > 65535 ||
      environment['TONIK_IMPOSTER_PACKAGE'] != path.normalize(directory)) {
    throw StateError('Invalid shared Imposter server configuration.');
  }
  return port;
}
