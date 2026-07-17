import 'package:composition_api/composition_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

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
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(headers: {'X-Response-Body': '"hello"'}),
        ),
      ),
    );
  }

  group('optional single-content request body', () {
    test('omits Content-Type when body is not provided', () async {
      final result = await buildApi().echoOneOfPrimitive();

      final success = result as TonikSuccess<OneOfPrimitive>;
      expect(success.response.requestOptions.headers['content-type'], isNull);
    });

    test('sends Content-Type application/json when body is provided', () async {
      final result = await buildApi().echoOneOfPrimitive(
        body: const OneOfPrimitiveString('hello'),
      );

      final success = result as TonikSuccess<OneOfPrimitive>;
      expect(
        success.response.requestOptions.headers['content-type'],
        'application/json',
      );
    });
  });
}
