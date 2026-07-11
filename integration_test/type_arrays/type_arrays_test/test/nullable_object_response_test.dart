import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';
import 'package:type_arrays_api/type_arrays_api.dart';

void main() {
  test('decodes JSON null as a successful nullable object response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _CannedAdapter();

    final result = await GetNullableWidget(dio).call();

    expect(result, isA<TonikSuccess<NullableWidget>>());
    final success = result as TonikSuccess<NullableWidget>;
    expect(success.value, isNull);
  });
}

class _CannedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(
      utf8.encode('null'),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
