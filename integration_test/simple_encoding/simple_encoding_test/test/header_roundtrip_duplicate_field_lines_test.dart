import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:simple_encoding_api/simple_encoding_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  group('Header Roundtrip Duplicate Field Lines', () {
    test(
      'list header sent as two field lines decodes to the combined list',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.com/v1'))
          ..httpClientAdapter = _DuplicateFieldLineAdapter();

        final response = await TestHeaderRoundtripSimpleLists(dio).call();

        expect(
          response,
          isA<TonikSuccess<HeadersRoundtripListsSimpleGet200Response>>(),
        );
        final success =
            response as TonikSuccess<HeadersRoundtripListsSimpleGet200Response>;
        expect(success.response.statusCode, 200);
        expect(success.response.headers['x-string-list'], ['a', 'b']);
        expect(success.value.xStringList, ['a', 'b']);
      },
    );
  });
}

class _DuplicateFieldLineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '',
      200,
      headers: {
        'x-string-list': ['a', 'b'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
