import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Fast JVM cold-start flags. Each suite spins up a fresh JVM in `setUpAll`,
/// so start-up latency dominates over peak throughput: C1-only JIT and the
/// serial collector shave seconds off boot for these short-lived servers.
const _fastStartJvmArgs = ['-XX:TieredStopAtLevel=1', '-XX:+UseSerialGC'];

/// A request observed by Imposter at the HTTP server boundary.
final class RecordedRequest {
  const RecordedRequest(this.uri, this.method, this.headers, this.body);

  final Uri uri;
  final String method;
  final Map<String, String> headers;
  final String? body;
}

/// Manages the lifecycle of an Imposter mock server for integration
/// tests.
class ImposterServer {
  ImposterServer();

  Process? _process;
  int _port = 0;
  Completer<void> _readyCompleter = Completer<void>();

  int get port => _port;

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
            'Recorded request is not a JSON object.', payload);
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
  List<String> jvmArgs = _fastStartJvmArgs,
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
