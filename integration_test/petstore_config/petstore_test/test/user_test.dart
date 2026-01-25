import 'package:dio/dio.dart';
import 'package:petstore_api/petstore_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  const port = 8084;
  const baseUrl = 'http://localhost:$port/api/v3';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  AccountsApi buildUserApi({required String responseStatus}) {
    return AccountsApi(
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

  group('createUser', () {
    test('200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final user = await userApi.createUser(
        body: const UserPostBodyRequestBodyJson(
          Account(
            id: 1,
            username: 'test',
            givenName: 'test',
            familyName: 'test',
            emailAddress: 'test@test.com',
            password: 'test',
            phone: 'test',
            accountStatus: 1,
          ),
        ),
      );
      final success = user as TonikSuccess<CreateUserResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<CreateUserResponse200>());
      final responseBody = (success.value as CreateUserResponse200).body;
      expect(responseBody, isA<UserPost200ResponseJson>());
      final body = (responseBody as UserPost200ResponseJson).body;

      expect(body.id, isA<int?>());
      expect(body.username, isA<String?>());
      expect(body.givenName, isA<String?>());
      expect(body.familyName, isA<String?>());
      expect(body.emailAddress, isA<String?>());
      expect(body.password, isA<String?>());
      expect(body.phone, isA<String?>());
      expect(body.accountStatus, isA<int?>());
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '321');

      final user = await userApi.createUser(
        body: const UserPostBodyRequestBodyJson(Account()),
      );

      final success = user as TonikSuccess<CreateUserResponse>;
      expect(success.response.statusCode, 321);
      expect(success.value, isA<CreateUserResponseDefault>());
    });
  });

  group('createUsersWithListInput', () {
    test('200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final response = await userApi.batchCreateUsers(
        body: const [Account(), Account(), Account()],
      );
      final success = response as TonikSuccess<BatchCreateUsersResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<BatchCreateUsersResponse200>());
      final responseBody = (success.value as BatchCreateUsersResponse200).body;
      expect(responseBody, isA<UserCreateWithListPost200ResponseJson>());
      final account =
          (responseBody as UserCreateWithListPost200ResponseJson).body;
      expect(account, isA<Account>());
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '321');

      final response = await userApi.batchCreateUsers(
        body: const [
          Account(
            id: 1,
            username: 'test',
            givenName: 'test',
            familyName: 'test',
            emailAddress: 'test@test.com',
            password: 'test',
            phone: 'test',
            accountStatus: 1,
          ),
          Account(
            id: 2,
            username: 'test2',
            givenName: 'test2',
            familyName: 'test2',
            emailAddress: 'test2@test.com',
            password: 'test2',
            phone: 'test2',
            accountStatus: 2,
          ),
          Account(
            id: 3,
            username: 'test3',
            givenName: 'test3',
            familyName: 'test3',
            emailAddress: 'test3@test.com',
            password: 'test3',
            phone: 'test3',
            accountStatus: 3,
          ),
        ],
      );

      final success = response as TonikSuccess<BatchCreateUsersResponse>;
      expect(success.response.statusCode, 321);
      expect(success.value, isA<BatchCreateUsersResponseDefault>());
    });
  });

  group('loginUser', () {
    test('200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final response = await userApi.authenticateUser(
        loginName: 'test',
        loginPassword: 'test',
      );

      final success = response as TonikSuccess<AuthenticateUserResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<AuthenticateUserResponse200>());
      final responseBody = (success.value as AuthenticateUserResponse200).body;
      expect(responseBody, isA<UserLoginGet200ResponseJson>());
      final body = (responseBody as UserLoginGet200ResponseJson).body;

      expect(body, isA<String>());
      expect(responseBody.xExpiresAfter, isA<DateTime?>());
      expect(responseBody.xRateLimit, isA<int?>());
    });

    test('400', () async {
      final userApi = buildUserApi(responseStatus: '400');

      final response = await userApi.authenticateUser();

      final success = response as TonikSuccess<AuthenticateUserResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<AuthenticateUserResponse400>());
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '321');

      final response = await userApi.authenticateUser();

      final success = response as TonikSuccess<AuthenticateUserResponse>;
      expect(success.response.statusCode, 321);
      expect(success.value, isA<AuthenticateUserResponseDefault>());
    });
  });

  group('logoutUser', () {
    test('200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final response = await userApi.logoutUser();

      final success = response as TonikSuccess<LogoutUserResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<LogoutUserResponse200>());
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '321');

      final response = await userApi.logoutUser();

      final success = response as TonikSuccess<LogoutUserResponse>;
      expect(success.response.statusCode, 321);
      expect(success.value, isA<LogoutUserResponseDefault>());
    });
  });

  group('getUserByName', () {
    test('200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final response = await userApi.fetchUserByName(username: 'test');
      final success = response as TonikSuccess<FetchUserByNameResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<FetchUserByNameResponse200>());
      final responseBody = (success.value as FetchUserByNameResponse200).body;
      expect(responseBody, isA<UserUsernameGet200ResponseJson>());
      final account = (responseBody as UserUsernameGet200ResponseJson).body;
      expect(account, isA<Account>());
    });

    test('400', () async {
      final userApi = buildUserApi(responseStatus: '400');

      final response = await userApi.fetchUserByName(username: 'test');
      final success = response as TonikSuccess<FetchUserByNameResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<FetchUserByNameResponse400>());
    });

    test('404', () async {
      final userApi = buildUserApi(responseStatus: '404');

      final response = await userApi.fetchUserByName(username: 'test');
      final success = response as TonikSuccess<FetchUserByNameResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<FetchUserByNameResponse404>());
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '855');

      final response = await userApi.fetchUserByName(username: 'test');
      final success = response as TonikSuccess<FetchUserByNameResponse>;
      expect(success.response.statusCode, 855);
      expect(success.value, isA<FetchUserByNameResponseDefault>());
    });
  });

  group('updateUser', () {
    test('200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final response = await userApi.updateUser(
        username: 'test',
        body: const UserUsernamePutBodyRequestBodyJson(Account()),
      );

      final success = response as TonikSuccess<UpdateUserResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<UpdateUserResponse200>());
    });

    test('400', () async {
      final userApi = buildUserApi(responseStatus: '400');

      final response = await userApi.updateUser(
        username: 'test',
        body: const UserUsernamePutBodyRequestBodyJson(
          Account(
            id: 1,
            username: 'test',
            givenName: 'test',
            familyName: 'test',
            emailAddress: 'test@test.com',
            password: 'test',
            phone: 'test',
            accountStatus: 1,
          ),
        ),
      );
      final success = response as TonikSuccess<UpdateUserResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<UpdateUserResponse400>());
    });

    test('404', () async {
      final userApi = buildUserApi(responseStatus: '404');

      final response = await userApi.updateUser(
        username: 'test',
        body: const UserUsernamePutBodyRequestBodyJson(
          Account(accountStatus: 4674),
        ),
      );
      final success = response as TonikSuccess<UpdateUserResponse>;
      expect(success.response.statusCode, 404);
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '321');

      final response = await userApi.updateUser(
        username: 'test',
        body: const UserUsernamePutBodyRequestBodyJson(Account()),
      );
      final success = response as TonikSuccess<UpdateUserResponse>;
      expect(success.response.statusCode, 321);
    });
  });

  group('deleteUser', () {
    test('200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final response = await userApi.deleteUser(
        username: 'test/asdf/asdf/asdf',
      );
      final success = response as TonikSuccess<DeleteUserResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<DeleteUserResponse200>());
    });

    test('400', () async {
      final userApi = buildUserApi(responseStatus: '400');

      final response = await userApi.deleteUser(username: 'test');
      final success = response as TonikSuccess<DeleteUserResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<DeleteUserResponse400>());
    });

    test('404', () async {
      final userApi = buildUserApi(responseStatus: '404');

      final response = await userApi.deleteUser(username: 'test');
      final success = response as TonikSuccess<DeleteUserResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<DeleteUserResponse404>());
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '211');

      final response = await userApi.deleteUser(username: 'test');
      final success = response as TonikSuccess<DeleteUserResponse>;
      expect(success.response.statusCode, 211);
      expect(success.value, isA<DeleteUserResponseDefault>());
    });
  });
}
