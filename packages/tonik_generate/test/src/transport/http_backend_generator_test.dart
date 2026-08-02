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
        final generatedMethod = getter.rebuild(
          (builder) => builder
            ..type = null
            ..name = getter.name,
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
          collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
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

        final generatedMethod = close.rebuild(
          (builder) => builder
            ..type = null
            ..name = close.name,
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
          collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );
  });

  group('ordinary request dispatch', () {
    test('emits and sends one abortable GET request', () {
      final statements = generator.generateDispatchStatements(
        plan: OperationRequestPlan(
          method: HttpMethod.get,
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
        (builder) => builder
          ..name = 'dispatch'
          ..returns = TypeReference(
            (builder) => builder
              ..symbol = 'Future'
              ..url = 'dart:core'
              ..types.add(
                TypeReference(
                  (builder) => builder
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

      const expectedMethod = r'''
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

      expect(
        collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('emits and sends one abortable HEAD request', () {
      final statements = generator.generateDispatchStatements(
        plan: OperationRequestPlan(
          method: HttpMethod.head,
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
        (builder) => builder
          ..name = 'dispatch'
          ..returns = TypeReference(
            (builder) => builder
              ..symbol = 'Future'
              ..url = 'dart:core'
              ..types.add(
                TypeReference(
                  (builder) => builder
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

      const expectedMethod = r'''
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

      expect(
        collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('emits and sends one abortable POST request', () {
      final statements = generator.generateDispatchStatements(
        plan: OperationRequestPlan(
          method: HttpMethod.post,
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
        (builder) => builder
          ..name = 'dispatch'
          ..returns = TypeReference(
            (builder) => builder
              ..symbol = 'Future'
              ..url = 'dart:core'
              ..types.add(
                TypeReference(
                  (builder) => builder
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

      const expectedMethod = r'''
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

      expect(
        collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('emits and sends one abortable PUT request', () {
      final statements = generator.generateDispatchStatements(
        plan: OperationRequestPlan(
          method: HttpMethod.put,
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
        (builder) => builder
          ..name = 'dispatch'
          ..returns = TypeReference(
            (builder) => builder
              ..symbol = 'Future'
              ..url = 'dart:core'
              ..types.add(
                TypeReference(
                  (builder) => builder
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

      const expectedMethod = r'''
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

      expect(
        collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('emits and sends one abortable PATCH request', () {
      final statements = generator.generateDispatchStatements(
        plan: OperationRequestPlan(
          method: HttpMethod.patch,
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
        (builder) => builder
          ..name = 'dispatch'
          ..returns = TypeReference(
            (builder) => builder
              ..symbol = 'Future'
              ..url = 'dart:core'
              ..types.add(
                TypeReference(
                  (builder) => builder
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

      const expectedMethod = r'''
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

      expect(
        collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('emits and sends one abortable DELETE request', () {
      final statements = generator.generateDispatchStatements(
        plan: OperationRequestPlan(
          method: HttpMethod.delete,
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
        (builder) => builder
          ..name = 'dispatch'
          ..returns = TypeReference(
            (builder) => builder
              ..symbol = 'Future'
              ..url = 'dart:core'
              ..types.add(
                TypeReference(
                  (builder) => builder
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

      const expectedMethod = r'''
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

      expect(
        collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('emits and sends one abortable OPTIONS request', () {
      final statements = generator.generateDispatchStatements(
        plan: OperationRequestPlan(
          method: HttpMethod.options,
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
        (builder) => builder
          ..name = 'dispatch'
          ..returns = TypeReference(
            (builder) => builder
              ..symbol = 'Future'
              ..url = 'dart:core'
              ..types.add(
                TypeReference(
                  (builder) => builder
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

      const expectedMethod = r'''
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

      expect(
        collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test('emits and sends one abortable TRACE request', () {
      final statements = generator.generateDispatchStatements(
        plan: OperationRequestPlan(
          method: HttpMethod.trace,
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
        (builder) => builder
          ..name = 'dispatch'
          ..returns = TypeReference(
            (builder) => builder
              ..symbol = 'Future'
              ..url = 'dart:core'
              ..types.add(
                TypeReference(
                  (builder) => builder
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

      const expectedMethod = r'''
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

      expect(
        collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
        collapseWhitespace(format(expectedMethod)),
      );
    });
  });

  group('multipart request dispatch', () {
    test('emits and sends one abortable multipart request', () {
      final statements = generator.generateDispatchStatements(
        plan: OperationRequestPlan(
          method: HttpMethod.post,
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
          body: MultipartBodyPlan(
            value: refer('body'),
            rawContentType: 'multipart/form-data',
            parts: const [],
            isRequired: true,
          ),
        ),
        responseVariable: r'_$response',
        resultValueType: refer('void', 'dart:core'),
      );

      final generatedMethod = Method(
        (builder) => builder
          ..name = 'dispatch'
          ..returns = TypeReference(
            (builder) => builder
              ..symbol = 'Future'
              ..url = 'dart:core'
              ..types.add(
                TypeReference(
                  (builder) => builder
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

      const expectedMethod = r'''
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

  late final AbortableMultipartRequest _$request;
  try {
    _$request = AbortableMultipartRequest(
      'POST',
      _$uri,
      abortTrigger: cancellation?.whenCancelled,
    );
    _$request.headers.addAll(_$options);
    _$request.files.addAll((_$data as List<MultipartFile>));
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

      expect(
        collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
        collapseWhitespace(format(expectedMethod)),
      );
    });

    test(
      'uses an ordinary bodyless request when optional multipart is null',
      () {
        final statements = generator.generateDispatchStatements(
          plan: OperationRequestPlan(
            method: HttpMethod.post,
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
            body: MultipartBodyPlan(
              value: refer('body'),
              rawContentType: 'multipart/form-data',
              parts: const [],
              isRequired: false,
            ),
          ),
          responseVariable: r'_$response',
          resultValueType: refer('void', 'dart:core'),
        );

        final generatedMethod = Method(
          (builder) => builder
            ..name = 'dispatch'
            ..returns = TypeReference(
              (builder) => builder
                ..symbol = 'Future'
                ..url = 'dart:core'
                ..types.add(
                  TypeReference(
                    (builder) => builder
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

        const expectedMethod = r'''
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

  late final BaseRequest _$request;
  try {
    if (_$data is List<MultipartFile>) {
      final _$multipartRequest = AbortableMultipartRequest(
        'POST',
        _$uri,
        abortTrigger: cancellation?.whenCancelled,
      );
      _$multipartRequest.files.addAll(_$data);
      _$request = _$multipartRequest;
    } else {
      final _$ordinaryRequest = AbortableRequest(
        'POST',
        _$uri,
        abortTrigger: cancellation?.whenCancelled,
      );
      if (_$data != null) {
        _$ordinaryRequest.bodyBytes = (_$data as List<int>);
      }
      _$request = _$ordinaryRequest;
    }
    _$request.headers.addAll(_$options);
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

        expect(
          collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );
  });
}
