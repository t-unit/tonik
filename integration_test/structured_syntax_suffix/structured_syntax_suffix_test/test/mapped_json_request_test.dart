import 'package:structured_syntax_suffix_api/structured_syntax_suffix_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('sends an object as JSON for a mapped custom content type', () async {
    final server = await RawRequestServer.start();
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postMappedObject(
      body: const JsonPayload(name: 'a b', count: 2),
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyText, '{"name":"a b","count":2}');
    expect(request.header('content-type'), 'application/x-amz-json-1.1');
  });

  test(
    'sends a string list as JSON for a mapped custom content type',
    () async {
      final server = await RawRequestServer.start();
      final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

      final response = await api.postMappedList(body: ['a', 'b']);

      expect(response, isTonikSuccess);
      final request = await server.takeRequest();
      expect(request.bodyText, '["a","b"]');
      expect(request.header('content-type'), 'application/x-amz-json-1.1');
    },
  );

  test('JSON encodes a custom string body exactly once', () async {
    final server = await RawRequestServer.start();
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postMappedString(body: 'a "b"');

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyText, r'"a \"b\""');
    expect(request.header('content-type'), 'application/x-amz-json-1.1');
  });

  test('omits an optional custom JSON body', () async {
    final server = await RawRequestServer.start();
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postMappedOptional();

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyBytes, isEmpty);
  });

  test('sends JSON null for a required nullable custom body', () async {
    final server = await RawRequestServer.start();
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postMappedNullable(body: null);

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyText, 'null');
    expect(request.header('content-type'), 'application/x-amz-json-1.1');
  });

  test('sends a selected custom JSON object variant', () async {
    final server = await RawRequestServer.start();
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postMappedChoice(
      body: const JsonChoiceXAmzJson11(
        $RawNullableJsonPayload(name: 'a b', count: 2),
      ),
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyText, '{"name":"a b","count":2}');
    expect(request.header('content-type'), 'application/x-amz-json-1.1');
  });

  test('sends JSON null for an explicitly selected custom variant', () async {
    final server = await RawRequestServer.start();
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postMappedChoice(
      body: const JsonChoiceXAmzJson11(null),
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyText, 'null');
    expect(request.header('content-type'), 'application/x-amz-json-1.1');
  });

  test('omits an unselected optional multi-content body', () async {
    final server = await RawRequestServer.start();
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postMappedChoice();

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyBytes, isEmpty);
  });

  test('preserves standard JSON object encoding', () async {
    final server = await RawRequestServer.start();
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postStandardObject(
      body: const JsonPayload(name: 'a b', count: 2),
    );

    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.bodyText, '{"name":"a b","count":2}');
    expect(request.header('content-type'), 'application/json');
  });

  test('reports non-finite JSON numbers before sending a request', () async {
    final server = await RawRequestServer.start();
    final api = WidgetsApi(CustomServer(baseUrl: server.baseUrl));

    final response = await api.postMappedNumber(body: double.nan);

    expect(requireError(response).type, TonikErrorType.encoding);
    expect(server.requestCount, 0);
  });
}
