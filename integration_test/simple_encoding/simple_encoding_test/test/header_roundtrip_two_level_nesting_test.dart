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

  late SimpleEncodingApi api;

  setUp(() {
    api = buildApi(responseStatus: '200');
  });

  group('TwoLevelOneOf header roundtrip', () {
    group('with bool variant', () {
      test('roundtrips true value', () async {
        const input = TwoLevelOneOfBool(true);

        final result = await api.testHeaderRoundtripTwoLevelNesting(
          twoLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>;
        expect(success.value.xTwoLevelOneOf, isA<TwoLevelOneOfBool>());
        final decoded = success.value.xTwoLevelOneOf! as TwoLevelOneOfBool;
        expect(decoded.value, true);
      });

      test('roundtrips false value', () async {
        const input = TwoLevelOneOfBool(false);

        final result = await api.testHeaderRoundtripTwoLevelNesting(
          twoLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>;
        expect(success.value.xTwoLevelOneOf, isA<TwoLevelOneOfBool>());
        final decoded = success.value.xTwoLevelOneOf! as TwoLevelOneOfBool;
        expect(decoded.value, false);
      });
    });

    group('with nested OneOf variant (int)', () {
      test('roundtrips integer value', () async {
        const nestedOneOf = TwoLevelOneOfModelInt(42);
        const input = TwoLevelOneOfOneOf(nestedOneOf);

        final result = await api.testHeaderRoundtripTwoLevelNesting(
          twoLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>;
        expect(success.value.xTwoLevelOneOf, isA<TwoLevelOneOfOneOf>());
        final decoded = success.value.xTwoLevelOneOf! as TwoLevelOneOfOneOf;
        expect(decoded.value, isA<TwoLevelOneOfModelInt>());
        final innerValue = decoded.value as TwoLevelOneOfModelInt;
        expect(innerValue.value, 42);
      });

      test('roundtrips zero value', () async {
        const nestedOneOf = TwoLevelOneOfModelInt(0);
        const input = TwoLevelOneOfOneOf(nestedOneOf);

        final result = await api.testHeaderRoundtripTwoLevelNesting(
          twoLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>;
        expect(success.value.xTwoLevelOneOf, isA<TwoLevelOneOfOneOf>());
        final decoded = success.value.xTwoLevelOneOf! as TwoLevelOneOfOneOf;
        expect(decoded.value, isA<TwoLevelOneOfModelInt>());
        final innerValue = decoded.value as TwoLevelOneOfModelInt;
        expect(innerValue.value, 0);
      });

      test('roundtrips negative value', () async {
        const nestedOneOf = TwoLevelOneOfModelInt(-100);
        const input = TwoLevelOneOfOneOf(nestedOneOf);

        final result = await api.testHeaderRoundtripTwoLevelNesting(
          twoLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>;
        expect(success.value.xTwoLevelOneOf, isA<TwoLevelOneOfOneOf>());
        final decoded = success.value.xTwoLevelOneOf! as TwoLevelOneOfOneOf;
        expect(decoded.value, isA<TwoLevelOneOfModelInt>());
        final innerValue = decoded.value as TwoLevelOneOfModelInt;
        expect(innerValue.value, -100);
      });
    });

    group('with nested OneOf variant (string)', () {
      test('roundtrips simple string', () async {
        const nestedOneOf = TwoLevelOneOfModelString('hello');
        const input = TwoLevelOneOfOneOf(nestedOneOf);

        final result = await api.testHeaderRoundtripTwoLevelNesting(
          twoLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>;
        expect(success.value.xTwoLevelOneOf, isA<TwoLevelOneOfOneOf>());
        final decoded = success.value.xTwoLevelOneOf! as TwoLevelOneOfOneOf;
        expect(decoded.value, isA<TwoLevelOneOfModelString>());
        final innerValue = decoded.value as TwoLevelOneOfModelString;
        expect(innerValue.value, 'hello');
      });

      test('roundtrips string with special characters', () async {
        const nestedOneOf = TwoLevelOneOfModelString('hello world');
        const input = TwoLevelOneOfOneOf(nestedOneOf);

        final result = await api.testHeaderRoundtripTwoLevelNesting(
          twoLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>;
        expect(success.value.xTwoLevelOneOf, isA<TwoLevelOneOfOneOf>());
        final decoded = success.value.xTwoLevelOneOf! as TwoLevelOneOfOneOf;
        expect(decoded.value, isA<TwoLevelOneOfModelString>());
        final innerValue = decoded.value as TwoLevelOneOfModelString;
        expect(innerValue.value, 'hello world');
      });
    });
  });

  group('TwoLevelAllOf header roundtrip', () {
    test('roundtrips with all properties set', () async {
      const input = TwoLevelAllOf(
        twoLevelAllOfModel: TwoLevelAllOfModel(active: true),
        twoLevelAllOfAllOfModel: TwoLevelAllOfAllOfModel(
          twoLevelAllOfAllOfModel2: TwoLevelAllOfAllOfModel2(id: 'user-123'),
          twoLevelAllOfAllOfModel3: TwoLevelAllOfAllOfModel3(name: 'Alice'),
        ),
      );

      final result = await api.testHeaderRoundtripTwoLevelNesting(
        twoLevelAllOf: input,
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>;
      expect(success.value.xTwoLevelAllOf, isNotNull);
      final decoded = success.value.xTwoLevelAllOf!;
      expect(decoded.twoLevelAllOfModel.active, true);
      expect(
        decoded.twoLevelAllOfAllOfModel.twoLevelAllOfAllOfModel2.id,
        'user-123',
      );
      expect(
        decoded.twoLevelAllOfAllOfModel.twoLevelAllOfAllOfModel3.name,
        'Alice',
      );
    });

    test('roundtrips with active false', () async {
      const input = TwoLevelAllOf(
        twoLevelAllOfModel: TwoLevelAllOfModel(active: false),
        twoLevelAllOfAllOfModel: TwoLevelAllOfAllOfModel(
          twoLevelAllOfAllOfModel2: TwoLevelAllOfAllOfModel2(id: 'item-456'),
          twoLevelAllOfAllOfModel3: TwoLevelAllOfAllOfModel3(name: 'Bob'),
        ),
      );

      final result = await api.testHeaderRoundtripTwoLevelNesting(
        twoLevelAllOf: input,
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>;
      expect(success.value.xTwoLevelAllOf, isNotNull);
      final decoded = success.value.xTwoLevelAllOf!;
      expect(decoded.twoLevelAllOfModel.active, false);
      expect(
        decoded.twoLevelAllOfAllOfModel.twoLevelAllOfAllOfModel2.id,
        'item-456',
      );
      expect(
        decoded.twoLevelAllOfAllOfModel.twoLevelAllOfAllOfModel3.name,
        'Bob',
      );
    });

    test('roundtrips with some optional properties set', () async {
      const input = TwoLevelAllOf(
        twoLevelAllOfModel: TwoLevelAllOfModel(active: true),
        twoLevelAllOfAllOfModel: TwoLevelAllOfAllOfModel(
          twoLevelAllOfAllOfModel2: TwoLevelAllOfAllOfModel2(),
          twoLevelAllOfAllOfModel3: TwoLevelAllOfAllOfModel3(name: 'TestName'),
        ),
      );

      final result = await api.testHeaderRoundtripTwoLevelNesting(
        twoLevelAllOf: input,
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>;
      expect(success.value.xTwoLevelAllOf, isNotNull);
      final decoded = success.value.xTwoLevelAllOf!;
      expect(decoded.twoLevelAllOfModel.active, true);
      expect(
        decoded.twoLevelAllOfAllOfModel.twoLevelAllOfAllOfModel2.id,
        isNull,
      );
      expect(
        decoded.twoLevelAllOfAllOfModel.twoLevelAllOfAllOfModel3.name,
        'TestName',
      );
    });
  });

  group('combined TwoLevelOneOf and TwoLevelAllOf', () {
    test('roundtrips both headers together', () async {
      const oneOfInput = TwoLevelOneOfBool(true);
      const allOfInput = TwoLevelAllOf(
        twoLevelAllOfModel: TwoLevelAllOfModel(active: false),
        twoLevelAllOfAllOfModel: TwoLevelAllOfAllOfModel(
          twoLevelAllOfAllOfModel2: TwoLevelAllOfAllOfModel2(id: 'combo-id'),
          twoLevelAllOfAllOfModel3: TwoLevelAllOfAllOfModel3(name: 'Charlie'),
        ),
      );

      final result = await api.testHeaderRoundtripTwoLevelNesting(
        twoLevelOneOf: oneOfInput,
        twoLevelAllOf: allOfInput,
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripDeepTwoLevelGet200Response>;

      // Verify TwoLevelOneOf
      expect(success.value.xTwoLevelOneOf, isA<TwoLevelOneOfBool>());
      expect(
        (success.value.xTwoLevelOneOf! as TwoLevelOneOfBool).value,
        true,
      );

      // Verify TwoLevelAllOf
      expect(success.value.xTwoLevelAllOf, isNotNull);
      expect(
        success.value.xTwoLevelAllOf!.twoLevelAllOfModel.active,
        false,
      );
      expect(
        success
            .value
            .xTwoLevelAllOf!
            .twoLevelAllOfAllOfModel
            .twoLevelAllOfAllOfModel2
            .id,
        'combo-id',
      );
      expect(
        success
            .value
            .xTwoLevelAllOf!
            .twoLevelAllOfAllOfModel
            .twoLevelAllOfAllOfModel3
            .name,
        'Charlie',
      );
    });
  });
}
