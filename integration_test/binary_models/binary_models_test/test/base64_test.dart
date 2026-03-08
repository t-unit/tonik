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

  DefaultApi buildBase64Api({required String responseStatus}) {
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

  group('uploadBase64Data', () {
    test('201 - uploads data with base64 encoded field', () async {
      final base64Api = buildBase64Api(responseStatus: '201');

      // Create test binary data — format:byte auto-encodes to base64 in JSON.
      final binaryData = Uint8List.fromList(
        List.generate(256, (i) => i),
      );

      final base64Data = Base64Data(
        name: 'test-data',
        encodedData: TonikFileBytes(binaryData),
        description: 'Test data with base64 encoding',
      );

      final result = await base64Api.uploadBase64Data(body: base64Data);
      final success = result as TonikSuccess<UploadBase64DataResponse>;

      expect(success.response.statusCode, 201);
      expect(success.value, isA<UploadBase64DataResponse201>());

      final responseBody = (success.value as UploadBase64DataResponse201).body;
      expect(responseBody.id, 'data-999');
      expect(responseBody.message, contains('test-data'));
    });

    test('binary data (format:byte) is base64 encoded in JSON', () {
      // format:byte fields are stored as binary (TonikFile) and automatically
      // base64-encoded when serialized to JSON.
      final binaryData = Uint8List.fromList([10, 20, 30, 40, 50]);
      final expectedBase64 = base64.encode(binaryData);

      final base64Data = Base64Data(
        name: 'test',
        encodedData: TonikFileBytes(binaryData),
      );

      // Serialize to JSON
      final json = base64Data.toJson()! as Map<String, dynamic>;

      // Verify encodedData is a base64 string in JSON (auto-encoded)
      expect(json['encodedData'], isA<String>());
      expect(json['encodedData'], equals(expectedBase64));

      // Verify we can decode the JSON value back to binary
      final decoded = base64.decode(json['encodedData'] as String);
      expect(decoded, equals(binaryData));
    });

    test('400 - bad request', () async {
      final base64Api = buildBase64Api(responseStatus: '400');

      const base64Data = Base64Data(
        name: '',
        encodedData: TonikFileBytes([]),
      );

      final result = await base64Api.uploadBase64Data(body: base64Data);
      final success = result as TonikSuccess<UploadBase64DataResponse>;

      expect(success.response.statusCode, 400);
      expect(success.value, isA<UploadBase64DataResponse400>());

      final responseBody = (success.value as UploadBase64DataResponse400).body;
      expect(responseBody.code, 400);
    });
  });

  group('getBase64Data', () {
    test('200 - gets data with base64 encoded field', () async {
      final base64Api = buildBase64Api(responseStatus: '200');

      final result = await base64Api.getBase64Data(id: 'data-123');
      final success = result as TonikSuccess<GetBase64DataResponse>;

      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetBase64DataResponse200>());

      final responseBody = (success.value as GetBase64DataResponse200).body;
      expect(responseBody.name, 'test-data');

      // format:byte is decoded from base64 JSON string to binary (TonikFile).
      expect(responseBody.encodedData, isA<TonikFile>());
      expect(responseBody.encodedData.toBytes().length, greaterThan(0));
    });

    test('base64 JSON string (format:byte) is decoded to binary', () {
      // When parsing JSON, the base64 string is decoded to binary (TonikFile).
      final binaryData = Uint8List.fromList([100, 200, 50, 75, 125]);
      final base64String = base64.encode(binaryData);

      final json = {
        'name': 'test-data',
        'encodedData': base64String,
        'description': 'Test description',
      };

      // Parse from JSON
      final data = Base64Data.fromJson(json);

      // Verify encodedData is decoded back to binary
      expect(data.encodedData.toBytes(), equals(binaryData));
    });

    test('404 - data not found', () async {
      final base64Api = buildBase64Api(responseStatus: '404');

      final result = await base64Api.getBase64Data(id: 'nonexistent');
      final success = result as TonikSuccess<GetBase64DataResponse>;

      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetBase64DataResponse404>());

      final responseBody = (success.value as GetBase64DataResponse404).body;
      expect(responseBody.code, 404);
      expect(responseBody.message, 'Data not found');
    });
  });
}
