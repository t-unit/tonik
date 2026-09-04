import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

import 'multipart_wire.dart';

void main() {
  test(
    'composed upload sends ordered files and complete merged metadata',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );
      final body = ComposedUpload(
        uploadFiles: UploadFiles(
          files: [
            TonikFileBytes(
              Uint8List.fromList([0, 255, 10, 13]),
              fileName: 'first.bin',
            ),
            TonikFileBytes(
              Uint8List.fromList([128, 1, 2]),
              fileName: 'second.bin',
            ),
          ],
          metadata: const UploadBaseMetadata(
            name: 'worker',
            settings: UploadBaseSettings(enabled: true),
          ),
        ),
        uploadDetails: UploadDetails(
          uploadAnnotations: UploadAnnotations(
            metadata: UploadAnnotationMetadata(
              name: 'worker',
              settings: const UploadExtraSettings(region: 'eu'),
              annotations: const {'team': 'platform', 'release': 'v2'},
            ),
          ),
          uploadOptional: const UploadOptional(),
        ),
      );
      final result = await api.postComposedUpload(body: body);
      expect(result, isTonikSuccess);
      final request = await server.takeRequest();
      expect(request.method, 'POST');
      expect(request.uri.path, '/multipart/composed-upload');
      final wire = MultipartWire(request);
      expect(wire.parts.map((p) => p.name), ['files', 'files', 'metadata']);
      final files = wire.named('files');
      expect(files.map((p) => p.filename), ['first.bin', 'second.bin']);
      expect(files.map((p) => p.contentType), [
        'application/octet-stream',
        'application/octet-stream',
      ]);
      expect(files.map((p) => p.bodyBytes), [
        [0, 255, 10, 13],
        [128, 1, 2],
      ]);
      final metadata = wire.single('metadata');
      expect(metadata.contentType, startsWith('application/json'));
      expect(jsonDecode(metadata.bodyText), {
        'name': 'worker',
        'settings': {'enabled': true, 'region': 'eu'},
        'annotations': {'team': 'platform', 'release': 'v2'},
      });
    },
  );

  test(
    'composed upload handles missing optional values and nullable fields',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );
      final body = ComposedUpload(
        uploadFiles: UploadFiles(
          files: [
            TonikFileBytes(
              Uint8List.fromList([0, 255, 10, 13]),
              fileName: 'first.bin',
            ),
            TonikFileBytes(
              Uint8List.fromList([128, 1, 2]),
              fileName: 'second.bin',
            ),
          ],
          metadata: const UploadBaseMetadata(
            name: 'worker',
            settings: UploadBaseSettings(enabled: true),
          ),
        ),
        uploadDetails: const UploadDetails(
          uploadAnnotations: UploadAnnotations(),
          uploadOptional: UploadOptional(),
        ),
      );
      final result = await api.postComposedUpload(body: body);
      expect(result, isTonikSuccess);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((p) => p.name), ['files', 'files', 'metadata']);
      expect(jsonDecode(wire.single('metadata').bodyText), {
        'name': 'worker',
        'settings': {'enabled': true},
      });
    },
  );

  test('composed upload rejects conflicting values before sending', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var receivedRequests = 0;
    final subscription = server.listen((request) async {
      receivedRequests++;
      await request.drain<void>();
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
    });
    addTearDown(subscription.cancel);
    final api = MultipartApi(
      CustomServer(
        baseUrl: 'http://127.0.0.1:${server.port}',
        serverConfig: testServerConfig(),
      ),
    );
    final body = ComposedUpload(
      uploadFiles: UploadFiles(
        files: [
          TonikFileBytes(
            Uint8List.fromList([0, 255, 10, 13]),
            fileName: 'first.bin',
          ),
          TonikFileBytes(
            Uint8List.fromList([128, 1, 2]),
            fileName: 'second.bin',
          ),
        ],
        metadata: const UploadBaseMetadata(
          name: 'worker',
          settings: UploadBaseSettings(enabled: true),
        ),
      ),
      uploadDetails: UploadDetails(
        uploadAnnotations: UploadAnnotations(
          metadata: UploadAnnotationMetadata(
            name: 'different',
            settings: const UploadExtraSettings(region: 'eu'),
            annotations: const {'team': 'platform', 'release': 'v2'},
          ),
        ),
        uploadOptional: const UploadOptional(),
      ),
    );
    final result = await api.postComposedUpload(body: body);
    expect(result, isTonikError);
    expect(receivedRequests, 0);
  });
}
