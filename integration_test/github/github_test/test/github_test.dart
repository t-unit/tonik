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

  CustomServer buildServer({required String responseStatus}) {
    return CustomServer(
      baseUrl: baseUrl,
      serverConfig: ServerConfig.clientFactory(
        () => Dio(
          BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  // ── GET / (metaroot) ──────────────────────────────────────────────

  group('Metaroot', () {
    test('metaroot 200', () async {
      final api = MetaApi(buildServer(responseStatus: '200'));

      final result = await api.metaroot();

      expect(result, isA<TonikSuccess<Root, Response<Object?>>>());
      final success = result as TonikSuccess<Root, Response<Object?>>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/');
    });
  });

  // ── GET /meta (metaget) ───────────────────────────────────────────

  group('Metaget', () {
    test('metaget 200', () async {
      final api = MetaApi(buildServer(responseStatus: '200'));

      final result = await api.metaget();

      expect(result, isA<TonikSuccess<MetagetResponse, Response<Object?>>>());
      final success =
          result as TonikSuccess<MetagetResponse, Response<Object?>>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<MetagetResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/meta');
    });
  });

  // ── GET /rate_limit ───────────────────────────────────────────────

  group('RateLimitget', () {
    test('rate_limitget 200', () async {
      final api = RateLimitApi(buildServer(responseStatus: '200'));

      final result = await api.rateLimitget();

      expect(
        result,
        isA<TonikSuccess<RateLimitgetResponse, Response<Object?>>>(),
      );
      final success =
          result as TonikSuccess<RateLimitgetResponse, Response<Object?>>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<RateLimitgetResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/rate_limit');
    });

    test('rate_limitget 404', () async {
      final api = RateLimitApi(buildServer(responseStatus: '404'));

      final result = await api.rateLimitget();

      expect(
        result,
        isA<TonikSuccess<RateLimitgetResponse, Response<Object?>>>(),
      );
      final success =
          result as TonikSuccess<RateLimitgetResponse, Response<Object?>>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<RateLimitgetResponse404>());
    });
  });

  // ── GET /users/{username} ──────────────────────────────────────────

  group('UsersgetByUsername', () {
    test('usersget_by_username 200', () async {
      final api = UsersApi(buildServer(responseStatus: '200'));

      final result = await api.usersgetByUsername(username: 'octocat');

      expect(
        result,
        isA<TonikSuccess<UsersgetByUsernameResponse, Response<Object?>>>(),
      );
      final success =
          result as TonikSuccess<UsersgetByUsernameResponse, Response<Object?>>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<UsersgetByUsernameResponse200>());

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/users/octocat');
    });

    test('usersget_by_username 404', () async {
      final api = UsersApi(buildServer(responseStatus: '404'));

      final result = await api.usersgetByUsername(username: 'nonexistent');

      expect(
        result,
        isA<TonikSuccess<UsersgetByUsernameResponse, Response<Object?>>>(),
      );
      final success =
          result as TonikSuccess<UsersgetByUsernameResponse, Response<Object?>>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<UsersgetByUsernameResponse404>());
    });
  });

  // ── GET /repos/{owner}/{repo} ──────────────────────────────────────
  // Blocked by Bug #5: nullable schema fromJson doesn't handle null input.
  // The full-repository schema has a required-but-nullable `license` field.

  group('Reposget', () {
    test('reposget 200', () async {
      final api = ReposApi(buildServer(responseStatus: '200'));

      final result = await api.reposget(
        owner: 'octocat',
        repo: 'hello-world',
      );

      expect(result, isA<TonikSuccess<ReposgetResponse, Response<Object?>>>());
    });

    test('reposget 404', () async {
      final api = ReposApi(buildServer(responseStatus: '404'));

      final result = await api.reposget(
        owner: 'nonexistent',
        repo: 'nonexistent',
      );

      expect(result, isA<TonikSuccess<ReposgetResponse, Response<Object?>>>());
      final success =
          result as TonikSuccess<ReposgetResponse, Response<Object?>>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<ReposgetResponse404>());
    });
  });

  // ── GET /repos/{owner}/{repo}/issues ───────────────────────────────
  // Blocked by Bug #5 for 200 responses.

  group('IssueslistForRepo', () {
    test('issueslist_for_repo 200', () async {
      final api = IssuesApi(buildServer(responseStatus: '200'));

      final result = await api.issueslistForRepo(
        owner: 'octocat',
        repo: 'hello-world',
      );

      expect(
        result,
        isA<TonikSuccess<IssueslistForRepoResponse, Response<Object?>>>(),
      );
    });

    test('issueslist_for_repo 404', () async {
      final api = IssuesApi(buildServer(responseStatus: '404'));

      final result = await api.issueslistForRepo(
        owner: 'nonexistent',
        repo: 'nonexistent',
      );

      expect(
        result,
        isA<TonikSuccess<IssueslistForRepoResponse, Response<Object?>>>(),
      );
      final success =
          result as TonikSuccess<IssueslistForRepoResponse, Response<Object?>>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<IssueslistForRepoResponse404>());
    });
  });

  // ── GET /repos/{owner}/{repo}/issues/{issue_number} ────────────────
  // Blocked by Bug #5 for 200 responses.

  group('Issuesget', () {
    test('issuesget 200', () async {
      final api = IssuesApi(buildServer(responseStatus: '200'));

      final result = await api.issuesget(
        owner: 'octocat',
        repo: 'hello-world',
        issueNumber: 1,
      );

      expect(result, isA<TonikSuccess<IssuesgetResponse, Response<Object?>>>());
    });

    test('issuesget 404', () async {
      final api = IssuesApi(buildServer(responseStatus: '404'));

      final result = await api.issuesget(
        owner: 'nonexistent',
        repo: 'nonexistent',
        issueNumber: 999,
      );

      expect(result, isA<TonikSuccess<IssuesgetResponse, Response<Object?>>>());
      final success =
          result as TonikSuccess<IssuesgetResponse, Response<Object?>>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<IssuesgetResponse404>());
    });
  });
}
