import 'dart:convert';
import 'dart:typed_data';

import 'package:big_decimal/big_decimal.dart';
import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('preserves file order and merges duplicate metadata properties across '
      'allOf members', () async {
    final server = await RawRequestServer.start();
    final first = Uint8List.fromList([1, 2, 3]);
    final second = Uint8List.fromList([4, 5, 6]);

    final api = MultipartApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    await api.postAllOfUpload(
      body: FilesAndMergedMetadataUpload(
        uploadFiles: UploadFiles(
          files: [
            TonikFileBytes(first, fileName: 'first.bin'),
            TonikFileBytes(second, fileName: 'second.bin'),
          ],
        ),
        uploadMetadataBase: UploadMetadataBase(
          metadata: const MetadataBase(id: 'upload-1', source: 'integration'),
          amounts: {'small': BigDecimal.parse('0.00000001')},
        ),
        uploadMetadataAnnotations: UploadMetadataAnnotations(
          metadata: const MetadataAnnotations(
            annotations: MetadataAnnotationsAnnotationsModel(
              language: 'en',
              labels: ['one', 'two'],
            ),
          ),
          amounts: {'large': BigDecimal.parse('1E+3')},
        ),
      ),
    );

    final wire = MultipartWire(await server.takeRequest());
    expect(wire.parts.map((part) => part.name), [
      'files',
      'files',
      'metadata',
      'amounts',
    ]);
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
    expect(jsonDecode(wire.single('amounts').bodyText), {
      'small': '0.00000001',
      'large': '1000',
    });
  });
}
