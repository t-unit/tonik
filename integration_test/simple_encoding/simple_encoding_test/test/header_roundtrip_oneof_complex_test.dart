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

  group('OneOfComplex header roundtrip', () {
    group('Class1 variant', () {
      test('round-trips Class1 with simple name', () async {
        final result = await api.testHeaderRoundtripOneOfComplex.call(
          complexUnion: const OneOfComplexClass1(Class1(name: 'test')),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofComplexGet200Response>;

        // Verify encoded request header (simple style: key,value)
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'name,test',
        );

        // Verify decoded response
        expect(success.value.xComplexUnion, isA<OneOfComplexClass1>());
        final class1 = success.value.xComplexUnion! as OneOfComplexClass1;
        expect(class1.value.name, 'test');
      });

      test('round-trips Class1 with spaces in name', () async {
        final result = await api.testHeaderRoundtripOneOfComplex.call(
          complexUnion: const OneOfComplexClass1(
            Class1(name: 'hello world'),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofComplexGet200Response>;

        // Verify encoded request header (spaces are URL encoded)
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'name,hello%20world',
        );

        // Verify decoded response
        expect(success.value.xComplexUnion, isA<OneOfComplexClass1>());
        final class1 = success.value.xComplexUnion! as OneOfComplexClass1;
        expect(class1.value.name, 'hello world');
      });

      test('round-trips Class1 with special characters', () async {
        final result = await api.testHeaderRoundtripOneOfComplex.call(
          complexUnion: const OneOfComplexClass1(
            Class1(name: "O'Brien"),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofComplexGet200Response>;

        // Verify encoded request header (apostrophe is URL encoded)
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          "name,O'Brien",
        );

        // Verify decoded response
        expect(success.value.xComplexUnion, isA<OneOfComplexClass1>());
        final class1 = success.value.xComplexUnion! as OneOfComplexClass1;
        expect(class1.value.name, "O'Brien");
      });

      test('Class1 with empty name fails at encoding', () async {
        final result = await api.testHeaderRoundtripOneOfComplex.call(
          complexUnion: const OneOfComplexClass1(Class1(name: '')),
        );

        // Empty strings throw EmptyValueException during encoding
        // because allowEmpty is false for headers
        expect(
          result,
          isA<TonikError<HeadersRoundtripOneofComplexGet200Response>>(),
        );
        final error =
            result as TonikError<HeadersRoundtripOneofComplexGet200Response>;

        expect(error.type, TonikErrorType.encoding);
        expect(error.response, isNull);
      });
    });

    group('Class2 variant', () {
      test('round-trips Class2 with positive number', () async {
        final result = await api.testHeaderRoundtripOneOfComplex.call(
          complexUnion: const OneOfComplexClass2(Class2(number: 42)),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofComplexGet200Response>;

        // Verify encoded request header (simple style: key,value)
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'number,42',
        );

        // Verify decoded response
        expect(success.value.xComplexUnion, isA<OneOfComplexClass2>());
        final class2 = success.value.xComplexUnion! as OneOfComplexClass2;
        expect(class2.value.number, 42);
      });

      test('round-trips Class2 with zero', () async {
        final result = await api.testHeaderRoundtripOneOfComplex.call(
          complexUnion: const OneOfComplexClass2(Class2(number: 0)),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofComplexGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'number,0',
        );

        // Verify decoded response
        expect(success.value.xComplexUnion, isA<OneOfComplexClass2>());
        final class2 = success.value.xComplexUnion! as OneOfComplexClass2;
        expect(class2.value.number, 0);
      });

      test('round-trips Class2 with negative number', () async {
        final result = await api.testHeaderRoundtripOneOfComplex.call(
          complexUnion: const OneOfComplexClass2(Class2(number: -123)),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofComplexGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'number,-123',
        );

        // Verify decoded response
        expect(success.value.xComplexUnion, isA<OneOfComplexClass2>());
        final class2 = success.value.xComplexUnion! as OneOfComplexClass2;
        expect(class2.value.number, -123);
      });

      test('round-trips Class2 with large number', () async {
        final result = await api.testHeaderRoundtripOneOfComplex.call(
          complexUnion: const OneOfComplexClass2(Class2(number: 9999999)),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofComplexGet200Response>;

        // Verify encoded request header
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'number,9999999',
        );

        // Verify decoded response
        expect(success.value.xComplexUnion, isA<OneOfComplexClass2>());
        final class2 = success.value.xComplexUnion! as OneOfComplexClass2;
        expect(class2.value.number, 9999999);
      });
    });

    group('null handling', () {
      test('handles null complexUnion parameter', () async {
        final result = await api.testHeaderRoundtripOneOfComplex.call();

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofComplexGet200Response>;

        // Verify header is not present when null
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          isNull,
        );

        // Verify decoded response
        expect(success.value.xComplexUnion, isNull);
      });
    });
  });
}
