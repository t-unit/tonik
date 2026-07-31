import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/transport/http_backend_generator.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';

void main() {
  const generator = HttpBackendGenerator();
  final emitter = DartEmitter(useNullSafetySyntax: true);
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  group('http client adapter', () {
    late Class adapter;

    setUp(() {
      adapter = generator.generateClientAdapter();
    });

    test('tracks cached ownership and one stable closed error', () {
      expect(
        adapter.fields.map((field) => field.name),
        [
          'serverConfig',
          r'_$client',
          r'_$ownsClient',
          r'_$isClosed',
          r'_$closedError',
        ],
      );

      final serverConfig = adapter.fields.first;
      expect(
        serverConfig.type?.accept(emitter).toString(),
        'ServerConfig<Client>',
      );
      expect(serverConfig.modifier, FieldModifier.final$);

      final closedError = adapter.fields.last;
      expect(
        closedError.type?.accept(emitter).toString(),
        'StateError',
      );
      expect(closedError.modifier, FieldModifier.final$);
    });

    test(
      'resolves default injected and factory clients once with ownership',
      () {
        final getter = adapter.methods.singleWhere(
          (method) => method.name == 'client',
        );

        const expectedMethod = r'''
Client client() {
  if (_$isClosed) {
    throw _$closedError;
  }

  final cachedClient = _$client;
  if (cachedClient != null) {
    return cachedClient;
  }

  final configuredClient = serverConfig.client;
  final resolvedClient =
      configuredClient ?? serverConfig.clientFactory?.call() ?? Client();
  _$ownsClient = configuredClient == null;
  return _$client = resolvedClient;
}
''';

        expect(
          collapseWhitespace(format(_asMethod(getter, emitter))),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test(
      'closes only an owned resolved client once without resolving on close',
      () {
        final close = adapter.methods.singleWhere(
          (method) => method.name == 'close',
        );

        expect(
          close.returns?.accept(emitter).toString(),
          'void',
        );

        const expectedMethod = r'''
void close() {
  if (_$isClosed) {
    return;
  }

  _$isClosed = true;
  if (_$ownsClient) {
    _$client?.close();
  }
}
''';

        expect(
          collapseWhitespace(format(_asMethod(close, emitter))),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );
  });

  group('ordinary request dispatch', () {
    test('emits and sends one abortable GET request', () {
      _expectDispatch(
        generator: generator,
        emitter: emitter,
        format: format,
        method: HttpMethod.get,
        expectedMethod: _expectedGetDispatch,
      );
    });

    test('emits and sends one abortable HEAD request', () {
      _expectDispatch(
        generator: generator,
        emitter: emitter,
        format: format,
        method: HttpMethod.head,
        expectedMethod: _expectedHeadDispatch,
      );
    });

    test('emits and sends one abortable POST request', () {
      _expectDispatch(
        generator: generator,
        emitter: emitter,
        format: format,
        method: HttpMethod.post,
        expectedMethod: _expectedPostDispatch,
      );
    });

    test('emits and sends one abortable PUT request', () {
      _expectDispatch(
        generator: generator,
        emitter: emitter,
        format: format,
        method: HttpMethod.put,
        expectedMethod: _expectedPutDispatch,
      );
    });

    test('emits and sends one abortable PATCH request', () {
      _expectDispatch(
        generator: generator,
        emitter: emitter,
        format: format,
        method: HttpMethod.patch,
        expectedMethod: _expectedPatchDispatch,
      );
    });

    test('emits and sends one abortable DELETE request', () {
      _expectDispatch(
        generator: generator,
        emitter: emitter,
        format: format,
        method: HttpMethod.delete,
        expectedMethod: _expectedDeleteDispatch,
      );
    });

    test('emits and sends one abortable OPTIONS request', () {
      _expectDispatch(
        generator: generator,
        emitter: emitter,
        format: format,
        method: HttpMethod.options,
        expectedMethod: _expectedOptionsDispatch,
      );
    });

    test('emits and sends one abortable TRACE request', () {
      _expectDispatch(
        generator: generator,
        emitter: emitter,
        format: format,
        method: HttpMethod.trace,
        expectedMethod: _expectedTraceDispatch,
      );
    });
  });
}

const _expectedGetDispatch = r'''
Future<TonikResult<void, Response>> dispatch() async {
  late final Response _$response;
  if (cancellation != null && cancellation.isCancelled) {
    final exception = RequestAbortedException(_$uri);
    return TonikError<void, Response>(
      exception,
      stackTrace: StackTrace.current,
      type: TonikErrorType.cancelled,
      response: null,
    );
  }

  final Client _$client;
  try {
    _$client = _client();
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.other,
      response: null,
    );
  }

  late final AbortableRequest _$request;
  try {
    _$request = AbortableRequest(
      'GET',
      _$uri,
      abortTrigger: cancellation?.whenCancelled,
    );
    _$request.headers.addAll(_$options);
    if (_$data != null) {
      _$request.bodyBytes = (_$data as List<int>);
    }
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.encoding,
      response: null,
    );
  }

  await _$client.send(_$request);
  throw UnsupportedError(
    'The http transport backend does not support response normalization yet.',
  );
}
''';

const _expectedHeadDispatch = r'''
Future<TonikResult<void, Response>> dispatch() async {
  late final Response _$response;
  if (cancellation != null && cancellation.isCancelled) {
    final exception = RequestAbortedException(_$uri);
    return TonikError<void, Response>(
      exception,
      stackTrace: StackTrace.current,
      type: TonikErrorType.cancelled,
      response: null,
    );
  }

  final Client _$client;
  try {
    _$client = _client();
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.other,
      response: null,
    );
  }

  late final AbortableRequest _$request;
  try {
    _$request = AbortableRequest(
      'HEAD',
      _$uri,
      abortTrigger: cancellation?.whenCancelled,
    );
    _$request.headers.addAll(_$options);
    if (_$data != null) {
      _$request.bodyBytes = (_$data as List<int>);
    }
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.encoding,
      response: null,
    );
  }

  await _$client.send(_$request);
  throw UnsupportedError(
    'The http transport backend does not support response normalization yet.',
  );
}
''';

const _expectedPostDispatch = r'''
Future<TonikResult<void, Response>> dispatch() async {
  late final Response _$response;
  if (cancellation != null && cancellation.isCancelled) {
    final exception = RequestAbortedException(_$uri);
    return TonikError<void, Response>(
      exception,
      stackTrace: StackTrace.current,
      type: TonikErrorType.cancelled,
      response: null,
    );
  }

  final Client _$client;
  try {
    _$client = _client();
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.other,
      response: null,
    );
  }

  late final AbortableRequest _$request;
  try {
    _$request = AbortableRequest(
      'POST',
      _$uri,
      abortTrigger: cancellation?.whenCancelled,
    );
    _$request.headers.addAll(_$options);
    if (_$data != null) {
      _$request.bodyBytes = (_$data as List<int>);
    }
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.encoding,
      response: null,
    );
  }

  await _$client.send(_$request);
  throw UnsupportedError(
    'The http transport backend does not support response normalization yet.',
  );
}
''';

const _expectedPutDispatch = r'''
Future<TonikResult<void, Response>> dispatch() async {
  late final Response _$response;
  if (cancellation != null && cancellation.isCancelled) {
    final exception = RequestAbortedException(_$uri);
    return TonikError<void, Response>(
      exception,
      stackTrace: StackTrace.current,
      type: TonikErrorType.cancelled,
      response: null,
    );
  }

  final Client _$client;
  try {
    _$client = _client();
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.other,
      response: null,
    );
  }

  late final AbortableRequest _$request;
  try {
    _$request = AbortableRequest(
      'PUT',
      _$uri,
      abortTrigger: cancellation?.whenCancelled,
    );
    _$request.headers.addAll(_$options);
    if (_$data != null) {
      _$request.bodyBytes = (_$data as List<int>);
    }
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.encoding,
      response: null,
    );
  }

  await _$client.send(_$request);
  throw UnsupportedError(
    'The http transport backend does not support response normalization yet.',
  );
}
''';

const _expectedPatchDispatch = r'''
Future<TonikResult<void, Response>> dispatch() async {
  late final Response _$response;
  if (cancellation != null && cancellation.isCancelled) {
    final exception = RequestAbortedException(_$uri);
    return TonikError<void, Response>(
      exception,
      stackTrace: StackTrace.current,
      type: TonikErrorType.cancelled,
      response: null,
    );
  }

  final Client _$client;
  try {
    _$client = _client();
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.other,
      response: null,
    );
  }

  late final AbortableRequest _$request;
  try {
    _$request = AbortableRequest(
      'PATCH',
      _$uri,
      abortTrigger: cancellation?.whenCancelled,
    );
    _$request.headers.addAll(_$options);
    if (_$data != null) {
      _$request.bodyBytes = (_$data as List<int>);
    }
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.encoding,
      response: null,
    );
  }

  await _$client.send(_$request);
  throw UnsupportedError(
    'The http transport backend does not support response normalization yet.',
  );
}
''';

const _expectedDeleteDispatch = r'''
Future<TonikResult<void, Response>> dispatch() async {
  late final Response _$response;
  if (cancellation != null && cancellation.isCancelled) {
    final exception = RequestAbortedException(_$uri);
    return TonikError<void, Response>(
      exception,
      stackTrace: StackTrace.current,
      type: TonikErrorType.cancelled,
      response: null,
    );
  }

  final Client _$client;
  try {
    _$client = _client();
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.other,
      response: null,
    );
  }

  late final AbortableRequest _$request;
  try {
    _$request = AbortableRequest(
      'DELETE',
      _$uri,
      abortTrigger: cancellation?.whenCancelled,
    );
    _$request.headers.addAll(_$options);
    if (_$data != null) {
      _$request.bodyBytes = (_$data as List<int>);
    }
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.encoding,
      response: null,
    );
  }

  await _$client.send(_$request);
  throw UnsupportedError(
    'The http transport backend does not support response normalization yet.',
  );
}
''';

const _expectedOptionsDispatch = r'''
Future<TonikResult<void, Response>> dispatch() async {
  late final Response _$response;
  if (cancellation != null && cancellation.isCancelled) {
    final exception = RequestAbortedException(_$uri);
    return TonikError<void, Response>(
      exception,
      stackTrace: StackTrace.current,
      type: TonikErrorType.cancelled,
      response: null,
    );
  }

  final Client _$client;
  try {
    _$client = _client();
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.other,
      response: null,
    );
  }

  late final AbortableRequest _$request;
  try {
    _$request = AbortableRequest(
      'OPTIONS',
      _$uri,
      abortTrigger: cancellation?.whenCancelled,
    );
    _$request.headers.addAll(_$options);
    if (_$data != null) {
      _$request.bodyBytes = (_$data as List<int>);
    }
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.encoding,
      response: null,
    );
  }

  await _$client.send(_$request);
  throw UnsupportedError(
    'The http transport backend does not support response normalization yet.',
  );
}
''';

const _expectedTraceDispatch = r'''
Future<TonikResult<void, Response>> dispatch() async {
  late final Response _$response;
  if (cancellation != null && cancellation.isCancelled) {
    final exception = RequestAbortedException(_$uri);
    return TonikError<void, Response>(
      exception,
      stackTrace: StackTrace.current,
      type: TonikErrorType.cancelled,
      response: null,
    );
  }

  final Client _$client;
  try {
    _$client = _client();
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.other,
      response: null,
    );
  }

  late final AbortableRequest _$request;
  try {
    _$request = AbortableRequest(
      'TRACE',
      _$uri,
      abortTrigger: cancellation?.whenCancelled,
    );
    _$request.headers.addAll(_$options);
    if (_$data != null) {
      _$request.bodyBytes = (_$data as List<int>);
    }
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.encoding,
      response: null,
    );
  }

  await _$client.send(_$request);
  throw UnsupportedError(
    'The http transport backend does not support response normalization yet.',
  );
}
''';

void _expectDispatch({
  required HttpBackendGenerator generator,
  required DartEmitter emitter,
  required String Function(String, {Object? uri}) format,
  required HttpMethod method,
  required String expectedMethod,
}) {
  final statements = generator.generateDispatchStatements(
    plan: OperationRequestPlan(
      method: method,
      uri: refer(r'_$uri'),
      pathParameters: const [],
      queryParameters: const [],
      headers: const [],
      cookies: const [],
      contentType: null,
      cancellation: refer('cancellation'),
      response: ResponseRequirements(
        expectsBytes: true,
        statuses: const [],
        contentTypes: const [],
      ),
      body: const AbsentBodyPlan(),
    ),
    responseVariable: r'_$response',
    resultValueType: refer('void', 'dart:core'),
  );

  final generatedMethod = Method(
    (b) => b
      ..name = 'dispatch'
      ..returns = TypeReference(
        (b) => b
          ..symbol = 'Future'
          ..url = 'dart:core'
          ..types.add(
            TypeReference(
              (b) => b
                ..symbol = 'TonikResult'
                ..url = 'package:tonik_util/tonik_util.dart'
                ..types.addAll([
                  refer('void', 'dart:core'),
                  refer('Response', 'package:http/http.dart'),
                ]),
            ),
          ),
      )
      ..modifier = MethodModifier.async
      ..body = Block.of([statements]),
  );

  expect(
    collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
    collapseWhitespace(format(expectedMethod)),
  );
}

String _asMethod(Method method, DartEmitter emitter) {
  final wrapped = method.rebuild(
    (builder) => builder
      ..type = null
      ..name = method.name,
  );
  return '${wrapped.accept(emitter)}';
}
