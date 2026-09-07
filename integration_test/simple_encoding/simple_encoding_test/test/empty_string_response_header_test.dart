import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('present empty optional string response header stays empty', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'X-String': ''},
    );
    final api = SimpleEncodingApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.testHeaderRoundtripPrimitives();

    final success = requireSuccess(response);
    expect(success.value.xString, '');
  });

  test('absent optional string response header remains null', () async {
    final server = await RawRequestServer.start(responseStatusCode: 200);
    final api = SimpleEncodingApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.testHeaderRoundtripPrimitives();

    final success = requireSuccess(response);
    expect(success.value.xString, isNull);
  });

  test('nonempty optional string response header keeps its value', () async {
    final server = await RawRequestServer.start(
      responseStatusCode: 200,
      responseHeaders: {'X-String': 'daily'},
    );
    final api = SimpleEncodingApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.testHeaderRoundtripPrimitives();

    final success = requireSuccess(response);
    expect(success.value.xString, 'daily');
  });

  test(
    'optional string response header preserves literal percent text',
    () async {
      final server = await RawRequestServer.start(
        responseStatusCode: 200,
        responseHeaders: {'X-String': '50% ready%2Fdone'},
      );
      final api = SimpleEncodingApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.testHeaderRoundtripPrimitives();

      final success = requireSuccess(response);
      expect(success.value.xString, '50% ready%2Fdone');
    },
  );
}
