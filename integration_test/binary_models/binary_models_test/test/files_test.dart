import 'dart:typed_data';

import 'package:binary_models_api/binary_models_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  const port = 8083;
  const baseUrl = 'http://localhost:$port/api/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  FilesApi buildFilesApi({required String responseStatus}) {
    return FilesApi(
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

  group('getFile', () {
    test('200 - downloads binary file', () async {
      final filesApi = buildFilesApi(responseStatus: '200');

      final result = await filesApi.getFile(id: 'test-file');

      expect(result, isA<TonikSuccess<GetFileResponse>>());
      final success = result as TonikSuccess<GetFileResponse>;

      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetFileResponse200>());

      final responseBody = (success.value as GetFileResponse200).body;
      expect(responseBody, isA<List<int>>());
      expect(responseBody.length, greaterThan(0));
    });

    test('404 - file not found', () async {
      final filesApi = buildFilesApi(responseStatus: '404');

      final result = await filesApi.getFile(id: 'nonexistent');
      final success = result as TonikSuccess<GetFileResponse>;

      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetFileResponse404>());

      final responseBody = (success.value as GetFileResponse404).body;
      expect(responseBody.code, 404);
      expect(responseBody.message, 'File not found');
    });
  });

  group('uploadFile', () {
    test('201 - uploads binary file', () async {
      final filesApi = buildFilesApi(responseStatus: '201');

      // Create test binary data
      final testData = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

      final result = await filesApi.uploadFile(
        id: 'new-file',
        body: testData,
      );
      final success = result as TonikSuccess<UploadFileResponse>;

      expect(success.response.statusCode, 201);
      expect(success.value, isA<UploadFileResponse201>());

      final responseBody = (success.value as UploadFileResponse201).body;
      expect(responseBody.id, 'file-123');
      expect(responseBody.size, testData.length);
    });

    test('400 - bad request', () async {
      final filesApi = buildFilesApi(responseStatus: '400');

      final testData = Uint8List.fromList([1, 2, 3]);

      final result = await filesApi.uploadFile(
        id: 'invalid',
        body: testData,
      );
      final success = result as TonikSuccess<UploadFileResponse>;

      expect(success.response.statusCode, 400);
      expect(success.value, isA<UploadFileResponse400>());

      final responseBody = (success.value as UploadFileResponse400).body;
      expect(responseBody.code, 400);
      expect(responseBody.message, 'Bad request');
    });
  });
}
