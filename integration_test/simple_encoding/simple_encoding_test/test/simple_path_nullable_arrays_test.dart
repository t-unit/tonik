import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  SimpleEncodingApi buildApi() {
    return SimpleEncodingApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(headers: {'X-Response-Status': '200'}),
      ),
    );
  }

  group('Simple path nullable array', () {
    test(
      'string array escapes special chars and encodes null as empty',
      () async {
        final api = buildApi();
        final response = await api.testSimplePathNullableStringArray(
          values: ['hello world', 'foo/bar', null],
        );

        expect(response, isTonikSuccess);
        final success = requireSuccess(response);
        expect(success.response.statusCode, 200);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.uri.path,
          '/v1/simple/array/nullable-string/hello%20world,foo%2Fbar,',
        );
      },
    );

    test('integer array encodes null element as empty', () async {
      final api = buildApi();
      final response = await api.testSimplePathNullableIntegerArray(
        values: [1, null, 2],
      );

      expect(response, isTonikSuccess);
      final success = requireSuccess(response);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();
      expect(
        recordedRequest.uri.path,
        '/v1/simple/array/nullable-integer/1,,2',
      );
    });
  });
}
