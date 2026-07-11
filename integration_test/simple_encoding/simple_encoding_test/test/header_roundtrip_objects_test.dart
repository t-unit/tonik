import 'package:big_decimal/big_decimal.dart';
import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
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
          simpleObject: const SimpleObject(name: 'onlyName'),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripObjectsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;

        expect(success.value.xSimpleObject?.name, 'onlyName');
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
            username: 'johnDoe',
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
        expect(profile?.username, 'johnDoe');
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
            username: 'janeDoe',
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
        expect(profile?.username, 'janeDoe');
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

    group('literal special characters', () {
      test('object property value keeps spaces, slash, percent literal '
          'on the wire and through decode', () async {
        final api = buildApi(responseStatus: '200');
        const name = 'a/b c%2Fd 100%';
        final response = await api.testHeaderRoundtripObjects(
          simpleObject: const SimpleObject(name: name, value: 7),
        );

        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;
        expect(
          success.response.requestOptions.headers['X-Simple-Object'],
          'name,a/b c%2Fd 100%,value,7',
        );
        expect(success.value.xSimpleObject?.name, name);
        expect(success.value.xSimpleObject?.value, 7);
      });

      test('object Uri property keeps its literal slashes and colon', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripObjects(
          userProfile: UserProfile(
            id: 1,
            username: 'john_doe',
            isVerified: true,
            createdAt: DateTime.utc(2024),
            email: 'john@example.com',
            website: Uri.parse('https://example.com/a/b'),
          ),
        );

        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;
        final wire =
            success.response.requestOptions.headers['X-User-Profile'] as String;
        expect(wire, contains('website,https://example.com/a/b'));
        expect(
          success.value.xUserProfile?.website,
          Uri.parse('https://example.com/a/b'),
        );
      });
    });

    group('delimiter collision', () {
      test('a comma inside an object value cannot round-trip: it is '
          'transmitted literally and decode reads it as a new key/value',
          () async {
        // Literal encoding doesn't escape the `,` delimiter, so an in-value
        // comma can't round-trip.
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripObjects(
          simpleObject: const SimpleObject(name: 'a,b', value: 5),
        );

        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;
        expect(
          success.response.requestOptions.headers['X-Simple-Object'],
          'name,a,b,value,5',
        );
        expect(success.value.xSimpleObject?.name, 'a');
      });
    });

    group('server-originated composite response', () {
      test('literal percent sequences in an injected object header '
          'survive decode without re-decoding', () async {
        // Server-originated: X-Simple-Object is injected via Dio, not
        // sent by Tonik's encoder.
        final injected = SimpleEncodingApi(
          CustomServer(
            baseUrl: baseUrl,
            serverConfig: ServerConfig(
              baseOptions: BaseOptions(
                headers: {
                  'X-Response-Status': '200',
                  'X-Simple-Object': 'name,x%2Fy 50%,value,9',
                },
              ),
            ),
          ),
        );

        final response = await injected.testHeaderRoundtripObjects();

        final success =
            response as TonikSuccess<HeadersRoundtripObjectsGet200Response>;
        expect(success.value.xSimpleObject?.name, 'x%2Fy 50%');
        expect(success.value.xSimpleObject?.value, 9);
      });
    });
  });
}
