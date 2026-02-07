import 'dart:convert';
import 'dart:typed_data';

import 'package:binary_models_api/binary_models_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/api/v1';
  });

  MixedApi buildMixedApi({required String responseStatus}) {
    return MixedApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  group('uploadFileInfo', () {
    test('201 - uploads file info with binary thumbnail in JSON', () async {
      final mixedApi = buildMixedApi(responseStatus: '201');

      // Create test thumbnail data
      final thumbnailData = Uint8List.fromList(
        List.generate(1024, (i) => i % 256),
      );

      final fileInfo = FileInfo(
        fileName: 'photo.png',
        contentType: 'image/png',
        thumbnail: thumbnailData,
        description: 'A test photo',
      );

      final result = await mixedApi.uploadFileInfo(body: fileInfo);
      final success = result as TonikSuccess<UploadFileInfoResponse>;

      expect(success.response.statusCode, 201);
      expect(success.value, isA<UploadFileInfoResponse201>());

      final responseBody = (success.value as UploadFileInfoResponse201).body;
      expect(responseBody.id, 'file-456');
      expect(responseBody.message, contains('photo.png'));
    });

    test('thumbnail is automatically UTF-8 encoded in JSON', () {
      final thumbnailData = Uint8List.fromList([1, 2, 3, 4, 5]);

      final fileInfo = FileInfo(
        fileName: 'test.jpg',
        contentType: 'image/jpeg',
        thumbnail: thumbnailData,
      );

      final json = fileInfo.toJson()! as Map<String, dynamic>;

      expect(json['thumbnail'], isA<String>());

      final decoded = utf8.encode(json['thumbnail'] as String);
      expect(decoded, equals(thumbnailData));
    });

    test('400 - bad request', () async {
      final mixedApi = buildMixedApi(responseStatus: '400');

      const fileInfo = FileInfo(fileName: '', contentType: 'invalid');

      final result = await mixedApi.uploadFileInfo(body: fileInfo);
      final success = result as TonikSuccess<UploadFileInfoResponse>;

      expect(success.response.statusCode, 400);
      expect(success.value, isA<UploadFileInfoResponse400>());

      final responseBody = (success.value as UploadFileInfoResponse400).body;
      expect(responseBody.code, 400);
    });
  });

  group('getFileWithMetadata', () {
    test('200 - gets file metadata with binary thumbnail', () async {
      final mixedApi = buildMixedApi(responseStatus: '200');

      final result = await mixedApi.getFileWithMetadata(id: 'file-789');
      final success = result as TonikSuccess<GetFileWithMetadataResponse>;

      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetFileWithMetadataResponse200>());

      final responseBody =
          (success.value as GetFileWithMetadataResponse200).body;
      expect(responseBody.id, 'file-789');
      expect(responseBody.fileName, 'example.pdf');
      expect(responseBody.size, 2048);

      // Verify thumbnail is binary data (automatically decoded from base64)
      expect(responseBody.thumbnail, isNotNull);
      expect(responseBody.thumbnail, isA<List<int>>());
      expect(responseBody.thumbnail!.length, greaterThan(0));
    });

    test('thumbnail is automatically UTF-8 decoded from JSON', () {
      // Create mock JSON response with UTF-8 thumbnail
      final thumbnailData = Uint8List.fromList([10, 20, 30, 40, 50]);
      final utf8Thumbnail = utf8.decode(thumbnailData, allowMalformed: true);

      final json = {
        'id': 'test-id',
        'fileName': 'test.pdf',
        'size': 1234,
        'thumbnail': utf8Thumbnail,
        'createdAt': '2023-12-20T10:30:00Z',
      };

      // Parse from JSON
      final metadata = FileMetadata.fromJson(json);

      // Verify thumbnail is decoded to binary
      expect(metadata.thumbnail, isNotNull);
      expect(metadata.thumbnail, equals(thumbnailData));
    });

    test('404 - file not found', () async {
      final mixedApi = buildMixedApi(responseStatus: '404');

      final result = await mixedApi.getFileWithMetadata(id: 'nonexistent');
      final success = result as TonikSuccess<GetFileWithMetadataResponse>;

      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetFileWithMetadataResponse404>());

      final responseBody =
          (success.value as GetFileWithMetadataResponse404).body;
      expect(responseBody.code, 404);
      expect(responseBody.message, 'File not found');
    });
  });
}
