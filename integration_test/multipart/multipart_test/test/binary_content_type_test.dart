import 'dart:io';

import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

import 'multipart_wire.dart';

void main() {
  test(
    'binary bytes with a text filename keep the schema content type',
    () async {
      final server = await RawRequestServer.start();
      final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

      await api.postBinaryUpload(
        body: const BinaryUpload(
          file: TonikFileBytes([72, 105], fileName: 'report.txt'),
          description: 'A report',
        ),
      );

      final file = MultipartWire(await server.takeRequest()).single('file');
      expect(file.filename, 'report.txt');
      expect(file.contentType, 'application/octet-stream');
      expect(file.bodyBytes, [72, 105]);
    },
  );

  test(
    'binary file path with an image filename keeps the schema content type',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'multipart-type-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/image.png');
      await source.writeAsBytes([1, 2, 3]);
      final server = await RawRequestServer.start();
      final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

      await api.postBinaryUpload(
        body: BinaryUpload(
          file: TonikFilePath(source.path, fileName: 'image.png'),
          description: 'An image',
        ),
      );

      final file = MultipartWire(await server.takeRequest()).single('file');
      expect(file.filename, 'image.png');
      expect(file.contentType, 'application/octet-stream');
      expect(file.bodyBytes, [1, 2, 3]);
    },
  );

  test(
    'binary array byte and path items keep the schema content type',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'multipart-type-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/image.png');
      await source.writeAsBytes([1, 2, 3]);
      final server = await RawRequestServer.start();
      final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

      await api.postMultipleFiles(
        body: MultipleFilesForm(
          files: [
            const TonikFileBytes([72, 105], fileName: 'report.txt'),
            TonikFilePath(source.path, fileName: 'image.png'),
          ],
        ),
      );

      final files = MultipartWire(await server.takeRequest()).named('files');
      expect(files, hasLength(2));
      expect(files[0].filename, 'report.txt');
      expect(files[0].contentType, 'application/octet-stream');
      expect(files[0].bodyBytes, [72, 105]);
      expect(files[1].filename, 'image.png');
      expect(files[1].contentType, 'application/octet-stream');
      expect(files[1].bodyBytes, [1, 2, 3]);
    },
  );

  test(
    'binary array byte and path items honor the content-type override',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'multipart-type-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/report.txt');
      await source.writeAsBytes([1, 2, 3]);
      final server = await RawRequestServer.start();
      final api = MultipartApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.postMultipleFilesOverride(
        body: MultipleFilesForm(
          files: [
            const TonikFileBytes([72, 105], fileName: 'first.txt'),
            TonikFilePath(source.path, fileName: 'second.txt'),
          ],
        ),
      );

      expect(response, isTonikSuccess);
      final files = MultipartWire(await server.takeRequest()).named('files');
      expect(files, hasLength(2));
      expect(files[0].filename, 'first.txt');
      expect(files[0].contentType, 'image/png');
      expect(files[0].bodyBytes, [72, 105]);
      expect(files[1].filename, 'second.txt');
      expect(files[1].contentType, 'image/png');
      expect(files[1].bodyBytes, [1, 2, 3]);
    },
  );
}
