import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Helper class to manage Imposter server lifecycle
class ImposterServer {
  ImposterServer({required this.port});

  final int port;
  Process? _process;

  Future<void> start() async {
    final imposterJar = path.join(
      Directory.current.path,
      '..',
      '..',
      'imposter.jar',
    );

    if (!File(imposterJar).existsSync()) {
      throw Exception('Imposter JAR not found at $imposterJar');
    }

    final configDir = path.join(Directory.current.path, 'imposter');

    _process = await Process.start(
      'java',
      [
        '-jar',
        imposterJar,
        '--configDir',
        configDir,
        '--listenPort',
        port.toString(),
      ],
    );

    // Wait for server to be ready
    await _waitForServer();
  }

  Future<void> _waitForServer() async {
    const maxAttempts = 30;
    const delayBetweenAttempts = Duration(milliseconds: 500);

    for (var i = 0; i < maxAttempts; i++) {
      try {
        final socket = await Socket.connect(
          'localhost',
          port,
        ).timeout(const Duration(seconds: 1));
        await socket.close();
        return;
      } on Exception catch (_) {
        await Future<void>.delayed(delayBetweenAttempts);
      }
    }

    throw Exception('Imposter server failed to start within timeout');
  }

  Future<void> stop() async {
    _process?.kill();
    _process = null;
  }
}

/// Sets up the Imposter server for tests
Future<void> setupImposterServer(ImposterServer server) async {
  await server.start();
}

/// Tears down the Imposter server after tests
Future<void> teardownImposterServer(ImposterServer server) async {
  await server.stop();
}
