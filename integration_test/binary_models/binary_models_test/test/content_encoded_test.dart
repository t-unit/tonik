import 'dart:convert';
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

  DefaultApi buildContentEncodedApi({required String responseStatus}) {
    return DefaultApi(
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

  group('uploadContentEncodedData', () {
    test('201 - uploads data with contentEncoding:base64 field', () async {
      final contentEncodedApi = buildContentEncodedApi(responseStatus: '201');

      // Create test binary data and encode to base64
      final binaryData = Uint8List.fromList(
        List.generate(256, (i) => i),
      );
      final base64String = base64.encode(binaryData);

      final contentEncodedData = ContentEncodedData(
        name: 'test-content-encoded',
        encodedData: base64String,
        description: 'Test data with contentEncoding:base64',
      );

      final result = await contentEncodedApi.uploadContentEncodedData(
        body: contentEncodedData,
      );
      final success = result as TonikSuccess<UploadContentEncodedDataResponse>;

      expect(success.response.statusCode, 201);
      expect(success.value, isA<UploadContentEncodedDataResponse201>());

      final responseBody =
          (success.value as UploadContentEncodedDataResponse201).body;
      expect(responseBody.id, 'data-999');
      expect(responseBody.message, contains('test-content-encoded'));
    });

    test('encodedData (contentEncoding:base64) is a base64 string in JSON', () {
      // Create test binary data and encode to base64
      final binaryData = Uint8List.fromList([10, 20, 30, 40, 50]);
      final base64String = base64.encode(binaryData);

      final contentEncodedData = ContentEncodedData(
        name: 'test',
        encodedData: base64String,
      );

      // Serialize to JSON
      final json = contentEncodedData.toJson()! as Map<String, dynamic>;

      // Verify encodedData is a base64 string in JSON
      expect(json['encodedData'], isA<String>());
      expect(json['encodedData'], equals(base64String));

      // Verify we can decode it back to binary
      final decoded = base64.decode(json['encodedData'] as String);
      expect(decoded, equals(binaryData));
    });

    test(
      'contentEncoding:base64 behaves identically to format:byte',
      () {
        final binaryData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final base64String = base64.encode(binaryData);

        // Create both format:byte and contentEncoding:base64 models
        final formatByteData = Base64Data(
          name: 'format-byte',
          encodedData: base64String,
        );

        final contentEncodedData = ContentEncodedData(
          name: 'content-encoding',
          encodedData: base64String,
        );

        // Both should serialize identically (as base64 string)
        final formatByteJson = formatByteData.toJson()! as Map<String, dynamic>;
        final contentEncodedJson =
            contentEncodedData.toJson()! as Map<String, dynamic>;

        expect(formatByteJson['encodedData'], isA<String>());
        expect(contentEncodedJson['encodedData'], isA<String>());
        expect(
          formatByteJson['encodedData'],
          equals(contentEncodedJson['encodedData']),
        );
      },
    );

    test('400 - bad request', () async {
      final contentEncodedApi = buildContentEncodedApi(responseStatus: '400');

      const contentEncodedData = ContentEncodedData(
        name: '',
        encodedData: '',
      );

      final result = await contentEncodedApi.uploadContentEncodedData(
        body: contentEncodedData,
      );
      final success = result as TonikSuccess<UploadContentEncodedDataResponse>;

      expect(success.response.statusCode, 400);
      expect(success.value, isA<UploadContentEncodedDataResponse400>());

      final responseBody =
          (success.value as UploadContentEncodedDataResponse400).body;
      expect(responseBody.code, 400);
      expect(responseBody.message, isNotEmpty);
    });
  });

  group('getContentEncodedData', () {
    test('200 - retrieves data with contentEncoding:base64 field', () async {
      final contentEncodedApi = buildContentEncodedApi(responseStatus: '200');

      final result = await contentEncodedApi.getContentEncodedData(id: 'abc');
      final success = result as TonikSuccess<GetContentEncodedDataResponse>;

      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetContentEncodedDataResponse200>());

      final responseBody =
          (success.value as GetContentEncodedDataResponse200).body;
      expect(responseBody.name, 'test-data');
      expect(responseBody.encodedData, isA<String>());

      // Verify we can decode the base64 data
      final decoded = base64.decode(responseBody.encodedData);
      expect(decoded, isNotEmpty);
    });

    test('404 - data not found', () async {
      final contentEncodedApi = buildContentEncodedApi(responseStatus: '404');

      final result = await contentEncodedApi.getContentEncodedData(id: 'xyz');
      final success = result as TonikSuccess<GetContentEncodedDataResponse>;

      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetContentEncodedDataResponse404>());

      final responseBody =
          (success.value as GetContentEncodedDataResponse404).body;
      expect(responseBody.code, 404);
      expect(responseBody.message, contains('not found'));
    });
  });
}
