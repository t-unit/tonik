import 'package:query_parameters_api/query_parameters_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/v1';
  });

  QueryApi buildQueryApi({required String responseStatus}) {
    return QueryApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: testServerConfig(
          headers: {'X-Response-Status': responseStatus},
        ),
      ),
    );
  }

  test('ampersand in a parameter name is percent-encoded', () async {
    final api = buildQueryApi(responseStatus: '204');
    final response = await api.testFormSpecialNames(qAmpersandA: 'hello');

    expect(response, isTonikSuccess);
    requireSuccess(response);
    final recordedRequest = await imposterServer.takeRequest();
    expect(recordedRequest.uri.query, 'q%26a=hello');
  });

  test('equals in a parameter name is percent-encoded', () async {
    final api = buildQueryApi(responseStatus: '204');
    final response = await api.testFormSpecialNames(aEqualsB: 'v');

    expect(response, isTonikSuccess);
    requireSuccess(response);
    final recordedRequest = await imposterServer.takeRequest();
    expect(recordedRequest.uri.query, 'a%3Db=v');
  });

  test(
    'special names keep their pair structure when parsed by a server',
    () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testFormSpecialNames(
        qAmpersandA: 'hello',
        aEqualsB: 'v',
      );

      expect(response, isTonikSuccess);
      requireSuccess(response);
      final recordedRequest = await imposterServer.takeRequest();
      expect(recordedRequest.uri.query, 'q%26a=hello&a%3Db=v');
      expect(Uri.splitQueryString(recordedRequest.uri.query), {
        'q&a': 'hello',
        'a=b': 'v',
      });
    },
  );

  test('deepObject model and map names survive query assembly', () async {
    final api = buildQueryApi(responseStatus: '204');
    final response = await api.testStyledSpecialNames(
      qAmpersandA: const PartialFilter(name: 'a/b'),
      aEqualsB: {'k': 'v'},
    );

    expect(response, isTonikSuccess);
    requireSuccess(response);
    final recordedRequest = await imposterServer.takeRequest();
    expect(recordedRequest.uri.query, 'q%26a%5Bname%5D=a/b&a%3Db%5Bk%5D=v');
    expect(recordedRequest.uri.queryParameters, {
      'q&a[name]': 'a/b',
      'a=b[k]': 'v',
    });
  });

  test(
    'delimited map and dynamic array names survive query assembly',
    () async {
      final api = buildQueryApi(responseStatus: '204');
      final response = await api.testStyledSpecialNames(
        pipeAmpersandName: {'k': 'a/b'},
        spaceAmpersandName: ['v', 'w'],
      );

      expect(response, isTonikSuccess);
      requireSuccess(response);
      final recordedRequest = await imposterServer.takeRequest();
      expect(
        recordedRequest.uri.query,
        'pipe%26name=k%7Ca/b&space%26name=v%20w',
      );
      expect(recordedRequest.uri.queryParameters, {
        'pipe&name': 'k|a/b',
        'space&name': 'v w',
      });
    },
  );

  test('typed and composite array names survive query assembly', () async {
    final api = buildQueryApi(responseStatus: '204');
    final response = await api.testStyledSpecialNames(
      arrayAmpersandName: ['a/b', 'c'],
      compositeAmpersandName: [
        const OneOfPrimitiveString('v'),
        const OneOfPrimitiveInt(2),
      ],
    );

    expect(response, isTonikSuccess);
    requireSuccess(response);
    final recordedRequest = await imposterServer.takeRequest();
    expect(
      recordedRequest.uri.query,
      'array%26name=a/b%7Cc&composite%26name=v%7C2',
    );
    expect(recordedRequest.uri.queryParameters, {
      'array&name': 'a/b|c',
      'composite&name': 'v|2',
    });
  });

  test('exploded composite arrays encode every repeated name', () async {
    final api = buildQueryApi(responseStatus: '204');
    final response = await api.testStyledSpecialNames(
      explodedAmpersandName: [
        const OneOfPrimitiveString('a/b'),
        const OneOfPrimitiveString('c'),
      ],
    );

    expect(response, isTonikSuccess);
    requireSuccess(response);
    final recordedRequest = await imposterServer.takeRequest();
    expect(recordedRequest.uri.query, 'exploded%26name=a/b&exploded%26name=c');
    expect(recordedRequest.uri.queryParametersAll, {
      'exploded&name': ['a/b', 'c'],
    });
  });
}
