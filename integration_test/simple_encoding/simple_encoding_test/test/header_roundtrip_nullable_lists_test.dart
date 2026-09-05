import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

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
        serverConfig: testServerConfig(headers: {'X-Response-Status': '200'}),
      ),
    );
  }

  group('Header roundtrip nullable lists', () {
    test(
      'string list escapes special chars and encodes null as empty',
      () async {
        final api = buildApi();
        final response = await api.testHeaderRoundtripNullableLists(
          nullableStringList: ['hello world', 'foo/bar', null],
        );

        expect(response, isTonikSuccess);
        final success = requireSuccess(response);
        expect(success.response.statusCode, 200);
        final recordedRequest = await imposterServer.takeRequest();
        expect(
          recordedRequest.headers['x-nullable-string-list'],
          'hello world,foo/bar,',
        );
      },
    );

    test(
      'integer list encodes null as empty and is not decodable back',
      () async {
        final api = buildApi();
        final response = await api.testHeaderRoundtripNullableLists(
          nullableIntegerList: [1, null, 2],
        );

        // The request encodes the null element as an empty string.
        requireError(response);
        final recordedRequest = await imposterServer.takeRequest();
        expect(recordedRequest.headers['x-nullable-integer-list'], '1,,2');

        // A null array element has no wire representation in parameter styles,
        // so the echoed empty element cannot be decoded back to int. See
        // docs/uri_encoding_limitations.md.
        expect(response, isTonikError);
      },
    );

    group('server-originated response', () {
      test('injected literal decodes reserved chars verbatim and empty '
          'elements as null', () async {
        // Server-originated: X-Nullable-String-List injected via Dio;
        // exercises the empty-element→null branch.
        final injected = SimpleEncodingApi(
          CustomServer(
            baseUrl: baseUrl,
            serverConfig: testServerConfig(
              headers: {
                'X-Response-Status': '200',
                'X-Nullable-String-List': 'a%2Fb,,50%',
              },
            ),
          ),
        );

        final response = await injected.testHeaderRoundtripNullableLists();

        final success = requireSuccess(response);
        expect(success.value.xNullableStringList, ['a%2Fb', null, '50%']);
      });
    });
  });
}
