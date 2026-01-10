import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class ImposterServer {
  ImposterServer({required this.port});

  Process? _process;
  final int port;

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
      environment: {...Platform.environment, 'IMPOSTER_LOG_LEVEL': 'DEBUG'},
    );

    _process!.stdout.transform(const Utf8Decoder()).listen((data) {
      print('Imposter stdout: $data');
    });
    _process!.stderr.transform(const Utf8Decoder()).listen((data) {
      print('Imposter stderr: $data');
    });

    await _waitForImposterReady();
  }

  Future<bool> _waitForImposterReady({int timeoutSec = 15}) async {
    final deadline = DateTime.now().add(Duration(seconds: timeoutSec));
    final client = HttpClient();

    while (DateTime.now().isBefore(deadline)) {
      try {
        final request = await client.getUrl(
          Uri.parse('http://localhost:$port/system/status'),
        );
        final response = await request.close();

        if (response.statusCode == 200) {
          print('Imposter is ready on port $port');
          return true;
        }
      } on SocketException catch (_) {
        // ignore
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    throw Exception('Imposter server did not become ready in time');
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
