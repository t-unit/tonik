import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  group('Header Roundtrip Duplicate Field Lines', () {
    test(
      'list header sent as two field lines decodes to the combined list',
      () async {
        final api = SimpleEncodingApi(
          CustomServer(
            baseUrl: 'https://example.com/v1',
            serverConfig: testServerConfig(
              response: const TestResponseStub(
                statusCode: 200,
                headers: {
                  'x-string-list': ['a', 'b'],
                },
              ),
            ),
          ),
        );

        final response = await api.testHeaderRoundtripSimpleLists();
        final success = requireSuccess(response);

        expect(success.response.statusCode, 200);
        expect(success.response.headers['x-string-list'], ['a', 'b']);
        expect(success.value.xStringList, ['a', 'b']);
      },
    );
  });
}
