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

  group('AllOfEnum header roundtrip', () {
    test('round-trips with both enums set', () async {
      final result = await api.testHeaderRoundtripAllOfEnums.call(
        enumComposite: const AllOfEnum(
          allOfEnumModel: AllOfEnumModel(priority: PriorityEnum.three),
          allOfEnumModel2: AllOfEnumModel2(status: StatusEnum.active),
        ),
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripAllofEnumsGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripAllofEnumsGet200Response>;

      // Verify encoded request header contains both enum values
      final headerValue =
          success.response.requestOptions.headers['X-Enum-Composite'] as String;
      expect(headerValue, contains('priority,3'));
      expect(headerValue, contains('status,active'));

      // Verify decoded response
      expect(success.value.xEnumComposite, isNotNull);
      expect(
        success.value.xEnumComposite!.allOfEnumModel.priority,
        PriorityEnum.three,
      );
      expect(
        success.value.xEnumComposite!.allOfEnumModel2.status,
        StatusEnum.active,
      );
    });

    test('round-trips with only status set', () async {
      final result = await api.testHeaderRoundtripAllOfEnums.call(
        enumComposite: const AllOfEnum(
          allOfEnumModel: AllOfEnumModel(),
          allOfEnumModel2: AllOfEnumModel2(status: StatusEnum.pending),
        ),
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripAllofEnumsGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripAllofEnumsGet200Response>;

      // Verify decoded response
      expect(success.value.xEnumComposite, isNotNull);
      expect(
        success.value.xEnumComposite!.allOfEnumModel2.status,
        StatusEnum.pending,
      );
    });

    test('round-trips with only priority set', () async {
      final result = await api.testHeaderRoundtripAllOfEnums.call(
        enumComposite: const AllOfEnum(
          allOfEnumModel: AllOfEnumModel(priority: PriorityEnum.five),
          allOfEnumModel2: AllOfEnumModel2(),
        ),
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripAllofEnumsGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripAllofEnumsGet200Response>;

      // Verify decoded response
      expect(success.value.xEnumComposite, isNotNull);
      expect(
        success.value.xEnumComposite!.allOfEnumModel.priority,
        PriorityEnum.five,
      );
    });

    test(
      'round-trips with all enum values (status archived, priority one)',
      () async {
        final result = await api.testHeaderRoundtripAllOfEnums.call(
          enumComposite: const AllOfEnum(
            allOfEnumModel: AllOfEnumModel(priority: PriorityEnum.one),
            allOfEnumModel2: AllOfEnumModel2(status: StatusEnum.archived),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAllofEnumsGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAllofEnumsGet200Response>;

        // Verify decoded response
        expect(success.value.xEnumComposite, isNotNull);
        expect(
          success.value.xEnumComposite!.allOfEnumModel.priority,
          PriorityEnum.one,
        );
        expect(
          success.value.xEnumComposite!.allOfEnumModel2.status,
          StatusEnum.archived,
        );
      },
    );

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripAllOfEnums.call();

          expect(
            result,
            isA<TonikSuccess<HeadersRoundtripAllofEnumsGet200Response>>(),
          );
          final success =
              result as TonikSuccess<HeadersRoundtripAllofEnumsGet200Response>;

          // Verify no header was sent
          expect(
            success.response.requestOptions.headers['X-Enum-Composite'],
            isNull,
          );

          // Verify response property is null
          expect(success.value.xEnumComposite, isNull);
        },
      );
    });
  });
}
