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

  group('form allowReserved object with list property', () {
    test('keeps the list-property items reserved chars literal', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormObjectAllowReserved(
        reservedObject: const ReservedListObject(tags: listValues),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'reservedObject=tags,a/b:c?d@e;f,g%26h%3Di%2Bj%20k%23l%5Bm%5Dn',
      );
    });

    test('sibling default object list property is fully percent-encoded',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormObjectAllowReserved(
        notReservedObject: const ReservedListObject(tags: listValues),
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'notReservedObject=tags,a%2Fb%3Ac%3Fd%40e%3Bf,'
        'g%26h%3Di%2Bj%20k%23l%5Bm%5Dn',
      );
    });
  });
}
