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

  group('AnyOfMixed (FlexibleValue) header roundtrip', () {
    group('string variant', () {
      test('round-trips string value', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(string: 'hello'),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Mixed-Value'],
          'hello',
        );

        // Verify decoded response
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.string, 'hello');
      });
    });

    group('integer variant', () {
      test('round-trips integer value', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(int: 42),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Mixed-Value'],
          '42',
        );

        // Verify decoded response
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.int, 42);
      });
    });

    group('boolean variant', () {
      test('round-trips true', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(bool: true),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Mixed-Value'],
          'true',
        );

        // Verify decoded response
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.bool, true);
      });

      test('round-trips false', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(bool: false),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Mixed-Value'],
          'false',
        );

        // Verify decoded response
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.bool, false);
      });
    });

    group('SimpleObject variant', () {
      test('round-trips SimpleObject with both fields', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(
            simpleObject: SimpleObject(name: 'test', value: 42),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>;

        // Verify encoded request header (simple style: key,value,key,value)
        expect(
          success.response.requestOptions.headers['X-Mixed-Value'],
          'name,test,value,42',
        );

        // Verify decoded response
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.simpleObject, isNotNull);
        expect(success.value.xMixedValue!.simpleObject!.name, 'test');
        expect(success.value.xMixedValue!.simpleObject!.value, 42);
      });

      test('round-trips SimpleObject with only name', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(
            simpleObject: SimpleObject(name: 'onlyName'),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>;

        // Verify decoded response
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.simpleObject, isNotNull);
        expect(success.value.xMixedValue!.simpleObject!.name, 'onlyName');
      });

      test('round-trips SimpleObject with only value', () async {
        final result = await api.testHeaderRoundtripAnyOfMixed.call(
          mixedValue: const FlexibleValue(
            simpleObject: SimpleObject(value: 99),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>;

        // Verify decoded response
        expect(success.value.xMixedValue, isNotNull);
        expect(success.value.xMixedValue!.simpleObject, isNotNull);
        expect(success.value.xMixedValue!.simpleObject!.value, 99);
      });
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripAnyOfMixed.call();

          expect(
            result,
            isA<TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>>(),
          );
          final success =
              result as TonikSuccess<HeadersRoundtripAnyofMixedGet200Response>;

          // Verify no header was sent
          expect(
            success.response.requestOptions.headers['X-Mixed-Value'],
            isNull,
          );

          // Verify response property is null
          expect(success.value.xMixedValue, isNull);
        },
      );
    });
  });
}
