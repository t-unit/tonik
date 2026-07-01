import 'package:allow_reserved_api/allow_reserved_api.dart';
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

  QueryApi buildQueryApi({required String responseStatus}) {
    return QueryApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  const objectValue = {'k1': 'a/b:c?d@e;f', 'k2': 'g&h=i+j k#l[m]n'};

  group('deepObject allowReserved', () {
    test(
        'keeps reserved value survivors literal, encodes form delimiters, '
        'brackets and hash, and leaves the name brackets intact', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectAllowReserved(
        reservedObject: objectValue,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'reservedObject%5Bk1%5D=a/b:c?d@e;f'
        '&reservedObject%5Bk2%5D=g%26h%3Di%2Bj%20k%23l%5Bm%5Dn',
      );
    });

    test('sibling default object is fully percent-encoded', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testDeepObjectAllowReserved(
        notReservedObject: objectValue,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'notReservedObject%5Bk1%5D=a%2Fb%3Ac%3Fd%40e%3Bf'
        '&notReservedObject%5Bk2%5D=g%26h%3Di%2Bj%20k%23l%5Bm%5Dn',
      );
    });
  });
}
