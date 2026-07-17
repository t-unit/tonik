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

        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'name,test',
        );
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

        // Header field-values are transmitted literally: the space survives.
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'name,hello world',
        );
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

        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          "name,O'Brien",
        );
        expect(success.value.xComplexUnion, isA<OneOfComplexClass1>());
        final class1 = success.value.xComplexUnion! as OneOfComplexClass1;
        expect(class1.value.name, "O'Brien");
      });

      test('round-trips Class1 with empty name', () async {
        final result = await api.testHeaderRoundtripOneOfComplex.call(
          complexUnion: const OneOfComplexClass1(Class1(name: '')),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripOneofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripOneofComplexGet200Response>;

        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'name,',
        );
        expect(success.value.xComplexUnion, isA<OneOfComplexClass1>());
        final class1 = success.value.xComplexUnion! as OneOfComplexClass1;
        expect(class1.value.name, '');
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

        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'number,42',
        );
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
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'number,0',
        );
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
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'number,-123',
        );
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
        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          'number,9999999',
        );
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

        expect(
          success.response.requestOptions.headers['X-Complex-Union'],
          isNull,
        );
        expect(success.value.xComplexUnion, isNull);
      });
    });

    group('server-originated response', () {
      test('literal percent sequences in an injected oneOf object header '
          'decode verbatim', () async {
        // Server-originated: X-Complex-Union is injected via Dio, not
        // sent by Tonik's encoder.
        final injected = SimpleEncodingApi(
          CustomServer(
            baseUrl: baseUrl,
            serverConfig: ServerConfig(
              baseOptions: BaseOptions(
                headers: {
                  'X-Response-Status': '200',
                  'X-Complex-Union': 'name,x%2Fy 50%',
                },
              ),
            ),
          ),
        );

        final result = await injected.testHeaderRoundtripOneOfComplex.call();

        final success =
            result as TonikSuccess<HeadersRoundtripOneofComplexGet200Response>;
        expect(success.value.xComplexUnion, isA<OneOfComplexClass1>());
        final class1 = success.value.xComplexUnion! as OneOfComplexClass1;
        expect(class1.value.name, 'x%2Fy 50%');
      });
    });
  });
}
