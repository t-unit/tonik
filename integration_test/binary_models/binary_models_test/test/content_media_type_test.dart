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
        imageData: imageBytes,
        description: 'Test PNG image',
      );

      expect(imageEncodedData.imageData, isA<List<int>>());
      expect(imageEncodedData.imageData, equals(imageBytes));
    });

    test('ImageEncodedData serializes imageData to string in JSON', () {
      final imageBytes = Uint8List.fromList([
        72,
        101,
        108,
        108,
        111,
      ]); // "Hello"

      final imageEncodedData = ImageEncodedData(
        name: 'test-image',
        imageData: imageBytes,
      );

      // Serialize to JSON
      final json = imageEncodedData.toJson()! as Map<String, dynamic>;

      // The schema has contentEncoding: base64, but this test uses
      // ASCII-compatible bytes that are valid UTF-8 to demonstrate the
      // bidirectional conversion. In this test, List<int> is decoded as UTF-8
      // string in JSON for simplicity.
      expect(json['imageData'], isA<String>());
      expect(json['imageData'], equals('Hello'));
    });

    test('ImageEncodedData deserializes string from JSON to List<int>', () {
      // Server sends data in JSON as a string
      const jsonString = 'Hello';

      final json = {
        'name': 'test-image',
        'imageData': jsonString,
      };

      final imageEncodedData = ImageEncodedData.fromJson(json);

      // fromJson UTF-8 encodes the string to List<int>
      expect(imageEncodedData.imageData, isA<List<int>>());
      expect(
        imageEncodedData.imageData,
        equals([72, 101, 108, 108, 111]),
      ); // UTF-8 bytes of "Hello"
    });

    test('201 - uploads image data', () async {
      final api = buildApi(responseStatus: '201');

      final imageBytes = Uint8List.fromList(List.generate(100, (i) => i));

      final imageEncodedData = ImageEncodedData(
        name: 'test-upload-image',
        imageData: imageBytes,
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
      expect(responseBody.imageData, isA<List<int>>());
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
        data: dataBytes,
      );

      expect(unconfiguredData.data, isA<List<int>>());
      expect(unconfiguredData.data, equals(dataBytes));
    });

    test('UnconfiguredEncodedData serializes data to string in JSON', () {
      final dataBytes = Uint8List.fromList([87, 111, 114, 108, 100]); // "World"

      final unconfiguredData = UnconfiguredEncodedData(
        name: 'test-unconfigured',
        data: dataBytes,
      );

      // Serialize to JSON
      final json = unconfiguredData.toJson()! as Map<String, dynamic>;

      // In JSON, the List<int> is UTF-8 decoded to string (not base64)
      expect(json['data'], isA<String>());
      expect(json['data'], equals('World'));
    });

    test(
      'UnconfiguredEncodedData deserializes string from JSON to List<int>',
      () {
        // Server sends data in JSON as a string
        const jsonString = 'Test';

        final json = {
          'name': 'test-unconfigured',
          'data': jsonString,
        };

        final unconfiguredData = UnconfiguredEncodedData.fromJson(json);

        // fromJson UTF-8 encodes the string to List<int>
        expect(unconfiguredData.data, isA<List<int>>());
        expect(
          unconfiguredData.data,
          equals([84, 101, 115, 116]),
        ); // UTF-8 bytes of "Test"
      },
    );

    test('201 - uploads unconfigured data', () async {
      final api = buildApi(responseStatus: '201');

      final dataBytes = Uint8List.fromList(List.generate(50, (i) => i * 2));

      final unconfiguredData = UnconfiguredEncodedData(
        name: 'test-upload-unconfigured',
        data: dataBytes,
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
      expect(responseBody.data, isA<List<int>>());
    });
  });
}
