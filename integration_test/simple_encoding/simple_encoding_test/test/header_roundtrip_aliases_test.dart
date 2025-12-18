import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_helper.dart';

void main() {
  const port = 8085;
  const baseUrl = 'http://localhost:$port/v1';

  late ImposterServer imposterServer;

  setUpAll(() async {
    imposterServer = ImposterServer(port: port);
    await setupImposterServer(imposterServer);
  });

  SimpleEncodingApi buildApi({required String responseStatus}) {
    return SimpleEncodingApi(
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

  late SimpleEncodingApi api;

  setUp(() {
    api = buildApi(responseStatus: '200');
  });

  group('Type aliases header roundtrip', () {
    group('UserId (alias for int)', () {
      test('roundtrips UserId with positive integer', () async {
        const userId = 12345;

        final result = await api.testHeaderRoundtripAliases(userId: userId);

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xUserId, userId);
      });

      test('roundtrips UserId with zero', () async {
        const userId = 0;

        final result = await api.testHeaderRoundtripAliases(userId: userId);

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xUserId, userId);
      });

      test('roundtrips UserId with negative integer', () async {
        const userId = -999;

        final result = await api.testHeaderRoundtripAliases(userId: userId);

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xUserId, userId);
      });

      test('roundtrips UserId with large integer', () async {
        const userId = 9223372036854775807; // max int64

        final result = await api.testHeaderRoundtripAliases(userId: userId);

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xUserId, userId);
      });
    });

    group('UserName (alias for String)', () {
      test('roundtrips UserName with simple string', () async {
        const userName = 'john_doe';

        final result = await api.testHeaderRoundtripAliases(userName: userName);

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xUserName, userName);
      });

      test('fails to encode empty string', () async {
        // Empty strings fail encoding with EmptyValueException
        const userName = '';

        final result = await api.testHeaderRoundtripAliases(userName: userName);

        expect(
          result,
          isA<TonikError<HeadersRoundtripAliasesGet200Response>>(),
        );
        final error =
            result as TonikError<HeadersRoundtripAliasesGet200Response>;
        expect(error.type, TonikErrorType.encoding);
      });

      test('roundtrips UserName with special characters', () async {
        const userName = 'user@example.com';

        final result = await api.testHeaderRoundtripAliases(userName: userName);

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xUserName, isNotNull);
      });

      test('roundtrips UserName with unicode characters', () async {
        const userName = 'José García';

        final result = await api.testHeaderRoundtripAliases(userName: userName);

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xUserName, isNotNull);
      });
    });

    group('Timestamp (alias for DateTime)', () {
      test('roundtrips Timestamp with UTC datetime', () async {
        final timestamp = DateTime.utc(2024, 6, 15, 14, 30);

        final result = await api.testHeaderRoundtripAliases(
          timestamp: timestamp,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xTimestamp, isNotNull);
      });

      test('roundtrips Timestamp at epoch', () async {
        final timestamp = DateTime.utc(1970);

        final result = await api.testHeaderRoundtripAliases(
          timestamp: timestamp,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xTimestamp, isNotNull);
      });

      test('roundtrips Timestamp with milliseconds', () async {
        final timestamp = DateTime.utc(2024, 1, 1, 12, 0, 0, 123);

        final result = await api.testHeaderRoundtripAliases(
          timestamp: timestamp,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xTimestamp, isNotNull);
      });
    });

    group('all aliases combined', () {
      test('roundtrips all alias types together', () async {
        const userId = 42;
        const userName = 'admin';
        final timestamp = DateTime.utc(2024, 12, 31, 23, 59, 59);

        final result = await api.testHeaderRoundtripAliases(
          userId: userId,
          userName: userName,
          timestamp: timestamp,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xUserId, userId);
        expect(success.value.xUserName, userName);
        expect(success.value.xTimestamp, isNotNull);
      });

      test('roundtrips with no parameters', () async {
        final result = await api.testHeaderRoundtripAliases();

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xUserId, isNull);
        expect(success.value.xUserName, isNull);
        expect(success.value.xTimestamp, isNull);
      });

      test('roundtrips with partial parameters', () async {
        const userId = 100;
        final timestamp = DateTime.utc(2024, 6);

        final result = await api.testHeaderRoundtripAliases(
          userId: userId,
          timestamp: timestamp,
          // userName omitted
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAliasesGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAliasesGet200Response>;
        expect(success.value.xUserId, userId);
        expect(success.value.xUserName, isNull);
        expect(success.value.xTimestamp, isNotNull);
      });
    });
  });
}
