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

  late SimpleEncodingApi api;

  setUp(() {
    api = buildApi(responseStatus: '200');
  });

  group('OneOfEnum header roundtrip', () {
    group('StatusEnum variant', () {
      test('round-trips StatusEnum.active', () async {
        final result = await api.testHeaderRoundtripOneOfEnum.call(
          enumUnion: const OneOfEnumStatusEnum(StatusEnum.active),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofEnumGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofEnumGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Enum-Union'],
          'active',
        );

        // Verify decoded response
        expect(success.value.xEnumUnion, isA<OneOfEnumStatusEnum>());
        final decoded = success.value.xEnumUnion! as OneOfEnumStatusEnum;
        expect(decoded.value, StatusEnum.active);
      });

      test('round-trips StatusEnum.inactive', () async {
        final result = await api.testHeaderRoundtripOneOfEnum.call(
          enumUnion: const OneOfEnumStatusEnum(StatusEnum.inactive),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofEnumGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofEnumGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Enum-Union'],
          'inactive',
        );

        // Verify decoded response
        expect(success.value.xEnumUnion, isA<OneOfEnumStatusEnum>());
        final decoded = success.value.xEnumUnion! as OneOfEnumStatusEnum;
        expect(decoded.value, StatusEnum.inactive);
      });

      test('round-trips StatusEnum.pending', () async {
        final result = await api.testHeaderRoundtripOneOfEnum.call(
          enumUnion: const OneOfEnumStatusEnum(StatusEnum.pending),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofEnumGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofEnumGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Enum-Union'],
          'pending',
        );

        // Verify decoded response
        expect(success.value.xEnumUnion, isA<OneOfEnumStatusEnum>());
        final decoded = success.value.xEnumUnion! as OneOfEnumStatusEnum;
        expect(decoded.value, StatusEnum.pending);
      });

      test('round-trips StatusEnum.archived', () async {
        final result = await api.testHeaderRoundtripOneOfEnum.call(
          enumUnion: const OneOfEnumStatusEnum(StatusEnum.archived),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofEnumGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofEnumGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Enum-Union'],
          'archived',
        );

        // Verify decoded response
        expect(success.value.xEnumUnion, isA<OneOfEnumStatusEnum>());
        final decoded = success.value.xEnumUnion! as OneOfEnumStatusEnum;
        expect(decoded.value, StatusEnum.archived);
      });
    });

    group('PriorityEnum variant', () {
      test('round-trips PriorityEnum.one', () async {
        final result = await api.testHeaderRoundtripOneOfEnum.call(
          enumUnion: const OneOfEnumPriorityEnum(PriorityEnum.one),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofEnumGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofEnumGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Enum-Union'],
          '1',
        );

        // Note: Integer enum values sent as headers are decoded back to integer
        // variants when possible. The decoder tries PriorityEnum first.
        expect(success.value.xEnumUnion, isA<OneOfEnumPriorityEnum>());
        final decoded = success.value.xEnumUnion! as OneOfEnumPriorityEnum;
        expect(decoded.value, PriorityEnum.one);
      });

      test('round-trips PriorityEnum.two', () async {
        final result = await api.testHeaderRoundtripOneOfEnum.call(
          enumUnion: const OneOfEnumPriorityEnum(PriorityEnum.two),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofEnumGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofEnumGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Enum-Union'],
          '2',
        );

        // Verify decoded response
        expect(success.value.xEnumUnion, isA<OneOfEnumPriorityEnum>());
        final decoded = success.value.xEnumUnion! as OneOfEnumPriorityEnum;
        expect(decoded.value, PriorityEnum.two);
      });

      test('round-trips PriorityEnum.five', () async {
        final result = await api.testHeaderRoundtripOneOfEnum.call(
          enumUnion: const OneOfEnumPriorityEnum(PriorityEnum.five),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofEnumGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofEnumGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Enum-Union'],
          '5',
        );

        // Verify decoded response
        expect(success.value.xEnumUnion, isA<OneOfEnumPriorityEnum>());
        final decoded = success.value.xEnumUnion! as OneOfEnumPriorityEnum;
        expect(decoded.value, PriorityEnum.five);
      });
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripOneOfEnum.call();

          expect(
            result,
            isA<TonikSuccess<HeadersRoundtripOneofEnumGet200Response>>(),
          );
          final success =
              result as TonikSuccess<HeadersRoundtripOneofEnumGet200Response>;

          // Verify no header was sent
          expect(
            success.response.requestOptions.headers['X-Enum-Union'],
            isNull,
          );

          // Verify response property is null
          expect(success.value.xEnumUnion, isNull);
        },
      );
    });
  });
}
