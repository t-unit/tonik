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

  ImagesApi buildImagesApi({required String responseStatus}) {
    return ImagesApi(
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

  group('OAS 3.1 Empty Schema Support', () {
    group('getRawBinary', () {
      test('200 - downloads binary with empty schema (OAS 3.1)', () async {
        final filesApi = buildFilesApi(responseStatus: '200');

        final result = await filesApi.getRawBinary();

        expect(result, isA<TonikSuccess<GetRawBinaryResponse>>());
        final success = result as TonikSuccess<GetRawBinaryResponse>;

        expect(success.response.statusCode, 200);
        expect(success.value, isA<GetRawBinaryResponse200>());

        final responseBody = (success.value as GetRawBinaryResponse200).body;
        expect(responseBody, isA<List<int>>());
        expect(responseBody.length, greaterThan(0));
      });

      test('404 - not found with empty schema', () async {
        final filesApi = buildFilesApi(responseStatus: '404');

        final result = await filesApi.getRawBinary();
        final success = result as TonikSuccess<GetRawBinaryResponse>;

        expect(success.response.statusCode, 404);
        expect(success.value, isA<GetRawBinaryResponse404>());

        final responseBody = (success.value as GetRawBinaryResponse404).body;
        expect(responseBody.code, 404);
        expect(responseBody.message, isNotEmpty);
      });
    });

    group('uploadRawBinary', () {
      test('201 - uploads binary with empty schema (OAS 3.1)', () async {
        final filesApi = buildFilesApi(responseStatus: '201');

        // Create test binary data
        final testData = Uint8List.fromList([
          0xDE,
          0xAD,
          0xBE,
          0xEF,
          0xCA,
          0xFE,
          0xBA,
          0xBE,
        ]);

        final result = await filesApi.uploadRawBinary(body: testData);

        expect(result, isA<TonikSuccess<UploadResponse>>());
        final success = result as TonikSuccess<UploadResponse>;

        expect(success.response.statusCode, 201);
        expect(success.value.id, isNotEmpty);
        expect(success.value.size, greaterThan(0));
      });
    });

    group('getImageOas31', () {
      test('200 - downloads image with empty schema (OAS 3.1)', () async {
        final imagesApi = buildImagesApi(responseStatus: '200');

        final result = await imagesApi.getImageOas31();

        expect(result, isA<TonikSuccess<List<int>>>());
        final success = result as TonikSuccess<List<int>>;

        expect(success.response.statusCode, 200);
        expect(success.value.length, greaterThan(0));

        // Verify it's PNG data (starts with PNG magic bytes)
        expect(success.value[0], 0x89);
        expect(success.value[1], 0x50); // 'P'
        expect(success.value[2], 0x4E); // 'N'
        expect(success.value[3], 0x47); // 'G'
      });
    });
  });
}
