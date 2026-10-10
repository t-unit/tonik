import 'package:code_builder/code_builder.dart';
import 'package:tonik_generate/src/operation/operation_base_generator.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';

final class const DioOperationBaseGenerator({final bool streaming = false})
    implements OperationBaseGenerator {
  static final _nativeResponse = TypeReference(
    (builder) => builder
      ..symbol = 'Response'
      ..url = 'package:dio/dio.dart'
      ..types.add(refer('Object?', 'dart:core')),
  );
  TypeReference get _completedResponse => streaming
      ? _nativeResponse
      : TypeReference(
          (builder) => builder
            ..symbol = 'Response'
            ..url = 'package:dio/dio.dart'
            ..types.add(
              TypeReference(
                (list) => list
                  ..symbol = 'List'
                  ..url = 'dart:core'
                  ..types.add(refer('int', 'dart:core')),
              ),
            ),
        );

  @override
  String get className => streaming ? 'DioStreamingOperation' : 'DioOperation';

  @override
  String get filename => 'dio_operation.dart';

  @override
  String get clientConstructorParameterName => 'clientAccessor';

  @override
  Reference baseType({
    required String package,
    required Reference valueType,
    String? filename,
    bool streaming = false,
  }) => TypeReference(
    (builder) => builder
      ..symbol = streaming ? 'DioStreamingOperation' : 'DioOperation'
      ..url = 'package:$package/src/operation/${filename ?? this.filename}'
      ..types.add(valueType),
  );

  @override
  Expression executionInvocation({
    required String package,
    required String filename,
    required OperationRequestPlan plan,
    required Expression path,
    required Expression queryParameters,
    required Expression data,
    required Expression options,
    required Expression? decode,
    required bool isVoid,
    required bool isDataAsync,
    bool streaming = false,
  }) {
    final methodName = switch ((isVoid, isDataAsync)) {
      (false, false) => 'execute',
      (false, true) => 'executeAsync',
      (true, false) => 'executeVoid',
      (true, true) => 'executeVoidAsync',
    };
    final request =
        refer(
          'DioOperationRequest',
          'package:$package/src/operation/$filename',
        ).newInstance([], {
          'path': path,
          'query': queryParameters,
          'data': isDataAsync ? data.awaited : data,
          'options': options,
        });
    return refer('this').property(methodName).call([], {
      'cancellation': plan.cancellation,
      'prepare': isDataAsync ? _asyncClosure(request) : _closure(request),
      'decode': decode ?? _noopDecoder(),
      if (streaming) 'isStreaming': refer('_isStreamingResponse'),
    });
  }

  @override
  Iterable<Spec> generate({bool includeStreaming = false}) => [
    _generateBase(),
    _generateOperationRequest(),
    _generatePreparedRequest(),
    _generateDispatchResult(),
    if (includeStreaming) ...[
      const DioOperationBaseGenerator(streaming: true)._generateBase(),
      const DioOperationBaseGenerator(streaming: true)
          ._generateDispatchResult(),
    ],
  ];

  Class _generateBase() => Class(
    (builder) => builder
      ..name = className
      ..abstract = true
      ..modifier = ClassModifier.base
      ..types.add(refer('T'))
      ..fields.addAll([
        Field(
          (field) => field
            ..name = 'baseUrl'
            ..type = refer('String', 'dart:core')
            ..modifier = FieldModifier.final$,
        ),
        Field(
          (field) => field
            ..name = 'clientAccessor'
            ..type = FunctionType(
              (type) => type..returnType = refer('Dio', 'package:dio/dio.dart'),
            )
            ..modifier = FieldModifier.final$,
        ),
      ])
      ..constructors.add(
        Constructor(
          (constructor) => constructor.requiredParameters.addAll([
            Parameter(
              (parameter) => parameter
                ..name = 'baseUrl'
                ..toThis = true,
            ),
            Parameter(
              (parameter) => parameter
                ..name = 'clientAccessor'
                ..toThis = true,
            ),
          ]),
        ),
      )
      ..methods.addAll([
        _executionMethod(isVoid: false, isDataAsync: false),
        _executionMethod(isVoid: false, isDataAsync: true),
        _executionMethod(isVoid: true, isDataAsync: false),
        _executionMethod(isVoid: true, isDataAsync: true),
        _completionMethod(isVoid: false),
        _completionMethod(isVoid: true),
        _syncDispatchMethod(),
        _dispatchMethod(),
      ]),
  );

  Method _executionMethod({required bool isVoid, required bool isDataAsync}) {
    final valueType = isVoid ? refer('void') : refer('T');
    final methodName = switch ((isVoid, isDataAsync)) {
      (false, false) => 'execute',
      (false, true) => 'executeAsync',
      (true, false) => 'executeVoid',
      (true, true) => 'executeVoidAsync',
    };
    return Method(
      (builder) => builder
        ..name = methodName
        ..returns = _futureResult(valueType)
        ..optionalParameters.addAll([
          _namedParameter(
            'cancellation',
            TypeReference(
              (type) => type
                ..symbol = 'TonikCancellation'
                ..url = 'package:tonik_util/tonik_util.dart'
                ..isNullable = true,
            ),
            isRequired: false,
          ),
          _namedParameter(
            'prepare',
            _functionType(
              isDataAsync
                  ? TypeReference(
                      (type) => type
                        ..symbol = 'Future'
                        ..url = 'dart:async'
                        ..types.add(refer('DioOperationRequest')),
                    )
                  : refer('DioOperationRequest'),
            ),
          ),
          _namedParameter(
            'decode',
            _functionType(valueType, [
              _completedResponse,
              if (streaming)
                refer(
                  'TonikCancellation',
                  'package:tonik_util/tonik_util.dart',
                ),
            ]),
          ),
          if (streaming)
            _namedParameter(
              'isStreaming',
              _functionType(refer('bool?', 'dart:core'), [_completedResponse]),
            ),
        ])
        ..modifier = isDataAsync ? MethodModifier.async : null
        ..body = Block.of([
          if (streaming) ...[
            const Code('cancellation ??= '),
            refer(
              'TonikCancellation',
              'package:tonik_util/tonik_util.dart',
            ).call([]).code,
            const Code(';'),
          ],
          const Code('late final '),
          refer('_DioPreparedRequest').code,
          const Code(' prepared;'),
          const Code('try {'),
          const Code('  final request = '),
          if (isDataAsync)
            const Code('await prepare();')
          else
            const Code('prepare();'),
          const Code('  final baseUri = '),
          refer(
            'Uri',
            'dart:core',
          ).property('parse').call([refer('baseUrl')]).code,
          const Code(';'),
          const Code('  final pathResult = request.path;'),
          const Code(r"""
  final newPath = baseUri.path.endsWith('/')
      ? '${baseUri.path.substring(0, baseUri.path.length - 1)}/${pathResult.join('/')}'
      : '${baseUri.path}/${pathResult.join('/')}';"""),
          const Code('  final uri = baseUri.replace('),
          const Code('    path: newPath,'),
          const Code('    query: request.query,'),
          const Code('  );'),
          const Code('  prepared = _DioPreparedRequest('),
          const Code('    uri,'),
          const Code('    request.data,'),
          const Code('    request.options,'),
          const Code('  );'),
          const Code('} on '),
          refer('Object', 'dart:core').code,
          const Code(' catch (exception, stackTrace) {'),
          _returnResult(
            _tonikError(valueType).call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer(
                  'TonikErrorType.encoding',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': literalNull,
              },
            ),
            isAsync: isDataAsync,
          ),
          const Code('}'),
          const Code(''),
          const Code('return '),
          refer(isVoid ? '_completeVoid' : '_complete').call([], {
            'dispatched': refer(isDataAsync ? '_dispatch' : '_dispatchSync')
                .call(
                  [],
                  {
                    'prepared': refer('prepared'),
                    'cancellation': refer('cancellation'),
                  },
                  [valueType],
                ),
            'decode': refer('decode'),
            if (streaming) 'cancellation': refer('cancellation'),
            if (streaming) 'isStreaming': refer('isStreaming'),
          }).code,
          const Code(';'),
        ]),
    );
  }

  Method _syncDispatchMethod() => Method(
    (builder) => builder
      ..name = '_dispatchSync'
      ..types.add(refer('V'))
      ..returns = TypeReference(
        (type) => type
          ..symbol = 'Future'
          ..url = 'dart:async'
          ..types.add(
            TypeReference(
              (result) => result
                ..symbol = streaming
                    ? '_DioStreamingDispatchResult'
                    : '_DioDispatchResult'
                ..types.add(refer('V')),
            ),
          ),
      )
      ..optionalParameters.addAll([
        _namedParameter('prepared', refer('_DioPreparedRequest')),
        _namedParameter(
          'cancellation',
          TypeReference(
            (type) => type
              ..symbol = 'TonikCancellation'
              ..url = 'package:tonik_util/tonik_util.dart'
              ..isNullable = true,
          ),
        ),
      ])
      ..body = Block.of([
        refer('CancelToken?', 'package:dio/dio.dart').code,
        const Code(' cancelToken;'),
        const Code('if (cancellation != null) {'),
        const Code('  cancelToken = '),
        refer('CancelToken', 'package:dio/dio.dart').newInstance([]).code,
        const Code(';'),
        const Code('  if (cancellation.isCancelled) {'),
        const Code('    cancelToken.cancel(cancellation.reason);'),
        const Code('    return '),
        refer('Future', 'dart:async').property('value').call([
          refer(
            streaming
                ? '_DioStreamingDispatchResult<V>'
                : '_DioDispatchResult<V>',
          ).call([
            _tonikError(refer('V')).call(
              [refer('cancelToken.cancelError!')],
              {
                'stackTrace': refer('cancelToken.cancelError!.stackTrace'),
                'type': refer(
                  'TonikErrorType.cancelled',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': literalNull,
              },
            ),
            literalNull,
          ]),
        ]).code,
        const Code(';'),
        const Code('  }'),
        refer('unawaited', 'dart:async').call([
          refer('cancellation.whenCancelled.then').call([
            Method(
              (method) => method
                ..requiredParameters.add(Parameter((p) => p..name = '_'))
                ..body = const Code(
                  'cancelToken!.cancel(cancellation.reason);',
                ),
            ).closure,
          ]),
        ]).statement,
        const Code('}'),
        const Code('late final '),
        refer('Dio', 'package:dio/dio.dart').code,
        const Code(' client;'),
        const Code('try {'),
        const Code('  client = clientAccessor();'),
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  return '),
        refer('Future', 'dart:async').property('value').call([
          refer(
            streaming
                ? '_DioStreamingDispatchResult<V>'
                : '_DioDispatchResult<V>',
          ).call([
            _tonikError(refer('V')).call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer(
                  'TonikErrorType.other',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': literalNull,
              },
            ),
            literalNull,
          ]),
        ]).code,
        const Code(';'),
        const Code('}'),
        const Code('try {'),
        const Code('  final response = client.requestUri<'),
        _completedResponse.types.single.code,
        const Code('>('),
        const Code('    prepared.uri,'),
        const Code('    data: prepared.data,'),
        const Code('    options: prepared.options'),
        if (streaming) ...[
          const Code('.copyWith(responseType: '),
          refer('ResponseType.stream', 'package:dio/dio.dart').code,
          const Code(')'),
        ],
        const Code(','),
        const Code('    cancelToken: cancelToken,'),
        const Code('  );'),
        Code(
          streaming
              ? '  return response.then<_DioStreamingDispatchResult<V>>('
              : '  return response.then<_DioDispatchResult<V>>(',
        ),
        Code(
          streaming
              ? '    (value) => _DioStreamingDispatchResult<V>(null, value),'
              : '    (value) => _DioDispatchResult<V>(null, value),',
        ),
        const Code('    onError: (exception, stackTrace) {'),
        const Code('      if (exception is '),
        refer('DioException', 'package:dio/dio.dart').code,
        const Code(') {'),
        const Code('        final type = exception.type == '),
        refer('DioExceptionType.cancel', 'package:dio/dio.dart').code,
        const Code(' ? '),
        refer(
          'TonikErrorType.cancelled',
          'package:tonik_util/tonik_util.dart',
        ).code,
        const Code(' : '),
        refer(
          'TonikErrorType.network',
          'package:tonik_util/tonik_util.dart',
        ).code,
        const Code(';'),
        Code(
          streaming
              ? '        return _DioStreamingDispatchResult<V>('
              : '        return _DioDispatchResult<V>(',
        ),
        _tonikError(refer('V'))
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer('type'),
                'response': refer('exception.response'),
              },
            )
            .code,
        const Code(', null);'),
        const Code('      }'),
        Code(
          streaming
              ? '      return _DioStreamingDispatchResult<V>('
              : '      return _DioDispatchResult<V>(',
        ),
        _tonikError(refer('V'))
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer(
                  'TonikErrorType.network',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': literalNull,
              },
            )
            .code,
        const Code(', null);'),
        const Code('    },'),
        const Code('  );'),
        const Code('} on '),
        refer('DioException', 'package:dio/dio.dart').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  final type = exception.type == '),
        refer('DioExceptionType.cancel', 'package:dio/dio.dart').code,
        const Code(' ? '),
        refer(
          'TonikErrorType.cancelled',
          'package:tonik_util/tonik_util.dart',
        ).code,
        const Code(' : '),
        refer(
          'TonikErrorType.network',
          'package:tonik_util/tonik_util.dart',
        ).code,
        const Code(';'),
        const Code('  return '),
        refer('Future', 'dart:async').property('value').call([
          refer(
            streaming
                ? '_DioStreamingDispatchResult<V>'
                : '_DioDispatchResult<V>',
          ).call([
            _tonikError(refer('V')).call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer('type'),
                'response': refer('exception.response'),
              },
            ),
            literalNull,
          ]),
        ]).code,
        const Code(';'),
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  return '),
        refer('Future', 'dart:async').property('value').call([
          refer(
            streaming
                ? '_DioStreamingDispatchResult<V>'
                : '_DioDispatchResult<V>',
          ).call([
            _tonikError(refer('V')).call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer(
                  'TonikErrorType.network',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': literalNull,
              },
            ),
            literalNull,
          ]),
        ]).code,
        const Code(';'),
        const Code('}'),
      ]),
  );

  Method _completionMethod({required bool isVoid}) {
    final valueType = isVoid ? refer('void') : refer('T');
    return Method(
      (builder) => builder
        ..name = isVoid ? '_completeVoid' : '_complete'
        ..returns = _futureResult(valueType)
        ..optionalParameters.addAll([
          if (streaming)
            _namedParameter(
              'cancellation',
              refer('TonikCancellation', 'package:tonik_util/tonik_util.dart'),
            ),
          _namedParameter(
            'dispatched',
            TypeReference(
              (type) => type
                ..symbol = 'Future'
                ..url = 'dart:async'
                ..types.add(
                  TypeReference(
                    (result) => result
                      ..symbol = streaming
                          ? '_DioStreamingDispatchResult'
                          : '_DioDispatchResult'
                      ..types.add(valueType),
                  ),
                ),
            ),
          ),
          _namedParameter(
            'decode',
            _functionType(valueType, [
              _completedResponse,
              if (streaming)
                refer(
                  'TonikCancellation',
                  'package:tonik_util/tonik_util.dart',
                ),
            ]),
          ),
          if (streaming)
            _namedParameter(
              'isStreaming',
              _functionType(refer('bool?', 'dart:core'), [_completedResponse]),
            ),
        ])
        ..modifier = MethodModifier.async
        ..body = Block.of([
          const Code('final result = await dispatched;'),
          const Code('final error = result.error;'),
          const Code('if (error != null) return error;'),
          const Code('final response = result.response!;'),
          if (!isVoid) const Code('final T value;'),
          const Code('try {'),
          if (streaming) ..._selectResponse(valueType),
          if (isVoid)
            Code(
              streaming
                  ? 'decode(response, cancellation);'
                  : 'decode(response);',
            )
          else
            Code(
              streaming
                  ? 'value = decode(response, cancellation);'
                  : 'value = decode(response);',
            ),
          const Code('} on '),
          refer('Object', 'dart:core').code,
          const Code(' catch (exception, stackTrace) {'),
          if (streaming) const Code('cancellation.cancel(exception);'),
          _tonikError(valueType)
              .call(
                [refer('exception')],
                {
                  'stackTrace': refer('stackTrace'),
                  'type': refer(
                    'TonikErrorType.decoding',
                    'package:tonik_util/tonik_util.dart',
                  ),
                  'response': refer('response'),
                },
              )
              .returned
              .statement,
          const Code('}'),
          _tonikSuccess(valueType)
              .call([
                if (isVoid) literalNull else refer('value'),
                refer('response'),
              ])
              .returned
              .statement,
        ]),
    );
  }

  Method _dispatchMethod() => Method(
    (builder) => builder
      ..name = '_dispatch'
      ..types.add(refer('V'))
      ..returns = TypeReference(
        (type) => type
          ..symbol = 'Future'
          ..url = 'dart:async'
          ..types.add(
            TypeReference(
              (result) => result
                ..symbol = streaming
                    ? '_DioStreamingDispatchResult'
                    : '_DioDispatchResult'
                ..types.add(refer('V')),
            ),
          ),
      )
      ..optionalParameters.addAll([
        _namedParameter('prepared', refer('_DioPreparedRequest')),
        _namedParameter(
          'cancellation',
          TypeReference(
            (type) => type
              ..symbol = 'TonikCancellation'
              ..url = 'package:tonik_util/tonik_util.dart'
              ..isNullable = true,
          ),
        ),
      ])
      ..modifier = MethodModifier.async
      ..body = Block.of([
        const Code(''),
        refer('CancelToken?', 'package:dio/dio.dart').code,
        const Code(' cancelToken;'),
        const Code('if (cancellation != null) {'),
        const Code('  cancelToken = '),
        refer('CancelToken', 'package:dio/dio.dart').newInstance([]).code,
        const Code(';'),
        const Code('  if (cancellation.isCancelled) {'),
        const Code('    cancelToken.cancel(cancellation.reason);'),
        Code(
          streaming
              ? '    return _DioStreamingDispatchResult<V>('
              : '    return _DioDispatchResult<V>(',
        ),
        _tonikError(refer('V'))
            .call(
              [refer('cancelToken.cancelError!')],
              {
                'stackTrace': refer('cancelToken.cancelError!.stackTrace'),
                'type': refer(
                  'TonikErrorType.cancelled',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': literalNull,
              },
            )
            .code,
        const Code(', null);'),
        const Code('  }'),
        refer('unawaited', 'dart:async').call([
          refer('cancellation.whenCancelled.then').call([
            Method(
              (method) => method
                ..requiredParameters.add(Parameter((p) => p..name = '_'))
                ..body = const Code(
                  'cancelToken!.cancel(cancellation.reason);',
                ),
            ).closure,
          ]),
        ]).statement,
        const Code('}'),
        const Code(''),
        const Code('final '),
        refer('Dio', 'package:dio/dio.dart').code,
        const Code(' client;'),
        const Code('try {'),
        const Code('  client = clientAccessor();'),
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        Code(
          streaming
              ? '  return _DioStreamingDispatchResult<V>('
              : '  return _DioDispatchResult<V>(',
        ),
        _tonikError(refer('V'))
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer(
                  'TonikErrorType.other',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': literalNull,
              },
            )
            .code,
        const Code(', null);'),
        const Code('}'),
        const Code(''),
        const Code('final '),
        _completedResponse.code,
        const Code(' response;'),
        const Code('try {'),
        const Code('  response = await client.requestUri<'),
        _completedResponse.types.single.code,
        const Code('>('),
        const Code('    prepared.uri,'),
        const Code('    data: prepared.data,'),
        const Code('    options: prepared.options'),
        if (streaming) ...[
          const Code('.copyWith(responseType: '),
          refer('ResponseType.stream', 'package:dio/dio.dart').code,
          const Code(')'),
        ],
        const Code(','),
        const Code('    cancelToken: cancelToken,'),
        const Code('  );'),
        const Code('} on '),
        refer('DioException', 'package:dio/dio.dart').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  if (exception.type == '),
        refer('DioExceptionType.cancel', 'package:dio/dio.dart').code,
        const Code(') {'),
        Code(
          streaming
              ? '    return _DioStreamingDispatchResult<V>('
              : '    return _DioDispatchResult<V>(',
        ),
        _tonikError(refer('V'))
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer(
                  'TonikErrorType.cancelled',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': refer('exception.response'),
              },
            )
            .code,
        const Code(', null);'),
        const Code('  }'),
        Code(
          streaming
              ? '  return _DioStreamingDispatchResult<V>('
              : '  return _DioDispatchResult<V>(',
        ),
        _tonikError(refer('V'))
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer(
                  'TonikErrorType.network',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': refer('exception.response'),
              },
            )
            .code,
        const Code(', null);'),
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        Code(
          streaming
              ? '  return _DioStreamingDispatchResult<V>('
              : '  return _DioDispatchResult<V>(',
        ),
        _tonikError(refer('V'))
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer(
                  'TonikErrorType.network',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': literalNull,
              },
            )
            .code,
        const Code(', null);'),
        const Code('}'),
        Code(
          streaming
              ? 'return _DioStreamingDispatchResult<V>(null, response);'
              : 'return _DioDispatchResult<V>(null, response);',
        ),
      ]),
  );

  List<Code> _selectResponse(Reference valueType) => [
    const Code('final streamingBody = isStreaming(response);'),
    const Code('if (streamingBody == false) {'),
    const Code('try { response.data = await (response.data as '),
    refer('ResponseBody', 'package:dio/dio.dart').code,
    const Code(').stream.fold<'),
    TypeReference(
      (b) => b
        ..symbol = 'List'
        ..url = 'dart:core'
        ..types.add(refer('int', 'dart:core')),
    ).code,
    const Code('>([], (bytes, chunk) => bytes..addAll(chunk));'),
    const Code('} on '),
    refer('Object', 'dart:core').code,
    const Code(' catch (exception, stackTrace) {'),
    const Code('final type = exception is '),
    refer('DioException', 'package:dio/dio.dart').code,
    const Code(' && exception.type == '),
    refer('DioExceptionType.cancel', 'package:dio/dio.dart').code,
    const Code(' ? '),
    refer(
      'TonikErrorType.cancelled',
      'package:tonik_util/tonik_util.dart',
    ).code,
    const Code(' : '),
    refer('TonikErrorType.network', 'package:tonik_util/tonik_util.dart').code,
    const Code('; cancellation.cancel(exception);'),
    _tonikError(valueType)
        .call(
          [refer('exception')],
          {
            'stackTrace': refer('stackTrace'),
            'type': refer('type'),
            'response': refer('response'),
          },
        )
        .returned
        .statement,
    const Code(
      '} } else if (streamingBody == null) { cancellation.cancel(); }',
    ),
  ];

  Class _generateOperationRequest() => Class(
    (builder) => builder
      ..name = 'DioOperationRequest'
      ..modifier = ClassModifier.final$
      ..fields.addAll([
        _finalField(
          'path',
          TypeReference(
            (type) => type
              ..symbol = 'List'
              ..url = 'dart:core'
              ..types.add(refer('String', 'dart:core')),
          ),
        ),
        _finalField('query', refer('String?', 'dart:core')),
        _finalField('data', refer('Object?', 'dart:core')),
        _finalField('options', refer('Options', 'package:dio/dio.dart')),
      ])
      ..constructors.add(
        _namedThisConstructor(['path', 'query', 'data', 'options']),
      ),
  );

  Class _generatePreparedRequest() => Class(
    (builder) => builder
      ..name = '_DioPreparedRequest'
      ..fields.addAll([
        _finalField('uri', refer('Uri', 'dart:core')),
        _finalField('data', refer('Object?', 'dart:core')),
        _finalField('options', refer('Options', 'package:dio/dio.dart')),
      ])
      ..constructors.add(_thisConstructor(['uri', 'data', 'options'])),
  );

  Class _generateDispatchResult() => Class(
    (builder) => builder
      ..name = streaming ? '_DioStreamingDispatchResult' : '_DioDispatchResult'
      ..types.add(refer('T'))
      ..fields.addAll([
        _finalField(
          'error',
          TypeReference(
            (type) => type
              ..symbol = 'TonikError'
              ..url = 'package:tonik_util/tonik_util.dart'
              ..types.addAll([refer('T'), _nativeResponse])
              ..isNullable = true,
          ),
        ),
        _finalField(
          'response',
          _completedResponse.rebuild((builder) => builder..isNullable = true),
        ),
      ])
      ..constructors.add(_thisConstructor(['error', 'response'])),
  );

  TypeReference _futureResult(Reference valueType) => TypeReference(
    (type) => type
      ..symbol = 'Future'
      ..url = 'dart:async'
      ..types.add(_tonikResult(valueType)),
  );

  TypeReference _tonikResult(Reference valueType) => TypeReference(
    (type) => type
      ..symbol = 'TonikResult'
      ..url = 'package:tonik_util/tonik_util.dart'
      ..types.addAll([valueType, _nativeResponse]),
  );

  TypeReference _tonikError(Reference valueType) => TypeReference(
    (type) => type
      ..symbol = 'TonikError'
      ..url = 'package:tonik_util/tonik_util.dart'
      ..types.addAll([valueType, _nativeResponse]),
  );

  TypeReference _tonikSuccess(Reference valueType) => TypeReference(
    (type) => type
      ..symbol = 'TonikSuccess'
      ..url = 'package:tonik_util/tonik_util.dart'
      ..types.addAll([valueType, _nativeResponse]),
  );
}

Parameter _namedParameter(
  String name,
  Reference type, {
  bool isRequired = true,
}) => Parameter(
  (builder) => builder
    ..name = name
    ..type = type
    ..named = true
    ..required = isRequired,
);

FunctionType _functionType(
  Reference returnType, [
  List<Reference> parameters = const [],
]) => FunctionType(
  (builder) => builder
    ..returnType = returnType
    ..requiredParameters.addAll(parameters),
);

Expression _closure(Expression expression) => Method(
  (builder) => builder
    ..lambda = true
    ..body = expression.code,
).closure;

Expression _asyncClosure(Expression expression) => Method(
  (builder) => builder
    ..lambda = true
    ..modifier = MethodModifier.async
    ..body = expression.code,
).closure;

Expression _noopDecoder() => Method(
  (builder) => builder
    ..requiredParameters.add(Parameter((parameter) => parameter..name = '_'))
    ..body = const Code(''),
).closure;

Field _finalField(String name, Reference type) => Field(
  (builder) => builder
    ..name = name
    ..type = type
    ..modifier = FieldModifier.final$,
);

Constructor _thisConstructor(List<String> fields) => Constructor(
  (builder) => builder.requiredParameters.addAll([
    for (final field in fields)
      Parameter(
        (parameter) => parameter
          ..name = field
          ..toThis = true,
      ),
  ]),
);

Constructor _namedThisConstructor(List<String> fields) => Constructor(
  (builder) => builder.optionalParameters.addAll([
    for (final field in fields)
      Parameter(
        (parameter) => parameter
          ..name = field
          ..toThis = true
          ..named = true
          ..required = true,
      ),
  ]),
);

Code _returnResult(Expression result, {required bool isAsync}) => isAsync
    ? result.returned.statement
    : refer(
        'Future',
        'dart:async',
      ).property('value').call([result]).returned.statement;
