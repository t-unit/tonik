import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
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

  SimpleEncodingApi buildApi() {
    return SimpleEncodingApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(headers: {'X-Response-Status': '200'}),
        ),
      ),
    );
  }

  group('Simple path nullable array', () {
    test('string array escapes special chars and encodes null as empty',
        () async {
      final api = buildApi();
      final response = await api.testSimplePathNullableStringArray(
        values: ['hello world', 'foo/bar', null],
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.path,
        '/v1/simple/array/nullable-string/hello%20world,foo%2Fbar,',
      );
    });

    test('integer array encodes null element as empty', () async {
      final api = buildApi();
      final response = await api.testSimplePathNullableIntegerArray(
        values: [1, null, 2],
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.path,
        '/v1/simple/array/nullable-integer/1,,2',
      );
    });
  });
}
