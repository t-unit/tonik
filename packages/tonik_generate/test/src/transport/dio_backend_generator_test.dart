import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/transport/dio_backend_generator.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';

void main() {
  const generator = DioBackendGenerator();
  final emitter = DartEmitter(useNullSafetySyntax: true);
  final format = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format;

  test('exposes portable cancellation while keeping Dio bridging private', () {
    final parameter = generator.cancellationParameter;

    expect(parameter.name, 'cancellation');
    expect(
      parameter.type?.accept(emitter).toString(),
      'TonikCancellation?',
    );
    expect(parameter.named, isTrue);
    expect(parameter.required, isFalse);
  });

  group('Dio client adapter', () {
    late Class adapter;

    setUp(() {
      adapter = generator.generateClientAdapter();
    });

    test('tracks cached ownership and one stable closed error', () {
      expect(
        adapter.fields.map((field) => field.name),
        [
          'baseUrl',
          'serverConfig',
          r'_$dio',
          r'_$ownsDio',
          r'_$isClosed',
          r'_$closedError',
        ],
      );

      final closedError = adapter.fields.singleWhere(
        (field) => field.name == r'_$closedError',
      );
      expect(
        closedError.type?.accept(emitter).toString(),
        'StateError',
      );
      expect(closedError.modifier, FieldModifier.final$);
    });

    test(
      'resolves once, records ownership, and rejects access after close',
      () {
        final getter = adapter.methods.singleWhere(
          (method) => method.name == 'dio',
        );

        const expectedMethod = r'''
Dio dio() {
  if (_$isClosed) {
    throw _$closedError;
  }

  final cachedDio = _$dio;
  if (cachedDio != null) {
    return cachedDio;
  }

  final client = serverConfig.client;
  final clientFactory = serverConfig.clientFactory;
  final resolvedDio = client ?? clientFactory?.call() ?? Dio();
  _$ownsDio = client == null;
  resolvedDio.options.baseUrl = baseUrl;
  return _$dio = resolvedDio;
}
''';

        expect(
          collapseWhitespace(format(_asMethod(getter, emitter))),
          collapseWhitespace(format(expectedMethod)),
        );
      },
    );

    test('closes an owned resolved Dio once without resolving on close', () {
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
  if (_$ownsDio) {
    _$dio?.close();
  }
}
''';

      expect(
        collapseWhitespace(format(_asMethod(close, emitter))),
        collapseWhitespace(format(expectedMethod)),
      );
    });
  });

  test(
    'guards pre-cancellation, resolves lazily, and bridges in-flight cancel '
    'without a shadow-prone local',
    () {
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
        resultValueType: refer('void'),
      );

      final method = Method(
        (b) => b
          ..name = 'dispatch'
          ..returns = TypeReference(
            (b) => b
              ..symbol = 'Future'
              ..url = 'dart:core'
              ..types.add(refer('void')),
          )
          ..modifier = MethodModifier.async
          ..body = Block.of([statements]),
      );

      const expectedMethod = r'''
Future<void> dispatch() async {
  final Response<List<int>> _$response;
  CancelToken? _$cancelToken;
  if (cancellation != null) {
    _$cancelToken = CancelToken();
    if (cancellation.isCancelled) {
      _$cancelToken.cancel(cancellation.reason);
      return TonikError<void, Response<Object?>>(
        _$cancelToken.cancelError!,
        stackTrace: _$cancelToken.cancelError!.stackTrace,
        type: TonikErrorType.cancelled,
        response: null,
      );
    }
    unawaited(
      cancellation.whenCancelled.then((_) {
        _$cancelToken!.cancel(cancellation.reason);
      }),
    );
  }

  final Dio _$dio;
  try {
    _$dio = _dio();
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response<Object?>>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.other,
      response: null,
    );
  }

  try {
    _$response = await _$dio.requestUri<List<int>>(
      _$uri,
      data: _$data,
      options: _$options,
      cancelToken: _$cancelToken,
    );
  } on DioException catch (exception, stackTrace) {
    if (exception.type == DioExceptionType.cancel) {
      return TonikError<void, Response<Object?>>(
        exception,
        stackTrace: stackTrace,
        type: TonikErrorType.cancelled,
        response: exception.response,
      );
    }
    return TonikError<void, Response<Object?>>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.network,
      response: exception.response,
    );
  } on Object catch (exception, stackTrace) {
    return TonikError<void, Response<Object?>>(
      exception,
      stackTrace: stackTrace,
      type: TonikErrorType.network,
      response: null,
    );
  }
}
''';

      expect(
        collapseWhitespace(format('${method.accept(emitter)}')),
        collapseWhitespace(format(expectedMethod)),
      );
    },
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
