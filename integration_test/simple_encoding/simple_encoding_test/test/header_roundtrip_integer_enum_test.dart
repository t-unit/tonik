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

  group('Header Roundtrip Integer Enum', () {
    test('priority 1 roundtrip', () async {
      final api = buildApi(responseStatus: '200');
      final response = await api.testHeaderRoundtripIntegerEnum(
        priority: PriorityEnum.one,
      );

      expect(
        response,
        isA<TonikSuccess<HeadersRoundtripIntegerEnumGet200Response>>(),
      );
      final success =
          response as TonikSuccess<HeadersRoundtripIntegerEnumGet200Response>;
      expect(success.response.statusCode, 200);

      expect(success.response.requestOptions.headers['x-priority'], '1');
      expect(success.value.xPriority, PriorityEnum.one);
    });

    test('priority 2 roundtrip', () async {
      final api = buildApi(responseStatus: '200');
      final response = await api.testHeaderRoundtripIntegerEnum(
        priority: PriorityEnum.two,
      );

      expect(
        response,
        isA<TonikSuccess<HeadersRoundtripIntegerEnumGet200Response>>(),
      );
      final success =
          response as TonikSuccess<HeadersRoundtripIntegerEnumGet200Response>;

      expect(success.response.requestOptions.headers['x-priority'], '2');
      expect(success.value.xPriority, PriorityEnum.two);
    });

    test('priority 3 roundtrip', () async {
      final api = buildApi(responseStatus: '200');
      final response = await api.testHeaderRoundtripIntegerEnum(
        priority: PriorityEnum.three,
      );

      expect(
        response,
        isA<TonikSuccess<HeadersRoundtripIntegerEnumGet200Response>>(),
      );
      final success =
          response as TonikSuccess<HeadersRoundtripIntegerEnumGet200Response>;

      expect(success.response.requestOptions.headers['x-priority'], '3');
      expect(success.value.xPriority, PriorityEnum.three);
    });

    test('priority 4 roundtrip', () async {
      final api = buildApi(responseStatus: '200');
      final response = await api.testHeaderRoundtripIntegerEnum(
        priority: PriorityEnum.four,
      );

      expect(
        response,
        isA<TonikSuccess<HeadersRoundtripIntegerEnumGet200Response>>(),
      );
      final success =
          response as TonikSuccess<HeadersRoundtripIntegerEnumGet200Response>;

      expect(success.response.requestOptions.headers['x-priority'], '4');
      expect(success.value.xPriority, PriorityEnum.four);
    });

    test('priority 5 (highest) roundtrip', () async {
      final api = buildApi(responseStatus: '200');
      final response = await api.testHeaderRoundtripIntegerEnum(
        priority: PriorityEnum.five,
      );

      expect(
        response,
        isA<TonikSuccess<HeadersRoundtripIntegerEnumGet200Response>>(),
      );
      final success =
          response as TonikSuccess<HeadersRoundtripIntegerEnumGet200Response>;

      expect(success.response.requestOptions.headers['x-priority'], '5');
      expect(success.value.xPriority, PriorityEnum.five);
    });
  });
}
