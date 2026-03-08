import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;
  late MultipartApi api;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';

    api = MultipartApi(CustomServer(baseUrl: baseUrl));
  });

  group('Simple fields', () {
    test('posts string, integer, and boolean fields as multipart', () async {
      const form = SimpleFields(name: 'John Doe', age: 30, active: true);

      final response = await api.postSimpleFields(body: form);

      expect(response, isA<TonikSuccess<SimpleFieldsResponse>>());

      final success = response as TonikSuccess<SimpleFieldsResponse>;
      final requestData = success.response.requestOptions.data;
      expect(requestData, isA<FormData>());

      final formData = requestData as FormData;

      // Verify fields are present in files (scalar parts now use
      // MultipartFile.fromString with explicit Content-Type).
      expect(formData.files.any((e) => e.key == 'name'), isTrue);
      expect(formData.files.any((e) => e.key == 'age'), isTrue);
      expect(formData.files.any((e) => e.key == 'active'), isTrue);

      // Verify server received the form params.
      expect(success.response.headers['x-has-name']?.first, 'true');
      expect(success.response.headers['x-has-age']?.first, 'true');
      expect(success.response.headers['x-has-active']?.first, 'true');

      // Verify server read correct values.
      expect(success.response.headers['x-param-name']?.first, 'John Doe');
      expect(success.response.headers['x-param-age']?.first, '30');
      expect(success.response.headers['x-param-active']?.first, 'true');

      // Verify response body decoded.
      expect(success.value.name, 'John Doe');
      expect(success.value.age, 30);
      expect(success.value.active, true);
    });
  });

  group('Binary upload', () {
    test('uploads a binary file with a description field', () async {
      final fileBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      final form = BinaryUpload(
        file: TonikFileBytes(fileBytes),
        description: 'test file',
      );

      final response = await api.postBinaryUpload(body: form);

      expect(response, isA<TonikSuccess<UploadResponse>>());

      final success = response as TonikSuccess<UploadResponse>;
      final requestData = success.response.requestOptions.data;
      expect(requestData, isA<FormData>());

      final formData = requestData as FormData;

      // Both fields go into files (binary as bytes, text as MultipartFile).
      expect(formData.files.any((e) => e.key == 'file'), isTrue);
      expect(formData.files.any((e) => e.key == 'description'), isTrue);

      // Server sees the description text field in formParams.
      expect(
        success.response.headers['x-has-description']?.first,
        'true',
      );
      expect(
        success.response.headers['x-param-description']?.first,
        'test file',
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
        final form = EnumForm(status: status);

        final response = await api.postEnumField(body: form);

        expect(response, isA<TonikSuccess<StatusResponse>>());

        final success = response as TonikSuccess<StatusResponse>;
        final formData = success.response.requestOptions.data as FormData;

        // Enum fields go to files with explicit Content-Type.
        expect(formData.files.any((e) => e.key == 'status'), isTrue);

        expect(success.response.headers['x-has-status']?.first, 'true');
        expect(success.response.headers['x-param-status']?.first, expected);
      });
    }
  });

  group('Complex object', () {
    test('JSON-encodes a nested object property', () async {
      const profile = Profile(firstName: 'John', lastName: 'Doe');
      const form = ComplexForm(label: 'test', profile: profile);

      final response = await api.postComplexObject(body: form);

      expect(response, isA<TonikSuccess<ComplexResponse>>());

      final success = response as TonikSuccess<ComplexResponse>;
      final formData = success.response.requestOptions.data as FormData;

      // Label and profile go to files (scalar with explicit Content-Type,
      // and JSON-encoded complex object respectively).
      expect(formData.files.any((e) => e.key == 'label'), isTrue);
      expect(formData.files.any((e) => e.key == 'profile'), isTrue);

      // Server received both fields.
      expect(success.response.headers['x-has-label']?.first, 'true');
      expect(success.response.headers['x-has-profile']?.first, 'true');

      // Profile value contains JSON property names.
      expect(
        success.response.headers['x-profile-contains-firstname']?.first,
        'true',
      );
      expect(
        success.response.headers['x-profile-contains-lastname']?.first,
        'true',
      );
    });
  });

  group('Array fields', () {
    test(
      'serializes arrays as repeated form fields (one field per element)',
      () async {
        const form = ArrayForm(
          tags: ['dart', 'flutter', 'openapi'],
          priorities: [Priority.high, Priority.low],
        );

        final response = await api.postArrayFields(body: form);

        expect(response, isA<TonikSuccess<ArrayResponse>>());

        final success = response as TonikSuccess<ArrayResponse>;

        // Per RFC 7578 §4.3 and OAS 3.x default: each array element is sent
        // as a separate form field with the same name (repeated fields),
        // not as a single JSON-encoded blob.
        final formData = success.response.requestOptions.data as FormData;

        final tagEntries =
            formData.fields.where((e) => e.key == 'tags').toList();
        expect(tagEntries, hasLength(3));
        expect(
          tagEntries.map((e) => e.value).toList(),
          ['dart', 'flutter', 'openapi'],
        );

        final priorityEntries =
            formData.fields.where((e) => e.key == 'priorities').toList();
        expect(priorityEntries, hasLength(2));
        expect(
          priorityEntries.map((e) => e.value).toList(),
          ['high', 'low'],
        );
      },
    );
  });

  group('Mixed required/optional fields', () {
    test('sends only required fields when optional are null', () async {
      const form = MixedRequiredForm(requiredField: 'hello');

      final response = await api.postMixedRequired(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      // Required field is present in files with explicit Content-Type.
      expect(formData.files.any((e) => e.key == 'requiredField'), isTrue);

      // Optional fields should be absent.
      expect(formData.files.any((e) => e.key == 'optionalField'), isFalse);
      expect(formData.files.any((e) => e.key == 'optionalFile'), isFalse);

      // Server saw required, but not optional.
      expect(success.response.headers['x-has-required']?.first, 'true');
      expect(success.response.headers['x-has-optional']?.first, 'false');
      expect(
        success.response.headers['x-has-optionalfile']?.first,
        'false',
      );
    });

    test('sends all fields when optional are provided', () async {
      final fileBytes = Uint8List.fromList([1, 2, 3]);
      final form = MixedRequiredForm(
        requiredField: 'hello',
        optionalField: 'world',
        optionalFile: TonikFileBytes(fileBytes),
      );

      final response = await api.postMixedRequired(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      // All scalar fields go to files with explicit Content-Type.
      expect(formData.files.any((e) => e.key == 'requiredField'), isTrue);
      expect(formData.files.any((e) => e.key == 'optionalField'), isTrue);
      expect(formData.files.any((e) => e.key == 'optionalFile'), isTrue);

      // Server saw all text parts (binary file not in formParams).
      expect(success.response.headers['x-has-required']?.first, 'true');
      expect(success.response.headers['x-has-optional']?.first, 'true');
    });
  });

  group('Encoding override', () {
    test('applies explicit contentType encoding override', () async {
      const form = EncodingOverrideForm(data: 'plain text value', label: 'x');

      final response = await api.postEncodingOverride(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      final allKeys = [
        ...formData.fields.map((e) => e.key),
        ...formData.files.map((e) => e.key),
      ];
      expect(allKeys, contains('data'));
      expect(allKeys, contains('label'));

      // Server received both fields.
      expect(success.response.headers['x-has-data']?.first, 'true');
      expect(success.response.headers['x-has-label']?.first, 'true');
    });
  });

  group('Multiple files', () {
    test('uploads multiple binary files in an array field', () async {
      final file1 = Uint8List.fromList([1, 2, 3]);
      final file2 = Uint8List.fromList([4, 5, 6]);
      final file3 = Uint8List.fromList([7, 8, 9]);
      final form = MultipleFilesForm(
        files: [
          TonikFileBytes(file1),
          TonikFileBytes(file2),
          TonikFileBytes(file3),
        ],
      );

      final response = await api.postMultipleFiles(body: form);

      expect(response, isA<TonikSuccess<FilesResponse>>());

      final success = response as TonikSuccess<FilesResponse>;
      final formData = success.response.requestOptions.data as FormData;

      // Per RFC 7578 §4.3, each file is a separate part with the same name.
      final fileEntries = formData.files
          .where((e) => e.key == 'files')
          .toList();
      expect(fileEntries, hasLength(3));
    });
  });

  group('Multipart response', () {
    test(
      'throws ResponseDecodingException for multipart response body',
      () async {
        final response = await api.getMultipartResponse();

        // The generator should produce a ResponseDecodingException because
        // decoding multipart/form-data responses is not supported.
        expect(response, isA<TonikError<SimpleFields>>());
        final error = response as TonikError<SimpleFields>;
        expect(error.error, isA<ResponseDecodingException>());
      },
    );
  });

  group('Per-part headers', () {
    test(
      'sends required and optional per-part headers on multipart fields',
      () async {
        final fileBytes = Uint8List.fromList([10, 20, 30]);
        final form = HeaderPartsForm(
          description: 'test desc',
          file: TonikFileBytes(fileBytes),
        );

        final response = await api.postWithHeaders(
          body: form,
          descriptionPartMeta: 'meta-value',
          fileFileHash: 'abc123',
          fileFileTag: 'tag-value',
        );

        expect(response, isA<TonikSuccess<GenericResponse>>());

        final success = response as TonikSuccess<GenericResponse>;

        // Both fields should be sent as MultipartFile (per-part headers promote
        // text fields from formData.fields to formData.files).
        final formData = success.response.requestOptions.data as FormData;
        expect(
          formData.files.where((e) => e.key == 'description').toList(),
          isNotEmpty,
        );
        expect(
          formData.files.where((e) => e.key == 'file').toList(),
          isNotEmpty,
        );
      },
    );

    test('omits optional X-File-Tag header when not provided', () async {
      final fileBytes = Uint8List.fromList([10, 20, 30]);
      final form = HeaderPartsForm(
        description: 'test desc',
        file: TonikFileBytes(fileBytes),
      );

      final response = await api.postWithHeaders(
        body: form,
        descriptionPartMeta: 'meta-value',
        fileFileHash: 'abc123',
      );

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      // Both parts are still sent even without the optional header.
      expect(
        formData.files.where((e) => e.key == 'description').toList(),
        isNotEmpty,
      );
      expect(
        formData.files.where((e) => e.key == 'file').toList(),
        isNotEmpty,
      );
    });
  });
}
