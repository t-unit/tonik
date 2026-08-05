import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  group('Header Roundtrip Duplicate Field Lines', () {
    test(
      'list header sent as two field lines decodes to the combined list',
      () async {
        // Imposter cannot guarantee separate duplicate header field lines.
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);
        server.listen((socket) {
          final requestBytes = <int>[];
          socket.listen((bytes) {
            requestBytes.addAll(bytes);
            if (!utf8.decode(requestBytes).contains('\r\n\r\n')) return;

            socket.add(
              utf8.encode(
                'HTTP/1.1 200 OK\r\n'
                'Content-Length: 0\r\n'
                'x-string-list: a\r\n'
                'x-string-list: b\r\n'
                'Connection: close\r\n'
                '\r\n',
              ),
            );
            unawaited(socket.close());
          });
        });

        final api = SimpleEncodingApi(
          CustomServer(
            baseUrl: 'http://${server.address.address}:${server.port}/v1',
            serverConfig: testServerConfig(),
          ),
        );

        final response = await api.testHeaderRoundtripSimpleLists();
        final success = requireSuccess(response);

        expect(success.response.statusCode, 200);
        expect(success.response.headers['x-string-list'], ['a', 'b']);
        expect(success.value.xStringList, ['a', 'b']);
      },
    );
  });
}
