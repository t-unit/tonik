import 'package:code_builder/code_builder.dart';
import 'package:tonik_generate/src/operation/operation_base_generator.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';

final class HttpOperationBaseGenerator implements OperationBaseGenerator {
  const HttpOperationBaseGenerator();

  static final Reference _nativeResponse = refer(
    'Response',
    'package:http/http.dart',
  );

  @override
  String get className => 'HttpOperation';

  @override
  String get filename => 'http_operation.dart';

  @override
  String get clientConstructorParameterName => 'clientAccessor';

  @override
  Reference baseType({
    required String package,
    required Reference valueType,
    String? filename,
  }) => TypeReference(
    (builder) => builder
      ..symbol = className
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
  }) {
    final methodName = switch ((isVoid, isDataAsync)) {
      (false, false) => 'execute',
      (false, true) => 'executeAsync',
      (true, false) => 'executeVoid',
      (true, true) => 'executeVoidAsync',
    };
    final request =
        refer(
          'HttpOperationRequest',
          'package:$package/src/operation/$filename',
        ).newInstance([], {
          'method': literalString(plan.methodName),
          'path': path,
          'query': queryParameters,
          'data': isDataAsync ? data.awaited : data,
          'options': options,
        });
    return refer('this').property(methodName).call([], {
      'cancellation': plan.cancellation,
      'prepare': isDataAsync ? _asyncClosure(request) : _closure(request),
      'decode': decode ?? _noopDecoder(),
    });
  }

  @override
  Iterable<Spec> generate() => [
    _generateBase(),
    _generateOperationRequest(),
    _generatePreparedRequest(),
    _generateDispatchResult(),
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
              (type) =>
                  type..returnType = refer('Client', 'package:http/http.dart'),
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
        _dispatchMethod(),
        _abortErrorTypeMethod(),
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
                        ..types.add(refer('HttpOperationRequest')),
                    )
                  : refer('HttpOperationRequest'),
            ),
          ),
          _namedParameter(
            'decode',
            _functionType(valueType, [_nativeResponse]),
          ),
        ])
        ..modifier = MethodModifier.async
        ..body = Block.of([
          const Code('late final '),
          refer('HttpOperationRequest').code,
          const Code(' request;'),
          const Code('late final '),
          refer('_HttpPreparedRequest').code,
          const Code(' prepared;'),
          const Code('try {'),
          const Code('  request = '),
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
          const Code('  prepared = _HttpPreparedRequest('),
          const Code('    uri,'),
          const Code('    request.data,'),
          const Code('    request.options,'),
          const Code('  );'),
          const Code('} on '),
          refer('Object', 'dart:core').code,
          const Code(' catch (exception, stackTrace) {'),
          _tonikError(valueType)
              .call(
                [refer('exception')],
                {
                  'stackTrace': refer('stackTrace'),
                  'type': refer(
                    'TonikErrorType.encoding',
                    'package:tonik_util/tonik_util.dart',
                  ),
                  'response': literalNull,
                },
              )
              .returned
              .statement,
          const Code('}'),
          const Code(''),
          const Code('final dispatched = await _dispatch<'),
          valueType.code,
          const Code('>('),
          const Code('  method: request.method,'),
          const Code('  prepared: prepared,'),
          const Code('  cancellation: cancellation,'),
          const Code(');'),
          const Code('final error = dispatched.error;'),
          const Code('if (error != null) return error;'),
          const Code('final response = dispatched.response!;'),
          const Code(''),
          if (isVoid) ...[
            const Code('try {'),
            const Code('  decode(response);'),
            const Code('} on '),
            refer('Object', 'dart:core').code,
            const Code(' catch (exception, stackTrace) {'),
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
            _tonikSuccess(
              valueType,
            ).call([literalNull, refer('response')]).returned.statement,
          ] else ...[
            const Code('final T value;'),
            const Code('try {'),
            const Code('  value = decode(response);'),
            const Code('} on '),
            refer('Object', 'dart:core').code,
            const Code(' catch (exception, stackTrace) {'),
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
            _tonikSuccess(
              valueType,
            ).call([refer('value'), refer('response')]).returned.statement,
          ],
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
                ..symbol = '_HttpDispatchResult'
                ..types.add(refer('V')),
            ),
          ),
      )
      ..optionalParameters.addAll([
        _namedParameter('method', refer('String', 'dart:core')),
        _namedParameter('prepared', refer('_HttpPreparedRequest')),
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
        const Code('if (cancellation != null && cancellation.isCancelled) {'),
        const Code('  final exception = '),
        refer(
          'RequestAbortedException',
          'package:http/http.dart',
        ).newInstance([refer('prepared.uri')]).code,
        const Code(';'),
        const Code('  return _HttpDispatchResult<V>('),
        _tonikError(refer('V'))
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('StackTrace.current', 'dart:core'),
                'type': refer(
                  'TonikErrorType.cancelled',
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
        refer('Client', 'package:http/http.dart').code,
        const Code(' resolvedClient;'),
        const Code('try {'),
        const Code('  resolvedClient = clientAccessor();'),
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  return _HttpDispatchResult<V>('),
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
        const Code('late final '),
        refer('BaseRequest', 'package:http/http.dart').code,
        const Code(' request;'),
        const Code('try {'),
        const Code('  final data = prepared.data;'),
        const Code('  if (data is '),
        refer('TonikMultipartBody', 'package:tonik_util/tonik_util.dart').code,
        const Code(') {'),
        const Code('    final bodyRequest = '),
        refer('AbortableRequest', 'package:http/http.dart')
            .newInstance(
              [refer('method'), refer('prepared.uri')],
              {'abortTrigger': refer('cancellation?.whenCancelled')},
            )
            .code,
        const Code(';'),
        const Code('    bodyRequest.bodyBytes = data.bodyBytes;'),
        const Code('    request = bodyRequest;'),
        const Code('  } else if (data is '),
        TypeReference(
          (type) => type
            ..symbol = 'List'
            ..url = 'dart:core'
            ..types.add(refer('MultipartFile', 'package:http/http.dart')),
        ).code,
        const Code(') {'),
        const Code('    final multipartRequest = '),
        refer('AbortableMultipartRequest', 'package:http/http.dart')
            .newInstance(
              [refer('method'), refer('prepared.uri')],
              {'abortTrigger': refer('cancellation?.whenCancelled')},
            )
            .code,
        const Code(';'),
        const Code('    multipartRequest.fields.addAll(const <'),
        refer('String', 'dart:core').code,
        const Code(', '),
        refer('String', 'dart:core').code,
        const Code('>{});'),
        const Code('    multipartRequest.files.addAll(data);'),
        const Code('    request = multipartRequest;'),
        const Code('  } else {'),
        const Code('    final ordinaryRequest = '),
        refer('AbortableRequest', 'package:http/http.dart')
            .newInstance(
              [refer('method'), refer('prepared.uri')],
              {'abortTrigger': refer('cancellation?.whenCancelled')},
            )
            .code,
        const Code(';'),
        const Code('    if (data case final '),
        TypeReference(
          (type) => type
            ..symbol = 'List'
            ..url = 'dart:core'
            ..types.add(refer('int', 'dart:core')),
        ).code,
        const Code(' bodyBytes) {'),
        const Code('      ordinaryRequest.bodyBytes = bodyBytes;'),
        const Code('    } else if (data != null) {'),
        const Code('      throw '),
        refer('StateError', 'dart:core').newInstance([
          literalString('Unexpected HTTP request body type.'),
        ]).code,
        const Code(';'),
        const Code('    }'),
        const Code('    request = ordinaryRequest;'),
        const Code('  }'),
        const Code('  request.headers.addAll(prepared.options);'),
        const Code('  if (data is '),
        refer('TonikMultipartBody', 'package:tonik_util/tonik_util.dart').code,
        const Code(') {'),
        const Code("    request.headers['content-type'] = data.contentType;"),
        const Code('  }'),
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  return _HttpDispatchResult<V>('),
        _tonikError(refer('V'))
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer(
                  'TonikErrorType.encoding',
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
        refer('StreamedResponse', 'package:http/http.dart').code,
        const Code(' streamedResponse;'),
        const Code('try {'),
        const Code('  streamedResponse = await resolvedClient.send(request);'),
        const Code('} on '),
        refer('RequestAbortedException', 'package:http/http.dart').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  return _HttpDispatchResult<V>('),
        _transportError(
          refer('V'),
          refer('_requestAbortErrorType(cancellation)'),
        ).code,
        const Code(', null);'),
        const Code('} on '),
        refer('ClientException', 'package:http/http.dart').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  return _HttpDispatchResult<V>('),
        _transportError(
          refer('V'),
          refer('TonikErrorType.network', 'package:tonik_util/tonik_util.dart'),
        ).code,
        const Code(', null);'),
        const Code('} on '),
        refer('TimeoutException', 'dart:async').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  return _HttpDispatchResult<V>('),
        _transportError(
          refer('V'),
          refer('TonikErrorType.network', 'package:tonik_util/tonik_util.dart'),
        ).code,
        const Code(', null);'),
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  return _HttpDispatchResult<V>('),
        _transportError(
          refer('V'),
          refer('TonikErrorType.other', 'package:tonik_util/tonik_util.dart'),
        ).code,
        const Code(', null);'),
        const Code('}'),
        const Code(''),
        const Code('final '),
        _nativeResponse.code,
        const Code(' response;'),
        const Code('try {'),
        const Code('  response = await '),
        refer(
          'Response',
          'package:http/http.dart',
        ).property('fromStream').call([refer('streamedResponse')]).code,
        const Code(';'),
        const Code('} on '),
        refer('RequestAbortedException', 'package:http/http.dart').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  return _HttpDispatchResult<V>('),
        _transportError(
          refer('V'),
          refer('_requestAbortErrorType(cancellation)'),
        ).code,
        const Code(', null);'),
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        const Code('  return _HttpDispatchResult<V>('),
        _transportError(
          refer('V'),
          refer('TonikErrorType.network', 'package:tonik_util/tonik_util.dart'),
        ).code,
        const Code(', null);'),
        const Code('}'),
        const Code('return _HttpDispatchResult<V>(null, response);'),
      ]),
  );

  Method _abortErrorTypeMethod() => Method(
    (builder) => builder
      ..name = '_requestAbortErrorType'
      ..returns = refer('TonikErrorType', 'package:tonik_util/tonik_util.dart')
      ..requiredParameters.add(
        Parameter(
          (parameter) => parameter
            ..name = 'cancellation'
            ..type = TypeReference(
              (type) => type
                ..symbol = 'TonikCancellation'
                ..url = 'package:tonik_util/tonik_util.dart'
                ..isNullable = true,
            ),
        ),
      )
      ..lambda = true
      ..body = Block.of([
        const Code('cancellation?.isCancelled ?? false ? '),
        refer(
          'TonikErrorType.cancelled',
          'package:tonik_util/tonik_util.dart',
        ).code,
        const Code(' : '),
        refer(
          'TonikErrorType.network',
          'package:tonik_util/tonik_util.dart',
        ).code,
      ]),
  );

  Class _generateOperationRequest() => Class(
    (builder) => builder
      ..name = 'HttpOperationRequest'
      ..modifier = ClassModifier.final$
      ..fields.addAll([
        _finalField('method', refer('String', 'dart:core')),
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
        _finalField(
          'options',
          TypeReference(
            (type) => type
              ..symbol = 'Map'
              ..url = 'dart:core'
              ..types.addAll([
                refer('String', 'dart:core'),
                refer('String', 'dart:core'),
              ]),
          ),
        ),
      ])
      ..constructors.add(
        _namedThisConstructor(['method', 'path', 'query', 'data', 'options']),
      ),
  );

  Class _generatePreparedRequest() => Class(
    (builder) => builder
      ..name = '_HttpPreparedRequest'
      ..fields.addAll([
        _finalField('uri', refer('Uri', 'dart:core')),
        _finalField('data', refer('Object?', 'dart:core')),
        _finalField(
          'options',
          TypeReference(
            (type) => type
              ..symbol = 'Map'
              ..url = 'dart:core'
              ..types.addAll([
                refer('String', 'dart:core'),
                refer('String', 'dart:core'),
              ]),
          ),
        ),
      ])
      ..constructors.add(_thisConstructor(['uri', 'data', 'options'])),
  );

  Class _generateDispatchResult() => Class(
    (builder) => builder
      ..name = '_HttpDispatchResult'
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
          TypeReference(
            (type) => type
              ..symbol = 'Response'
              ..url = 'package:http/http.dart'
              ..isNullable = true,
          ),
        ),
      ])
      ..constructors.add(_thisConstructor(['error', 'response'])),
  );

  Expression _transportError(Reference valueType, Expression type) =>
      _tonikError(valueType).call(
        [refer('exception')],
        {
          'stackTrace': refer('stackTrace'),
          'type': type,
          'response': literalNull,
        },
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
