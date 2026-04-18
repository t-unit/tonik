import 'package:dio/dio.dart';
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

  // ── GetCurrentUser ───────────────────────────────────────────────────

  group('GetCurrentUser', () {
    test('getCurrentUser 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.totemUsersMobileApiGetCurrentUser();

      expect(result, isA<TonikSuccess<UserSchema>>());
      final success = result as TonikSuccess<UserSchema>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/mobile/protected/users/current');
    });

    test('getCurrentUser error returns TonikError', () async {
      final api = buildDefaultApi(responseStatus: '401');

      final result = await api.totemUsersMobileApiGetCurrentUser();

      expect(result, isA<TonikError<UserSchema>>());
      final error = result as TonikError<UserSchema>;
      expect(error.type, TonikErrorType.decoding);
    });
  });

  // ── GetUserProfile ───────────────────────────────────────────────────

  group('GetUserProfile', () {
    test('getUserProfile 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.totemUsersMobileApiGetUserProfile(
        userSlug: 'test-user',
      );

      expect(result, isA<TonikSuccess<PublicUserSchema>>());
      final success = result as TonikSuccess<PublicUserSchema>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/mobile/protected/users/profile/test-user');
    });

    test('getUserProfile error returns TonikError', () async {
      final api = buildDefaultApi(responseStatus: '404');

      final result = await api.totemUsersMobileApiGetUserProfile(
        userSlug: 'nonexistent',
      );

      expect(result, isA<TonikError<PublicUserSchema>>());
      final error = result as TonikError<PublicUserSchema>;
      expect(error.type, TonikErrorType.decoding);
    });
  });

  // ── ListSpaces ───────────────────────────────────────────────────────

  group('ListSpaces', () {
    test('listSpaces 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.totemSpacesMobileApiMobileApiListSpaces();

      expect(result, isA<TonikSuccess<PagedMobileSpaceDetailSchema>>());
      final success = result as TonikSuccess<PagedMobileSpaceDetailSchema>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/mobile/protected/spaces/');
    });
  });

  // ── ListPosts ────────────────────────────────────────────────────────

  group('ListPosts', () {
    test('listPosts 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.totemBlogMobileApiListPosts();

      expect(result, isA<TonikSuccess<PagedBlogPostListSchema>>());
      final success = result as TonikSuccess<PagedBlogPostListSchema>;
      expect(success.response.statusCode, 200);

      final uri = success.response.requestOptions.uri;
      expect(uri.path, '/api/mobile/protected/blog/posts');
    });

    test('listPosts with pagination', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.totemBlogMobileApiListPosts(
        limit: 10,
        offset: 20,
      );

      expect(result, isA<TonikSuccess<PagedBlogPostListSchema>>());

      final success = result as TonikSuccess<PagedBlogPostListSchema>;
      final uri = success.response.requestOptions.uri;
      expect(uri.queryParameters['limit'], '10');
      expect(uri.queryParameters['offset'], '20');
    });
  });

  // ── DeleteCurrentUser ────────────────────────────────────────────────

  group('DeleteCurrentUser', () {
    test('deleteCurrentUser 200', () async {
      final api = buildDefaultApi(responseStatus: '200');

      final result = await api.totemUsersMobileApiDeleteCurrentUser();

      expect(result, isA<TonikSuccess<bool>>());
      final success = result as TonikSuccess<bool>;
      expect(success.response.statusCode, 200);

      expect(success.response.requestOptions.method, 'DELETE');
    });
  });
}
