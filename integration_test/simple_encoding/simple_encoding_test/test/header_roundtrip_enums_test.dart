import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

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

  group('Header Roundtrip Enums', () {
    group('StatusEnum (string enum)', () {
      test('active status roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          status: StatusEnum.active,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;
        expect(success.response.statusCode, 200);

        expect(success.response.requestOptions.headers['x-status'], 'active');

        expect(success.value.xStatus, StatusEnum.active);
      });

      test('inactive status roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          status: StatusEnum.inactive,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;

        expect(success.response.requestOptions.headers['x-status'], 'inactive');
        expect(success.value.xStatus, StatusEnum.inactive);
      });

      test('pending status roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          status: StatusEnum.pending,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;

        expect(success.response.requestOptions.headers['x-status'], 'pending');
        expect(success.value.xStatus, StatusEnum.pending);
      });

      test('archived status roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          status: StatusEnum.archived,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;

        expect(success.response.requestOptions.headers['x-status'], 'archived');
        expect(success.value.xStatus, StatusEnum.archived);
      });
    });

    group('PriorityEnum (integer enum)', () {
      test('priority 1 roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          priority: PriorityEnum.one,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;
        expect(success.response.statusCode, 200);

        // Verify request header was encoded correctly
        expect(success.response.requestOptions.headers['x-priority'], '1');

        // Verify response header was decoded correctly
        expect(success.value.xPriority, PriorityEnum.one);
      });

      test('priority 2 roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          priority: PriorityEnum.two,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;

        expect(success.response.requestOptions.headers['x-priority'], '2');
        expect(success.value.xPriority, PriorityEnum.two);
      });

      test('priority 3 roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          priority: PriorityEnum.three,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;

        expect(success.response.requestOptions.headers['x-priority'], '3');
        expect(success.value.xPriority, PriorityEnum.three);
      });

      test('priority 4 roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          priority: PriorityEnum.four,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;

        expect(success.response.requestOptions.headers['x-priority'], '4');
        expect(success.value.xPriority, PriorityEnum.four);
      });

      test('priority 5 roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          priority: PriorityEnum.five,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;

        expect(success.response.requestOptions.headers['x-priority'], '5');
        expect(success.value.xPriority, PriorityEnum.five);
      });
    });

    group('both enums together', () {
      test('string and integer enum in single request roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          status: StatusEnum.active,
          priority: PriorityEnum.three,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;
        expect(success.response.statusCode, 200);

        // Verify all request headers
        final requestHeaders = success.response.requestOptions.headers;
        expect(requestHeaders['x-status'], 'active');
        expect(requestHeaders['x-priority'], '3');

        // Verify all response values
        expect(success.value.xStatus, StatusEnum.active);
        expect(success.value.xPriority, PriorityEnum.three);
      });

      test('all enum combinations - inactive with priority 1', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          status: StatusEnum.inactive,
          priority: PriorityEnum.one,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;

        expect(success.value.xStatus, StatusEnum.inactive);
        expect(success.value.xPriority, PriorityEnum.one);
      });

      test('all enum combinations - archived with priority 5', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          status: StatusEnum.archived,
          priority: PriorityEnum.five,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;

        expect(success.value.xStatus, StatusEnum.archived);
        expect(success.value.xPriority, PriorityEnum.five);
      });
    });

    group('null/missing values', () {
      test('no headers sent - null response values', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums();

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;
        expect(success.response.statusCode, 200);

        // All values should be null when no headers are sent
        expect(success.value.xStatus, isNull);
        expect(success.value.xPriority, isNull);
      });

      test('only status sent - priority is null', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          status: StatusEnum.pending,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;

        expect(success.value.xStatus, StatusEnum.pending);
        expect(success.value.xPriority, isNull);
      });

      test('only priority sent - status is null', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnums(
          priority: PriorityEnum.two,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripEnumsGet200Response>;

        expect(success.value.xStatus, isNull);
        expect(success.value.xPriority, PriorityEnum.two);
      });
    });
  });
}
