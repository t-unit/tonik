import 'package:big_decimal/big_decimal.dart';
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

  SimpleEncodingApi buildApi({Map<String, dynamic> rawHeaders = const {}}) {
    return SimpleEncodingApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': '200', ...rawHeaders},
          ),
        ),
      ),
    );
  }

  group('primitive string header transmits literal values', () {
    for (final value in ['acme corp', '50%', '75%2Fdone', 'a%20b']) {
      test('transmits $value verbatim on the wire', () async {
        final api = buildApi();
        final response = await api.testHeaderRoundtripPrimitives(string: value);

        final success =
            response
                as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;
        expect(success.response.requestOptions.headers['x-string'], value);
      });
    }
  });

  group('server-originated response header decodes literally', () {
    test('50% response header parses as 50%', () async {
      final api = buildApi(rawHeaders: {'X-String': '50%'});
      final response = await api.testHeaderRoundtripPrimitives();

      final success =
          response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;
      expect(success.value.xString, '50%');
    });

    test('75%2Fdone response header remains unchanged', () async {
      final api = buildApi(rawHeaders: {'X-String': '75%2Fdone'});
      final response = await api.testHeaderRoundtripPrimitives();

      final success =
          response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;
      expect(success.value.xString, '75%2Fdone');
    });

    test('a%20b response header remains unchanged', () async {
      final api = buildApi(rawHeaders: {'X-String': 'a%20b'});
      final response = await api.testHeaderRoundtripPrimitives();

      final success =
          response as TonikSuccess<HeadersRoundtripPrimitivesGet200Response>;
      expect(success.value.xString, 'a%20b');
    });
  });

  group('base64 header retains standard-alphabet characters', () {
    test('bytes producing + / = survive on the wire and roundtrip', () async {
      // These bytes base64-encode to a value containing '+', '/', and '='.
      final bytes = [0xFB, 0xFF, 0xBF, 0x00];
      final api = buildApi();
      final response = await api.testHeaderRoundtripBase64(
        fileData: TonikFileBytes(bytes),
      );

      final success =
          response as TonikSuccess<HeadersRoundtripBase64Get200Response>;
      final wire = success.response.requestOptions.headers['x-file-data'];
      expect(wire, '+/+/AA==');
      expect(success.value.xFileData?.toBytes(), bytes);
    });
  });

  group('path parameters keep URI percent-encoding', () {
    test('reserved characters in a string path segment are encoded', () async {
      final api = buildApi();
      final response = await api.testPrimitiveInPath(
        integer: 1,
        double: 1,
        number: 1,
        string: 'a b/c%d',
        boolean: true,
        datetime: DateTime.utc(1970),
        date: Date(2000, 1, 1),
        decimal: BigDecimal.parse('1'),
        uri: Uri.parse('https://example.com'),
        $enum: StatusEnum.active,
      );

      final success = response as TonikSuccess<void>;
      expect(
        success.response.requestOptions.uri.path,
        '/v1/primitive/1/1.0/1/a%20b%2Fc%25d/true/'
            '1970-01-01T00%3A00%3A00.000Z/2000-01-01/1/'
            'https%3A%2F%2Fexample.com/active',
      );
    });
  });

  group('control characters are rejected before dispatch', () {
    final cases = <String, String>{
      'carriage return': 'a${String.fromCharCode(13)}b',
      'line feed': 'a${String.fromCharCode(10)}b',
      'null byte': 'a${String.fromCharCode(0)}b',
      'unit separator': 'a${String.fromCharCode(31)}b',
    };
    for (final entry in cases.entries) {
      test('${entry.key} in a header value is rejected pre-dispatch, '
          'while the same header without it succeeds', () async {
        final api = buildApi();

        final control = await api.testHeaderRoundtripPrimitives(string: 'ab');
        expect(
          control,
          isA<TonikSuccess<HeadersRoundtripPrimitivesGet200Response>>(),
        );

        final response = await api.testHeaderRoundtripPrimitives(
          string: entry.value,
        );

        expect(
          response,
          isA<TonikError<HeadersRoundtripPrimitivesGet200Response>>(),
        );
        final error =
            response
                as TonikError<HeadersRoundtripPrimitivesGet200Response>;
        expect(error.response, isNull);
      });
    }
  });
}
