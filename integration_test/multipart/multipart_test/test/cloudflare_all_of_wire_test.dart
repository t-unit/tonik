import 'dart:convert';
import 'dart:typed_data';

import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

import 'multipart_wire.dart';

void main() {
  test('merges allOf members into ordered Cloudflare-shaped parts', () async {
    final server = await RawRequestServer.start();
    final first = Uint8List.fromList([1, 2, 3]);
    final second = Uint8List.fromList([4, 5, 6]);

    await _rawApi(server).postAllOfUpload(
      body: CloudflareUpload(
        uploadFiles: UploadFiles(
          files: [
            TonikFileBytes(first, fileName: 'first.bin'),
            TonikFileBytes(second, fileName: 'second.bin'),
          ],
        ),
        uploadMetadataBase: const UploadMetadataBase(
          metadata: MetadataBase(id: 'upload-1', source: 'integration'),
        ),
        uploadMetadataAnnotations: const UploadMetadataAnnotations(
          metadata: MetadataAnnotations(
            annotations: MetadataAnnotationsAnnotationsModel(
              language: 'en',
              labels: ['one', 'two'],
            ),
          ),
        ),
      ),
    );

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), ['files', 'files', 'metadata']);
    expect(wire.named('files').map((part) => part.filename), [
      'first.bin',
      'second.bin',
    ]);
    expect(wire.named('files').map((part) => part.bodyBytes), [first, second]);
    expect(wire.named('files').map((part) => part.contentType), [
      'application/octet-stream',
      'application/octet-stream',
    ]);
    expect(wire.single('metadata').contentType, startsWith('application/json'));
    expect(jsonDecode(wire.single('metadata').bodyText), {
      'id': 'upload-1',
      'source': 'integration',
      'annotations': {
        'language': 'en',
        'labels': ['one', 'two'],
      },
    });
  });
}

MultipartApi _rawApi(RawRequestServer server) => MultipartApi(
  CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
);
