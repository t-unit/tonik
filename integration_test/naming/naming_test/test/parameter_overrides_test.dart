import 'package:naming_api/naming_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late ParameterOverridesApi api;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    api = ParameterOverridesApi(
      CustomServer(
        baseUrl: 'http://localhost:${imposterServer.port}',
        serverConfig: testServerConfig(),
      ),
    );
  });

  test(
    'shared parameters keep independent names and original wire keys',
    () async {
      final first = await api.renamedSharedParameters(
        itemId: 'first',
        maxResults: 10,
        token: 'first-token',
        session: 'first-session',
      );
      expect(first, isTonikSuccess);
      final firstRequest = await imposterServer.takeRequest();
      expect(firstRequest.uri.path, '/parameter-overrides/first');
      expect(firstRequest.uri.queryParameters, {'limit': '10'});
      expect(firstRequest.headers['x-trace'], 'first-token');
      expect(firstRequest.headers['cookie'], 'session_id=first-session');

      final second = await api.secondSharedParameters(
        resourceId: 'second',
        resultCount: 20,
        traceToken: 'second-token',
        sessionToken: 'second-session',
      );
      expect(second, isTonikSuccess);
      final secondRequest = await imposterServer.takeRequest();
      expect(secondRequest.uri.path, '/parameter-overrides/second');
      expect(secondRequest.uri.queryParameters, {'limit': '20'});
      expect(secondRequest.headers['x-trace'], 'second-token');
      expect(secondRequest.headers['cookie'], 'session_id=second-session');

      final unchanged = await api.unchangedSharedParameters(
        id: 'third',
        limit: 30,
        trace: 'third-token',
        sessionId: 'third-session',
      );
      expect(unchanged, isTonikSuccess);
      final unchangedRequest = await imposterServer.takeRequest();
      expect(unchangedRequest.uri.path, '/parameter-overrides/third');
      expect(unchangedRequest.uri.queryParameters, {'limit': '30'});
      expect(unchangedRequest.headers['x-trace'], 'third-token');
      expect(unchangedRequest.headers['cookie'], 'session_id=third-session');
    },
  );
}
