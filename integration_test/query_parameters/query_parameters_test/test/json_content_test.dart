import 'package:query_parameters_api/query_parameters_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test('sends arbitrary JSON objects as one query parameter', () async {
    final server = await RawRequestServer.start();
    final api = QueryApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.itemsGet(
      filter: const {
        'nested': {'status': 'active'},
        'tags': [1, true, null],
      },
    );

    requireSuccess(response);
    final request = await server.takeRequest();
    expect(request.method, 'GET');
    expect(request.uri.path, '/items');
    expect(
      request.uri.query,
      'filter=%7B%22nested%22%3A%7B%22status%22%3A%22active%22%7D%2C'
      '%22tags%22%3A%5B1%2Ctrue%2Cnull%5D%7D',
    );
    expect(request.uri.queryParametersAll, {
      'filter': ['{"nested":{"status":"active"},"tags":[1,true,null]}'],
    });
  });

  test('omits an optional JSON query parameter when absent', () async {
    final server = await RawRequestServer.start();
    final api = QueryApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.itemsGet();

    requireSuccess(response);
    final request = await server.takeRequest();
    expect(request.uri.hasQuery, isFalse);
    expect(request.uri.queryParametersAll, isEmpty);
  });

  test(
    'escapes reserved and Unicode values in a required typed filter',
    () async {
      final server = await RawRequestServer.start();
      final api = QueryApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.testJsonContentFilter(
        filter: const JsonFilter(status: 'a&b=+%/# ü東京'),
      );

      requireSuccess(response);
      final request = await server.takeRequest();
      expect(
        request.uri.query,
        'filter=%7B%22status%22%3A%22a%26b%3D%2B%25%2F%23%20'
        '%C3%BC%E6%9D%B1%E4%BA%AC%22%7D',
      );
      expect(request.uri.queryParametersAll, {
        'filter': ['{"status":"a&b=+%/# ü東京"}'],
      });
      expect(request.uri.hasFragment, isFalse);
    },
  );

  test('serializes a referenced schema default as JSON', () async {
    final server = await RawRequestServer.start();
    final api = QueryApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testJsonContentDefault();

    requireSuccess(response);
    final request = await server.takeRequest();
    expect(request.uri.query, 'status=%22active%22');
    expect(request.uri.queryParametersAll, {
      'status': ['"active"'],
    });
  });

  test(
    'sends JSON null for required nullable content and omits optional null',
    () async {
      final server = await RawRequestServer.start();
      final api = QueryApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.testJsonContentNullable(filter: null);

      requireSuccess(response);
      final request = await server.takeRequest();
      expect(request.uri.query, 'filter=null');
      expect(request.uri.queryParametersAll, {
        'filter': ['null'],
      });
    },
  );

  test(
    'uses JSON date conversion for required and optional nullable lists',
    () async {
      final server = await RawRequestServer.start();
      final api = QueryApi(
        CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
      );

      final response = await api.testJsonContentNullable(
        filter: [DateTime.utc(2026, 9, 7)],
        other: [DateTime.utc(2026, 9, 8)],
      );

      requireSuccess(response);
      final request = await server.takeRequest();
      expect(
        request.uri.query,
        'filter=%5B%222026-09-07T00%3A00%3A00.000Z%22%5D&'
        'other=%5B%222026-09-08T00%3A00%3A00.000Z%22%5D',
      );
      expect(request.uri.queryParametersAll, {
        'filter': ['["2026-09-07T00:00:00.000Z"]'],
        'other': ['["2026-09-08T00:00:00.000Z"]'],
      });
    },
  );

  test('serializes shared recursive nullable content schemas', () async {
    final server = await RawRequestServer.start();
    final api = QueryApi(
      CustomServer(baseUrl: server.baseUrl, serverConfig: testServerConfig()),
    );

    final response = await api.testJsonContentRecursive(
      filter: const {
        'child': {'leaf': null},
      },
      other: const {'child': null},
    );

    requireSuccess(response);
    final request = await server.takeRequest();
    expect(
      request.uri.query,
      'filter=%7B%22child%22%3A%7B%22leaf%22%3Anull%7D%7D&'
      'other=%7B%22child%22%3Anull%7D',
    );
    expect(request.uri.queryParametersAll, {
      'filter': ['{"child":{"leaf":null}}'],
      'other': ['{"child":null}'],
    });
  });
}
