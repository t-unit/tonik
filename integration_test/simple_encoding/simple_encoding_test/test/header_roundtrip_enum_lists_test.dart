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

  group('Header Roundtrip Enum Lists', () {
    group('status enum list', () {
      test('single status enum roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnumLists(
          statusList: [StatusEnum.active],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsEnumsGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-status-list'],
          'active',
        );
        expect(success.value.xStatusList, [StatusEnum.active]);
      });

      test('multiple status enums roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnumLists(
          statusList: [
            StatusEnum.active,
            StatusEnum.pending,
            StatusEnum.archived,
          ],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsEnumsGet200Response>;

        expect(
          success.response.requestOptions.headers['x-status-list'],
          'active,pending,archived',
        );
        expect(success.value.xStatusList, [
          StatusEnum.active,
          StatusEnum.pending,
          StatusEnum.archived,
        ]);
      });

      test('all status enum values roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnumLists(
          statusList: [
            StatusEnum.active,
            StatusEnum.inactive,
            StatusEnum.pending,
            StatusEnum.archived,
          ],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsEnumsGet200Response>;

        expect(
          success.response.requestOptions.headers['x-status-list'],
          'active,inactive,pending,archived',
        );
        expect(success.value.xStatusList, [
          StatusEnum.active,
          StatusEnum.inactive,
          StatusEnum.pending,
          StatusEnum.archived,
        ]);
      });
    });

    group('priority enum list', () {
      test('single priority enum roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnumLists(
          priorityList: [PriorityEnum.one],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsEnumsGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-priority-list'],
          '1',
        );
        expect(success.value.xPriorityList, [PriorityEnum.one]);
      });

      test('multiple priority enums roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnumLists(
          priorityList: [
            PriorityEnum.one,
            PriorityEnum.three,
            PriorityEnum.five,
          ],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsEnumsGet200Response>;

        expect(
          success.response.requestOptions.headers['x-priority-list'],
          '1,3,5',
        );
        expect(success.value.xPriorityList, [
          PriorityEnum.one,
          PriorityEnum.three,
          PriorityEnum.five,
        ]);
      });

      test('all priority enum values roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnumLists(
          priorityList: [
            PriorityEnum.one,
            PriorityEnum.two,
            PriorityEnum.three,
            PriorityEnum.four,
            PriorityEnum.five,
          ],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsEnumsGet200Response>;

        expect(
          success.response.requestOptions.headers['x-priority-list'],
          '1,2,3,4,5',
        );
        expect(success.value.xPriorityList, [
          PriorityEnum.one,
          PriorityEnum.two,
          PriorityEnum.three,
          PriorityEnum.four,
          PriorityEnum.five,
        ]);
      });
    });

    group('combined enum lists', () {
      test('both enum lists together roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnumLists(
          statusList: [StatusEnum.active, StatusEnum.pending],
          priorityList: [PriorityEnum.two, PriorityEnum.four],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsEnumsGet200Response>;

        expect(
          success.response.requestOptions.headers['x-status-list'],
          'active,pending',
        );
        expect(
          success.response.requestOptions.headers['x-priority-list'],
          '2,4',
        );

        expect(
          success.value.xStatusList,
          [StatusEnum.active, StatusEnum.pending],
        );
        expect(
          success.value.xPriorityList,
          [PriorityEnum.two, PriorityEnum.four],
        );
      });
    });

    group('null and missing values', () {
      test('null status list returns null', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnumLists(
          priorityList: [PriorityEnum.one],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsEnumsGet200Response>;

        expect(success.value.xStatusList, isNull);
        expect(success.value.xPriorityList, [PriorityEnum.one]);
      });

      test('null priority list returns null', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnumLists(
          statusList: [StatusEnum.inactive],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsEnumsGet200Response>;

        expect(success.value.xStatusList, [StatusEnum.inactive]);
        expect(success.value.xPriorityList, isNull);
      });

      test('both null returns null values', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripEnumLists();

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsEnumsGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsEnumsGet200Response>;

        expect(success.value.xStatusList, isNull);
        expect(success.value.xPriorityList, isNull);
      });
    });
  });
}
