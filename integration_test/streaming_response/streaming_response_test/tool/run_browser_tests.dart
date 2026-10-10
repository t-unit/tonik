import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final String backend;
  if (File('../streaming_response_api/lib/src/operation/http_operation.dart')
      .existsSync()) {
    backend = 'http';
  } else if (File(
    '../streaming_response_api/lib/src/operation/dio_operation.dart',
  ).existsSync()) {
    backend = 'dio';
  } else {
    stderr.writeln('Run scripts/setup_integration_tests.sh first.');
    exitCode = 64;
    return;
  }

  final host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final fixture = _ResponseFixture();
  final requests = host.listen(fixture.handle);
  final origin = 'http://localhost:${host.port}';
  stdout.writeln('Browser streaming tests: backend=$backend origin=$origin');
  Process? tests;
  try {
    tests = await Process.start(Platform.resolvedExecutable, [
      'test',
      '--platform',
      'chrome',
      '--concurrency',
      '1',
      '--timeout',
      '30s',
      '--dart2js-args=-DSTREAMING_TEST_ORIGIN=$origin',
      'browser/${backend}_streaming_test.dart',
    ], mode: ProcessStartMode.inheritStdio);
    exitCode = await tests.exitCode.timeout(const Duration(minutes: 3));
  } on TimeoutException {
    stderr.writeln('Browser streaming tests exceeded three minutes.');
    exitCode = 1;
  } finally {
    tests?.kill();
    await host.close(force: true).timeout(const Duration(seconds: 5));
    await requests.cancel();
  }
}

final class _ResponseFixture {
  var _received = Completer<HttpResponse>();
  String _contentType = 'application/x-ndjson';
  String _initial = '\n';
  bool _eof = false;

  Future<void> handle(HttpRequest request) async {
    request.response.headers
      ..set('access-control-allow-origin', '*')
      ..set('access-control-expose-headers', 'x-count')
      ..set('access-control-allow-methods', 'GET, POST, OPTIONS')
      ..set('access-control-allow-headers', 'content-type');
    if (request.method == 'OPTIONS') {
      await request.response.close();
      return;
    }
    try {
      if (request.uri.path.startsWith('/control/')) {
        await _control(request);
        await request.response.close();
      } else {
        request.response
          ..bufferOutput = false
          ..headers.set('content-type', _contentType)
          ..headers.set('x-count', '2')
          ..write(_initial);
        await request.response.flush();
        _received.complete(request.response);
      }
    } on Object catch (error, stackTrace) {
      stderr.writeln('$error\n$stackTrace');
      request.response
        ..statusCode = 500
        ..write('$error');
      await request.response.close();
    }
  }

  Future<void> _control(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final data = body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(body) as Map<String, dynamic>;
    switch (request.uri.path) {
      case '/control/start':
        if (_received.isCompleted && !_eof) {
          final response = await _received.future;
          await response.close().timeout(const Duration(seconds: 5));
        }
        _received = Completer<HttpResponse>();
        _contentType = data['contentType'] as String;
        _initial = data['initial'] as String;
        _eof = false;
      case '/control/wait':
        await _received.future.timeout(const Duration(seconds: 5));
      case '/control/write':
        final response = await _received.future;
        response.write(data['bytes'] as String);
        await response.flush();
      case '/control/finish':
        final response = await _received.future;
        await response.close();
        _eof = true;
      case '/control/state':
        request.response.write(jsonEncode({'eof': _eof}));
      default:
        throw StateError('Unknown control path: ${request.uri.path}');
    }
  }
}
