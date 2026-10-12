import 'dart:async';
import 'dart:io';

// Imposter completes each response at once. These gates let the timing tests
// hold EOF open after flushing headers or individual items to real clients.
final class ControlledResponse {
  new _(this._host, this._contentType, this._initial, this._headers) {
    _requests = _host.listen((request) {
      unawaited(_handle(request));
    });
  }

  static Future<ControlledResponse> bind({
    required String contentType,
    String initial = '\n',
    Map<String, String> headers = const {},
  }) async => ControlledResponse._(
    await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    contentType,
    initial,
    headers,
  );

  static const _deadline = Duration(seconds: 5);
  final HttpServer _host;
  late final StreamSubscription<HttpRequest> _requests;
  final _received = Completer<HttpRequest>();
  final String _contentType;
  final String _initial;
  final Map<String, String> _headers;
  (Object, StackTrace)? _failure;
  bool reachedEof = false;

  String get baseUrl => 'http://localhost:${_host.port}';

  Future<HttpRequest> waitForRequest() => _received.future.timeout(_deadline);

  Future<void> write(String bytes) async {
    final response = (await waitForRequest()).response;
    await (response..write(bytes)).flush().timeout(_deadline);
  }

  Future<void> finish() async {
    final response = (await waitForRequest()).response;
    await response.close().timeout(_deadline);
    reachedEof = true;
  }

  Future<void> close() async {
    try {
      await _host.close(force: true).timeout(_deadline);
    } finally {
      await _requests.cancel();
    }
    if (_failure case (final error, final stackTrace)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _handle(HttpRequest request) async {
    var responseStarted = false;
    try {
      request.response
        ..bufferOutput = false
        ..headers.set('content-type', _contentType);
      _headers.forEach(request.response.headers.set);
      responseStarted = true;
      request.response.write(_initial);
      await request.response.flush().timeout(_deadline);
      _received.complete(request);
    } on Object catch (error, stackTrace) {
      // Defer the failure until teardown can release the server, rather than
      // letting an unhandled request future escape the test.
      _failure ??= (error, stackTrace);
      stderr.writeln('$error\n$stackTrace');
      try {
        if (!responseStarted) {
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..write('$error');
        }
        await request.response.close().timeout(_deadline);
      } on Object catch (closeError, closeStackTrace) {
        stderr.writeln('$closeError\n$closeStackTrace');
      }
    }
  }
}
