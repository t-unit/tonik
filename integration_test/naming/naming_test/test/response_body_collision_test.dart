import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:naming_api/src/api_client/default_api2.dart';
import 'package:naming_api/src/response/response_body_collision_header_normalized_get200_response.dart';
import 'package:naming_api/src/server/server.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test('keeps the decoded body and the raw body_ header', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<List<int>>(
              requestOptions: options,
              statusCode: 200,
              headers: Headers.fromMap({
                'content-type': ['application/json'],
                'body_': ['header-value'],
              }),
              data: utf8.encode('{"id":"body-value"}'),
            ),
          );
        },
      ),
    );
    final api = DefaultApi2(
      CustomServer(
        baseUrl: 'http://localhost',
        serverConfig: ServerConfig<Dio>.client(dio),
      ),
    );

    final result = await api.getResponseWithNormalizedBodyHeader();

    expect(
      result,
      isA<
        TonikSuccess<
          ResponseBodyCollisionHeaderNormalizedGet200Response,
          Response<Object?>
        >
      >(),
    );
    final value =
        (result
                as TonikSuccess<
                  ResponseBodyCollisionHeaderNormalizedGet200Response,
                  Response<Object?>
                >)
            .value;
    expect(value.body, 'header-value');
    expect(value.body2.id, 'body-value');
  });
}
