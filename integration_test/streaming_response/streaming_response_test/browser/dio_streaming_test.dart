@TestOn('browser')
library;

import 'dart:async';

import 'package:dio/browser.dart';
import 'package:dio/dio.dart' as dio;
import 'package:streaming_response_api/streaming_response_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'support.dart';

void main() {
  late ResponseControl control;
  late CustomServer server;
  late dio.Dio client;

  setUp(() {
    control = ResponseControl();
    client = dio.Dio();
    server = CustomServer(
      baseUrl: browserTestOrigin,
      serverConfig: browserClientConfig(client),
    );
    expect(client.httpClientAdapter, isA<BrowserHttpClientAdapter>());
  });
  tearDown(() {
    server.close();
    client.close();
    control.close();
  });

  test('Dio XHR returns JSONL only after EOF and decodes all items', () async {
    await control.start(
      contentType: 'application/jsonl',
      initial: '{"value":1}\n',
    );
    final receivedBytes = Completer<void>();
    client.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) {
          options.onReceiveProgress = (received, total) {
            if (received > 0 && !receivedBytes.isCompleted) {
              receivedBytes.complete();
            }
          };
          handler.next(options);
        },
      ),
    );
    final cancellation = TonikCancellation();
    addTearDown(cancellation.cancel);
    var returned = false;
    final pending = StreamingApi(server)
        .getJsonLines(cancellation: cancellation)
        .then((result) {
          returned = true;
          return result;
        });
    await receivedBytes.future.timeout(testDeadline);
    expect(returned, isFalse);
    expect(await control.reachedEof, isFalse);
    await control.write('{"value":2}');
    await control.finish();
    final success = requireSuccess(await pending.timeout(testDeadline));
    expect(success.response, isA<dio.Response<Object?>>());
    final items = await success.value.toList().timeout(testDeadline);
    expect(
      items.first,
      isA<TonikSuccess<JsonlGet200BodyModel, dio.Response<Object?>>>(),
    );
    expect((items.first as TonikSuccess).response, same(success.response));
    expect(items.map((item) => requireSuccess(item).value), [
      const JsonlGet200BodyModel(value: 1),
      const JsonlGet200BodyModel(value: 2),
    ]);
  });

  test('Dio XHR decodes finite SSE after EOF', () async {
    await control.start(
      contentType: 'text/event-stream; charset=utf-8',
      initial: 'data: {"value":1}\r\n\r\n',
    );
    final cancellation = TonikCancellation();
    addTearDown(cancellation.cancel);
    var returned = false;
    final pending = StreamingApi(server)
        .getSseData(cancellation: cancellation)
        .then((result) {
          returned = true;
          return result;
        });
    await control.waitForRequest();
    expect(returned, isFalse);
    await control.write('data: caf\u00e9\ndata: second line\n\n');
    await control.finish();
    final success = requireSuccess(await pending.timeout(testDeadline));
    expect(
      await success.value
          .map((item) => requireSuccess(item).value)
          .toList()
          .timeout(testDeadline),
      [
        const SseData(data: '{"value":1}'),
        const SseData(data: 'caf\u00e9\nsecond line'),
      ],
    );
  });

  test('Dio mixed streaming branch retains wrappers and headers', () async {
    await control.start(contentType: 'application/x-ndjson');
    final pending = StreamingApi(server).getMixed();
    await control.waitForRequest();
    await control.write('{"value":1}\n{"value":2}\n');
    await control.finish();
    final success = requireSuccess(await pending.timeout(testDeadline));
    final status = success.value as GetMixedResponse200;
    final response = status.body as MixedGet200ResponseXNdjson;
    expect(response.xCount, 2);
    expect(
      await response.body
          .map((item) => requireSuccess(item).value)
          .toList()
          .timeout(testDeadline),
      [const StreamItem(value: 1), const StreamItem(value: 2)],
    );
  });

  test('Dio mixed JSON branch retains its complete body', () async {
    await control.start(
      contentType: 'application/json',
      initial: '{"value":9}',
    );
    final pending = StreamingApi(server).getMixed();
    await control.waitForRequest();
    await control.finish();
    final success = requireSuccess(await pending.timeout(testDeadline));
    expect(
      success.value,
      const GetMixedResponse200(
        body: MixedGet200ResponseJson(xCount: 2, body: StreamItem(value: 9)),
      ),
    );
  });

  test(
    'Dio public cancellation aborts a pending endless XHR response',
    () async {
      await control.start(
        contentType: 'application/x-ndjson',
        initial: '{"value":1}\n',
      );
      final receivedBytes = Completer<void>();
      final dispatched = Completer<dio.CancelToken>();
      client.interceptors.add(
        dio.InterceptorsWrapper(
          onRequest: (options, handler) {
            dispatched.complete(options.cancelToken!);
            options.onReceiveProgress = (received, total) {
              if (received > 0 && !receivedBytes.isCompleted) {
                receivedBytes.complete();
              }
            };
            handler.next(options);
          },
        ),
      );
      final cancellation = TonikCancellation();
      addTearDown(cancellation.cancel);
      var returned = false;
      final pending = StreamingApi(server)
          .getItems(cancellation: cancellation)
          .then((result) {
            returned = true;
            return result;
          });
      final token = await dispatched.future.timeout(testDeadline);
      await receivedBytes.future.timeout(testDeadline);
      expect(returned, isFalse);
      cancellation.cancel('endless response');
      expect(
        (await token.whenCancel.timeout(testDeadline)).type,
        dio.DioExceptionType.cancel,
      );
      final result = await pending.timeout(testDeadline);
      expect(result, isA<TonikError<Object?, Object>>());
      final error = result as TonikError<Object?, Object>;
      expect(error.type, TonikErrorType.cancelled);
      expect(error.error, isA<dio.DioException>());
      expect(
        (error.error as dio.DioException).type,
        dio.DioExceptionType.cancel,
      );
      expect(await control.reachedEof, isFalse);
    },
  );
}
