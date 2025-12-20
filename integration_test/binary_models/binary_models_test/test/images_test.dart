import 'dart:typed_data';

import 'package:binary_models_api/binary_models_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8083;
  const baseUrl = 'http://localhost:$port/api/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  tearDownAll(() async {
    await teardownImposterServer(imposterServer);
  });

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

  group('getImage', () {
    test('200 - downloads PNG image', () async {
      final imagesApi = buildImagesApi(responseStatus: '200');

      final result = await imagesApi.getImage(id: 'test-image');
      final success = result as TonikSuccess<GetImageResponse>;

      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetImageResponse200>());

      final responseBody = (success.value as GetImageResponse200).body;
      expect(responseBody, isA<List<int>>());
      expect(responseBody.length, greaterThan(0));

      // Verify it's actual binary data
      expect(responseBody, isA<Uint8List>());

      // Check PNG magic number (89 50 4E 47)
      expect(responseBody[0], 0x89);
      expect(responseBody[1], 0x50);
      expect(responseBody[2], 0x4E);
      expect(responseBody[3], 0x47);
    });

    test('404 - image not found', () async {
      final imagesApi = buildImagesApi(responseStatus: '404');

      final result = await imagesApi.getImage(id: 'nonexistent');
      final success = result as TonikSuccess<GetImageResponse>;

      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetImageResponse404>());

      final responseBody = (success.value as GetImageResponse404).body;
      expect(responseBody.code, 404);
      expect(responseBody.message, 'Image not found');
    });
  });
}
