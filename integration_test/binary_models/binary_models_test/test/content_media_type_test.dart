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

  ContentMediaTypeApi buildApi({required String responseStatus}) {
    return ContentMediaTypeApi(
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

  group('contentMediaType configured as binary (image/png -> List<int>)', () {
    test('ImageEncodedData.imageData is List<int>', () {
      // Create test image data
      final imageBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]); // PNG header bytes

      // ImageEncodedData.imageData should be List<int> due to config
      final imageEncodedData = ImageEncodedData(
        name: 'test-image',
        imageData: TonikFileBytes(imageBytes),
        description: 'Test PNG image',
      );

      expect(imageEncodedData.imageData, isA<TonikFile>());
      expect(imageEncodedData.imageData.toBytes(), equals(imageBytes));
    });

    test('ImageEncodedData serializes imageData to base64 in JSON', () {
      final imageBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);

      final imageEncodedData = ImageEncodedData(
        name: 'test-image',
        imageData: TonikFileBytes(imageBytes),
      );

      final json = imageEncodedData.toJson()! as Map<String, dynamic>;

      expect(json['imageData'], isA<String>());
      expect(json['imageData'], '3q2+7w==');
    });

    test('ImageEncodedData deserializes base64 imageData from JSON', () {
      final json = {
        'name': 'test-image',
        'imageData': 'iVBORw0KGgo=',
      };

      final imageEncodedData = ImageEncodedData.fromJson(json);

      expect(imageEncodedData.imageData, isA<TonikFile>());
      expect(
        imageEncodedData.imageData.toBytes(),
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      );
    });

    test('201 - uploads image data', () async {
      final api = buildApi(responseStatus: '201');

      final imageBytes = Uint8List.fromList(List.generate(100, (i) => i));

      final imageEncodedData = ImageEncodedData(
        name: 'test-upload-image',
        imageData: TonikFileBytes(imageBytes),
        description: 'Test image upload',
      );

      final result = await api.uploadContentMediaTypeImage(
        body: imageEncodedData,
      );
      final success = result as TonikSuccess<UploadResponse>;

      expect(success.response.statusCode, 201);
      expect(success.value.id, isNotEmpty);
    });

    test('200 - retrieves image data as List<int>', () async {
      final api = buildApi(responseStatus: '200');

      final result = await api.getContentMediaTypeImage(id: 'img-123');
      final success = result as TonikSuccess<GetContentMediaTypeImageResponse>;

      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetContentMediaTypeImageResponse200>());

      final responseBody =
          (success.value as GetContentMediaTypeImageResponse200).body;
      expect(responseBody.imageData, isA<TonikFile>());
      expect(responseBody.imageData.toBytes(), hasLength(256));
    });
  });

  group('contentMediaType configured as text (text/plain -> String)', () {
    test('TextEncodedData.textData is String', () {
      // TextEncodedData.textData should be String due to config
      const textEncodedData = TextEncodedData(
        name: 'test-text',
        textData: 'SGVsbG8gV29ybGQh', // base64 of "Hello World!"
        description: 'Test text data',
      );

      expect(textEncodedData.textData, isA<String>());
      expect(textEncodedData.textData, equals('SGVsbG8gV29ybGQh'));
    });

    test('TextEncodedData serializes textData as string in JSON', () {
      const base64String = 'SGVsbG8gV29ybGQh';

      const textEncodedData = TextEncodedData(
        name: 'test-text',
        textData: base64String,
      );

      // Serialize to JSON
      final json = textEncodedData.toJson()! as Map<String, dynamic>;

      // In JSON, the String remains a string (no transformation)
      expect(json['textData'], isA<String>());
      expect(json['textData'], equals(base64String));
    });

    test('TextEncodedData deserializes string as String', () {
      const base64String = 'SGVsbG8gV29ybGQh';

      final json = {
        'name': 'test-text',
        'textData': base64String,
      };

      final textEncodedData = TextEncodedData.fromJson(json);

      expect(textEncodedData.textData, isA<String>());
      expect(textEncodedData.textData, equals(base64String));
    });

    test('201 - uploads text data', () async {
      final api = buildApi(responseStatus: '201');

      const textEncodedData = TextEncodedData(
        name: 'test-upload-text',
        textData: 'SGVsbG8gV29ybGQh',
        description: 'Test text upload',
      );

      final result = await api.uploadContentMediaTypeText(
        body: textEncodedData,
      );
      final success = result as TonikSuccess<UploadResponse>;

      expect(success.response.statusCode, 201);
      expect(success.value.id, isNotEmpty);
    });

    test('200 - retrieves text data as String', () async {
      final api = buildApi(responseStatus: '200');

      final result = await api.getContentMediaTypeText(id: 'txt-123');
      final success = result as TonikSuccess<GetContentMediaTypeTextResponse>;

      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetContentMediaTypeTextResponse200>());

      final responseBody =
          (success.value as GetContentMediaTypeTextResponse200).body;
      expect(responseBody.textData, isA<String>());
    });
  });

  group('contentMediaType unconfigured (fallback to binary -> List<int>)', () {
    test('UnconfiguredEncodedData.data is List<int> (fallback)', () {
      // UnconfiguredEncodedData.data should be List<int> due to fallback
      final dataBytes = Uint8List.fromList([100, 200, 255]);

      final unconfiguredData = UnconfiguredEncodedData(
        name: 'test-unconfigured',
        data: TonikFileBytes(dataBytes),
      );

      expect(unconfiguredData.data, isA<TonikFile>());
      expect(unconfiguredData.data.toBytes(), equals(dataBytes));
    });

    test('UnconfiguredEncodedData serializes data to base64 in JSON', () {
      final dataBytes = Uint8List.fromList([0x64, 0xC8, 0xFF]);

      final unconfiguredData = UnconfiguredEncodedData(
        name: 'test-unconfigured',
        data: TonikFileBytes(dataBytes),
      );

      final json = unconfiguredData.toJson()! as Map<String, dynamic>;

      expect(json['data'], isA<String>());
      expect(json['data'], 'ZMj/');
    });

    test(
      'UnconfiguredEncodedData deserializes base64 data from JSON',
      () {
        final json = {
          'name': 'test-unconfigured',
          'data': '3q2+7w==',
        };

        final unconfiguredData = UnconfiguredEncodedData.fromJson(json);

        expect(unconfiguredData.data, isA<TonikFile>());
        expect(unconfiguredData.data.toBytes(), [0xDE, 0xAD, 0xBE, 0xEF]);
      },
    );

    test('201 - uploads unconfigured data', () async {
      final api = buildApi(responseStatus: '201');

      final dataBytes = Uint8List.fromList(List.generate(50, (i) => i * 2));

      final unconfiguredData = UnconfiguredEncodedData(
        name: 'test-upload-unconfigured',
        data: TonikFileBytes(dataBytes),
      );

      final result = await api.uploadContentMediaTypeUnconfigured(
        body: unconfiguredData,
      );
      final success = result as TonikSuccess<UploadResponse>;

      expect(success.response.statusCode, 201);
      expect(success.value.id, isNotEmpty);
    });

    test('200 - retrieves unconfigured data as List<int>', () async {
      final api = buildApi(responseStatus: '200');

      final result = await api.getContentMediaTypeUnconfigured(id: 'unc-123');
      final success =
          result as TonikSuccess<GetContentMediaTypeUnconfiguredResponse>;

      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetContentMediaTypeUnconfiguredResponse200>());

      final responseBody =
          (success.value as GetContentMediaTypeUnconfiguredResponse200).body;
      expect(responseBody.data, isA<TonikFile>());
      expect(responseBody.data.toBytes(), hasLength(64));
    });
  });
}
