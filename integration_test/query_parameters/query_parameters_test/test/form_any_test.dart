import 'package:query_parameters_api/query_parameters_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('untyped form parameter defaults to exploded list entries', () async {
    final server = await RawRequestServer.start();
    final api = QueryApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testFormAny(p: ['a', 'b']);
    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.uri.query, 'p=a&p=b');
    expect(request.uri.queryParametersAll, {
      'p': ['a', 'b'],
    });
  });

  test('untyped form parameter defaults to exploded map entries', () async {
    final server = await RawRequestServer.start();
    final api = QueryApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testFormAny(p: {'a': 1, 'b': 2});
    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.uri.query, 'a=1&b=2');
    expect(request.uri.queryParameters, {'a': '1', 'b': '2'});
  });

  test('untyped form parameter respects explicit non-explode', () async {
    final server = await RawRequestServer.start();
    final api = QueryApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testFormAny(q: {'a': 1, 'b': 2});
    expect(response, isTonikSuccess);
    final request = await server.takeRequest();
    expect(request.uri.query, 'q=a,1,b,2');
    expect(request.uri.queryParameters, {'q': 'a,1,b,2'});
  });
}
