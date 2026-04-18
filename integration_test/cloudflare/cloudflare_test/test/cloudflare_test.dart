import 'package:cloudflare_api/cloudflare_api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/client/v4';
  });

  // ── Helper ───────────────────────────────────────────────────────────

  DefaultApi buildDefaultApi({required String responseStatus}) {
    return DefaultApi(
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

  // ── AccountsListAccounts ─────────────────────────────────────────────

  group('AccountsListAccounts', () {
    test('accountsListAccounts 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.accountsListAccounts();

      expect(result, isA<TonikSuccess<AccountsListAccountsResponse>>());
      final success = result as TonikSuccess<AccountsListAccountsResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<AccountsListAccountsResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/client/v4/accounts');
    });

    test('accountsListAccounts 4xx', () async {
      final api = buildDefaultApi(responseStatus: '403');

      final result = await api.accountsListAccounts();

      expect(result, isA<TonikSuccess<AccountsListAccountsResponse>>());
      final success = result as TonikSuccess<AccountsListAccountsResponse>;
      expect(success.response.statusCode, 403);
      expect(success.value, isA<AccountsListAccountsResponse4XX>());
    });
  });

  // ── ZonesGet ─────────────────────────────────────────────────────────

  group('ZonesGet', () {
    test('zonesGet 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.zonesGet();

      expect(result, isA<TonikSuccess<ZonesGetResponse>>());
      final success = result as TonikSuccess<ZonesGetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<ZonesGetResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/client/v4/zones');
    });

    test('zonesGet 4xx', () async {
      final api = buildDefaultApi(responseStatus: '400');

      final result = await api.zonesGet();

      expect(result, isA<TonikSuccess<ZonesGetResponse>>());
      final success = result as TonikSuccess<ZonesGetResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<ZonesGetResponse4XX>());
    });
  });
}
