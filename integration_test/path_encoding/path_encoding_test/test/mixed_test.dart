import 'package:dio/dio.dart';
import 'package:path_encoding_api/path_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  const port = 8090;
  const baseUrl = 'http://localhost:$port/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  LabelApi buildLabelApi() {
    return LabelApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(baseOptions: BaseOptions()),
      ),
    );
  }

  group('Mixed styles in same path', () {
    test('label and matrix params in same path encode correctly', () async {
      final api = buildLabelApi();
      final response = await api.testMixedStyles(
        labelValue: 'hello',
        matrixValue: 'world',
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);
      // First param (label): .hello
      // Second param (matrix): ;matrixValue=world
      expect(
        success.response.requestOptions.uri.path,
        '/v1/mixed/.hello/;matrixValue=world',
      );
    });
  });
}
