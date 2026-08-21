import 'dart:convert';
import 'dart:typed_data';

import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

import 'multipart_wire.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;
  late MultipartApi api;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
    api = MultipartApi(
      CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
    );
  });

  group('Simple fields', () {
    test('posts string, integer, and boolean fields as multipart', () async {
      const form = SimpleFields(name: 'John Doe', age: 30, active: true);

      final response = await api.postSimpleFields(body: form);
      final success = requireSuccess(response);

      expect(success.response.headers['x-has-name']?.first, 'true');
      expect(success.response.headers['x-has-age']?.first, 'true');
      expect(success.response.headers['x-has-active']?.first, 'true');
      expect(success.response.headers['x-param-name']?.first, 'John Doe');
      expect(success.response.headers['x-param-age']?.first, '30');
      expect(success.response.headers['x-param-active']?.first, 'true');
      expect(success.value.name, 'John Doe');
      expect(success.value.age, 30);
      expect(success.value.active, isTrue);
    });
  });

  group('Binary upload', () {
    test('uploads a binary file with a description field', () async {
      final fileBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      final form = BinaryUpload(
        file: TonikFileBytes(fileBytes),
        description: 'test file',
      );

      final response = requireSuccess(await api.postBinaryUpload(body: form));
      expect(response.response.headers['x-has-description']?.first, 'true');
      expect(
        response.response.headers['x-param-description']?.first,
        'test file',
      );

      final server = await RawRequestServer.start();
      await _rawApi(server).postBinaryUpload(body: form);
      final wire = MultipartWire(await server.takeRequest());

      expect(wire.parts.map((part) => part.name), ['file', 'description']);
      expect(wire.single('file').contentType, 'application/octet-stream');
      expect(wire.single('file').bodyBytes, fileBytes);
      expect(wire.single('description').bodyText, 'test file');
      expect(
        wire.single('description').contentType,
        startsWith('text/plain'),
      );
    });
  });

  group('Enum field', () {
    for (final (status, expected) in [
      (Status.active, 'active'),
      (Status.inactive, 'inactive'),
      (Status.pending, 'pending'),
    ]) {
      test('serializes $expected in a multipart field', () async {
        final response = requireSuccess(
          await api.postEnumField(body: EnumForm(status: status)),
        );

        expect(response.response.headers['x-has-status']?.first, 'true');
        expect(
          response.response.headers['x-param-status']?.first,
          expected,
        );
      });
    }
  });

  group('Complex object', () {
    test('JSON-encodes a nested object property', () async {
      const form = ComplexForm(
        label: 'test',
        profile: Profile(firstName: 'John', lastName: 'Doe'),
      );

      final response = requireSuccess(
        await api.postComplexObject(body: form),
      );

      expect(response.response.headers['x-has-label']?.first, 'true');
      expect(response.response.headers['x-has-profile']?.first, 'true');
      expect(
        response.response.headers['x-profile-contains-firstname']?.first,
        'true',
      );
      expect(
        response.response.headers['x-profile-contains-lastname']?.first,
        'true',
      );
    });
  });

  group('Array fields', () {
    test(
      'serializes arrays as repeated form fields (one field per element)',
      () async {
        final server = await RawRequestServer.start();

        await _rawApi(server).postArrayFields(
          body: const ArrayForm(
            tags: ['dart', 'flutter', 'openapi'],
            priorities: [Priority.high, Priority.low],
          ),
        );

        final wire = MultipartWire(await server.takeRequest());
        expect(
          wire.named('tags').map((part) => part.bodyText),
          ['dart', 'flutter', 'openapi'],
        );
        expect(
          wire.named('priorities').map((part) => part.bodyText),
          ['high', 'low'],
        );
      },
    );
  });

  group('Enum array with content-based JSON encoding', () {
    test(
      'enum values with special characters are JSON-encoded, not URI-encoded',
      () async {
        final server = await RawRequestServer.start();

        await _rawApi(server).postCategoryArrayFields(
          body: const CategoryArrayForm(
            categories: [
              Category.scienceAmpersandTech,
              Category.artsAmpersandCrafts,
            ],
          ),
        );

        final part = MultipartWire(await server.takeRequest()).single(
          'categories',
        );
        expect(part.contentType, startsWith('application/json'));
        expect(jsonDecode(part.bodyText), [
          'science & tech',
          'arts & crafts',
        ]);
        expect(part.bodyText, isNot(contains('%26')));
        expect(part.bodyText, isNot(contains('%20')));
      },
    );
  });

  group('Mixed required/optional fields', () {
    test('sends only required fields when optional are null', () async {
      const form = MixedRequiredForm(requiredField: 'hello');

      final response = requireSuccess(
        await api.postMixedRequired(body: form),
      );
      expect(response.response.headers['x-has-required']?.first, 'true');
      expect(response.response.headers['x-has-optional']?.first, 'false');
      expect(response.response.headers['x-has-optionalfile']?.first, 'false');

      final server = await RawRequestServer.start();
      await _rawApi(server).postMixedRequired(body: form);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), ['requiredField']);
      expect(wire.single('requiredField').bodyText, 'hello');
    });

    test('sends all fields when optional are provided', () async {
      final fileBytes = Uint8List.fromList([1, 2, 3]);
      final form = MixedRequiredForm(
        requiredField: 'hello',
        optionalField: 'world',
        optionalFile: TonikFileBytes(fileBytes),
      );

      final response = requireSuccess(
        await api.postMixedRequired(body: form),
      );
      expect(response.response.headers['x-has-required']?.first, 'true');
      expect(response.response.headers['x-has-optional']?.first, 'true');

      final server = await RawRequestServer.start();
      await _rawApi(server).postMixedRequired(body: form);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), [
        'requiredField',
        'optionalField',
        'optionalFile',
      ]);
      expect(wire.single('requiredField').bodyText, 'hello');
      expect(wire.single('optionalField').bodyText, 'world');
      expect(wire.single('optionalFile').bodyBytes, fileBytes);
    });
  });

  group('Encoding override', () {
    test('applies explicit contentType encoding override', () async {
      const form = EncodingOverrideForm(data: 'plain text value', label: 'x');

      final response = requireSuccess(
        await api.postEncodingOverride(body: form),
      );
      expect(response.response.headers['x-has-data']?.first, 'true');
      expect(response.response.headers['x-has-label']?.first, 'true');

      final server = await RawRequestServer.start();
      await _rawApi(server).postEncodingOverride(body: form);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.single('data').bodyText, 'plain text value');
      expect(wire.single('data').contentType, startsWith('text/plain'));
      expect(wire.single('label').bodyText, 'x');
    });
  });

  group('Multiple files', () {
    test('uploads multiple binary files in an array field', () async {
      final server = await RawRequestServer.start();
      final files = [
        TonikFileBytes(Uint8List.fromList([1, 2, 3]), fileName: 'one.bin'),
        TonikFileBytes(Uint8List.fromList([4, 5, 6]), fileName: 'two.bin'),
        TonikFileBytes(Uint8List.fromList([7, 8, 9]), fileName: 'three.bin'),
      ];

      await _rawApi(server).postMultipleFiles(
        body: MultipleFilesForm(files: files),
      );

      final parts = MultipartWire(await server.takeRequest()).named('files');
      expect(parts.map((part) => part.filename), [
        'one.bin',
        'two.bin',
        'three.bin',
      ]);
      expect(
        parts.map((part) => part.contentType),
        everyElement('application/octet-stream'),
      );
      expect(parts.map((part) => part.bodyBytes), [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
      ]);
    });
  });

  group('Multipart response', () {
    test(
      'throws ResponseDecodingException for multipart response body',
      () async {
        final response = await api.getMultipartResponse();

        expect(response, isTonikError);
        expect(
          requireError(response).error,
          isA<ResponseDecodingException>(),
        );
      },
    );
  });

  group('Per-part headers', () {
    test(
      'sends required and optional per-part headers on multipart fields',
      () async {
        final server = await RawRequestServer.start();
        final fileBytes = Uint8List.fromList([10, 20, 30]);

        await _rawApi(server).postWithHeaders(
          body: HeaderPartsForm(
            description: 'test desc',
            file: TonikFileBytes(fileBytes),
          ),
          descriptionPartMeta: 'meta-value',
          fileFileHash: 'abc123',
          fileFileTag: 'tag-value',
        );

        final wire = MultipartWire(await server.takeRequest());
        expect(wire.single('description').bodyText, 'test desc');
        expect(
          wire.single('description').header('x-part-meta'),
          'meta-value',
        );
        expect(wire.single('file').bodyBytes, fileBytes);
        expect(wire.single('file').header('x-file-hash'), 'abc123');
        expect(wire.single('file').header('x-file-tag'), 'tag-value');
      },
    );

    test('omits optional X-File-Tag header when not provided', () async {
      final server = await RawRequestServer.start();

      await _rawApi(server).postWithHeaders(
        body: HeaderPartsForm(
          description: 'test desc',
          file: TonikFileBytes(Uint8List.fromList([10, 20, 30])),
        ),
        descriptionPartMeta: 'meta-value',
        fileFileHash: 'abc123',
      );

      final wire = MultipartWire(await server.takeRequest());
      expect(
        wire.single('description').header('x-part-meta'),
        'meta-value',
      );
      expect(wire.single('file').header('x-file-hash'), 'abc123');
      expect(wire.single('file').header('x-file-tag'), isNull);
    });
  });

  group('format:byte field (OAS 3.0)', () {
    test(
      'sends format:byte as binary part, not a readable text field',
      () async {
        final server = await RawRequestServer.start();
        final fileBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);

        await _rawApi(server).postByteField(
          body: ByteForm(
            label: 'test-label',
            data: TonikFileBytes(fileBytes),
          ),
        );

        final wire = MultipartWire(await server.takeRequest());
        expect(wire.single('label').bodyText, 'test-label');
        expect(wire.single('label').contentType, startsWith('text/plain'));
        expect(wire.single('data').contentType, 'application/octet-stream');
        expect(wire.single('data').bodyBytes, fileBytes);
      },
    );
  });

  group('anyOf model in multipart', () {
    test('sends anyOf enum variant as JSON-encoded multipart part', () async {
      final server = await RawRequestServer.start();
      final fileBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

      await _rawApi(server).postAnyOfModel(
        body: AnyOfModelForm(
          file: TonikFileBytes(fileBytes, fileName: 'test.bin'),
          model: const AnyOfModelChoice(modelType: ModelType.whisper1),
        ),
      );

      final wire = MultipartWire(await server.takeRequest());
      expect(wire.single('file').filename, 'test.bin');
      expect(wire.single('file').bodyBytes, fileBytes);
      expect(wire.single('model').contentType, startsWith('application/json'));
      expect(jsonDecode(wire.single('model').bodyText), 'whisper-1');
    });

    test('sends anyOf string variant as JSON-encoded multipart part', () async {
      final server = await RawRequestServer.start();

      await _rawApi(server).postAnyOfModel(
        body: AnyOfModelForm(
          file: TonikFileBytes(
            Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
            fileName: 'test.bin',
          ),
          model: const AnyOfModelChoice(string: 'custom-model-name'),
        ),
      );

      final model = MultipartWire(
        await server.takeRequest(),
      ).single('model');
      expect(model.contentType, startsWith('application/json'));
      expect(jsonDecode(model.bodyText), 'custom-model-name');
    });
  });

  group('Map field (additionalProperties)', () {
    test('sends map as JSON-encoded multipart part', () async {
      const form = MapFieldForm(
        name: 'test-resource',
        metadata: {'env': 'production', 'version': '2.1'},
      );

      final response = requireSuccess(await api.postMapField(body: form));
      expect(
        response.response.headers['x-param-name']?.first,
        'test-resource',
      );
      expect(response.response.headers['x-has-metadata']?.first, 'true');
      expect(response.response.headers['x-metadata-is-json']?.first, 'true');

      final server = await RawRequestServer.start();
      await _rawApi(server).postMapField(body: form);
      final wire = MultipartWire(await server.takeRequest());
      expect(wire.single('name').bodyText, 'test-resource');
      expect(
        wire.single('metadata').contentType,
        startsWith('application/json'),
      );
      expect(jsonDecode(wire.single('metadata').bodyText), {
        'env': 'production',
        'version': '2.1',
      });
    });

    test('omits optional map field when null', () async {
      final response = requireSuccess(
        await api.postMapField(
          body: const MapFieldForm(name: 'no-metadata'),
        ),
      );

      expect(response.response.headers['x-has-metadata']?.first, 'false');
    });
  });

  group('Kitchen sink (all field types)', () {
    test(
      'sends binary + string + number + bool + enum + array + object',
      () async {
        final server = await RawRequestServer.start();
        final fileBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

        await _rawApi(server).postKitchenSink(
          body: KitchenSinkForm(
            file: TonikFileBytes(fileBytes, fileName: 'image.png'),
            name: 'test-file',
            temperature: 0.7,
            active: true,
            status: Status.active,
            tags: const ['alpha', 'beta', 'gamma'],
            metadata: const Profile(firstName: 'John', lastName: 'Doe'),
          ),
        );

        final wire = MultipartWire(await server.takeRequest());
        final file = wire.single('file');
        expect(file.filename, 'image.png');
        expect(
          file.contentType,
          anyOf('image/png', 'application/octet-stream'),
        );
        expect(file.bodyBytes, fileBytes);
        expect(wire.single('name').bodyText, 'test-file');
        expect(wire.single('temperature').bodyText, '0.7');
        expect(wire.single('active').bodyText, 'true');
        expect(wire.single('status').bodyText, 'active');
        expect(
          wire.named('tags').map((part) => part.bodyText),
          ['alpha', 'beta', 'gamma'],
        );
        expect(
          wire.single('metadata').contentType,
          startsWith('application/json'),
        );
        expect(jsonDecode(wire.single('metadata').bodyText), {
          'firstName': 'John',
          'lastName': 'Doe',
        });
      },
    );

    test('sends only required fields, omits optional', () async {
      final server = await RawRequestServer.start();

      await _rawApi(server).postKitchenSink(
        body: KitchenSinkForm(
          file: TonikFileBytes(
            Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
            fileName: 'image.png',
          ),
          name: 'test-file',
        ),
      );

      final wire = MultipartWire(await server.takeRequest());
      expect(wire.parts.map((part) => part.name), ['file', 'name']);
    });
  });

  group('Multiple response content types', () {
    test('handles JSON response at 200', () async {
      final response = requireSuccess(
        await api.postMultiResponse(
          body: const SimpleFields(name: 'test', age: 1, active: true),
        ),
      );

      expect(response.response.statusCode, 200);
      expect(response.value, isA<MultipartMultiResponsePost200ResponseJson>());
    });

    test('handles binary response at 200', () async {
      final binaryApi = MultipartApi(
        CustomServer(
          baseUrl: baseUrl,
          serverConfig: testServerConfig(headers: {'X-Want-Binary': 'true'}),
        ),
      );

      final response = requireSuccess(
        await binaryApi.postMultiResponse(
          body: const SimpleFields(name: 'test', age: 1, active: true),
        ),
      );

      expect(response.response.statusCode, 200);
      expect(
        response.value,
        isA<MultipartMultiResponsePost200ResponseOctetStream>(),
      );
      final binary =
          response.value as MultipartMultiResponsePost200ResponseOctetStream;
      expect(binary.body, isA<TonikFile>());
    });
  });

  group('Request text encoding', () {
    test(
      'both backends send exact Latin-1 ordinary and multipart bytes',
      () async {
        final textServer = await RawRequestServer.start();
        await _rawApi(textServer).postLatin1Text(body: 'Grüße');
        final textRequest = await textServer.takeRequest();

        expect(textRequest.bodyBytes, [0x47, 0x72, 0xFC, 0xDF, 0x65]);
        expect(
          textRequest.header('content-type'),
          'text/plain; charset=iso-8859-1',
        );

        final multipartServer = await RawRequestServer.start();
        await _rawApi(multipartServer).postLatin1Multipart(
          body: const Latin1MultipartForm(message: 'Grüße'),
        );
        final part = MultipartWire(
          await multipartServer.takeRequest(),
        ).single('message');

        expect(part.bodyBytes, [0x47, 0x72, 0xFC, 0xDF, 0x65]);
        expect(part.contentType, 'text/plain; charset=iso-8859-1');
      },
    );

    test('Latin-1 form multipart percent-encodes Latin-1 bytes', () async {
      final server = await RawRequestServer.start();
      await _rawApi(server).postLatin1FormMultipart(
        body: const Latin1FormMultipartForm(
          payload: Latin1FormValue(word: 'café'),
        ),
      );
      final part = MultipartWire(
        await server.takeRequest(),
      ).single('payload');

      expect(part.bodyBytes, ascii.encode('word=caf%E9'));
      expect(
        part.contentType,
        'application/x-www-form-urlencoded; charset=iso-8859-1',
      );
    });
  });

  group('Recursive array', () {
    test('posts the form when the recursive array field is omitted', () async {
      final response = requireSuccess(
        await api.postRecursiveArray(
          body: const RecursiveArrayForm(name: 'root'),
        ),
      );

      expect(response.response.headers['x-has-name']?.first, 'true');
      expect(response.response.headers['x-has-tree']?.first, 'false');
      expect(response.response.headers['x-param-name']?.first, 'root');
      expect(response.value.success, isTrue);
    });

    test(
      'returns encoding error when the recursive array field is set',
      () async {
        final response = await api.postRecursiveArray(
          body: const RecursiveArrayForm(name: 'root', tree: [<Object?>[]]),
        );

        expect(response, isTonikError);
        final error = requireError(response);
        expect(error.type, TonikErrorType.encoding);
        expect(error.error, isA<EncodingException>());
      },
    );
  });
}

MultipartApi _rawApi(RawRequestServer server) => MultipartApi(
  CustomServer(
    baseUrl: server.baseUrl,
    serverConfig: testServerConfig(),
  ),
);
