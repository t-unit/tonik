import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:streaming_response_api/streaming_response_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  test(
    'returns before an item, preserves metadata and emits before EOF',
    () async {
      final host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => host.close(force: true));
      final requestReceived = Completer<HttpRequest>();
      host.listen((request) async {
        request.response.bufferOutput = false;
        request.response.headers
          ..set('content-type', 'application/x-ndjson; charset=utf-8')
          ..set('x-stream', 'native');
        request.response.add([10]);
        await request.response.flush();
        requestReceived.complete(request);
      });
      final server = CustomServer(
        baseUrl: 'http://localhost:${host.port}',
        serverConfig: testServerConfig(headers: {'X-Configured': 'kept'}),
      );
      addTearDown(server.close);
      final resultFuture = StreamingApi(server)
          .getItems(cursor: 7, request: 'user');
      final request = await requestReceived.future.timeout(
        const Duration(seconds: 5),
      );
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
      request.response.write('{"value":1}\n');
      await request.response.flush();
      expect((await first.future.timeout(const Duration(seconds: 5))).value, 1);
      expect(done.isCompleted, isFalse);
      request.response.write('{"value":2}\n');
      await request.response.close();
      await done.future.timeout(const Duration(seconds: 5));
      expect(values, [1, 2]);
    },
  );

  test(
    'SSE returns before data and preserves string data before EOF',
    () async {
      final host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => host.close(force: true));
      final requestReceived = Completer<HttpRequest>();
      host.listen((request) async {
        request.response.bufferOutput = false;
        request.response.headers.set(
          'content-type',
          'text/event-stream; charset=utf-8',
        );
        request.response.write(': connected\r\n\r\n');
        await request.response.flush();
        requestReceived.complete(request);
      });
      final server = CustomServer(baseUrl: 'http://localhost:${host.port}');
      addTearDown(server.close);
      final resultFuture = StreamingApi(server).getSseData();
      final request = await requestReceived.future.timeout(
        const Duration(seconds: 5),
      );
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
      request.response.write('data: {"value":1}\r\n\r\n');
      await request.response.flush();
      expect(
        await first.future.timeout(const Duration(seconds: 5)),
        const SseData(data: '{"value":1}'),
      );
      expect(done.isCompleted, isFalse);
      request.response.write('data: plain text\n\n');
      await request.response.close();
      await done.future.timeout(const Duration(seconds: 5));
      expect(values, [
        const SseData(data: '{"value":1}'),
        const SseData(data: 'plain text'),
      ]);
    },
  );

  test(
    'SSE optional fields reach item conversion without inherited values',
    () async {
      final probe = BackendProbe(contentType: 'text/event-stream');
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getSseFields();
      final values = requireSuccess(result).value
          .map((item) => requireSuccess(item).value)
          .toList();
      probe.bytes.add(
        utf8.encode(
          'event: update\nid: 7\nretry: 0010\ndata: one\ndata: two\n\n'
          'event:\nid:\ndata\n\ndata: last\n\n',
        ),
      );
      await probe.bytes.close();
      expect(await values, [
        const SseFields(data: 'one\ntwo', event: 'update', id: '7', retry: 10),
        const SseFields(data: '', event: '', id: ''),
        const SseFields(data: 'last'),
      ]);
    },
  );

  test(
    'SSE item conversion failure terminates and forwards public abort',
    () async {
      final probe = BackendProbe(contentType: 'text/event-stream');
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getSseRequiredEvent();
      final events = <Object>[];
      final done = Completer<void>();
      requireSuccess(result).value.listen(events.add, onDone: done.complete);
      probe.bytes.add(
        utf8.encode(
          'event: ready\ndata: first\n\ndata: missing event\n\n'
          'event: later\ndata: third\n\n',
        ),
      );
      await done.future.timeout(const Duration(seconds: 5));
      await probe.aborted.future.timeout(const Duration(seconds: 5));
      expect(events, hasLength(2));
      expect(
        requireSuccess(events.first as TonikResult<SseRequiredEvent, Object>)
            .value,
        const SseRequiredEvent(data: 'first', event: 'ready'),
      );
      final failure = events.last as TonikError<SseRequiredEvent, Object>;
      expect(failure.error, isA<InvalidTypeException>());
      expect(failure.type, TonikErrorType.decoding);
      expect(probe.clientClosed, isFalse);
    },
  );

  test('finite JSONL permits raw CR whitespace', () async {
    final probe = BackendProbe(contentType: 'application/jsonl');
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getJsonLines();
    final items = requireSuccess(result).value
        .map((item) => requireSuccess(item).value)
        .toList();
    probe.bytes.add(utf8.encode('{"value":3}\r \n{"value":4}'));
    await probe.bytes.close();
    expect(await items, [
      const JsonlGet200BodyModel(value: 3),
      const JsonlGet200BodyModel(value: 4),
    ]);
  });

  test('ordinary JSON retains its completed response', () async {
    final probe = BackendProbe(contentType: 'application/json');
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final resultFuture = StreamingApi(server).getOrdinary();
    probe.bytes.add(utf8.encode('{"value":9}'));
    unawaited(probe.bytes.close());
    final result = await resultFuture;
    expect(
      requireSuccess(result).value,
      const OrdinaryGet200BodyModel(value: 9),
    );
    final native = (result as TonikSuccess).response;
    if (native is http.BaseResponse) {
      expect(native, isA<http.Response>());
      expect(
        result,
        isA<TonikResult<OrdinaryGet200BodyModel, http.Response>>(),
      );
    } else {
      expect(native, isA<dio.Response<Object?>>());
    }
  });

  test(
    'cancellation before listening yields one cancelled item result',
    () async {
      final probe = BackendProbe(failOnAbort: true);
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final cancellation = TonikCancellation();
      final result = await StreamingApi(server)
          .getItems(cancellation: cancellation);
      expect(
        requireSuccess(result).value,
        isA<Stream<TonikResult<ItemsGet200BodyModel, Object>>>(),
      );
      cancellation.cancel('abandoned');
      await probe.aborted.future.timeout(const Duration(seconds: 5));
      final items = await requireSuccess(result).value
          .toList()
          .timeout(const Duration(seconds: 5));
      final failure = items.single as TonikError<ItemsGet200BodyModel, Object>;
      expect(failure.type, TonikErrorType.cancelled);
      expect(failure.response, same((result as TonikSuccess).response));
      expect(probe.clientClosed, isFalse);
    },
  );

  test(
    'public cancellation while listening yields a terminal item result',
    () async {
      final probe = BackendProbe(failOnAbort: true);
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final cancellation = TonikCancellation();
      final result = await StreamingApi(server)
          .getItems(cancellation: cancellation);
      final items = requireSuccess(result).value.toList();
      cancellation.cancel('stop listening');
      final failure =
          (await items.timeout(const Duration(seconds: 5))).single
              as TonikError<ItemsGet200BodyModel, Object>;
      expect(failure.type, TonikErrorType.cancelled);
      expect(failure.response, same((result as TonikSuccess).response));
      await probe.aborted.future.timeout(const Duration(seconds: 5));
      expect(probe.clientClosed, isFalse);
    },
  );

  test(
    'selection failure returns an operation error and forwards abort',
    () async {
      final probe = BackendProbe(contentType: 'text/plain');
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getItems();
      final error = requireError(result);
      expect(error.type, TonikErrorType.decoding);
      expect(error.error, isA<ResponseDecodingException>());
      expect(error.response!.statusCode, 200);
      await probe.aborted.future.timeout(const Duration(seconds: 5));
      expect(probe.clientClosed, isFalse);
    },
  );

  test('subscription cancellation forwards public request abort', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getItems();
    final subscription = requireSuccess(result).value.listen((_) {});
    await subscription.cancel();
    await probe.aborted.future.timeout(const Duration(seconds: 5));
    expect(probe.clientClosed, isFalse);
  });

  test('malformed record terminates and forwards public abort', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getItems();
    final events = <Object>[];
    final done = Completer<void>();
    requireSuccess(result).value.listen(events.add, onDone: done.complete);
    probe.bytes.add(utf8.encode('invalid\n{"value":2}\n'));
    await done.future.timeout(const Duration(seconds: 5));
    await probe.aborted.future.timeout(const Duration(seconds: 5));
    expect(events, hasLength(1));
    final failure = events.single as TonikError<Object?, Object>;
    expect(failure.error, isA<FormatException>());
    expect(failure.type, TonikErrorType.decoding);
  });

  test(
    'model conversion failure terminates and forwards public abort',
    () async {
      final probe = BackendProbe();
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getItems();
      final events = <Object>[];
      final done = Completer<void>();
      requireSuccess(result).value.listen(events.add, onDone: done.complete);
      probe.bytes.add(utf8.encode('{"value":"bad"}\n{"value":2}\n'));
      await done.future.timeout(const Duration(seconds: 5));
      await probe.aborted.future.timeout(const Duration(seconds: 5));
      expect(events, hasLength(1));
      final failure = events.single as TonikError<ItemsGet200BodyModel, Object>;
      expect(failure.error, isA<InvalidTypeException>());
      expect(failure.type, TonikErrorType.decoding);
    },
  );

  test(
    'source failure reaches item stream and forwards public abort',
    () async {
      final probe = BackendProbe();
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getItems();
      final events = <Object>[];
      final done = Completer<void>();
      requireSuccess(result).value.listen(events.add, onDone: done.complete);
      const error = FormatException('source failed');
      final stack = StackTrace.current;
      probe.bytes.addError(error, stack);
      probe.bytes.add(utf8.encode('{"value":2}\n'));
      await done.future.timeout(const Duration(seconds: 5));
      await probe.aborted.future.timeout(const Duration(seconds: 5));
      expect(events, hasLength(1));
      final failure = events.single as TonikError<ItemsGet200BodyModel, Object>;
      expect(failure.error, same(error));
      expect(failure.stackTrace, same(stack));
      expect(failure.type, TonikErrorType.network);
      final native = (result as TonikSuccess).response;
      expect(failure.response, same(native));
      if (native is http.BaseResponse) {
        expect(
          failure,
          isA<TonikError<ItemsGet200BodyModel, http.BaseResponse>>(),
        );
      } else {
        expect(
          failure,
          isA<TonikError<ItemsGet200BodyModel, dio.Response<Object?>>>(),
        );
      }
    },
  );

  test(
    'mixed stream preserves headers, variants, copyWith and metadata',
    () async {
      final probe = BackendProbe(headers: {'x-count': '2'});
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getMixed();
      final status = requireSuccess(result).value as GetMixedResponse200;
      final response = status.body as MixedGet200ResponseXNdjson;
      expect(response.xCount, 2);
      final replacement = response.body.map((item) => item);
      final copied = response.copyWith(xCount: 3, body: replacement);
      expect(copied.xCount, 3);
      expect(copied.body, same(replacement));
      expect(response.copyWith().body, same(response.body));
      final native = (result as TonikSuccess).response;
      if (native is http.BaseResponse) {
        expect(result, isA<TonikResult<GetMixedResponse, http.BaseResponse>>());
        expect(native, isA<http.StreamedResponse>());
        expect(native.headers['x-count'], '2');
      } else {
        expect(
          result,
          isA<TonikResult<GetMixedResponse, dio.Response<Object?>>>(),
        );
        expect(native, isA<dio.Response<Object?>>());
      }
      final items = response.body
          .map((item) => requireSuccess(item).value)
          .toList();
      probe.bytes.add(utf8.encode('{"value":1}\n{"value":2}\n'));
      await probe.bytes.close();
      expect(await items, [
        const StreamItem(value: 1),
        const StreamItem(value: 2),
      ]);
    },
  );

  test(
    'mixed complete JSON waits for EOF and exposes completed metadata',
    () async {
      final probe = BackendProbe(
        contentType: 'application/json',
        headers: {'x-count': '1'},
      );
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final completed = Completer<void>();
      final resultFuture = StreamingApi(server).getMixed().then((result) {
        completed.complete();
        return result;
      });
      await probe.listening.future.timeout(const Duration(seconds: 5));
      probe.bytes.add(utf8.encode('{"value":9}'));
      expect(completed.isCompleted, isFalse);
      await probe.bytes.close();
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

  test(
    'component response aliases retain the stream and modeled header',
    () async {
      final probe = BackendProbe(headers: {'x-count': '1'});
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getAliasedStream();
      // The explicit type checks the exported response alias at compile time.
      // ignore: omit_local_variable_types
      final AliasedStream response = requireSuccess(result).value;
      expect(response, isA<StreamWithHeaders>());
      expect(response.xCount, 1);
      final replacement = response.body.map((item) => item);
      final copied = response.copyWith(body: replacement);
      expect(copied, AliasedStream(xCount: 1, body: replacement));
      expect(
        copied.hashCode,
        AliasedStream(xCount: 1, body: replacement).hashCode,
      );
      final items = response.body
          .map((item) => requireSuccess(item).value)
          .toList();
      probe.bytes.add(utf8.encode('{"value":6}\n'));
      await probe.bytes.close();
      expect(await items, [const StreamItem(value: 6)]);
    },
  );

  test(
    'parameter-specific item stream overrides multipart content mapping',
    () async {
      final probe = BackendProbe(
        contentType: 'application/x-ndjson; charset=utf-8; profile="detail"',
      );
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getProfiles();
      final response =
          requireSuccess(result).value
              as ProfilesGet200ResponseXNdjsonProfileDetail;
      final items = response.body
          .map((item) => requireSuccess(item).value)
          .toList();
      probe.bytes.add(utf8.encode('{"value":4}\n'));
      await probe.bytes.close();
      expect(await items, [const StreamItem(value: 4)]);
    },
  );

  test(
    'unmatched media parameters select the generic complete variant',
    () async {
      final probe = BackendProbe(
        contentType: 'application/x-ndjson; profile=other',
      );
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final resultFuture = StreamingApi(server).getProfiles();
      probe.bytes.add([49, 10]);
      unawaited(probe.bytes.close());
      final result = await resultFuture;
      final response =
          requireSuccess(result).value as ProfilesGet200ResponseXNdjson;
      expect((response.body as TonikFileBytes).bytes, [49, 10]);
      final native = (result as TonikSuccess).response;
      if (native is http.BaseResponse) expect(native, isA<http.Response>());
    },
  );

  test(
    'explicit empty status wins over range and forwards public abort',
    () async {
      final probe = BackendProbe(statusCode: 204);
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getMixed();
      expect(requireSuccess(result).value, const GetMixedResponse204());
      expect(requireSuccess(result).response.statusCode, 204);
      await probe.aborted.future.timeout(const Duration(seconds: 5));
      expect(probe.clientClosed, isFalse);
    },
  );

  test(
    'bad modeled header fails before return and forwards public abort',
    () async {
      final probe = BackendProbe(headers: {'x-count': 'invalid'});
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getAliasedStream();
      final error = requireError(result);
      expect(error.type, TonikErrorType.decoding);
      expect(error.error, isA<InvalidTypeException>());
      expect(error.response!.headers.value('x-count'), 'invalid');
      await probe.aborted.future.timeout(const Duration(seconds: 5));
      expect(probe.clientClosed, isFalse);
    },
  );

  test(
    'ordinary modeled HTTP error keeps its explicit status variant',
    () async {
      final probe = BackendProbe(
        contentType: 'application/json',
        statusCode: 400,
      );
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final resultFuture = StreamingApi(server).getMixed();
      probe.bytes.add(utf8.encode('"invalid request"'));
      unawaited(probe.bytes.close());
      final result = await resultFuture;
      expect(
        requireSuccess(result).value,
        const GetMixedResponse400(body: 'invalid request'),
      );
      expect(requireSuccess(result).response.statusCode, 400);
      final native = (result as TonikSuccess).response;
      if (native is http.BaseResponse) expect(native, isA<http.Response>());
    },
  );

  test('range status returns its own typed stream variant', () async {
    final probe = BackendProbe(statusCode: 202);
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getMixed();
    final response = requireSuccess(result).value as GetMixedResponse2XX;
    final items = response.body
        .map((item) => requireSuccess(item).value)
        .toList();
    probe.bytes.add(utf8.encode('{"value":2}\n'));
    await probe.bytes.close();
    expect(await items, [const StreamItem(value: 2)]);
  });

  test('unmatched status selects the complete default variant', () async {
    final probe = BackendProbe(
      contentType: 'application/json',
      statusCode: 418,
    );
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final resultFuture = StreamingApi(server).getMixed();
    probe.bytes.add(utf8.encode('"teapot"'));
    unawaited(probe.bytes.close());
    final result = await resultFuture;
    expect(
      requireSuccess(result).value,
      const GetMixedResponseDefault(body: 'teapot'),
    );
  });

  test(
    'buffering a complete alternative keeps source failures as network errors',
    () async {
      final probe = BackendProbe(
        contentType: 'application/json',
        headers: {'x-count': '1'},
      );
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final resultFuture = StreamingApi(server).getMixed();
      await probe.listening.future.timeout(const Duration(seconds: 5));
      final failure = StateError('incomplete body');
      final stackTrace = StackTrace.current;
      probe.bytes.addError(failure, stackTrace);
      final error = requireError(await resultFuture);
      expect(error.type, TonikErrorType.network);
      expect(error.error, same(failure));
      expect(error.stackTrace, same(stackTrace));
      await probe.aborted.future.timeout(const Duration(seconds: 5));
    },
  );

  test(
    'cancelling a complete alternative keeps cancellation classification',
    () async {
      final probe = BackendProbe(
        contentType: 'application/json',
        headers: {'x-count': '1'},
        failOnAbort: true,
      );
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final cancellation = TonikCancellation();
      final resultFuture = StreamingApi(server)
          .getMixed(cancellation: cancellation);
      await probe.listening.future.timeout(const Duration(seconds: 5));
      cancellation.cancel('stopped before EOF');
      final error = requireError(
        await resultFuture.timeout(const Duration(seconds: 5)),
      );
      expect(error.type, TonikErrorType.cancelled);
      await probe.aborted.future.timeout(const Duration(seconds: 5));
      expect(probe.clientClosed, isFalse);
    },
  );

  test(
    'malformed mixed stream terminates without selecting complete JSON',
    () async {
      final probe = BackendProbe(headers: {'x-count': '1'});
      final server = CustomServer(
        baseUrl: 'http://example.test',
        serverConfig: probe.config(),
      );
      addTearDown(server.close);
      final result = await StreamingApi(server).getMixed();
      final status = requireSuccess(result).value as GetMixedResponse200;
      final response = status.body as MixedGet200ResponseXNdjson;
      final events = <Object>[];
      final done = Completer<void>();
      response.body.listen(events.add, onDone: done.complete);
      probe.bytes.add(utf8.encode('invalid\n{"value":2}\n'));
      await done.future.timeout(const Duration(seconds: 5));
      await probe.aborted.future.timeout(const Duration(seconds: 5));
      expect(events, hasLength(1));
      final failure = events.single as TonikError<Object?, Object>;
      expect(failure.error, isA<FormatException>());
      expect(failure.type, TonikErrorType.decoding);
    },
  );

  test('referenced media chain returns typed items', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getReferencedStream();
    final items = requireSuccess(result).value
        .map((item) => requireSuccess(item).value)
        .toList();
    probe.bytes.add(utf8.encode('{"value":11}\n{"value":12}\n'));
    await probe.bytes.close();
    expect(await items, [
      const StreamItem(value: 11),
      const StreamItem(value: 12),
    ]);
  });

  test('referenced mixed content selects its item stream', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getReferencedMixed();
    final response =
        requireSuccess(result).value as ReferencedMixedGet200ResponseXNdjson;
    final items = response.body
        .map((item) => requireSuccess(item).value)
        .toList();
    probe.bytes.add(utf8.encode('{"value":13}\n'));
    await probe.bytes.close();
    expect(await items, [const StreamItem(value: 13)]);
  });

  test('referenced mixed content selects its complete JSON', () async {
    final probe = BackendProbe(contentType: 'application/json');
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final resultFuture = StreamingApi(server).getReferencedMixed();
    probe.bytes.add(utf8.encode('{"value":14}'));
    unawaited(probe.bytes.close());
    final result = await resultFuture;
    final response =
        requireSuccess(result).value as ReferencedMixedGet200ResponseJson;
    expect(response.body, const StreamItem(value: 14));
    final native = (result as TonikSuccess).response;
    if (native is http.BaseResponse) expect(native, isA<http.Response>());
  });

  test('external media alternative keeps complete byte fallback', () async {
    final probe = BackendProbe(contentType: 'application/jsonl');
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final resultFuture = StreamingApi(server).getReferencedMixed();
    probe.bytes.add([49, 10, 50, 10]);
    unawaited(probe.bytes.close());
    final result = await resultFuture;
    final response =
        requireSuccess(result).value as ReferencedMixedGet200ResponseJsonl;
    expect((response.body as TonikFileBytes).bytes, [49, 10, 50, 10]);
    final native = (result as TonikSuccess).response;
    if (native is http.BaseResponse) expect(native, isA<http.Response>());
  });

  test('finite schema-only NDJSON retains byte decoding', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final resultFuture = StreamingApi(server).getSchemaOnly();
    probe.bytes.add([49, 10, 50, 10]);
    unawaited(probe.bytes.close());
    final result = await resultFuture;
    expect((requireSuccess(result).value as TonikFileBytes).bytes, [
      49,
      10,
      50,
      10,
    ]);
  });

  test(
    'referenced request media keeps ordinary complete JSON encoding',
    () async {
      final host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => host.close(force: true));
      final received = Completer<(String, Object?)>();
      host.listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        received.complete((
          request.headers.contentType!.mimeType,
          jsonDecode(body),
        ));
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"value":15}');
        await request.response.close();
      });
      final server = CustomServer(baseUrl: 'http://localhost:${host.port}');
      addTearDown(server.close);
      final result = await StreamingApi(server)
          .postReferencedRequest(body: const StreamItem(value: 15));
      expect(requireSuccess(result).value, const StreamItem(value: 15));
      final (contentType, body) = await received.future;
      expect(contentType, 'application/json');
      expect(body, {'value': 15});
    },
  );
  test('nullable scalar items keep nullability inside the stream', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getNullableItems();
    // The explicit type checks the generated public item type at compile time.
    final Stream<TonikResult<int?, Object>> items = requireSuccess(result)
        .value;
    final values = items.map((item) => requireSuccess(item).value).toList();
    probe.bytes.add(utf8.encode('1\nnull\n2\n'));
    await probe.bytes.close();
    expect(await values, [1, null, 2]);
  });

  test('unconstrained items preserve all JSON value shapes', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getAnyItems();
    // The explicit type checks the generated public item type at compile time.
    final Stream<TonikResult<Object?, Object>> items = requireSuccess(result)
        .value;
    final values = items.map((item) => requireSuccess(item).value).toList();
    probe.bytes.add(utf8.encode('null\n3\n"text"\ntrue\n[1]\n{"key":2}\n'));
    await probe.bytes.close();
    expect(await values, [
      null,
      3,
      'text',
      true,
      [1],
      {'key': 2},
    ]);
  });

  test('an impossible item schema permits an empty stream', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getNeverItems();
    // The explicit type checks the generated public item type at compile time.
    final Stream<TonikResult<Never, Object>> items = requireSuccess(result)
        .value;
    final values = items.toList();
    await probe.bytes.close();
    expect(await values, isEmpty);
  });

  test('an impossible item terminates conversion and forwards abort', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getNeverItems();
    final events = <Object?>[];
    final done = Completer<void>();
    requireSuccess(result).value.listen(events.add, onDone: done.complete);
    probe.bytes.add(utf8.encode('null\n1\n'));
    await done.future.timeout(const Duration(seconds: 5));
    await probe.aborted.future.timeout(const Duration(seconds: 5));
    expect(events, hasLength(1));
    final failure = events.single! as TonikError<Never, Object>;
    expect(failure.error, isA<JsonDecodingException>());
    expect(failure.type, TonikErrorType.decoding);
    expect(probe.clientClosed, isFalse);
  });

  test('referenced item aliases preserve nested normalized models', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getNestedItems();
    // The explicit type checks the generated public item type at compile time.
    final Stream<TonikResult<StreamBatchAlias, Object>> items = requireSuccess(
      result,
    ).value;
    final values = items.map((item) => requireSuccess(item).value).toList();
    probe.bytes.add(
      utf8.encode('[{"value":4,"metrics":{"scores":[2,3]}}]\n[]\n'),
    );
    await probe.bytes.close();
    expect(await values, [
      [
        const NestedStreamItem(
          streamItem: StreamItem(value: 4),
          nestedStreamItemModel: NestedStreamItemModel(
            metrics: {
              'scores': [2, 3],
            },
          ),
        ),
      ],
      <NestedStreamItem>[],
    ]);
  });

  test('application-error union members are ordinary stream items', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getEvents();
    final response =
        requireSuccess(result).value as EventsGet200ResponseXNdjson;
    // The explicit type checks the generated public item type at compile time.
    final Stream<TonikResult<StreamEvent, Object>> items = response.body;
    final values = items.map((item) => requireSuccess(item).value).toList();
    probe.bytes.add(
      utf8.encode(
        '{"kind":"state","progress":25}\n'
        '{"kind":"error","message":"try again"}\n'
        '{"kind":"result","result":"finished"}\n',
      ),
    );
    await probe.bytes.close();
    expect(await values, [
      const StreamEventStateEvent(
        StateEvent(kind: StateEventKindModel.state, progress: 25),
      ),
      const StreamEventApplicationErrorEvent(
        ApplicationErrorEvent(
          kind: ApplicationErrorEventKindModel.error,
          message: 'try again',
        ),
      ),
      const StreamEventResultEvent(
        ResultEvent(kind: ResultEventKindModel.result, result: 'finished'),
      ),
    ]);
    expect(probe.aborted.isCompleted, isFalse);
  });

  test('a real union conversion failure ends consumption and aborts', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getEvents();
    final response =
        requireSuccess(result).value as EventsGet200ResponseXNdjson;
    final events = <Object>[];
    final done = Completer<void>();
    response.body.listen(events.add, onDone: done.complete);
    probe.bytes.add(
      utf8.encode(
        '{"kind":"state","progress":25}\n'
        '{"kind":"result","result":42}\n'
        '{"kind":"result","result":"unreachable"}\n',
      ),
    );
    await done.future.timeout(const Duration(seconds: 5));
    await probe.aborted.future.timeout(const Duration(seconds: 5));
    expect(events, hasLength(2));
    expect(
      requireSuccess(events.first as TonikResult<StreamEvent, Object>).value,
      const StreamEventStateEvent(
        StateEvent(kind: StateEventKindModel.state, progress: 25),
      ),
    );
    final failure = events.last as TonikError<StreamEvent, Object>;
    expect(failure.error, isA<InvalidTypeException>());
    expect(failure.type, TonikErrorType.decoding);
    expect(probe.clientClosed, isFalse);
  });

  test('the event operation retains its complete JSON model', () async {
    final probe = BackendProbe(contentType: 'application/json');
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final resultFuture = StreamingApi(server).getEvents();
    probe.bytes.add(utf8.encode('{"total":3}'));
    unawaited(probe.bytes.close());
    final result = await resultFuture;
    final response = requireSuccess(result).value as EventsGet200ResponseJson;
    expect(response.body, const StreamSummary(total: 3));
  });

  test('NDJSON media retains its distinct inline item model', () async {
    final probe = BackendProbe();
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getAlternativeItems();
    final status =
        requireSuccess(result).value as GetAlternativeItemsResponse200;
    final response = status.body as AlternativeItemsGet200ResponseXNdjson;
    final values = response.body
        .map((item) => requireSuccess(item).value)
        .toList();
    probe.bytes.add(utf8.encode('{"count":5}\n'));
    await probe.bytes.close();
    expect(await values, [const AlternativeItemsGet200BodyModel(count: 5)]);
  });

  test('JSONL media retains its distinct inline item model', () async {
    final probe = BackendProbe(contentType: 'application/jsonl');
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getAlternativeItems();
    final status =
        requireSuccess(result).value as GetAlternativeItemsResponse200;
    final response = status.body as AlternativeItemsGet200ResponseJsonl;
    final values = response.body
        .map((item) => requireSuccess(item).value)
        .toList();
    probe.bytes.add(utf8.encode('{"label":"named"}\n'));
    await probe.bytes.close();
    expect(await values, [
      const AlternativeItemsGet200BodyModel2(label: 'named'),
    ]);
  });

  test('another status retains its distinct inline item model', () async {
    final probe = BackendProbe(statusCode: 202);
    final server = CustomServer(
      baseUrl: 'http://example.test',
      serverConfig: probe.config(),
    );
    addTearDown(server.close);
    final result = await StreamingApi(server).getAlternativeItems();
    final response =
        requireSuccess(result).value as GetAlternativeItemsResponse202;
    final values = response.body
        .map((item) => requireSuccess(item).value)
        .toList();
    probe.bytes.add(utf8.encode('{"ready":true}\n'));
    await probe.bytes.close();
    expect(await values, [const AlternativeItemsGet202BodyModel(ready: true)]);
  });
}

final class BackendProbe({
  final String contentType = 'application/x-ndjson',
  final int statusCode = 200,
  final Map<String, String> headers = const {},
  final bool failOnAbort = false,
}) {
  final bytes = StreamController<List<int>>();
  final aborted = Completer<void>();
  final listening = Completer<void>();
  bool clientClosed = false;

  ServerConfig<Client> config<Client extends Object>() {
    if (Client == dio.Dio) {
      final client = dio.Dio()..httpClientAdapter = ProbeDioAdapter(this);
      return ServerConfig.client(client) as ServerConfig<Client>;
    }
    if (Client == http.Client) {
      return ServerConfig.client(ProbeHttpClient(this)) as ServerConfig<Client>;
    }
    throw UnsupportedError('Unexpected backend: $Client');
  }

  void abort() {
    if (!aborted.isCompleted) aborted.complete();
  }
}

final class ProbeDioAdapter(final BackendProbe probe)
    implements dio.HttpClientAdapter {
  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final token = options.cancelToken;
    if (token != null) unawaited(token.whenCancel.then((_) => probe.abort()));
    probe.bytes.onListen = probe.listening.complete;
    return dio.ResponseBody(
      probe.bytes.stream.map(Uint8List.fromList),
      probe.statusCode,
      headers: {
        'content-type': [probe.contentType],
        for (final header in probe.headers.entries) header.key: [header.value],
      },
    );
  }

  @override
  void close({bool force = false}) => probe.clientClosed = true;
}

final class ProbeHttpClient(final BackendProbe probe) extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final abort = (request as http.Abortable).abortTrigger;
    if (abort != null) {
      unawaited(
        abort.then((_) {
          probe.abort();
          if (probe.failOnAbort) {
            probe.bytes.addError(http.RequestAbortedException(request.url));
          }
        }),
      );
    }
    probe.bytes.onListen = probe.listening.complete;
    return http.StreamedResponse(
      probe.bytes.stream,
      probe.statusCode,
      headers: {'content-type': probe.contentType, ...probe.headers},
      request: request,
    );
  }

  @override
  void close() => probe.clientClosed = true;
}
