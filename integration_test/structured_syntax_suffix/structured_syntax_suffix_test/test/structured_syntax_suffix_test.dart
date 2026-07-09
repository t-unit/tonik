import 'dart:convert';

import 'package:structured_syntax_suffix_api/structured_syntax_suffix_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  late ImposterServer imposterServer;
  late String baseUrl;

  setUpAll(() async {
    imposterServer = await setupImposterServer();
    baseUrl = 'http://localhost:${imposterServer.port}/api/v1';
  });

  WidgetsApi buildApi() {
    return WidgetsApi(CustomServer(baseUrl: baseUrl));
  }

  test(
    'application/vnd.api+json response decodes into the declared model',
    () async {
      final result = await buildApi().getWidget();

      expect(result, isA<TonikSuccess<Widget>>());
      final success = result as TonikSuccess<Widget>;

      expect(success.response.statusCode, 200);
      expect(success.value.id, 42);
      expect(success.value.name, 'sprocket');
    },
  );

  test(
    'application/problem+json response decodes into the declared model',
    () async {
      final result = await buildApi().getProblem();

      expect(result, isA<TonikSuccess<Widget>>());
      final success = result as TonikSuccess<Widget>;

      expect(success.response.statusCode, 200);
      expect(success.value.id, 7);
      expect(success.value.name, 'teapot');
    },
  );

  test(
    'application/* response matches application/json and returns bytes',
    () async {
      final result = await buildApi().getApplicationWildcard();

      expect(result, isA<TonikSuccess<TonikFile>>());
      final success = result as TonikSuccess<TonikFile>;

      expect(success.response.statusCode, 200);
      expect(
        utf8.decode(success.value.toBytes()),
        '{"id":99,"name":"application-wildcard"}',
      );
    },
  );

  test('*/* response matches text/plain and returns bytes', () async {
    final result = await buildApi().getCatchAllWildcard();

    expect(result, isA<TonikSuccess<TonikFile>>());
    final success = result as TonikSuccess<TonikFile>;

    expect(success.response.statusCode, 200);
    expect(utf8.decode(success.value.toBytes()), 'catch-all wildcard response');
  });

  test('status range with application/* matches concrete response', () async {
    final result = await buildApi().getRangeWildcard();

    expect(result, isA<TonikSuccess<TonikFile>>());
    final success = result as TonikSuccess<TonikFile>;

    expect(success.response.statusCode, 203);
    expect(
      utf8.decode(success.value.toBytes()),
      '{"id":203,"name":"range-wildcard"}',
    );
  });
}
