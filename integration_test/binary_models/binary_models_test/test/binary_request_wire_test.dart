import 'dart:convert';

import 'package:binary_models_api/binary_models_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('required binary body sends ordinary List<int> as raw octets', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 201,
      responseHeaders: {'content-type': 'application/json'},
      responseBody: utf8.encode('{"id":"uploaded","size":6}'),
    );
    final api = FilesApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final result = await api.uploadFile(
      id: 'raw-file',
      body: const TonikFileBytes([0, 255, 128, 65, 195, 40]),
    );

    expect(result, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.method, 'POST');
    expect(request.uri.path, '/files/raw-file');
    expect(request.header('content-type'), 'application/octet-stream');
    expect(request.bodyBytes, [0, 255, 128, 65, 195, 40]);
  });

  test('optional binary body sends ordinary List<int> as raw octets', () async {
    final server = await RawRequestServer.start();
    final api = FilesApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final result = await api.uploadOptionalFile(
      body: const TonikFileBytes([0, 255, 128, 65, 195, 40]),
    );

    expect(result, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.header('content-type'), 'application/octet-stream');
    expect(request.bodyBytes, [0, 255, 128, 65, 195, 40]);
  });

  test('optional binary body can be omitted', () async {
    final server = await RawRequestServer.start();
    final api = FilesApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final result = await api.uploadOptionalFile();

    expect(result, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyBytes, isEmpty);
  });

  test('multi-content binary variant sends raw octets', () async {
    final server = await RawRequestServer.start();
    final api = FilesApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final result = await api.uploadMultiContentFile(
      body: const FilesMultiContentPostBodyRequestBodyOctetStream(
        TonikFileBytes([0, 255, 128, 65, 195, 40]),
      ),
    );

    expect(result, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.header('content-type'), 'application/octet-stream');
    expect(request.bodyBytes, [0, 255, 128, 65, 195, 40]);
  });
}
