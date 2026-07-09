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

  group('AnyOfComplex header roundtrip', () {
    group('Class1 variant', () {
      test('round-trips Class1 with simple name', () async {
        final result = await api.testHeaderRoundtripAnyOfComplex.call(
          flexibleObject: const AnyOfComplex(class1: Class1(name: 'test')),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>;

        expect(
          success.response.requestOptions.headers['X-Flexible-Object'],
          'name,test',
        );
        expect(success.value.xFlexibleObject, isNotNull);
        expect(success.value.xFlexibleObject!.class1, isNotNull);
        expect(success.value.xFlexibleObject!.class1!.name, 'test');
      });

      test('round-trips Class1 with spaces in name', () async {
        final result = await api.testHeaderRoundtripAnyOfComplex.call(
          flexibleObject: const AnyOfComplex(
            class1: Class1(name: 'hello world'),
          ),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>;

        // Spaces are URL encoded in simple-style headers.
        expect(
          success.response.requestOptions.headers['X-Flexible-Object'],
          'name,hello%20world',
        );
        expect(success.value.xFlexibleObject, isNotNull);
        expect(success.value.xFlexibleObject!.class1, isNotNull);
        expect(success.value.xFlexibleObject!.class1!.name, 'hello world');
      });

      test('Class1 with empty name fails at encoding', () async {
        final result = await api.testHeaderRoundtripAnyOfComplex.call(
          flexibleObject: const AnyOfComplex(class1: Class1(name: '')),
        );

        expect(
          result,
          isA<TonikError<HeadersRoundtripAnyofComplexGet200Response>>(),
        );
        final error =
            result as TonikError<HeadersRoundtripAnyofComplexGet200Response>;

        expect(error.type, TonikErrorType.encoding);
        expect(error.response, isNull);
      });
    });

    group('Class2 variant', () {
      test('round-trips Class2 with positive number', () async {
        final result = await api.testHeaderRoundtripAnyOfComplex.call(
          flexibleObject: const AnyOfComplex(class2: Class2(number: 42)),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>;

        expect(
          success.response.requestOptions.headers['X-Flexible-Object'],
          'number,42',
        );
        expect(success.value.xFlexibleObject, isNotNull);
        expect(success.value.xFlexibleObject!.class2, isNotNull);
        expect(success.value.xFlexibleObject!.class2!.number, 42);
      });

      test('round-trips Class2 with zero', () async {
        final result = await api.testHeaderRoundtripAnyOfComplex.call(
          flexibleObject: const AnyOfComplex(class2: Class2(number: 0)),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>;
        expect(
          success.response.requestOptions.headers['X-Flexible-Object'],
          'number,0',
        );
        expect(success.value.xFlexibleObject, isNotNull);
        expect(success.value.xFlexibleObject!.class2, isNotNull);
        expect(success.value.xFlexibleObject!.class2!.number, 0);
      });

      test('round-trips Class2 with negative number', () async {
        final result = await api.testHeaderRoundtripAnyOfComplex.call(
          flexibleObject: const AnyOfComplex(class2: Class2(number: -99)),
        );

        expect(
          result,
          isA<TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>>(),
        );
        final success =
            result as TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>;
        expect(
          success.response.requestOptions.headers['X-Flexible-Object'],
          'number,-99',
        );
        expect(success.value.xFlexibleObject, isNotNull);
        expect(success.value.xFlexibleObject!.class2, isNotNull);
        expect(success.value.xFlexibleObject!.class2!.number, -99);
      });
    });

    group('null parameter', () {
      test(
        'null parameter results in no header sent and null response',
        () async {
          final result = await api.testHeaderRoundtripAnyOfComplex.call();

          expect(
            result,
            isA<TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>>(),
          );
          final success =
              result
                  as TonikSuccess<HeadersRoundtripAnyofComplexGet200Response>;
          expect(
            success.response.requestOptions.headers['X-Flexible-Object'],
            isNull,
          );
          expect(success.value.xFlexibleObject, isNull);
        },
      );
    });
  });
}
