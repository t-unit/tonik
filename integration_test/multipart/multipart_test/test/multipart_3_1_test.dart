import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:multipart_3_1_api/multipart_3_1_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;
  late Multipart31Api api;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';

    api = Multipart31Api(CustomServer(baseUrl: baseUrl));
  });

  group('OAS 3.1 pipe-delimited encoding', () {
    test('serializes array as single pipe-delimited value', () async {
      const form = PipeDelimitedForm(items: ['alpha', 'beta', 'gamma']);

      final response = await api.postPipeDelimited(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      // With style: pipeDelimited and explode: false, the array should be
      // serialized as a single field with pipe-separated values.
      final itemEntries = formData.fields
          .where((e) => e.key == 'items')
          .toList();
      expect(itemEntries, hasLength(1));
      expect(itemEntries.first.value, 'alpha|beta|gamma');

      // Server received the items field.
      expect(success.response.headers['x-has-items']?.first, 'true');
    });
  });

  group('OAS 3.1 content-based array (no encoding specified)', () {
    test(
      'serializes array as single JSON-encoded part when no encoding is set',
      () async {
        const form = DefaultExplodeForm(values: ['one', 'two', 'three']);

        final response = await api.postDefaultExplode(body: form);

        expect(response, isA<TonikSuccess<GenericResponse>>());

        final success = response as TonikSuccess<GenericResponse>;

        // In OAS 3.1, when no style/explode/allowReserved are set on an array
        // property, the spec defines content-based mode: the array is
        // JSON-encoded into a single part, NOT sent as multiple exploded
        // fields.
        // The server receives one JSON string, not three separate values.
        expect(success.response.headers['x-has-values']?.first, 'true');
        expect(
          success.response.headers['x-param-values']?.first,
          '["one","two","three"]',
        );
      },
    );
  });

  group('OAS 3.1 basic multipart', () {
    test('sends string and binary fields', () async {
      final fileBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
      final form = BasicForm(name: 'test-31', file: TonikFileBytes(fileBytes));

      final response = await api.postBasic31(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      // Scalar fields go to files with explicit Content-Type.
      expect(formData.files.any((e) => e.key == 'name'), isTrue);
      expect(formData.files.any((e) => e.key == 'file'), isTrue);

      // Server received the name text field.
      expect(success.response.headers['x-has-name']?.first, 'true');
      expect(success.response.headers['x-param-name']?.first, 'test-31');
    });
  });
}
