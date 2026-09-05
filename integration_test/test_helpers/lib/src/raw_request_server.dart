import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

/// The raw request body and transport metadata received by a local HTTP server.
final class const RawRequest({
  required final Uri uri,
  required final String method,
  required final Map<String, List<String>> headers,
  required final Uint8List bodyBytes,
}) {
  String? header(String name) => headers[name.toLowerCase()]?.join(',');

  String get bodyText => latin1.decode(bodyBytes);
}

/// A one-request HTTP server for assertions that require raw body bytes.
final class RawRequestServer._(
  final HttpServer _server,
  final Future<RawRequest> _request,
) {
  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<RawRequestServer> start({
    int responseStatusCode = HttpStatus.noContent,
    Map<String, String> responseHeaders = const {},
    List<int> responseBody = const [],
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requestCompleter = Completer<RawRequest>();

    server.listen((request) async {
      final bodyBytes = await request.fold<List<int>>(
        <int>[],
        (bytes, chunk) => bytes..addAll(chunk),
      );
      final headers = <String, List<String>>{};
      request.headers.forEach((name, values) {
        headers[name.toLowerCase()] = List.unmodifiable(values);
      });
      requestCompleter.complete(
        RawRequest(
          uri: request.requestedUri,
          method: request.method,
          headers: Map.unmodifiable(headers),
          bodyBytes: Uint8List.fromList(bodyBytes),
        ),
      );

      request.response.statusCode = responseStatusCode;
      for (final entry in responseHeaders.entries) {
        request.response.headers.set(entry.key, entry.value);
      }
      request.response.add(responseBody);
      await request.response.close();
    });

    final rawServer = RawRequestServer._(server, requestCompleter.future);
    addTearDown(rawServer.close);
    return rawServer;
  }

  Future<RawRequest> takeRequest() => _request;

  Future<void> close() => _server.close(force: true);
}
