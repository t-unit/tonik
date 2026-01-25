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

  group('Header Roundtrip Simple Lists', () {
    group('string list', () {
      test('single item string list roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          stringList: ['hello'],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-string-list'],
          'hello',
        );
        expect(success.value.xStringList, ['hello']);
      });

      test('multiple item string list roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          stringList: ['apple', 'banana', 'cherry'],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;

        expect(
          success.response.requestOptions.headers['x-string-list'],
          'apple,banana,cherry',
        );

        expect(success.value.xStringList, ['apple', 'banana', 'cherry']);
      });

      test('string list with special characters roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          stringList: ['hello world', 'foo@bar'],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;

        expect(success.value.xStringList, ['hello world', 'foo@bar']);
      });
    });

    group('integer list', () {
      test('single item integer list roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          integerList: [42],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;
        expect(success.response.statusCode, 200);

        expect(success.response.requestOptions.headers['x-integer-list'], '42');
        expect(success.value.xIntegerList, [42]);
      });

      test('multiple item integer list roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          integerList: [1, 2, 3, 4, 5],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;

        expect(
          success.response.requestOptions.headers['x-integer-list'],
          '1,2,3,4,5',
        );
        expect(success.value.xIntegerList, [1, 2, 3, 4, 5]);
      });

      test('integer list with negative numbers roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          integerList: [-10, 0, 10],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;

        expect(
          success.response.requestOptions.headers['x-integer-list'],
          '-10,0,10',
        );
        expect(success.value.xIntegerList, [-10, 0, 10]);
      });
    });

    group('number list', () {
      test('single item number list roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          numberList: [3.14],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-number-list'],
          '3.14',
        );
        expect(success.value.xNumberList, [3.14]);
      });

      test('multiple item number list roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          numberList: [1.1, 2.2, 3.3],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;

        expect(
          success.response.requestOptions.headers['x-number-list'],
          '1.1,2.2,3.3',
        );
        expect(success.value.xNumberList, [1.1, 2.2, 3.3]);
      });

      test('number list with mixed integers and decimals roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          numberList: [1, 2.5, 3],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;

        expect(success.value.xNumberList, [1, 2.5, 3]);
      });
    });

    group('boolean list', () {
      test('single item boolean list roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          booleanList: [true],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;
        expect(success.response.statusCode, 200);

        expect(
          success.response.requestOptions.headers['x-boolean-list'],
          'true',
        );
        expect(success.value.xBooleanList, [true]);
      });

      test('multiple item boolean list roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          booleanList: [true, false, true],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;

        expect(
          success.response.requestOptions.headers['x-boolean-list'],
          'true,false,true',
        );
        expect(success.value.xBooleanList, [true, false, true]);
      });

      test('all false boolean list roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          booleanList: [false, false],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;

        expect(
          success.response.requestOptions.headers['x-boolean-list'],
          'false,false',
        );
        expect(success.value.xBooleanList, [false, false]);
      });
    });

    group('all lists together', () {
      test('all list types in single request roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          stringList: ['a', 'b', 'c'],
          integerList: [1, 2, 3],
          numberList: [1.5, 2.5, 3.5],
          booleanList: [true, false],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;
        expect(success.response.statusCode, 200);

        // Verify all request headers
        final requestHeaders = success.response.requestOptions.headers;
        expect(requestHeaders['x-string-list'], 'a,b,c');
        expect(requestHeaders['x-integer-list'], '1,2,3');
        expect(requestHeaders['x-number-list'], '1.5,2.5,3.5');
        expect(requestHeaders['x-boolean-list'], 'true,false');

        // Verify all response values
        expect(success.value.xStringList, ['a', 'b', 'c']);
        expect(success.value.xIntegerList, [1, 2, 3]);
        expect(success.value.xNumberList, [1.5, 2.5, 3.5]);
        expect(success.value.xBooleanList, [true, false]);
      });
    });

    group('null/missing values', () {
      test('no headers sent - null response values', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists();

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;
        expect(success.response.statusCode, 200);

        // All values should be null when no headers are sent
        expect(success.value.xStringList, isNull);
        expect(success.value.xIntegerList, isNull);
        expect(success.value.xNumberList, isNull);
        expect(success.value.xBooleanList, isNull);
      });

      test('only string list sent - others are null', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripSimpleLists(
          stringList: ['test'],
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;

        expect(success.value.xStringList, ['test']);
        expect(success.value.xIntegerList, isNull);
        expect(success.value.xNumberList, isNull);
        expect(success.value.xBooleanList, isNull);
      });
    });
  });
}
