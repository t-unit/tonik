import 'dart:io';

import 'package:dio/dio.dart';
import 'package:immutable_collections_api/immutable_collections_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

// The /thing operation declares a 2XX range response before the explicit 200
// response. Imposter cannot serve range status codes, so this suite drives the
// generated client against an inline HTTP server that returns a ThingOk-shaped
// body for 200 and a ThingGeneric-shaped body for other 2XX codes. A 200 must
// be routed to the explicit branch, never the range branch.
void main() {
  late HttpServer server;
  late String baseUrl;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://localhost:${server.port}';
    server.listen((request) async {
      final statusCode =
          int.tryParse(request.headers.value('x-response-status') ?? '200') ??
          200;
      final body = statusCode == 200
          ? '{"value": "from explicit"}'
          : '{"message": "from range"}';
      request.response
        ..statusCode = statusCode
        ..headers.contentType = ContentType.json
        ..write(body);
      await request.response.close();
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  ItemsApi buildApi({required String responseStatus}) {
    return ItemsApi(
      CustomServer(
        baseUrl: baseUrl,
        serverConfig: ServerConfig(
          baseOptions: BaseOptions(
            headers: {'X-Response-Status': responseStatus},
          ),
        ),
      ),
    );
  }

  test('HTTP 200 routes to the explicit 200 branch, not the earlier 2XX '
      'range branch', () async {
    final api = buildApi(responseStatus: '200');
    final result = await api.getThing();

    expect(result, isA<TonikSuccess<GetThingResponse>>());
    final success = result as TonikSuccess<GetThingResponse>;
    expect(success.response.statusCode, 200);

    expect(success.value, isA<GetThingResponse200>());
    final body = (success.value as GetThingResponse200).body;
    expect(body, isA<ThingOk>());
    expect(body.value, 'from explicit');
  });

  test('a non-200 code in the 2XX range routes to the range branch', () async {
    final api = buildApi(responseStatus: '299');
    final result = await api.getThing();

    expect(result, isA<TonikSuccess<GetThingResponse>>());
    final success = result as TonikSuccess<GetThingResponse>;
    expect(success.response.statusCode, 299);

    expect(success.value, isA<GetThingResponse2XX>());
    final body = (success.value as GetThingResponse2XX).body;
    expect(body, isA<ThingGeneric>());
    expect(body.message, 'from range');
  });
}
