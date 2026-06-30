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

  // Reserved survivors (/ : ? @ ; ,), the form delimiters (& = +), a space and
  // (# [ ]) so a single value exercises every encoding branch at once.
  const value = 'a/b:c?d@e;f,g&h=i+j k#l[m]n';

  group('form allowReserved', () {
    test('keeps the reserved set literal and encodes only the survivors',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormAllowReserved(reserved: value);

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'reserved=a/b:c?d@e;f,g%26h%3Di%2Bj%20k%23l%5Bm%5Dn',
      );
    });

    test('sibling default parameter is fully percent-encoded', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormAllowReserved(notReserved: value);

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'notReserved=a%2Fb%3Ac%3Fd%40e%3Bf%2Cg%26h%3Di%2Bj%20k%23l%5Bm%5Dn',
      );
    });

    test('reserved and default siblings encode the same value differently',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormAllowReserved(
        reserved: value,
        notReserved: value,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'reserved=a/b:c?d@e;f,g%26h%3Di%2Bj%20k%23l%5Bm%5Dn'
        '&notReserved=a%2Fb%3Ac%3Fd%40e%3Bf%2Cg%26h%3Di%2Bj%20k%23l%5Bm%5Dn',
      );
    });
  });

  // The reserved survivors and the encodables are split across two items so the
  // comma joining the non-explode list stays an unambiguous delimiter.
  const listValues = ['a/b:c?d@e;f', 'g&h=i+j k#l[m]n'];

  group('form allowReserved list', () {
    test('keeps reserved survivors literal and encodes only the survivors',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormAllowReservedList(
        reservedList: listValues,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'reservedList=a/b:c?d@e;f,g%26h%3Di%2Bj%20k%23l%5Bm%5Dn',
      );
    });

    test('sibling default list is fully percent-encoded', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormAllowReservedList(
        notReservedList: listValues,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'notReservedList=a%2Fb%3Ac%3Fd%40e%3Bf,g%26h%3Di%2Bj%20k%23l%5Bm%5Dn',
      );
    });
  });
}
