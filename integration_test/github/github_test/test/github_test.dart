import 'package:dio/dio.dart';
import 'package:github_api/github_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}';
  });

  // ── Helper ───────────────────────────────────────────────────────────

  /// Creates a [MetaApi] with the given response status.
  MetaApi buildMetaApi({required String responseStatus}) {
    return MetaApi(
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

  /// Creates a [Dio] instance for direct operation usage.
  Dio buildDio({required String responseStatus}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'X-Response-Status': responseStatus},
      ),
    );
  }

  // ── GET / (metaroot) ──────────────────────────────────────────────

  group('Metaroot', () {
    test('metaroot 200', () async {
      final api = buildMetaApi(responseStatus: '200');

      final result = await api.metaroot();

      expect(result, isA<TonikSuccess<Root>>());
      final success = result as TonikSuccess<Root>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/');
    });
  });

  // ── GET /meta (metaget) ───────────────────────────────────────────

  group('Metaget', () {
    test('metaget 200', () async {
      final api = buildMetaApi(responseStatus: '200');

      final result = await api.metaget();

      expect(result, isA<TonikSuccess<MetagetResponse>>());
      final success = result as TonikSuccess<MetagetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<MetagetResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/meta');
    });
  });

  // ── GET /rate_limit ───────────────────────────────────────────────

  group('RateLimitget', () {
    test('rate_limitget 200', () async {
      final op = RateLimitget(buildDio(responseStatus: '200'));

      final result = await op();

      expect(result, isA<TonikSuccess<RateLimitgetResponse>>());
      final success = result as TonikSuccess<RateLimitgetResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<RateLimitgetResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/rate_limit');
    });

    test('rate_limitget 404', () async {
      final op = RateLimitget(buildDio(responseStatus: '404'));

      final result = await op();

      expect(result, isA<TonikSuccess<RateLimitgetResponse>>());
      final success = result as TonikSuccess<RateLimitgetResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<RateLimitgetResponse404>());
    });
  });

  // ── GET /users/{username} ──────────────────────────────────────────

  group('UsersgetByUsername', () {
    test('usersget_by_username 200', () async {
      final op = UsersgetByUsername(buildDio(responseStatus: '200'));

      final result = await op(username: 'octocat');

      expect(result, isA<TonikSuccess<UsersgetByUsernameResponse>>());
      final success = result as TonikSuccess<UsersgetByUsernameResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<UsersgetByUsernameResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/users/octocat');
    });

    test('usersget_by_username 404', () async {
      final op = UsersgetByUsername(buildDio(responseStatus: '404'));

      final result = await op(username: 'nonexistent');

      expect(result, isA<TonikSuccess<UsersgetByUsernameResponse>>());
      final success = result as TonikSuccess<UsersgetByUsernameResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<UsersgetByUsernameResponse404>());
    });
  });

  // ── GET /repos/{owner}/{repo} ──────────────────────────────────────
  // Blocked by Bug #5: nullable schema fromJson doesn't handle null input.
  // The full-repository schema has a required-but-nullable `license` field.

  group('Reposget', () {
    test('reposget 200', () async {
      final op = Reposget(buildDio(responseStatus: '200'));

      final result = await op(owner: 'octocat', repo: 'hello-world');

      expect(result, isA<TonikSuccess<ReposgetResponse>>());
    });

    test('reposget 404', () async {
      final op = Reposget(buildDio(responseStatus: '404'));

      final result = await op(owner: 'nonexistent', repo: 'nonexistent');

      expect(result, isA<TonikSuccess<ReposgetResponse>>());
      final success = result as TonikSuccess<ReposgetResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<ReposgetResponse404>());
    });
  });

  // ── GET /repos/{owner}/{repo}/issues ───────────────────────────────
  // Blocked by Bug #5 for 200 responses.

  group('IssueslistForRepo', () {
    test('issueslist_for_repo 200', () async {
      final op = IssueslistForRepo(buildDio(responseStatus: '200'));

      final result = await op(owner: 'octocat', repo: 'hello-world');

      expect(result, isA<TonikSuccess<IssueslistForRepoResponse>>());
    });

    test('issueslist_for_repo 404', () async {
      final op = IssueslistForRepo(buildDio(responseStatus: '404'));

      final result = await op(owner: 'nonexistent', repo: 'nonexistent');

      expect(result, isA<TonikSuccess<IssueslistForRepoResponse>>());
      final success = result as TonikSuccess<IssueslistForRepoResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<IssueslistForRepoResponse404>());
    });
  });

  // ── GET /repos/{owner}/{repo}/issues/{issue_number} ────────────────
  // Blocked by Bug #5 for 200 responses.

  group('Issuesget', () {
    test('issuesget 200', () async {
      final op = Issuesget(buildDio(responseStatus: '200'));

      final result = await op(
        owner: 'octocat',
        repo: 'hello-world',
        issueNumber: 1,
      );

      expect(result, isA<TonikSuccess<IssuesgetResponse>>());
    });

    test('issuesget 404', () async {
      final op = Issuesget(buildDio(responseStatus: '404'));

      final result = await op(
        owner: 'nonexistent',
        repo: 'nonexistent',
        issueNumber: 999,
      );

      expect(result, isA<TonikSuccess<IssuesgetResponse>>());
      final success = result as TonikSuccess<IssuesgetResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<IssuesgetResponse404>());
    });
  });
}
