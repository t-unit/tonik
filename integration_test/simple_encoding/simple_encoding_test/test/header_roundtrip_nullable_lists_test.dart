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

  SimpleEncodingApi buildApi() {
    return SimpleEncodingApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(headers: {'X-Response-Status': '200'}),
        ),
      ),
    );
  }

  group('Header roundtrip nullable lists', () {
    test('string list escapes special chars and encodes null as empty',
        () async {
      final api = buildApi();
      final response = await api.testHeaderRoundtripNullableLists(
        nullableStringList: ['hello world', 'foo/bar', null],
      );

      expect(
        response,
        isA<TonikSuccess<HeadersRoundtripListsNullableGet200Response>>(),
      );
      final success = response
          as TonikSuccess<HeadersRoundtripListsNullableGet200Response>;
      expect(success.response.statusCode, 200);
      expect(
        success.response.requestOptions.headers['x-nullable-string-list'],
        'hello%20world,foo%2Fbar,',
      );
    });

    test('integer list encodes null as empty and is not decodable back',
        () async {
      final api = buildApi();
      final response = await api.testHeaderRoundtripNullableLists(
        nullableIntegerList: [1, null, 2],
      );

      // The request encodes the null element as an empty string.
      final dioResponse = switch (response) {
        TonikSuccess(:final response) => response,
        TonikError(:final response) => response,
      };
      expect(
        dioResponse?.requestOptions.headers['x-nullable-integer-list'],
        '1,,2',
      );

      // A null array element has no wire representation in parameter styles, so
      // the echoed empty element cannot be decoded back to int. See
      // docs/uri_encoding_limitations.md.
      expect(
        response,
        isA<TonikError<HeadersRoundtripListsNullableGet200Response>>(),
      );
    });
  });
}
