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

  group('Header Roundtrip Nullable', () {
    group('Nullable String', () {
      test('non-null string value roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripNullable(
          nullableString: 'hello',
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripNullableGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripNullableGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-nullable-string'],
          'hello',
        );
        expect(success.value.xNullableString, 'hello');
      });

      test('null string value roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripNullable();

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripNullableGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripNullableGet200Response>;
        expect(success.response.statusCode, 200);

        // Null should not be sent as header
        expect(
          success.response.requestOptions.headers['x-nullable-string'],
          isNull,
        );
        expect(success.value.xNullableString, isNull);
      });
    });

    group('Nullable Integer', () {
      test('non-null integer value roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripNullable(
          nullableInteger: 42,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripNullableGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripNullableGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-nullable-integer'],
          '42',
        );
        expect(success.value.xNullableInteger, 42);
      });

      test('null integer value roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripNullable();

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripNullableGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripNullableGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-nullable-integer'],
          isNull,
        );
        expect(success.value.xNullableInteger, isNull);
      });
    });

    group('Nullable Object', () {
      test('non-null object value roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripNullable(
          nullableObject: const NullableObject(name: 'test', count: 5),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripNullableGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripNullableGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-nullable-object'],
          'name,test,count,5',
        );
        expect(success.value.xNullableObject?.name, 'test');
        expect(success.value.xNullableObject?.count, 5);
      });

      test('null object value roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripNullable();

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripNullableGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripNullableGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-nullable-object'],
          isNull,
        );
        expect(success.value.xNullableObject, isNull);
      });
    });

    group('Nullable Enum', () {
      test('non-null enum value roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripNullable(
          nullableEnum: const HeadersRoundtripNullableParametersAllOfModel(
            statusEnum: StatusEnum.active,
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripNullableGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripNullableGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-nullable-enum'],
          'active',
        );
        expect(
          success.value.xNullableEnum?.statusEnum,
          StatusEnum.active,
        );
      });

      test('null enum value roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripNullable();

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripNullableGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripNullableGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-nullable-enum'],
          isNull,
        );
        expect(success.value.xNullableEnum, isNull);
      });
    });

    group('Combined nullable parameters', () {
      test('all non-null values roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripNullable(
          nullableString: 'hello',
          nullableInteger: 42,
          nullableObject: const NullableObject(name: 'test', count: 10),
          nullableEnum: const HeadersRoundtripNullableParametersAllOfModel(
            statusEnum: StatusEnum.pending,
          ),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripNullableGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripNullableGet200Response>;
        expect(success.response.statusCode, 200);

        expect(success.value.xNullableString, 'hello');
        expect(success.value.xNullableInteger, 42);
        expect(success.value.xNullableObject?.name, 'test');
        expect(
          success.value.xNullableEnum?.statusEnum,
          StatusEnum.pending,
        );
      });

      test('all null values roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripNullable();

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripNullableGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripNullableGet200Response>;
        expect(success.response.statusCode, 200);

        expect(success.value.xNullableString, isNull);
        expect(success.value.xNullableInteger, isNull);
        expect(success.value.xNullableObject, isNull);
        expect(success.value.xNullableEnum, isNull);
      });

      test('mixed null and non-null values roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripNullable(
          nullableString: 'partial',
          nullableObject: const NullableObject(name: 'obj', count: 1),
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripNullableGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripNullableGet200Response>;
        expect(success.response.statusCode, 200);

        expect(success.value.xNullableString, 'partial');
        expect(success.value.xNullableInteger, isNull);
        expect(success.value.xNullableObject?.name, 'obj');
        expect(success.value.xNullableEnum, isNull);
      });
    });
  });
}
