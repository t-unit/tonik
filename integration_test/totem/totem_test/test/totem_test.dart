import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';
import 'package:totem_api/totem_api.dart';

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
      serverConfig: testServerConfig(
        headers: {'X-Response-Status': responseStatus},
      ),
    );
  }

  // ── GetCurrentUser ───────────────────────────────────────────────────

  group('GetCurrentUser', () {
    test('getCurrentUser 200', () async {
      final api = UsersApi(buildServer(responseStatus: '200'));

      final result = await api.totemUsersMobileApiGetCurrentUser();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/mobile/protected/users/current');
    });

    test('getCurrentUser error returns TonikError', () async {
      final api = UsersApi(buildServer(responseStatus: '401'));

      final result = await api.totemUsersMobileApiGetCurrentUser();

      expect(result, isTonikError);
      final error = requireError(result);
      expect(error.type, TonikErrorType.decoding);
    });
  });

  // ── GetUserProfile ───────────────────────────────────────────────────

  group('GetUserProfile', () {
    test('getUserProfile 200', () async {
      final api = UsersApi(buildServer(responseStatus: '200'));

      final result = await api.totemUsersMobileApiGetUserProfile(
        userSlug: 'test-user',
      );

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/mobile/protected/users/profile/test-user');
    });

    test('getUserProfile error returns TonikError', () async {
      final api = UsersApi(buildServer(responseStatus: '404'));

      final result = await api.totemUsersMobileApiGetUserProfile(
        userSlug: 'nonexistent',
      );

      expect(result, isTonikError);
      final error = requireError(result);
      expect(error.type, TonikErrorType.decoding);
    });
  });

  // ── ListSpaces ───────────────────────────────────────────────────────

  group('ListSpaces', () {
    test('listSpaces 200', () async {
      final api = SpacesApi(buildServer(responseStatus: '200'));

      final result = await api.totemSpacesMobileApiMobileApiListSpaces();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/mobile/protected/spaces/');
    });
  });

  // ── ListPosts ────────────────────────────────────────────────────────

  group('ListPosts', () {
    test('listPosts 200', () async {
      final api = BlogApi(buildServer(responseStatus: '200'));

      final result = await api.totemBlogMobileApiListPosts();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      final uri = recordedRequest.uri;
      expect(uri.path, '/api/mobile/protected/blog/posts');
    });

    test('listPosts with pagination', () async {
      final api = BlogApi(buildServer(responseStatus: '200'));

      final result = await api.totemBlogMobileApiListPosts(
        limit: 10,
        offset: 20,
      );

      expect(result, isTonikSuccess);

      requireSuccess(result);
      final recordedRequest = await imposterServer.takeRequest();
      final uri = recordedRequest.uri;
      expect(uri.queryParameters['limit'], '10');
      expect(uri.queryParameters['offset'], '20');
    });
  });

  // ── DeleteCurrentUser ────────────────────────────────────────────────

  group('DeleteCurrentUser', () {
    test('deleteCurrentUser 200', () async {
      final api = UsersApi(buildServer(responseStatus: '200'));

      final result = await api.totemUsersMobileApiDeleteCurrentUser();

      expect(result, isTonikSuccess);
      final success = requireSuccess(result);
      expect(success.response.statusCode, 200);
      final recordedRequest = await imposterServer.takeRequest();

      expect(recordedRequest.method, 'DELETE');
    });
  });
}
