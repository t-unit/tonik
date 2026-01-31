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

  group('MultiLevelNesting header roundtrip', () {
    group('with level1 as string variant', () {
      test('roundtrips MultiLevelNesting with string level1', () async {
        const input = MultiLevelNesting(
          multiLevelNestingModel: MultiLevelNestingModel(
            level1: MultiLevelNestingLevel1OneOfModelString('hello'),
          ),
          multiLevelNestingModel2: MultiLevelNestingModel2(level2: 42),
        );

        final result = await api.testHeaderRoundtripMultiLevel(
          multiLevel: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripComplexMultiLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexMultiLevelGet200Response
                >;
        expect(success.value.xMultiLevel, isNotNull);
      });
    });

    group('with level1 as anyOf variant (Class1)', () {
      // AnyOf variants have complex encoding shape which cannot be serialized
      // to simple style headers per OpenAPI spec (RFC6570).
      test('fails to encode anyOf variant in header', () async {
        const input = MultiLevelNesting(
          multiLevelNestingModel: MultiLevelNestingModel(
            level1: MultiLevelNestingLevel1OneOfModelAnyOf(
              MultiLevelNestingLevel1OneOfAnyOfModel(
                class1: Class1(name: 'test-name'),
              ),
            ),
          ),
          multiLevelNestingModel2: MultiLevelNestingModel2(level2: 100),
        );

        final result = await api.testHeaderRoundtripMultiLevel(
          multiLevel: input,
        );

        expect(
          result,
          isA<TonikError<HeadersRoundtripComplexMultiLevelGet200Response>>(),
        );
        final error =
            result
                as TonikError<HeadersRoundtripComplexMultiLevelGet200Response>;
        expect(error.type, TonikErrorType.encoding);
      });
    });

    group('with level1 as anyOf variant (Class2)', () {
      // AnyOf variants have complex encoding shape which cannot be serialized
      // to simple style headers per OpenAPI spec (RFC6570).
      test('fails to encode anyOf variant in header', () async {
        const input = MultiLevelNesting(
          multiLevelNestingModel: MultiLevelNestingModel(
            level1: MultiLevelNestingLevel1OneOfModelAnyOf(
              MultiLevelNestingLevel1OneOfAnyOfModel(
                class2: Class2(number: 999),
              ),
            ),
          ),
          multiLevelNestingModel2: MultiLevelNestingModel2(level2: 200),
        );

        final result = await api.testHeaderRoundtripMultiLevel(
          multiLevel: input,
        );

        expect(
          result,
          isA<TonikError<HeadersRoundtripComplexMultiLevelGet200Response>>(),
        );
        final error =
            result
                as TonikError<HeadersRoundtripComplexMultiLevelGet200Response>;
        expect(error.type, TonikErrorType.encoding);
      });
    });

    group('with level1 as anyOf variant (both Class1 and Class2)', () {
      // AnyOf variants have complex encoding shape which cannot be serialized
      // to simple style headers per OpenAPI spec (RFC6570).
      test('fails to encode anyOf variant in header', () async {
        const input = MultiLevelNesting(
          multiLevelNestingModel: MultiLevelNestingModel(
            level1: MultiLevelNestingLevel1OneOfModelAnyOf(
              MultiLevelNestingLevel1OneOfAnyOfModel(
                class1: Class1(name: 'combined-name'),
                class2: Class2(number: 777),
              ),
            ),
          ),
          multiLevelNestingModel2: MultiLevelNestingModel2(level2: 300),
        );

        final result = await api.testHeaderRoundtripMultiLevel(
          multiLevel: input,
        );

        expect(
          result,
          isA<TonikError<HeadersRoundtripComplexMultiLevelGet200Response>>(),
        );
        final error =
            result
                as TonikError<HeadersRoundtripComplexMultiLevelGet200Response>;
        expect(error.type, TonikErrorType.encoding);
      });
    });

    group('with null level1', () {
      test('roundtrips MultiLevelNesting with null level1', () async {
        const input = MultiLevelNesting(
          multiLevelNestingModel: MultiLevelNestingModel(),
          multiLevelNestingModel2: MultiLevelNestingModel2(level2: 50),
        );

        final result = await api.testHeaderRoundtripMultiLevel(
          multiLevel: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripComplexMultiLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexMultiLevelGet200Response
                >;
        expect(success.value.xMultiLevel, isNotNull);
      });
    });

    group('with null level2', () {
      test('roundtrips MultiLevelNesting with null level2', () async {
        const input = MultiLevelNesting(
          multiLevelNestingModel: MultiLevelNestingModel(
            level1: MultiLevelNestingLevel1OneOfModelString('no-level2'),
          ),
          multiLevelNestingModel2: MultiLevelNestingModel2(),
        );

        final result = await api.testHeaderRoundtripMultiLevel(
          multiLevel: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripComplexMultiLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<
                  HeadersRoundtripComplexMultiLevelGet200Response
                >;
        expect(success.value.xMultiLevel, isNotNull);
      });
    });

    group('with both levels null', () {
      test('fails to encode empty object in header', () async {
        const input = MultiLevelNesting(
          multiLevelNestingModel: MultiLevelNestingModel(),
          multiLevelNestingModel2: MultiLevelNestingModel2(),
        );

        final result = await api.testHeaderRoundtripMultiLevel(
          multiLevel: input,
        );

        expect(
          result,
          isA<TonikError<HeadersRoundtripComplexMultiLevelGet200Response>>(),
        );
        final error =
            result
                as TonikError<HeadersRoundtripComplexMultiLevelGet200Response>;
        expect(error.type, TonikErrorType.encoding);
      });
    });
  });
}
