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

  const listValues = ['a/b:c?d@e;f', 'g&h=i+j k#l[m]n'];

  group('spaceDelimited allowReserved', () {
    test(
        'keeps reserved survivors literal, encodes form delimiters, brackets '
        'and hash, and leaves the %20 delimiter intact', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedAllowReserved(
        reservedList: listValues,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'reservedList=a/b:c?d@e;f%20g%26h%3Di%2Bj%20k%23l%5Bm%5Dn',
      );
    });

    test('sibling default list is fully percent-encoded', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testSpaceDelimitedAllowReserved(
        notReservedList: listValues,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'notReservedList=a%2Fb%3Ac%3Fd%40e%3Bf%20g%26h%3Di%2Bj%20k%23l%5Bm%5Dn',
      );
    });
  });
}
