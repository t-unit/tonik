import 'package:dio/dio.dart';
import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;
  late CustomApi api;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';

    api = CustomApi(CustomServer(baseUrl: baseUrl));
  });

  group('Custom content type mapped to multipart', () {
    test('sends request body as FormData for custom content type', () async {
      const form = CustomForm(field1: 'test data', field2: 999);

      final response = await api.postCustomMultipart(body: form);

      expect(response, isA<TonikSuccess<GenericResponse>>());

      final success = response as TonikSuccess<GenericResponse>;
      final requestData = success.response.requestOptions.data;

      // The body should be FormData because the custom content type is
      // mapped to multipart serialization via tonik.yaml contentTypes.
      expect(requestData, isA<FormData>());

      final formData = requestData as FormData;
      // Scalar fields use formData.files with explicit Content-Type.
      expect(formData.files.any((e) => e.key == 'field1'), isTrue);
      expect(formData.files.any((e) => e.key == 'field2'), isTrue);

      // Verify actual field values via server echo-back headers.
      expect(success.response.headers['x-param-field1']?.first, 'test data');
      expect(success.response.headers['x-param-field2']?.first, '999');
    });

    test(
      'Dio overrides Content-Type with multipart/form-data boundary',
      () async {
        const form = CustomForm(field1: 'hello', field2: 42);

        final response = await api.postCustomMultipart(body: form);

        expect(response, isA<TonikSuccess<GenericResponse>>());

        final success = response as TonikSuccess<GenericResponse>;

        // Known limitation: Dio replaces content type with
        // multipart/form-data; boundary=... when body is FormData.
        // The original application/vnd.custom-multipart is NOT preserved.
        final receivedContentType =
            success.response.headers['x-received-content-type']?.first ?? '';
        expect(receivedContentType, contains('multipart/form-data'));
      },
    );
  });
}
