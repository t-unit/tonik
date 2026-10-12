import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:streaming_response_api/streaming_response_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

import '../support/controlled_response.dart';

void main() {
  test(
    'returns before an item, preserves metadata and emits before EOF',
    () async {
      final control = await ControlledResponse.bind(
        contentType: 'application/x-ndjson; charset=utf-8',
        headers: {'x-stream': 'native'},
      );
      addTearDown(control.close);
      final server = CustomServer(
        baseUrl: control.baseUrl,
        serverConfig: testServerConfig(headers: {'X-Configured': 'kept'}),
      );
      addTearDown(server.close);
      final resultFuture = StreamingApi(server)
          .getItems(cursor: 7, request: 'user');
      final request = await control.waitForRequest();
      final result = await resultFuture.timeout(const Duration(seconds: 5));
      final success = requireSuccess(result);
      // The explicit type verifies the generated public method at compile time.
      final Stream<TonikResult<ItemsGet200BodyModel, Object>> items =
          success.value;
      expect(request.uri.path, '/items');
      expect(request.uri.queryParameters, {'cursor': '7'});
      expect(request.headers.value('x-request'), 'user');
      expect(request.headers.value('x-configured'), 'kept');
      expect(success.response.statusCode, 200);
      expect(success.response.headers.value('x-stream'), 'native');
      final native = (result as TonikSuccess).response;
      if (native is http.BaseResponse) {
        expect(native, isA<http.StreamedResponse>());
        expect(
          result,
          isA<
            TonikResult<
              Stream<TonikResult<ItemsGet200BodyModel, http.BaseResponse>>,
              http.BaseResponse
            >
          >(),
        );
      } else {
        expect(native, isA<dio.Response<Object?>>());
      }
      final first = Completer<ItemsGet200BodyModel>();
      final done = Completer<void>();
      final values = <int>[];
      final subscription = items.listen((itemResult) {
        final item = requireSuccess(itemResult).value;
        expect((itemResult as TonikSuccess).response, same(native));
        if (native is http.BaseResponse) {
          expect(
            itemResult,
            isA<TonikSuccess<ItemsGet200BodyModel, http.BaseResponse>>(),
          );
        } else {
          expect(
            itemResult,
            isA<TonikSuccess<ItemsGet200BodyModel, dio.Response<Object?>>>(),
          );
        }
        values.add(item.value);
        if (!first.isCompleted) first.complete(item);
      }, onDone: done.complete);
      addTearDown(subscription.cancel);
      await control.write('{"value":1}\n');
      expect((await first.future.timeout(const Duration(seconds: 5))).value, 1);
      expect(done.isCompleted, isFalse);
      await control.write('{"value":2}\n');
      await control.finish();
      await done.future.timeout(const Duration(seconds: 5));
      expect(values, [1, 2]);
    },
  );

  test(
    'SSE returns before data and preserves string data before EOF',
    () async {
      final control = await ControlledResponse.bind(
        contentType: 'text/event-stream; charset=utf-8',
        initial: ': connected\r\n\r\n',
      );
      addTearDown(control.close);
      final server = CustomServer(baseUrl: control.baseUrl);
      addTearDown(server.close);
      final resultFuture = StreamingApi(server).getSseData();
      await control.waitForRequest();
      final result = await resultFuture.timeout(const Duration(seconds: 5));
      final success = requireSuccess(result);
      // The explicit type verifies the generated public method at compile time.
      final Stream<TonikResult<SseData, Object>> items = success.value;
      final first = Completer<SseData>();
      final done = Completer<void>();
      final values = <SseData>[];
      final subscription = items.listen((itemResult) {
        final item = requireSuccess(itemResult).value;
        values.add(item);
        if (!first.isCompleted) first.complete(item);
      }, onDone: done.complete);
      addTearDown(subscription.cancel);
      await control.write('data: {"value":1}\r\n\r\n');
      expect(
        await first.future.timeout(const Duration(seconds: 5)),
        const SseData(data: '{"value":1}'),
      );
      expect(done.isCompleted, isFalse);
      await control.write('data: plain text\n\n');
      await control.finish();
      await done.future.timeout(const Duration(seconds: 5));
      expect(values, [
        const SseData(data: '{"value":1}'),
        const SseData(data: 'plain text'),
      ]);
    },
  );

  test(
    'mixed complete JSON waits for EOF and exposes completed metadata',
    () async {
      final control = await ControlledResponse.bind(
        contentType: 'application/json',
        initial: '{"value":9}',
        headers: {'x-count': '1'},
      );
      addTearDown(control.close);
      final server = CustomServer(baseUrl: control.baseUrl);
      addTearDown(server.close);
      final completed = Completer<void>();
      final resultFuture = StreamingApi(server).getMixed().then((result) {
        completed.complete();
        return result;
      });
      await control.waitForRequest();
      expect(completed.isCompleted, isFalse);
      await control.finish();
      final result = await resultFuture;
      final status = requireSuccess(result).value as GetMixedResponse200;
      final response = status.body as MixedGet200ResponseJson;
      expect(response.xCount, 1);
      expect(response.body, const StreamItem(value: 9));
      expect(response.copyWith(xCount: 2).xCount, 2);
      final native = (result as TonikSuccess).response;
      if (native is http.BaseResponse) {
        expect(native, isA<http.Response>());
        expect((native as http.Response).body, '{"value":9}');
        expect(result, isA<TonikResult<GetMixedResponse, http.BaseResponse>>());
      } else {
        expect(
          (native as dio.Response<Object?>).data,
          utf8.encode('{"value":9}'),
        );
      }
    },
  );

  test('public cancellation stops an unfinished response', () async {
    final control = await ControlledResponse.bind(
      contentType: 'application/x-ndjson',
    );
    addTearDown(control.close);
    final server = CustomServer(baseUrl: control.baseUrl);
    addTearDown(server.close);
    final cancellation = TonikCancellation();
    final result = await StreamingApi(server)
        .getItems(cancellation: cancellation)
        .timeout(const Duration(seconds: 5));
    final items = requireSuccess(result).value.toList();
    cancellation.cancel('unfinished response');
    final failure =
        (await items.timeout(const Duration(seconds: 5))).single
            as TonikError<ItemsGet200BodyModel, Object>;
    expect(failure.type, TonikErrorType.cancelled);
    expect(failure.response, same((result as TonikSuccess).response));
    expect(control.reachedEof, isFalse);
  });
}
