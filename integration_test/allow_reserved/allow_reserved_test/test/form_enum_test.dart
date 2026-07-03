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

  group('form allowReserved enum', () {
    test('keeps reserved survivors literal and encodes the form delimiters',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormAllowReservedEnum(
        reserved: ReservedChoice.gAmpersandHEqualsIPlusJ,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'reserved=g%26h%3Di%2Bj',
      );
    });

    test('sibling default enum is fully percent-encoded', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormAllowReservedEnum(
        notReserved: ReservedChoice.gAmpersandHEqualsIPlusJ,
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'notReserved=g%26h%3Di%2Bj',
      );
    });
  });

  group('form allowReserved enum list', () {
    test('keeps reserved survivors literal and encodes the form delimiters',
        () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormAllowReservedEnumList(
        reservedList: [
          ReservedChoice.aSlashBc,
          ReservedChoice.gAmpersandHEqualsIPlusJ,
        ],
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'reservedList=a/b:c,g%26h%3Di%2Bj',
      );
    });

    test('sibling default enum list is fully percent-encoded', () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormAllowReservedEnumList(
        notReservedList: [
          ReservedChoice.aSlashBc,
          ReservedChoice.gAmpersandHEqualsIPlusJ,
        ],
      );

      expect(response, isA<TonikSuccess<void>>());
      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.query,
        'notReservedList=a%2Fb%3Ac,g%26h%3Di%2Bj',
      );
    });
  });
}
