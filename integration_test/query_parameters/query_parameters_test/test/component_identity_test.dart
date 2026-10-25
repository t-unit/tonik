import 'dart:io';

import 'package:query_parameters_api/query_parameters_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';

void main() {
  test(
    'aliases and direct components accept one enum type on the wire',
    () async {
      final requests = <Uri>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        requests.add(request.uri);
        request.response
          ..statusCode = 200
          ..headers.set('X-State', 'ready');
        await request.response.close();
      });
      final api = QueryApi(
        CustomServer(
          baseUrl: 'http://localhost:${server.port}/v1',
          serverConfig: testServerConfig(),
        ),
      );
      const sort = SharedSortModel.asc;

      final alias = await api.testForwardComponentAlias(sort: sort);
      final direct = await api.testDirectComponent(sort: sort);

      expect(alias, isTonikSuccess);
      expect(direct, isTonikSuccess);
      expect(requests.first.queryParameters, {'sort': 'asc'});
      expect(requests.last.queryParameters, {'sort': 'asc'});
      expect(requireSuccess(alias).response.headers.value('X-State'), 'ready');
      expect(requireSuccess(direct).response.headers.value('X-State'), 'ready');
    },
  );
}
