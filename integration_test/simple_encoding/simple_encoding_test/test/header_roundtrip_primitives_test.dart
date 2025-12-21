import 'package:big_decimal/big_decimal.dart';
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

  group('Header Roundtrip Primitives', () {
    group('integer', () {
      test('positive integer roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          integer: 42,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;
        expect(success.response.statusCode, 200);

        expect(success.response.requestOptions.headers['x-integer'], '42');

        expect(success.value.xInteger, 42);
      });

      test('negative integer roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          integer: -123,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.response.requestOptions.headers['x-integer'], '-123');

        expect(success.value.xInteger, -123);
      });

      test('zero integer roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          integer: 0,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.response.requestOptions.headers['x-integer'], '0');

        expect(success.value.xInteger, 0);
      });
    });

    group('double', () {
      test('positive double roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          double: 3.14159,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.response.requestOptions.headers['x-double'], '3.14159');

        expect(success.value.xDouble, 3.14159);
      });

      test('negative double roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          double: -99.99,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.response.requestOptions.headers['x-double'], '-99.99');

        expect(success.value.xDouble, -99.99);
      });

      test('whole number double roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          double: 42,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.response.requestOptions.headers['x-double'], '42.0');

        expect(success.value.xDouble, 42.0);
      });
    });

    group('number', () {
      test('positive number roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          number: 123.456,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.response.requestOptions.headers['x-number'], '123.456');

        expect(success.value.xNumber, 123.456);
      });

      test('integer as number roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          number: 100,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xNumber, 100);
      });
    });

    group('string', () {
      test('simple string roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          string: 'hello',
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.response.requestOptions.headers['x-string'], 'hello');

        expect(success.value.xString, 'hello');
      });

      test('string with spaces roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          string: 'hello world',
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        // Note: spaces may be encoded
        expect(success.value.xString, 'hello world');
      });

      test('string with special characters roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          string: 'test@example.com',
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xString, 'test@example.com');
      });

      test('string with percent literal roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          string: '50% discount',
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        // Percent sign should survive roundtrip
        expect(success.value.xString, '50% discount');
      });

      test('string with multiple percent signs roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          string: '100% free, 50% off',
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xString, '100% free, 50% off');
      });

      test('string with ampersand roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          string: 'foo & bar',
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xString, 'foo & bar');
      });

      test('string with equals sign roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          string: 'key=value',
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xString, 'key=value');
      });

      test('string with all special URL characters roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          string: 'foo%bar&baz=qux',
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        // All special characters should survive roundtrip
        expect(success.value.xString, 'foo%bar&baz=qux');
      });
    });

    group('boolean', () {
      test('true boolean roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          boolean: true,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.response.requestOptions.headers['x-boolean'], 'true');

        expect(success.value.xBoolean, true);
      });

      test('false boolean roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives(
          boolean: false,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.response.requestOptions.headers['x-boolean'], 'false');

        expect(success.value.xBoolean, false);
      });
    });

    group('dateTime', () {
      test('UTC datetime roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final dateTime = DateTime.utc(2023, 12, 25, 10, 30, 45);
        final response = await api.testHeaderRoundtripPrimitives(
          dateTime: dateTime,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        // DateTime should be ISO 8601 encoded
        expect(
          success.response.requestOptions.headers['x-datetime'],
          contains('2023-12-25'),
        );

        expect(success.value.xDateTime, dateTime);
      });

      test('epoch datetime roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final dateTime = DateTime.utc(1970);
        final response = await api.testHeaderRoundtripPrimitives(
          dateTime: dateTime,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xDateTime, dateTime);
      });
    });

    group('date', () {
      test('date roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final date = Date(2023, 12, 25);
        final response = await api.testHeaderRoundtripPrimitives(
          date: date,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(
          success.response.requestOptions.headers['x-date'],
          '2023-12-25',
        );

        expect(success.value.xDate, date);
      });

      test('leap year date roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final date = Date(2024, 2, 29);
        final response = await api.testHeaderRoundtripPrimitives(
          date: date,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(
          success.response.requestOptions.headers['x-date'],
          '2024-02-29',
        );

        expect(success.value.xDate, date);
      });
    });

    group('decimal', () {
      test('decimal roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final decimal = BigDecimal.parse('123.456789');
        final response = await api.testHeaderRoundtripPrimitives(
          decimal: decimal,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(
          success.response.requestOptions.headers['x-decimal'],
          '123.456789',
        );

        expect(success.value.xDecimal, decimal);
      });

      test('large decimal roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final decimal = BigDecimal.parse('999999999999999999.999999999999');
        final response = await api.testHeaderRoundtripPrimitives(
          decimal: decimal,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xDecimal, decimal);
      });

      test('negative decimal roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final decimal = BigDecimal.parse('-0.001');
        final response = await api.testHeaderRoundtripPrimitives(
          decimal: decimal,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xDecimal, decimal);
      });
    });

    group('uri', () {
      test('simple URI roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final uri = Uri.parse('https://example.com');
        final response = await api.testHeaderRoundtripPrimitives(
          uri: uri,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xUri, uri);
      });

      test('URI with path roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final uri = Uri.parse('https://example.com/path/to/resource');
        final response = await api.testHeaderRoundtripPrimitives(
          uri: uri,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xUri, uri);
      });

      test('URI with query parameters roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final uri = Uri.parse('https://example.com/search?q=test&page=1');
        final response = await api.testHeaderRoundtripPrimitives(
          uri: uri,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xUri, uri);
      });

      test('URI with special characters in query roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final uri = Uri.parse(
          'https://example.com/search?q=50%25+off&filter=a%26b',
        );
        final response = await api.testHeaderRoundtripPrimitives(
          uri: uri,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        // URI with encoded special characters should roundtrip correctly
        expect(success.value.xUri, uri);
      });

      test('URI with fragment roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final uri = Uri.parse('https://example.com/page#section');
        final response = await api.testHeaderRoundtripPrimitives(
          uri: uri,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;

        expect(success.value.xUri, uri);
      });
    });

    group('all primitives together', () {
      test('all primitives in single request roundtrip', () async {
        final api = buildApi(responseStatus: '200');
        final dateTime = DateTime.utc(2023, 6, 15, 12, 30, 45);
        final date = Date(2023, 6, 15);
        final decimal = BigDecimal.parse('99.99');
        final uri = Uri.parse('https://api.example.com/v1');

        final response = await api.testHeaderRoundtripPrimitives(
          integer: 42,
          double: 3.14,
          number: 100.5,
          string: 'test-value',
          boolean: true,
          dateTime: dateTime,
          date: date,
          decimal: decimal,
          uri: uri,
        );

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;
        expect(success.response.statusCode, 200);

        // Verify all request headers
        final requestHeaders = success.response.requestOptions.headers;
        expect(requestHeaders['x-integer'], '42');
        expect(requestHeaders['x-double'], '3.14');
        expect(requestHeaders['x-number'], '100.5');
        expect(requestHeaders['x-string'], 'test-value');
        expect(requestHeaders['x-boolean'], 'true');
        expect(requestHeaders['x-date'], '2023-06-15');

        // Verify all response values
        expect(success.value.xInteger, 42);
        expect(success.value.xDouble, 3.14);
        expect(success.value.xNumber, 100.5);
        expect(success.value.xString, 'test-value');
        expect(success.value.xBoolean, true);
        expect(success.value.xDateTime, dateTime);
        expect(success.value.xDate, date);
        expect(success.value.xDecimal, decimal);
        expect(success.value.xUri, uri);
      });
    });

    group('null/missing values', () {
      test('no headers sent - null response values', () async {
        final api = buildApi(responseStatus: '200');
        final response = await api.testHeaderRoundtripPrimitives();

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;
        expect(success.response.statusCode, 200);

        // All values should be null when no headers are sent
        expect(success.value.xInteger, isNull);
        expect(success.value.xDouble, isNull);
        expect(success.value.xNumber, isNull);
        expect(success.value.xString, isNull);
        expect(success.value.xBoolean, isNull);
        expect(success.value.xDateTime, isNull);
        expect(success.value.xDate, isNull);
        expect(success.value.xDecimal, isNull);
        expect(success.value.xUri, isNull);
      });
    });
  });
}
