import 'package:multipart_api/multipart_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

import 'multipart_wire.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;
  late CustomApi api;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';

    api = CustomApi(
      CustomServer(baseUrl: baseUrl, serverConfig: testServerConfig()),
    );
  });

  group('Custom content type mapped to multipart', () {
    test('sends multipart fields for the custom content type', () async {
      final rawServer = await RawRequestServer.start();
      final rawApi = CustomApi(
        CustomServer(
          baseUrl: rawServer.baseUrl,
          serverConfig: testServerConfig(),
        ),
      );
      const form = CustomForm(field1: 'test data', field2: 999);

      await rawApi.postCustomMultipart(body: form);

      final request = await rawServer.takeRequest();
      expect(request.header('content-type'), contains('multipart/form-data'));
      final wire = MultipartWire(request);
      expect(wire.single('field1').bodyText, 'test data');
      expect(wire.single('field2').bodyText, '999');
      expect(wire.single('field1').contentType, startsWith('text/plain'));
    });

    test(
      'the client adds the multipart/form-data boundary',
      () async {
        const form = CustomForm(field1: 'hello', field2: 42);

        final response = await api.postCustomMultipart(body: form);

        expect(
          response,
          isTonikSuccess,
        );

        final success = requireSuccess(response);

        final receivedContentType =
            success.response.headers['x-received-content-type']?.first ?? '';
        expect(receivedContentType, contains('multipart/form-data'));
      },
    );
  });
}
