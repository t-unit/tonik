import 'dart:io';

import 'package:medama_api/medama_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('generated client honors ISO-8859-1 response charset', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final requestHandled = server.first.then((request) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set(
          HttpHeaders.contentTypeHeader,
          'text/plain; charset=iso-8859-1',
        )
        ..headers.set(
          HttpHeaders.lastModifiedHeader,
          'Thu, 09 Jan 2026 00:00:00 GMT',
        )
        ..headers.set(HttpHeaders.cacheControlHeader, 'max-age=86400')
        ..add(const [
          0x63,
          0x61,
          0x66,
          0xe9,
          0x20,
          0x64,
          0xe9,
          0x6a,
          0xe0,
          0x20,
          0x76,
          0x75,
        ]);
      await request.response.close();
    });
    final api = EventApi(
      CustomServer(baseUrl: 'http://127.0.0.1:${server.port}'),
    );

    final response = await api.getEventPing();
    await requestHandled;

    final success = response as TonikSuccess<GetEventPingResponse>;
    final response200 = success.value as GetEventPingResponse200;
    expect(response200.body.body, 'café déjà vu');
  });
}
