import 'dart:convert';

import 'package:multipart_3_1_api/multipart_3_1_api.dart' as oas31;
import 'package:multipart_api/multipart_api.dart' as oas30;
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

import 'multipart_wire.dart';

void main() {
  test('OAS 3.0 multipart omits read-only and absent optional parts', () async {
    final server = await RawRequestServer.start();
    final api = oas30.MultipartApi(
      oas30.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await api.postReadOnlyFields(
      body: const oas30.ReadOnlyFields(serverId: 'server-only', name: 'café'),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['name']);
    expect(wire.single('name').bodyBytes, utf8.encode('café'));
    expect(wire.single('name').contentType, startsWith('text/plain'));
  });

  test('OAS 3.1 multipart omits read-only and absent optional parts', () async {
    final server = await RawRequestServer.start();
    final api = oas31.Multipart31Api(
      oas31.CustomServer(
        baseUrl: server.baseUrl,
        serverConfig: testServerConfig(),
      ),
    );

    final response = await api.postReadOnlyFields(
      body: const oas31.ReadOnlyFields(serverId: 'server-only', name: 'café'),
    );

    expect(response, isTonikSuccess);
    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['name']);
    expect(wire.single('name').bodyBytes, utf8.encode('café'));
    expect(wire.single('name').contentType, startsWith('text/plain'));
  });
}
