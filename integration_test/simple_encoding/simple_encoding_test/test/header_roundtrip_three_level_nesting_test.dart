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

  late SimpleEncodingApi api;

  setUp(() {
    api = buildApi(responseStatus: '200');
  });

  group('ThreeLevelOneOf header roundtrip', () {
    group('with number variant (level 1)', () {
      test('roundtrips positive number', () async {
        const input = ThreeLevelOneOfNumber(3.14);

        final result = await api.testHeaderRoundtripThreeLevelNesting(
          threeLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;
        expect(success.value.xThreeLevelOneOf, isA<ThreeLevelOneOfNumber>());
        final decoded =
            success.value.xThreeLevelOneOf! as ThreeLevelOneOfNumber;
        expect(decoded.value, closeTo(3.14, 0.001));
      });

      test('roundtrips zero', () async {
        const input = ThreeLevelOneOfNumber(0);

        final result = await api.testHeaderRoundtripThreeLevelNesting(
          threeLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;
        expect(success.value.xThreeLevelOneOf, isA<ThreeLevelOneOfNumber>());
        final decoded =
            success.value.xThreeLevelOneOf! as ThreeLevelOneOfNumber;
        expect(decoded.value, equals(0));
      });

      test('roundtrips negative number', () async {
        const input = ThreeLevelOneOfNumber(-42.5);

        final result = await api.testHeaderRoundtripThreeLevelNesting(
          threeLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;
        expect(success.value.xThreeLevelOneOf, isA<ThreeLevelOneOfNumber>());
        final decoded =
            success.value.xThreeLevelOneOf! as ThreeLevelOneOfNumber;
        expect(decoded.value, closeTo(-42.5, 0.001));
      });
    });

    group('with nested OneOf (level 2) - bool variant', () {
      test('roundtrips true', () async {
        const innerOneOf = ThreeLevelOneOfModelBool(true);
        const input = ThreeLevelOneOfOneOf(innerOneOf);

        final result = await api.testHeaderRoundtripThreeLevelNesting(
          threeLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;
        expect(success.value.xThreeLevelOneOf, isA<ThreeLevelOneOfOneOf>());
        final decoded = success.value.xThreeLevelOneOf! as ThreeLevelOneOfOneOf;
        expect(decoded.value, isA<ThreeLevelOneOfModelBool>());
        final innerValue = decoded.value as ThreeLevelOneOfModelBool;
        expect(innerValue.value, equals(true));
      });

      test('roundtrips false', () async {
        const innerOneOf = ThreeLevelOneOfModelBool(false);
        const input = ThreeLevelOneOfOneOf(innerOneOf);

        final result = await api.testHeaderRoundtripThreeLevelNesting(
          threeLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;
        expect(success.value.xThreeLevelOneOf, isA<ThreeLevelOneOfOneOf>());
        final decoded = success.value.xThreeLevelOneOf! as ThreeLevelOneOfOneOf;
        expect(decoded.value, isA<ThreeLevelOneOfModelBool>());
        final innerValue = decoded.value as ThreeLevelOneOfModelBool;
        expect(innerValue.value, equals(false));
      });
    });

    group('with nested OneOf (level 3) - int variant (ambiguous)', () {
      // Note: Integer values are ambiguous because they can be decoded as
      // either:
      // - ThreeLevelOneOfNumber (level 1 number variant)
      // - ThreeLevelOneOfOneOf > ThreeLevelOneOfModelOneOf >
      //   ThreeLevelOneOfOneOfModelInt (level 3 int)
      // The decoder tries number first, so integers will decode as
      // ThreeLevelOneOfNumber.

      test('roundtrips integer (ambiguous - may decode as number)', () async {
        const level3OneOf = ThreeLevelOneOfOneOfModelInt(42);
        const level2OneOf = ThreeLevelOneOfModelOneOf(level3OneOf);
        const input = ThreeLevelOneOfOneOf(level2OneOf);

        final result = await api.testHeaderRoundtripThreeLevelNesting(
          threeLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;

        // Accept either decoding - both are valid interpretations
        expect(
          success.value.xThreeLevelOneOf,
          isIn([
            const ThreeLevelOneOfNumber(42),
            const ThreeLevelOneOfOneOf(
              ThreeLevelOneOfModelOneOf(ThreeLevelOneOfOneOfModelInt(42)),
            ),
          ]),
        );
      });

      test(
        'roundtrips negative integer (ambiguous - may decode as number)',
        () async {
          const level3OneOf = ThreeLevelOneOfOneOfModelInt(-100);
          const level2OneOf = ThreeLevelOneOfModelOneOf(level3OneOf);
          const input = ThreeLevelOneOfOneOf(level2OneOf);

          final result = await api.testHeaderRoundtripThreeLevelNesting(
            threeLevelOneOf: input,
          );

          expect(
            result,
            isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
          );
          final success =
              result
                  as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;

          // Accept either decoding - both are valid interpretations
          expect(
            success.value.xThreeLevelOneOf,
            isIn([
              const ThreeLevelOneOfNumber(-100),
              const ThreeLevelOneOfOneOf(
                ThreeLevelOneOfModelOneOf(ThreeLevelOneOfOneOfModelInt(-100)),
              ),
            ]),
          );
        },
      );
    });

    group('with nested OneOf (level 3) - string variant', () {
      test('roundtrips simple string', () async {
        const level3OneOf = ThreeLevelOneOfOneOfModelString('hello');
        const level2OneOf = ThreeLevelOneOfModelOneOf(level3OneOf);
        const input = ThreeLevelOneOfOneOf(level2OneOf);

        final result = await api.testHeaderRoundtripThreeLevelNesting(
          threeLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;
        expect(success.value.xThreeLevelOneOf, isA<ThreeLevelOneOfOneOf>());
        final decoded = success.value.xThreeLevelOneOf! as ThreeLevelOneOfOneOf;
        expect(decoded.value, isA<ThreeLevelOneOfModelOneOf>());
        final level2 = decoded.value as ThreeLevelOneOfModelOneOf;
        expect(level2.value, isA<ThreeLevelOneOfOneOfModelString>());
        final level3 = level2.value as ThreeLevelOneOfOneOfModelString;
        expect(level3.value, equals('hello'));
      });

      test('roundtrips string with spaces', () async {
        const level3OneOf = ThreeLevelOneOfOneOfModelString('hello world');
        const level2OneOf = ThreeLevelOneOfModelOneOf(level3OneOf);
        const input = ThreeLevelOneOfOneOf(level2OneOf);

        final result = await api.testHeaderRoundtripThreeLevelNesting(
          threeLevelOneOf: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;
        expect(success.value.xThreeLevelOneOf, isA<ThreeLevelOneOfOneOf>());
        final decoded = success.value.xThreeLevelOneOf! as ThreeLevelOneOfOneOf;
        expect(decoded.value, isA<ThreeLevelOneOfModelOneOf>());
        final level2 = decoded.value as ThreeLevelOneOfModelOneOf;
        expect(level2.value, isA<ThreeLevelOneOfOneOfModelString>());
        final level3 = level2.value as ThreeLevelOneOfOneOfModelString;
        expect(level3.value, equals('hello world'));
      });
    });
  });

  group('ThreeLevelMixedOneOfAllOfAnyOf header roundtrip', () {
    group('with Class1 variant (encodable)', () {
      test('roundtrips Class1 with name property', () async {
        const input = ThreeLevelMixedOneOfAllOfAnyOfClass1(
          Class1(name: 'test-value'),
        );

        final result = await api.testHeaderRoundtripThreeLevelNesting(
          threeLevelMixed: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;
        expect(
          success.value.xThreeLevelMixed,
          isA<ThreeLevelMixedOneOfAllOfAnyOfClass1>(),
        );
        final decoded =
            success.value.xThreeLevelMixed!
                as ThreeLevelMixedOneOfAllOfAnyOfClass1;
        expect(decoded.value.name, equals('test-value'));
      });

      test('roundtrips Class1 with simple name', () async {
        const input = ThreeLevelMixedOneOfAllOfAnyOfClass1(
          Class1(name: 'simple'),
        );

        final result = await api.testHeaderRoundtripThreeLevelNesting(
          threeLevelMixed: input,
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
        );
        final success =
            result
                as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;
        expect(
          success.value.xThreeLevelMixed,
          isA<ThreeLevelMixedOneOfAllOfAnyOfClass1>(),
        );
        final decoded =
            success.value.xThreeLevelMixed!
                as ThreeLevelMixedOneOfAllOfAnyOfClass1;
        expect(decoded.value.name, equals('simple'));
      });
    });

    group('with AllOf variant (mixed encoding - fails)', () {
      test('fails to encode mixed allOf variant', () async {
        // The AllOf variant has EncodingShape.mixed which cannot be encoded
        // to a header value. This should result in an encoding error.
        const anyOfModel = ThreeLevelMixedOneOfAllOfAnyOfAllOfAnyOfModel(
          string: 'test',
        );
        const model2 = ThreeLevelMixedOneOfAllOfAnyOfAllOfModel2(flag: true);
        const allOfModel = ThreeLevelMixedOneOfAllOfAnyOfAllOfModel(
          threeLevelMixedOneOfAllOfAnyOfAllOfAnyOfModel: anyOfModel,
          threeLevelMixedOneOfAllOfAnyOfAllOfModel2: model2,
        );
        const input = ThreeLevelMixedOneOfAllOfAnyOfAllOf(allOfModel);

        final result = await api.testHeaderRoundtripThreeLevelNesting(
          threeLevelMixed: input,
        );

        expect(
          result,
          isA<TonikError<HeadersRoundtripDeepThreeLevelGet200Response>>(),
        );
        final error =
            result as TonikError<HeadersRoundtripDeepThreeLevelGet200Response>;
        expect(error.type, equals(TonikErrorType.encoding));
      });
    });
  });

  group('combined ThreeLevelOneOf and ThreeLevelMixed', () {
    test('roundtrips both headers with encodable variants', () async {
      const oneOfInput = ThreeLevelOneOfNumber(99.9);
      const mixedInput = ThreeLevelMixedOneOfAllOfAnyOfClass1(
        Class1(name: 'combined-test'),
      );

      final result = await api.testHeaderRoundtripThreeLevelNesting(
        threeLevelOneOf: oneOfInput,
        threeLevelMixed: mixedInput,
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;

      // Verify ThreeLevelOneOf
      expect(success.value.xThreeLevelOneOf, isA<ThreeLevelOneOfNumber>());
      final oneOfDecoded =
          success.value.xThreeLevelOneOf! as ThreeLevelOneOfNumber;
      expect(oneOfDecoded.value, closeTo(99.9, 0.001));

      // Verify ThreeLevelMixed
      expect(
        success.value.xThreeLevelMixed,
        isA<ThreeLevelMixedOneOfAllOfAnyOfClass1>(),
      );
      final mixedDecoded =
          success.value.xThreeLevelMixed!
              as ThreeLevelMixedOneOfAllOfAnyOfClass1;
      expect(mixedDecoded.value.name, equals('combined-test'));
    });

    test('roundtrips deeply nested OneOf with Class1 mixed', () async {
      const level3OneOf = ThreeLevelOneOfOneOfModelString('deep-value');
      const level2OneOf = ThreeLevelOneOfModelOneOf(level3OneOf);
      const oneOfInput = ThreeLevelOneOfOneOf(level2OneOf);
      const mixedInput = ThreeLevelMixedOneOfAllOfAnyOfClass1(
        Class1(name: 'shallow-value'),
      );

      final result = await api.testHeaderRoundtripThreeLevelNesting(
        threeLevelOneOf: oneOfInput,
        threeLevelMixed: mixedInput,
      );

      expect(
        result,
        isA<TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>>(),
      );
      final success =
          result as TonikSuccess<HeadersRoundtripDeepThreeLevelGet200Response>;

      // Verify ThreeLevelOneOf - deeply nested string
      expect(success.value.xThreeLevelOneOf, isA<ThreeLevelOneOfOneOf>());
      final decoded = success.value.xThreeLevelOneOf! as ThreeLevelOneOfOneOf;
      expect(decoded.value, isA<ThreeLevelOneOfModelOneOf>());
      final level2 = decoded.value as ThreeLevelOneOfModelOneOf;
      expect(level2.value, isA<ThreeLevelOneOfOneOfModelString>());
      final level3 = level2.value as ThreeLevelOneOfOneOfModelString;
      expect(level3.value, equals('deep-value'));

      // Verify ThreeLevelMixed
      expect(
        success.value.xThreeLevelMixed,
        isA<ThreeLevelMixedOneOfAllOfAnyOfClass1>(),
      );
      final mixedDecoded =
          success.value.xThreeLevelMixed!
              as ThreeLevelMixedOneOfAllOfAnyOfClass1;
      expect(mixedDecoded.value.name, equals('shallow-value'));
    });
  });
}
