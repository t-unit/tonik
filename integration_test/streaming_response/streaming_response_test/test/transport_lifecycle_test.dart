import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:streaming_response_api/streaming_response_api.dart';
import 'package:test/test.dart';
import 'package:test_helpers/test_helpers.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
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
