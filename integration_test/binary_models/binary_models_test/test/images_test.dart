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
      expect(responseBody, isA<TonikFile>());
      expect(responseBody.toBytes().length, greaterThan(0));

      // Verify it's actual binary data.
      expect(responseBody, isA<TonikFileBytes>());

      // Check PNG magic number (89 50 4E 47)
      expect(responseBody.toBytes()[0], 0x89);
      expect(responseBody.toBytes()[1], 0x50);
      expect(responseBody.toBytes()[2], 0x4E);
      expect(responseBody.toBytes()[3], 0x47);
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
