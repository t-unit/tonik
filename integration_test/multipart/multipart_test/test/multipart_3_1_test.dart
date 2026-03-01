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

  group('OAS 3.1 default explode', () {
    test('serializes array items as separate parts (explode=true)', () async {
      const form = DefaultExplodeForm(values: ['one', 'two', 'three']);

      final response = await api.postDefaultExplode(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      // Default explode=true: each array item is a separate form data entry.
      final valueEntries = formData.fields
          .where((e) => e.key == 'values')
          .toList();
      expect(valueEntries, hasLength(3));
      expect(valueEntries.map((e) => e.value), ['one', 'two', 'three']);

      // Server received the values field.
      expect(success.response.headers['x-has-values']?.first, 'true');
    });
  });

  group('OAS 3.1 basic multipart', () {
    test('sends string and binary fields', () async {
      final fileBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
      final form = BasicForm(name: 'test-31', file: fileBytes);

      final response = await api.postBasic31(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final formData = success.response.requestOptions.data as FormData;

      final fields = Map.fromEntries(formData.fields);
      expect(fields['name'], 'test-31');
      expect(formData.files.any((e) => e.key == 'file'), isTrue);

      // Server received the name text field.
      expect(success.response.headers['x-has-name']?.first, 'true');
      expect(success.response.headers['x-param-name']?.first, 'test-31');
    });
  });
}
