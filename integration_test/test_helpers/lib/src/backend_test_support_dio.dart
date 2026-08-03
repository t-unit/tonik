import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tonik_util/tonik_util.dart';

import 'test_result.dart';

ServerConfig<Dio> dioTestServerConfig({
  required Map<String, String> headers,
  required TestRequestRecorder? recorder,
  required TestResponseStub? response,
}) =>
    ServerConfig.clientFactory(() {
      final dio = Dio(BaseOptions(headers: headers));
      if (recorder != null || response != null) {
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              recorder?.record(_requestOptions(options));
              if (response == null) {
                handler.next(options);
                return;
              }
              handler.resolve(
                Response<List<int>>(
                  requestOptions: options,
                  statusCode: response.statusCode,
                  headers: Headers.fromMap(response.headers),
                  data: response.bodyBytes,
                ),
              );
            },
          ),
        );
      }
      return dio;
    });

TestResponse dioTestResponse(Response<Object?> response) => TestResponse(
      statusCode: response.statusCode,
      headers: TestHeaders(response.headers.map),
      data: response.data,
      requestOptions: _requestOptions(response.requestOptions),
    );

TestRequestOptions _requestOptions(RequestOptions options) =>
    TestRequestOptions(
      uri: options.uri,
      path: options.path,
      method: options.method,
      headers: TestRequestHeaders(options.headers),
      data: _requestData(options.data),
      contentType: options.contentType,
      cancelToken: options.cancelToken,
      bodyBytes: _requestBodyBytes(options.data),
    );

List<int>? _requestBodyBytes(Object? data) => switch (data) {
      null => null,
      List<int>() => List.unmodifiable(data),
      String() => List.unmodifiable(utf8.encode(data)),
      FormData() => null,
      _ => List.unmodifiable(utf8.encode(jsonEncode(data))),
    };

Object? _requestData(Object? data) {
  if (data is! FormData) return data;
  return TestFormData(
    fields: List.unmodifiable(data.fields),
    files: List.unmodifiable(
      data.files.map(
        (entry) => MapEntry(
          entry.key,
          TestMultipartFile(
            filename: entry.value.filename,
            contentType: entry.value.contentType,
            length: entry.value.length,
            headers: TestHeaders(entry.value.headers ?? const {}),
            finalize: () => entry.value.clone().finalize(),
          ),
        ),
      ),
    ),
  );
}
