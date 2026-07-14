import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:naming_api/src/operation/get_response_with_normalized_body_header.dart';
import 'package:naming_api/src/response/response_body_collision_header_normalized_get200_response.dart';
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
    final operation = GetResponseWithNormalizedBodyHeader(dio);

    final result = await operation.call();

    expect(
      result,
      isA<TonikSuccess<ResponseBodyCollisionHeaderNormalizedGet200Response>>(),
    );
    final value =
        (result
                as TonikSuccess<
                  ResponseBodyCollisionHeaderNormalizedGet200Response
                >)
            .value;
    expect(value.body, 'header-value');
    expect(value.body2.id, 'body-value');
  });
}
