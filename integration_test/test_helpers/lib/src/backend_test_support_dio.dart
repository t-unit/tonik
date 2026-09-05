import 'package:dio/dio.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_result.dart';

ServerConfig<Dio> dioTestServerConfig({required Map<String, String> headers}) =>
    ServerConfig.clientFactory(() => Dio(BaseOptions(headers: headers)));

TestResponse dioTestResponse(Response<Object?> response) => TestResponse(
  statusCode: response.statusCode,
  headers: TestHeaders(response.headers.map),
  data: response.data,
);
