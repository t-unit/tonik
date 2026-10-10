@TestOn('browser')
library;

import 'dart:async';

import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:streaming_response_api/streaming_response_api.dart';
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

import 'support.dart';

void main() {
  late ResponseControl control;
  late CustomServer server;
  late BrowserClient client;

  setUp(() {
    control = ResponseControl();
    client = BrowserClient();
    server = CustomServer(
      baseUrl: browserTestOrigin,
      serverConfig: browserClientConfig(client),
    );
  });
  tearDown(() {
    server.close();
    client.close();
    control.close();
  });

  test(
    'HTTP returns before the first JSONL item and emits before EOF',
    () async {
      await control.start(contentType: 'application/jsonl');
      final cancellation = TonikCancellation();
      addTearDown(cancellation.cancel);
      final pending = StreamingApi(server)
          .getJsonLines(cancellation: cancellation);
      await control.waitForRequest();
      final success = requireSuccess(await pending.timeout(testDeadline));
      expect(success.response, isA<http.StreamedResponse>());
      expect(await control.reachedEof, isFalse);
      final first = Completer<JsonlGet200BodyModel>();
      final done = Completer<void>();
      final values = <JsonlGet200BodyModel>[];
      final subscription = success.value.listen((itemResult) {
        expect(
          itemResult,
          isA<TonikSuccess<JsonlGet200BodyModel, http.BaseResponse>>(),
        );
        expect((itemResult as TonikSuccess).response, same(success.response));
        final item = requireSuccess(itemResult).value;
        values.add(item);
        if (!first.isCompleted) first.complete(item);
      }, onDone: done.complete);
      addTearDown(subscription.cancel);
      expect(first.isCompleted, isFalse);
      await control.write('{"value":1}\n');
      expect(
        await first.future.timeout(testDeadline),
        const JsonlGet200BodyModel(value: 1),
      );
      expect(done.isCompleted, isFalse);
      expect(await control.reachedEof, isFalse);
      await control.write('{"value":2}');
      await control.finish();
      await done.future.timeout(testDeadline);
      expect(values, [
        const JsonlGet200BodyModel(value: 1),
        const JsonlGet200BodyModel(value: 2),
      ]);
    },
  );

  test('HTTP SSE emits string data before EOF', () async {
    await control.start(
      contentType: 'text/event-stream; charset=utf-8',
      initial: ': connected\r\n\r\n',
    );
    final cancellation = TonikCancellation();
    addTearDown(cancellation.cancel);
    final success = requireSuccess(
      await StreamingApi(server)
          .getSseData(cancellation: cancellation)
          .timeout(testDeadline),
    );
    final first = Completer<SseData>();
    final done = Completer<void>();
    final values = <SseData>[];
    final subscription = success.value.listen((itemResult) {
      final item = requireSuccess(itemResult).value;
      values.add(item);
      if (!first.isCompleted) first.complete(item);
    }, onDone: done.complete);
    addTearDown(subscription.cancel);
    await control.write('data: {"value":1}\r\n\r\n');
    expect(
      await first.future.timeout(testDeadline),
      const SseData(data: '{"value":1}'),
    );
    expect(done.isCompleted, isFalse);
    expect(await control.reachedEof, isFalse);
    await control.write('data: caf\u00e9\ndata: second line\n\n');
    await control.finish();
    await done.future.timeout(testDeadline);
    expect(values, [
      const SseData(data: '{"value":1}'),
      const SseData(data: 'caf\u00e9\nsecond line'),
    ]);
  });

  test(
    'HTTP mixed streaming branch pauses and resumes item delivery',
    () async {
      await control.start(contentType: 'application/x-ndjson');
      final cancellation = TonikCancellation();
      addTearDown(cancellation.cancel);
      final success = requireSuccess(
        await StreamingApi(server)
            .getMixed(cancellation: cancellation)
            .timeout(testDeadline),
      );
      final status = success.value as GetMixedResponse200;
      final response = status.body as MixedGet200ResponseXNdjson;
      expect(response.xCount, 2);
      expect(success.response, isA<http.StreamedResponse>());
      final first = Completer<void>();
      final second = Completer<void>();
      final done = Completer<void>();
      final values = <StreamItem>[];
      final subscription = response.body.listen((itemResult) {
        final item = requireSuccess(itemResult).value;
        values.add(item);
        if (!first.isCompleted) {
          first.complete();
        } else {
          second.complete();
        }
      }, onDone: done.complete);
      addTearDown(subscription.cancel);
      await control.write('{"value":1}\n');
      await first.future.timeout(testDeadline);
      subscription.pause();
      await control.write('{"value":2}\n');
      expect(subscription.isPaused, isTrue);
      expect(values, [const StreamItem(value: 1)]);
      expect(second.isCompleted, isFalse);
      expect(await control.reachedEof, isFalse);
      subscription.resume();
      await second.future.timeout(testDeadline);
      expect(values, [const StreamItem(value: 1), const StreamItem(value: 2)]);
      expect(done.isCompleted, isFalse);
      await control.finish();
      await done.future.timeout(testDeadline);
    },
  );

  test(
    'HTTP mixed JSON branch waits for EOF and retains complete metadata',
    () async {
      await control.start(
        contentType: 'application/json',
        initial: '{"value":9}',
      );
      var returned = false;
      final pending = StreamingApi(server).getMixed().then((result) {
        returned = true;
        return result;
      });
      await control.waitForRequest();
      expect(returned, isFalse);
      await control.finish();
      final success = requireSuccess(await pending.timeout(testDeadline));
      expect(
        success.value,
        const GetMixedResponse200(
          body: MixedGet200ResponseJson(xCount: 2, body: StreamItem(value: 9)),
        ),
      );
      expect(success.response, isA<http.Response>());
    },
  );

  test('HTTP public cancellation aborts a response before listening', () async {
    await control.start(contentType: 'application/x-ndjson');
    final cancellation = TonikCancellation();
    addTearDown(cancellation.cancel);
    final success = requireSuccess(
      await StreamingApi(server)
          .getItems(cancellation: cancellation)
          .timeout(testDeadline),
    );
    final native = success.response as http.StreamedResponse;
    final request = native.request! as http.AbortableRequest;
    cancellation.cancel('abandoned');
    await request.abortTrigger!.timeout(testDeadline);
    await expectLater(
      success.value,
      emitsInOrder([
        isA<TonikError<ItemsGet200BodyModel, http.BaseResponse>>()
            .having(
              (error) => error.error,
              'cause',
              isA<http.RequestAbortedException>(),
            )
            .having((error) => error.type, 'type', TonikErrorType.cancelled)
            .having((error) => error.response, 'response', same(native)),
        emitsDone,
      ]),
    ).timeout(testDeadline);
    expect(await control.reachedEof, isFalse);
  });
}
