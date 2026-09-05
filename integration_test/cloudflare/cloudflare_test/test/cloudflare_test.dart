import 'package:cloudflare_api/cloudflare_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/client/v4';
  });

  // ── Helper ───────────────────────────────────────────────────────────

  CustomServer buildServer({required String responseStatus}) {
    return CustomServer(
      baseUrl: baseUrl,
      serverConfig: testServerConfig(
        headers: {'X-Response-Status': responseStatus},
      ),
    );
  }

  // ── AccountsListAccounts ─────────────────────────────────────────────

  group('AccountsListAccounts', () {
    test('accountsListAccounts 200', () async {
      final api = AccountsApi(buildServer(responseStatus: '200'));

      final result = await api.accountsListAccounts();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<AccountsListAccountsResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/client/v4/accounts');
    });

    test('accountsListAccounts 4xx', () async {
      final api = AccountsApi(buildServer(responseStatus: '403'));

      final result = await api.accountsListAccounts();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 403);
      expect(success.value, isA<AccountsListAccountsResponse4XX>());
    });
  });

  // ── ZonesGet ─────────────────────────────────────────────────────────

  group('ZonesGet', () {
    test('zonesGet 200', () async {
      final api = ZoneApi(buildServer(responseStatus: '200'));

      final result = await api.zonesGet();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      expect(success.value, isA<ZonesGetResponse200>());
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/client/v4/zones');
    });

    test('zonesGet 4xx', () async {
      final api = ZoneApi(buildServer(responseStatus: '400'));

      final result = await api.zonesGet();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 400);
      expect(success.value, isA<ZonesGetResponse4XX>());
    });
  });
}
