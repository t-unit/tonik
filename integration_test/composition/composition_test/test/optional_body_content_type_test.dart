import 'package:composition_api/composition_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  CompositionApi buildApi() {
    return CompositionApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(headers: {'X-Response-Body': '"hello"'}),
      ),
    );
  }

  group('optional single-content request body', () {
    test('omits Content-Type when body is not provided', () async {
      final result = await buildApi().echoOneOfPrimitive();

      requireSuccess(result);
      final recordedRequest = await imposterServer.takeRequest();
      expect(recordedRequest.headers['content-type'], isNull);
    });

    test('sends Content-Type application/json when body is provided', () async {
      final result = await buildApi().echoOneOfPrimitive(
        body: const OneOfPrimitiveString('hello'),
      );

      requireSuccess(result);
      final recordedRequest = await imposterServer.takeRequest();
      expect(recordedRequest.headers['content-type'], 'application/json');
    });
  });
}
