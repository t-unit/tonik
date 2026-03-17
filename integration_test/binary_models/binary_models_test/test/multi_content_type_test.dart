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

  group('getMultiContentType', () {
    test('200 - returns JSON when format=json', () async {
      final filesApi = buildFilesApi(responseStatus: '200');

      final result = await filesApi.getMultiContentType(format: 'json');

      expect(result, isA<TonikSuccess<BinaryMultiContentTypeGet200Response>>());
      final success =
          result as TonikSuccess<BinaryMultiContentTypeGet200Response>;

      expect(success.response.statusCode, 200);
      expect(success.value, isA<BinaryMultiContentTypeGet200ResponseJson>());

      final response =
          success.value as BinaryMultiContentTypeGet200ResponseJson;

      expect(response.body.id, 'file-123');
      expect(response.body.fileName, 'test.bin');
      expect(response.body.size, 1024);
    });

    test('200 - returns binary when format=binary', () async {
      final filesApi = buildFilesApi(responseStatus: '200');

      final result = await filesApi.getMultiContentType(format: 'binary');

      expect(result, isA<TonikSuccess<BinaryMultiContentTypeGet200Response>>());
      final success =
          result as TonikSuccess<BinaryMultiContentTypeGet200Response>;

      expect(success.response.statusCode, 200);
      expect(
        success.value,
        isA<BinaryMultiContentTypeGet200ResponseOctetStream>(),
      );

      final response =
          success.value as BinaryMultiContentTypeGet200ResponseOctetStream;

      // The server returns binary, so the body should be a TonikFile.
      expect(response.body.toBytes().length, greaterThan(0));
    });
  });

  group('getBinaryWithHeaders', () {
    test('200 - downloads binary and extracts response headers', () async {
      final filesApi = buildFilesApi(responseStatus: '200');

      final result = await filesApi.getBinaryWithHeaders(id: 'test-file');

      expect(result, isA<TonikSuccess<BinaryWithHeadersIdGet200Response>>());
      final success = result as TonikSuccess<BinaryWithHeadersIdGet200Response>;

      expect(success.response.statusCode, 200);
      expect(success.value, isA<BinaryWithHeadersIdGet200Response>());

      final response200 = success.value;

      // Verify binary body is present.
      expect(response200.body, isA<TonikFile>());
      expect(response200.body.toBytes().length, greaterThan(0));

      // Verify response headers are extracted.
      expect(
        response200.contentDisposition,
        'attachment; filename="downloaded.bin"',
      );
      expect(response200.xFileSize, 42);
    });
  });
}
