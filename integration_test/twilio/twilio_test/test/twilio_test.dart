import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';
import 'package:twilio_api/twilio_api.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  // ── Helpers ──────────────────────────────────────────────────────────

  Api20100401AccountApi buildAccountApi({required String responseStatus}) {
    return Api20100401AccountApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  Api20100401MessageApi buildMessageApi({required String responseStatus}) {
    return Api20100401MessageApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  Api20100401CallApi buildCallApi({required String responseStatus}) {
    return Api20100401CallApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  Api20100401BalanceApi buildBalanceApi({required String responseStatus}) {
    return Api20100401BalanceApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  // ── ListAccount ──────────────────────────────────────────────────────

  group('ListAccount', () {
    test('listAccount 200', () async {
      final api = buildAccountApi(responseStatus: '200');

      final result = await api.listAccount();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/2010-04-01/Accounts.json');
    });

    test('listAccount with query params', () async {
      final api = buildAccountApi(responseStatus: '200');

      final result = await api.listAccount(pageSize: 10);

      expect(result, isTonikSuccess);
      requireSuccess(result);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/2010-04-01/Accounts.json');
      expect(uri.queryParameters['PageSize'], '10');
    });

    test('listAccount error returns TonikError', () async {
      final api = buildAccountApi(responseStatus: '401');

      final result = await api.listAccount();

      expect(result, isTonikError);
      final error = requireError(result);
      expect(error.type, TonikErrorType.decoding);
    });
  });

  // ── FetchAccount ─────────────────────────────────────────────────────

  group('FetchAccount', () {
    test('fetchAccount 200', () async {
      final api = buildAccountApi(responseStatus: '200');

      final result = await api.fetchAccount(sid: 'AC_test123');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/2010-04-01/Accounts/AC_test123.json');
    });

    test('fetchAccount error returns TonikError', () async {
      final api = buildAccountApi(responseStatus: '404');

      final result = await api.fetchAccount(sid: 'nonexistent');

      expect(result, isTonikError);
    });
  });

  // ── CreateAccount ────────────────────────────────────────────────────

  group('CreateAccount', () {
    test('createAccount 201', () async {
      final api = buildAccountApi(responseStatus: '201');

      final result = await api.createAccount();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 201);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/2010-04-01/Accounts.json');
      expect(recordedRequest.method, 'POST');
    });
  });

  // ── ListMessage ──────────────────────────────────────────────────────

  group('ListMessage', () {
    test('listMessage 200', () async {
      final api = buildMessageApi(responseStatus: '200');

      final result = await api.listMessage(accountSid: 'AC_mock');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/2010-04-01/Accounts/AC_mock/Messages.json');
    });
  });

  // ── CreateMessage (form-urlencoded body) ─────────────────────────────

  group('CreateMessage', () {
    test('createMessage 201', () async {
      final api = buildMessageApi(responseStatus: '201');

      final result = await api.createMessage(accountSid: 'AC_mock');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 201);
      final recordedRequest = await imposterServer.takeRequest();

      expect(
        recordedRequest.uri.path,
        '/2010-04-01/Accounts/AC_mock/Messages.json',
      );
      expect(recordedRequest.method, 'POST');
    });
  });

  // ── ListCall ─────────────────────────────────────────────────────────

  group('ListCall', () {
    test('listCall 200', () async {
      final api = buildCallApi(responseStatus: '200');

      final result = await api.listCall(accountSid: 'AC_mock');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/2010-04-01/Accounts/AC_mock/Calls.json');
    });
  });

  // ── FetchBalance ─────────────────────────────────────────────────────

  group('FetchBalance', () {
    test('fetchBalance 200', () async {
      final api = buildBalanceApi(responseStatus: '200');

      final result = await api.fetchBalance(accountSid: 'AC_mock');

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/2010-04-01/Accounts/AC_mock/Balance.json');
    });
  });

  // ── DeleteMessage ────────────────────────────────────────────────────

  group('DeleteMessage', () {
    test('deleteMessage 204', () async {
      final api = buildMessageApi(responseStatus: '204');

      final result = await api.deleteMessage(
        accountSid: 'AC_mock',
        sid: 'SM_delete_me',
      );

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 204);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(
        uri.path,
        '/2010-04-01/Accounts/AC_mock/Messages/SM_delete_me.json',
      );
      expect(recordedRequest.method, 'DELETE');
    });
  });
}
