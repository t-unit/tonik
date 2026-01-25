import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class ImposterServer {
  ImposterServer({required this.port});

  Process? _process;
  final int port;
  final Completer<void> _readyCompleter = Completer<void>();

  Future<void> start() async {
    final imposterJar = path.join(
      Directory.current.parent.parent.path,
      'imposter.jar',
    );

    if (!File(imposterJar).existsSync()) {
      throw Exception(
        'Imposter JAR not found at $imposterJar. Please download it first.',
      );
    }

    _process = await Process.start(
      'java',
      [
        '-jar',
        imposterJar,
        '--listenPort',
        port.toString(),
        '--configDir',
        path.join(Directory.current.path, 'imposter'),
        '--plugin',
        'openapi',
        '--plugin',
        'rest',
      ],
      environment: {
        ...Platform.environment,
        'IMPOSTER_LOG_LEVEL': 'DEBUG',
      },
    );

    _process!.stdout.transform(const Utf8Decoder()).listen((data) {
      print('Imposter stdout: $data');
      // Signal readiness when we see the startup message
      if (data.contains('Mock engine up and running') &&
          !_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    });
    _process!.stderr.transform(const Utf8Decoder()).listen((data) {
      print('Imposter stderr: $data');
    });

    await _waitForImposterReady();
  }

  Future<bool> _waitForImposterReady({int timeoutSec = 30}) async {
    // First, wait for the startup message in stdout
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
          Uri.parse('http://localhost:$port'),
        );
        final response = await request.close();
        await response.drain<void>();

        return true; // Server is ready and responding
      } on SocketException catch (_) {
        // ignore
      } on HttpException catch (_) {
        // ignore
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return false;
  }

  Future<void> stop() async {
    if (_process != null) {
      _process!.kill();
      await _process!.exitCode;
      _process = null;
    }
  }
}

Future<void> setupImposterServer(ImposterServer server) async {
  await server.start();
  addTearDown(() => server.stop());
}
