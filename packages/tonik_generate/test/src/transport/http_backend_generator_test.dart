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
    for (final httpMethod in HttpMethod.values) {
      test(
        'emits and sends one abortable '
        '${httpMethod.name.toUpperCase()} request',
        () {
          final followsRedirects = httpMethod != HttpMethod.trace;
          final maxRedirects = httpMethod == HttpMethod.trace ? 2 : 5;
          final statements = generator.generateDispatchStatements(
            plan: OperationRequestPlan(
              method: httpMethod,
              uri: refer(r'_$uri'),
              pathParameters: const [],
              queryParameters: const [],
              headers: const [],
              cookies: const [],
              contentType: null,
              followRedirects: followsRedirects,
              maxRedirects: maxRedirects,
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

          final expectedMethod =
              r'''
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
      'METHOD',
      _$uri,
      abortTrigger: cancellation?.whenCancelled,
    );
    _$request.headers.addAll(_$options);
    _$request.followRedirects = FOLLOWS_REDIRECTS;
    _$request.maxRedirects = MAX_REDIRECTS;
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
'''
                  .replaceFirst('METHOD', httpMethod.name.toUpperCase())
                  .replaceFirst('FOLLOWS_REDIRECTS', '$followsRedirects')
                  .replaceFirst('MAX_REDIRECTS', '$maxRedirects');

          expect(
            collapseWhitespace(format('${generatedMethod.accept(emitter)}')),
            collapseWhitespace(format(expectedMethod)),
          );
        },
      );
    }
  });
}

String _asMethod(Method method, DartEmitter emitter) {
  final wrapped = method.rebuild(
    (builder) => builder
      ..type = null
      ..name = method.name,
  );
  return '${wrapped.accept(emitter)}';
}
