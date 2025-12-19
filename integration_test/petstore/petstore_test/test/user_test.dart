import 'package:dio/dio.dart';
import 'package:petstore_api/petstore_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8084;
  const baseUrl = 'http://localhost:$port/api/v3';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  UserApi buildUserApi({required String responseStatus}) {
    return UserApi(
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
          User(
            id: 1,
            username: 'test',
            firstName: 'test',
            lastName: 'test',
            email: 'test@test.com',
            password: 'test',
            phone: 'test',
            userStatus: 1,
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
      expect(body.firstName, isA<String?>());
      expect(body.lastName, isA<String?>());
      expect(body.email, isA<String?>());
      expect(body.password, isA<String?>());
      expect(body.phone, isA<String?>());
      expect(body.userStatus, isA<int?>());
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '321');

      final user = await userApi.createUser(
        body: const UserPostBodyRequestBodyJson(User()),
      );

      final success = user as TonikSuccess<CreateUserResponse>;
      expect(success.response.statusCode, 321);
      expect(success.value, isA<CreateUserResponseDefault>());
    });
  });

  group('createUsersWithListInput', () {
    test('200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final response = await userApi.createUsersWithListInput(
        body: const [User(), User(), User()],
      );
      final success =
          response as TonikSuccess<CreateUsersWithListInputResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<CreateUsersWithListInputResponse200>());
      final responseBody =
          (success.value as CreateUsersWithListInputResponse200).body;
      expect(responseBody, isA<UserCreateWithListPost200ResponseJson>());
      final body = (responseBody as UserCreateWithListPost200ResponseJson).body;
      expect(body, isA<User>());
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '321');

      final response = await userApi.createUsersWithListInput(
        body: const [
          User(
            id: 1,
            username: 'test',
            firstName: 'test',
            lastName: 'test',
            email: 'test@test.com',
            password: 'test',
            phone: 'test',
            userStatus: 1,
          ),
          User(
            id: 2,
            username: 'test2',
            firstName: 'test2',
            lastName: 'test2',
            email: 'test2@test.com',
            password: 'test2',
            phone: 'test2',
            userStatus: 2,
          ),
          User(
            id: 3,
            username: 'test3',
            firstName: 'test3',
            lastName: 'test3',
            email: 'test3@test.com',
            password: 'test3',
            phone: 'test3',
            userStatus: 3,
          ),
        ],
      );

      final success =
          response as TonikSuccess<CreateUsersWithListInputResponse>;
      expect(success.response.statusCode, 321);
      expect(success.value, isA<CreateUsersWithListInputResponseDefault>());
    });
  });

  group('loginUser', () {
    test('200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final response = await userApi.loginUser(
        username: 'test',
        password: 'test',
      );

      final success = response as TonikSuccess<LoginUserResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<LoginUserResponse200>());
      final responseBody = (success.value as LoginUserResponse200).body;
      expect(responseBody, isA<UserLoginGet200ResponseJson>());
      final body = responseBody as UserLoginGet200ResponseJson;

      expect(body.xExpiresAfter, isA<DateTime?>());
      expect(body.xRateLimit, isA<int?>());
    });

    test('400', () async {
      final userApi = buildUserApi(responseStatus: '400');

      final response = await userApi.loginUser();

      final success = response as TonikSuccess<LoginUserResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<LoginUserResponse400>());
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '321');

      final response = await userApi.loginUser();

      final success = response as TonikSuccess<LoginUserResponse>;
      expect(success.response.statusCode, 321);
      expect(success.value, isA<LoginUserResponseDefault>());
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

      final response = await userApi.getUserByName(username: 'test');
      final success = response as TonikSuccess<GetUserByNameResponse>;
      expect(success.response.statusCode, 200);
      expect(success.value, isA<GetUserByNameResponse200>());
      final responseBody = (success.value as GetUserByNameResponse200).body;
      expect(responseBody, isA<UserUsernameGet200ResponseJson>());
      final body = (responseBody as UserUsernameGet200ResponseJson).body;

      expect(body, isA<User>());
    });

    test('400', () async {
      final userApi = buildUserApi(responseStatus: '400');

      final response = await userApi.getUserByName(username: 'test');
      final success = response as TonikSuccess<GetUserByNameResponse>;
      expect(success.response.statusCode, 400);
      expect(success.value, isA<GetUserByNameResponse400>());
    });

    test('404', () async {
      final userApi = buildUserApi(responseStatus: '404');

      final response = await userApi.getUserByName(username: 'test');
      final success = response as TonikSuccess<GetUserByNameResponse>;
      expect(success.response.statusCode, 404);
      expect(success.value, isA<GetUserByNameResponse404>());
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '855');

      final response = await userApi.getUserByName(username: 'test');
      final success = response as TonikSuccess<GetUserByNameResponse>;
      expect(success.response.statusCode, 855);
      expect(success.value, isA<GetUserByNameResponseDefault>());
    });
  });

  group('updateUser', () {
    test('200', () async {
      final userApi = buildUserApi(responseStatus: '200');

      final response = await userApi.updateUser(
        username: 'test',
        body: const UserUsernamePutBodyRequestBodyJson(User()),
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
          User(
            id: 1,
            username: 'test',
            firstName: 'test',
            lastName: 'test',
            email: 'test@test.com',
            password: 'test',
            phone: 'test',
            userStatus: 1,
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
        body: const UserUsernamePutBodyRequestBodyJson(User(userStatus: 4674)),
      );
      final success = response as TonikSuccess<UpdateUserResponse>;
      expect(success.response.statusCode, 404);
    });

    test('default', () async {
      final userApi = buildUserApi(responseStatus: '321');

      final response = await userApi.updateUser(
        username: 'test',
        body: const UserUsernamePutBodyRequestBodyJson(User()),
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
