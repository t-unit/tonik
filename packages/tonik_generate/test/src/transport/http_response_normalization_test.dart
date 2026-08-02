import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:tonik_util/tonik_util.dart';

void main() {
  final uri = Uri.parse('https://example.com/pets');

  test(
    'buffers one complete native response with one stream listener',
    () async {
      var listenCount = 0;
      final controller = StreamController<List<int>>(
        sync: true,
        onListen: () => listenCount += 1,
      );
      final client = _FakeClient(
        (_) async => http.StreamedResponse(
          controller.stream,
          418,
          headers: const {
            'content-type': 'application/json',
            'x-values': 'first, second',
          },
        ),
      );

      final resultFuture = _dispatch(client: client, uri: uri);
      controller.add(const [123, 125]);
      await controller.close();
      final result = await resultFuture;

      expect(result, isA<TonikSuccess<void, http.Response>>());
      final success = result as TonikSuccess<void, http.Response>;
      expect(success.response.statusCode, 418);
      expect(success.response.bodyBytes, [123, 125]);
      expect(success.response.headersSplitValues['x-values'], [
        'first',
        'second',
      ]);
      expect(client.sendCount, 1);
      expect(listenCount, 1);
    },
  );

  test('pre-dispatch cancellation never sends', () async {
    final cancellation = TonikCancellation()..cancel('stop');
    final client = _FakeClient(
      (_) async => http.StreamedResponse(const Stream.empty(), 200),
    );

    final result = await _dispatch(
      client: client,
      uri: uri,
      cancellation: cancellation,
    );

    final error = _expectError(result, TonikErrorType.cancelled);
    expect(error.error, isA<http.RequestAbortedException>());
    expect(error.response, isNull);
    expect(client.sendCount, 0);
  });

  test('matching abort during send is cancelled', () async {
    final cancellation = TonikCancellation();
    final exception = http.RequestAbortedException(uri);
    final stackTrace = StackTrace.current;
    final client = _FakeClient((request) async {
      await (request as http.Abortable).abortTrigger!;
      Error.throwWithStackTrace(exception, stackTrace);
    });

    final resultFuture = _dispatch(
      client: client,
      uri: uri,
      cancellation: cancellation,
    );
    cancellation.cancel('stop');
    final result = await resultFuture;

    final error = _expectError(result, TonikErrorType.cancelled);
    expect(error.error, same(exception));
    expect(error.stackTrace, same(stackTrace));
    expect(error.response, isNull);
    expect(client.sendCount, 1);
  });

  test('abort without explicit cancellation is network', () async {
    final exception = http.RequestAbortedException(uri);
    final client = _FakeClient((_) => Future.error(exception));

    final result = await _dispatch(client: client, uri: uri);

    final error = _expectError(result, TonikErrorType.network);
    expect(error.error, same(exception));
    expect(error.response, isNull);
  });

  for (final failure in <({Object error, TonikErrorType type})>[
    (
      error: http.ClientException('connection failed', uri),
      type: TonikErrorType.network,
    ),
    (
      error: TimeoutException('request timed out'),
      type: TonikErrorType.network,
    ),
    (
      error: StateError('unexpected client failure'),
      type: TonikErrorType.other,
    ),
  ]) {
    test(
      'classifies send ${failure.error.runtimeType} as ${failure.type}',
      () async {
        final stackTrace = StackTrace.current;
        final client = _FakeClient(
          (_) => Future.error(failure.error, stackTrace),
        );

        final result = await _dispatch(client: client, uri: uri);

        final error = _expectError(result, failure.type);
        expect(error.error, same(failure.error));
        expect(error.stackTrace, same(stackTrace));
        expect(error.response, isNull);
      },
    );
  }

  for (final partialBody in [false, true]) {
    test(
      'stream failure with${partialBody ? '' : 'out'} partial bytes is network',
      () async {
        var listenCount = 0;
        final exception = StateError('stream failed');
        final stackTrace = StackTrace.current;
        final controller = StreamController<List<int>>(
          sync: true,
          onListen: () => listenCount += 1,
        );
        final client = _FakeClient(
          (_) async => http.StreamedResponse(controller.stream, 200),
        );

        final resultFuture = _dispatch(client: client, uri: uri);
        if (partialBody) {
          controller.add(const [1, 2, 3]);
        }
        controller.addError(exception, stackTrace);
        await controller.close();
        final result = await resultFuture;

        final error = _expectError(result, TonikErrorType.network);
        expect(error.error, same(exception));
        expect(error.stackTrace, same(stackTrace));
        expect(error.response, isNull);
        expect(listenCount, 1);
      },
    );
  }

  test('matching abort during response streaming is cancelled', () async {
    final cancellation = TonikCancellation();
    final exception = http.RequestAbortedException(uri);
    final stackTrace = StackTrace.current;
    final controller = StreamController<List<int>>(sync: true);
    final client = _FakeClient((request) async {
      unawaited(
        (request as http.Abortable).abortTrigger!.then((_) async {
          controller.addError(exception, stackTrace);
          await controller.close();
        }),
      );
      return http.StreamedResponse(controller.stream, 200);
    });

    final resultFuture = _dispatch(
      client: client,
      uri: uri,
      cancellation: cancellation,
    );
    cancellation.cancel('stop');
    final result = await resultFuture;

    final error = _expectError(result, TonikErrorType.cancelled);
    expect(error.error, same(exception));
    expect(error.stackTrace, same(stackTrace));
    expect(error.response, isNull);
  });

  test('an injected client may ignore an in-flight cancellation', () async {
    final cancellation = TonikCancellation();
    final controller = StreamController<List<int>>(sync: true);
    final client = _FakeClient(
      (_) async => http.StreamedResponse(controller.stream, 200),
    );
    var terminalCount = 0;

    final resultFuture =
        _dispatch(
          client: client,
          uri: uri,
          cancellation: cancellation,
        ).then((result) {
          terminalCount += 1;
          return result;
        });
    cancellation.cancel('ignored');
    controller.add(const [111, 107]);
    await controller.close();
    final result = await resultFuture;

    expect(result, isA<TonikSuccess<void, http.Response>>());
    expect(terminalCount, 1);
    expect(client.sendCount, 1);
  });
}

TonikError<void, http.Response> _expectError(
  TonikResult<void, http.Response> result,
  TonikErrorType type,
) {
  expect(result, isA<TonikError<void, http.Response>>());
  final error = result as TonikError<void, http.Response>;
  expect(error.type, type);
  return error;
}

/// Executable contract for the complete method body asserted by
/// `http_backend_generator_test.dart`.
Future<TonikResult<void, http.Response>> _dispatch({
  required http.Client client,
  required Uri uri,
  TonikCancellation? cancellation,
}) async {
  if (cancellation != null && cancellation.isCancelled) {
    final exception = http.RequestAbortedException(uri);
    return TonikError<void, http.Response>(
      exception,
      stackTrace: StackTrace.current,
      type: TonikErrorType.cancelled,
      response: null,
    );
  }

  final request = http.AbortableRequest(
    'GET',
    uri,
    abortTrigger: cancellation?.whenCancelled,
  );
  final http.StreamedResponse streamedResponse;
  try {
    streamedResponse = await client.send(request);
  } on http.RequestAbortedException catch (exception, stackTrace) {
    return TonikError<void, http.Response>(
      exception,
      stackTrace: stackTrace,
      type: cancellation?.isCancelled ?? false
          ? TonikErrorType.cancelled
          : TonikErrorType.network,
      response: null,
    );
  } on http.ClientException catch (exception, stackTrace) {
    return TonikError<void, http.Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.network,
      response: null,
    );
  } on TimeoutException catch (exception, stackTrace) {
    return TonikError<void, http.Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.network,
      response: null,
    );
  } on Object catch (exception, stackTrace) {
    return TonikError<void, http.Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.other,
      response: null,
    );
  }

  final http.Response response;
  try {
    response = await http.Response.fromStream(streamedResponse);
  } on http.RequestAbortedException catch (exception, stackTrace) {
    return TonikError<void, http.Response>(
      exception,
      stackTrace: stackTrace,
      type: cancellation?.isCancelled ?? false
          ? TonikErrorType.cancelled
          : TonikErrorType.network,
      response: null,
    );
  } on Object catch (exception, stackTrace) {
    return TonikError<void, http.Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.network,
      response: null,
    );
  }

  return TonikSuccess<void, http.Response>(null, response);
}

final class _FakeClient extends http.BaseClient {
  _FakeClient(this._send);

  final Future<http.StreamedResponse> Function(http.BaseRequest request) _send;
  int sendCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    sendCount += 1;
    return _send(request);
  }
}
