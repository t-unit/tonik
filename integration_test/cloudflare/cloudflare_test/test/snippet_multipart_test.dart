import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudflare_api/cloudflare_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('sends exact snippet metadata and repeated binary files', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'content-type': 'application/json'},
      responseBody: utf8.encode(
        '{"success":true,"errors":[],"messages":[], "result": '
        '{"snippet_name":"demo", "created_on":"2026-09-13T00:00:00Z"}}',
      ),
    );
    final api = ZoneSnippetsApi(CustomServer(baseUrl: server.baseUrl));
    final response = await api.updateZoneSnippet(
      zoneId: 'zone-123',
      snippetName: 'demo',
      body: SnippetsSnippetBodyModel(
        metadata: const SnippetsSnippetBodyMetadataModel(mainModule: 'main.js'),
        additionalProperties: {
          'files': [
            TonikFileBytes(
              Uint8List.fromList([0, 255, 128, 65]),
              fileName: 'main.js',
            ),
            TonikFileBytes(Uint8List.fromList([66, 67])),
          ],
        },
      ),
    );
    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.method, 'PUT');
    expect(request.uri.path, '/zones/zone-123/snippets/demo');
    final wire = MultipartWire(request);
    expect(wire.parts.map((p) => p.name), ['metadata', 'files', 'files']);
    expect(jsonDecode(wire.parts[0].bodyText), {'main_module': 'main.js'});
    expect(wire.parts[0].contentType, startsWith('application/json'));
    expect(wire.parts[0].filename, isNull);
    expect(wire.parts[1].filename, 'main.js');
    expect(wire.parts[1].bodyBytes, [0, 255, 128, 65]);
    expect(wire.parts[1].contentType, 'application/octet-stream');
    expect(wire.parts[2].filename, 'files');
    expect(wire.parts[2].bodyBytes, [66, 67]);
    expect(wire.parts[2].contentType, 'application/octet-stream');
  });
}
