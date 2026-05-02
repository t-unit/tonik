import 'package:dio/dio.dart';
import 'package:path_encoding_api/path_encoding_api.dart';
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

  SimpleApi buildSimpleApi() {
    return SimpleApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(baseOptions: BaseOptions()),
      ),
    );
  }

  group('Simple style - string-value map with literal suffix', () {
    test('map (explode=false) encodes key,value pairs before suffix', () async {
      final api = buildSimpleApi();
      final response = await api.testSimpleMapStringWithSuffix(
        m: const {'k': 'v'},
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.path,
        '/v1/simple/encode-suffix/map-string/k,v.json',
      );
    });

    test('map (explode=true) encodes key=value pairs before suffix', () async {
      final api = buildSimpleApi();
      final response = await api.testSimpleMapStringExplodeWithSuffix(
        m: const {'k': 'v'},
      );

      expect(response, isA<TonikSuccess<EchoResponse>>());
      final success = response as TonikSuccess<EchoResponse>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.uri.path,
        '/v1/simple/encode-suffix/map-string-explode/k=v.json',
      );
    });
  });

  group('Simple style - Special character property names', () {
    test(
      'special keys (explode=false) encodes keys with URI encoding',
      () async {
        final api = buildSimpleApi();
        final response = await api.testSimpleSpecialKeys(
          value: const SpecialKeyObject(myField: 'hello', aEqualsB: 42),
        );

        expect(response, isA<TonikSuccess<EchoResponse>>());
        final success = response as TonikSuccess<EchoResponse>;
        expect(success.response.statusCode, 200);

        // explode=false: k1,v1,k2,v2
        expect(
          success.response.requestOptions.uri.path,
          '/v1/simple/special-keys/my.field,hello,a%3Db,42',
        );
      },
    );

    test(
      'special keys (explode=true) encodes keys with URI encoding',
      () async {
        final api = buildSimpleApi();
        final response = await api.testSimpleSpecialKeysExplode(
          value: const SpecialKeyObject(myField: 'hello', aEqualsB: 42),
        );

        expect(response, isA<TonikSuccess<EchoResponse>>());
        final success = response as TonikSuccess<EchoResponse>;
        expect(success.response.statusCode, 200);

        // explode=true: k1=v1,k2=v2 — a=b must be encoded as a%3Db
        expect(
          success.response.requestOptions.uri.path,
          '/v1/simple/special-keys/explode/my.field=hello,a%3Db=42',
        );
      },
    );
  });
}
