import 'package:big_decimal/big_decimal.dart';
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

  group('Header Roundtrip Objects', () {
    group('SimpleObject', () {
      test('simple object with all fields roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripObjects(
          simpleObject: const SimpleObject(name: 'test', value: 42),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.value.xSimpleObject,
          const SimpleObject(name: 'test', value: 42),
        );
      });

      test('simple object with only name roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripObjects(
          simpleObject: const SimpleObject(name: 'onlyname'),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;

        expect(success.value.xSimpleObject?.name, 'onlyname');
        expect(success.value.xSimpleObject?.value, isNull);
      });

      test('simple object with only value roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripObjects(
          simpleObject: const SimpleObject(value: 123),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;

        expect(success.value.xSimpleObject?.name, isNull);
        expect(success.value.xSimpleObject?.value, 123);
      });

      test('simple object with negative value roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripObjects(
          simpleObject: const SimpleObject(name: 'negative', value: -99),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;

        expect(
          success.value.xSimpleObject,
          const SimpleObject(name: 'negative', value: -99),
        );
      });
    });

    group('UserProfile', () {
      test('user profile with required fields only roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final createdAt = DateTime.utc(2024, 1, 15, 10, 30);
        final response = await api.testHeaderRoundtripObjects(
          userProfile: UserProfile(
            id: 1,
            username: 'johndoe',
            isVerified: true,
            createdAt: createdAt,
            email: 'john@example.com',
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;
        expect(success.response.statusCode, 200);

        final profile = success.value.xUserProfile;
        expect(profile?.id, 1);
        expect(profile?.username, 'johndoe');
        expect(profile?.isVerified, true);
        expect(profile?.createdAt, createdAt);
        expect(profile?.email, 'john@example.com');
      });

      test('user profile with all fields roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final createdAt = DateTime.utc(2024, 6, 20, 14, 45, 30);
        final birthDate = Date(1990, 3, 25);
        final response = await api.testHeaderRoundtripObjects(
          userProfile: UserProfile(
            id: 42,
            username: 'janedoe',
            isVerified: false,
            createdAt: createdAt,
            email: 'jane@example.com',
            score: 95.5,
            rating: 4.8,
            birthDate: birthDate,
            balance: BigDecimal.parse('1234.56'),
            website: Uri.parse('https://example.com/jane'),
            fullName: 'Jane Doe',
            age: 34,
            status: StatusEnum.active,
            priority: PriorityEnum.three,
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;

        final profile = success.value.xUserProfile;
        expect(profile?.id, 42);
        expect(profile?.username, 'janedoe');
        expect(profile?.isVerified, false);
        expect(profile?.createdAt, createdAt);
        expect(profile?.email, 'jane@example.com');
        expect(profile?.score, 95.5);
        expect(profile?.rating, 4.8);
        expect(profile?.birthDate, birthDate);
        expect(profile?.balance, BigDecimal.parse('1234.56'));
        expect(profile?.website, Uri.parse('https://example.com/jane'));
        expect(profile?.fullName, 'Jane Doe');
        expect(profile?.age, 34);
        expect(profile?.status, StatusEnum.active);
        expect(profile?.priority, PriorityEnum.three);
      });

      test('user profile with enum values roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final createdAt = DateTime.utc(2024, 11, 30);
        final response = await api.testHeaderRoundtripObjects(
          userProfile: UserProfile(
            id: 100,
            username: 'admin',
            isVerified: true,
            createdAt: createdAt,
            email: 'admin@example.com',
            status: StatusEnum.pending,
            priority: PriorityEnum.five,
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;

        final profile = success.value.xUserProfile;
        expect(profile?.status, StatusEnum.pending);
        expect(profile?.priority, PriorityEnum.five);
      });
    });

    group('combined objects', () {
      test('both objects together roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final createdAt = DateTime.utc(2024, 12);
        final response = await api.testHeaderRoundtripObjects(
          simpleObject: const SimpleObject(name: 'combined', value: 777),
          userProfile: UserProfile(
            id: 999,
            username: 'combo',
            isVerified: true,
            createdAt: createdAt,
            email: 'combo@test.com',
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;

        expect(
          success.value.xSimpleObject,
          const SimpleObject(name: 'combined', value: 777),
        );
        expect(success.value.xUserProfile?.id, 999);
        expect(success.value.xUserProfile?.username, 'combo');
      });
    });

    group('null and missing values', () {
      test('null simple object returns null', () async {
        final api = buildApi(responseStatus: '200');
        final createdAt = DateTime.utc(2024);
        final response = await api.testHeaderRoundtripObjects(
          userProfile: UserProfile(
            id: 1,
            username: 'test',
            isVerified: true,
            createdAt: createdAt,
            email: 'test@test.com',
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;

        expect(success.value.xSimpleObject, isNull);
        expect(success.value.xUserProfile, isNotNull);
      });

      test('null user profile returns null', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripObjects(
          simpleObject: const SimpleObject(name: 'solo', value: 1),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;

        expect(success.value.xSimpleObject, isNotNull);
        expect(success.value.xUserProfile, isNull);
      });

      test('both null returns null values', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripObjects();

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;

        expect(success.value.xSimpleObject, isNull);
        expect(success.value.xUserProfile, isNull);
      });
    });
  });
}
