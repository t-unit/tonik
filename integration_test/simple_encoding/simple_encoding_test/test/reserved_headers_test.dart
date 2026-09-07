import 'dart:convert';

import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('ignores required reserved headers and sends wildcard Accept', () async {
    final server = await RawRequestServer.start();
    final api = SimpleEncodingApi(CustomServer(baseUrl: server.baseUrl));

    final result = await api.testReservedHeadersNoContent();

    final success = requireSuccess(result);
    expect(success.response.statusCode, 204);
    final request = await server.takeRequest();
    expect(request.method, 'GET');
    expect(request.uri.path, '/headers/reserved/no-content');
    expect(request.header('Accept'), '*/*');
    expect(request.header('Authorization'), isNull);
    expect(request.bodyBytes, isEmpty);
  });

  test('derives JSON headers and retains the custom header and body', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'content-type': 'application/json'},
      responseBody: utf8.encode('"ok"'),
    );
    final api = SimpleEncodingApi(CustomServer(baseUrl: server.baseUrl));

    final result = await api.testReservedHeadersJson(
      body: 'payload',
      traceId: 'trace-42',
    );

    final success = requireSuccess(result);
    expect(success.value, 'ok');
    final request = await server.takeRequest();
    expect(request.method, 'POST');
    expect(request.uri.path, '/headers/reserved/json');
    expect(request.header('Accept'), 'application/json');
    expect(request.header('Content-Type'), 'application/json');
    expect(request.header('Authorization'), isNull);
    expect(request.header('X-Trace-Id'), 'trace-42');
    expect(request.bodyText, '"payload"');
  });

  test('decodes JSON despite a stale response Content-Type enum', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'content-type': 'application/json'},
      responseBody: utf8.encode('"ok"'),
    );
    final api = SimpleEncodingApi(CustomServer(baseUrl: server.baseUrl));

    final result = await api.testReservedResponseContentType();

    final success = requireSuccess(result);
    expect(success.value, 'ok');
    expect(success.response.statusCode, 200);
    expect(success.response.headers.value('Content-Type'), 'application/json');
    final request = await server.takeRequest();
    expect(request.uri.path, '/headers/reserved/status');
    expect(request.header('Accept'), 'application/json');
  });

  test('rejects text/plain even when its body contains valid JSON', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'content-type': 'text/plain'},
      responseBody: utf8.encode('"ok"'),
    );
    final api = SimpleEncodingApi(CustomServer(baseUrl: server.baseUrl));

    final result = await api.testReservedResponseContentType();

    final error = requireError(result);
    expect(error.type, TonikErrorType.decoding);
    expect(error.error, isA<ResponseDecodingException>());
    expect(error.response?.statusCode, 200);
    expect(error.response?.headers.value('Content-Type'), 'text/plain');
    final request = await server.takeRequest();
    expect(request.uri.path, '/headers/reserved/status');
    expect(request.header('Accept'), 'application/json');
  });

  test(
    'ignores referenced Content-Type and decodes ordinary headers',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {
          'content-type': 'application/json',
          'x-media-type': 'custom/media',
          'x-request-id': 'request-42',
        },
        responseBody: utf8.encode('"ok"'),
      );
      final api = SimpleEncodingApi(CustomServer(baseUrl: server.baseUrl));

      final result = await api.testReservedReferencedResponseHeader();

      final success = requireSuccess(result);
      expect(success.value.body, 'ok');
      expect(success.value.xMediaType, 'custom/media');
      expect(success.value.xRequestId, 'request-42');
      expect(
        success.response.headers.value('Content-Type'),
        'application/json',
      );
      final request = await server.takeRequest();
      expect(request.uri.path, '/headers/reserved/referenced-response');
    },
  );
}
