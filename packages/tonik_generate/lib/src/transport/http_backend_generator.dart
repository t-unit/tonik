import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/http/http_body_generator.dart';
import 'package:tonik_generate/src/transport/http/http_headers_generator.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_generator.dart';
import 'package:tonik_generate/src/transport/http/http_multipart_support_generator.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

final class HttpBackendGenerator implements TransportBackendGenerator {
  const HttpBackendGenerator();

  @override
  List<DependencyDescriptor> get dependencies => const [
    DependencyDescriptor(name: 'http', versionConstraint: '^1.6.0'),
  ];

  @override
  Reference get nativeClientType => refer('Client', 'package:http/http.dart');

  @override
  TypeReference get nativeResponseType => TypeReference(
    (b) => b
      ..symbol = 'Response'
      ..url = 'package:http/http.dart',
  );

  @override
  TypeReference get operationResponseType => TypeReference(
    (b) => b
      ..symbol = 'Response'
      ..url = 'package:http/http.dart',
  );

  @override
  Reference get requestOptionsType => TypeReference(
    (b) => b
      ..symbol = 'Map'
      ..url = 'dart:core'
      ..types.addAll([
        refer('String', 'dart:core'),
        refer('String', 'dart:core'),
      ]),
  );

  @override
  Parameter get cancellationParameter => Parameter(
    (b) => b
      ..name = 'cancellation'
      ..type = TypeReference(
        (b) => b
          ..symbol = 'TonikCancellation'
          ..url = 'package:tonik_util/tonik_util.dart'
          ..isNullable = true,
      )
      ..named = true
      ..required = false,
  );

  @override
  bool get responseStatusCodeIsNullable => false;

  @override
  Expression responseStatusCode(Expression response) =>
      response.property('statusCode');

  @override
  Expression responseContentType(Expression response) =>
      response.property('headers').index(literalString('content-type'));

  @override
  Expression responseBodyBytes(Expression response) =>
      response.property('bodyBytes');

  @override
  Expression responseHeaderValues(Expression response, String name) {
    final value = response
        .property('headers')
        .index(specLiteralString(name.toLowerCase()));
    return value
        .equalTo(literalNull)
        .conditional(
          literalNull,
          literalList([value.nullChecked], refer('String', 'dart:core')),
        )
        .parenthesized;
  }

  @override
  Reference get serverConfigType => TypeReference(
    (b) => b
      ..symbol = 'ServerConfig'
      ..url = 'package:tonik_util/tonik_util.dart'
      ..types.add(nativeClientType),
  );

  @override
  String get clientGetterName => 'client';

  @override
  String get clientAccessorFieldName => '_client';

  @override
  Reference get nativeClientAccessorType => FunctionType(
    (b) => b..returnType = nativeClientType,
  );

  @override
  String get clientAdapterName => '_HttpClientAdapter';

  @override
  String get clientAdapterFieldName => r'_$httpClientAdapter';

  @override
  List<Expression> clientAdapterConstructorArguments({
    required Expression baseUrl,
    required Expression serverConfig,
  }) => [serverConfig];

  @override
  Class generateClientAdapter() {
    final clientType = nativeClientType;

    return Class(
      (b) => b
        ..name = clientAdapterName
        ..fields.addAll([
          Field(
            (f) => f
              ..name = 'serverConfig'
              ..type = serverConfigType
              ..modifier = FieldModifier.final$,
          ),
          Field(
            (f) => f
              ..name = r'_$client'
              ..type = TypeReference(
                (b) => b
                  ..symbol = 'Client'
                  ..url = 'package:http/http.dart'
                  ..isNullable = true,
              ),
          ),
          Field(
            (f) => f
              ..name = r'_$ownsClient'
              ..type = refer('bool', 'dart:core')
              ..assignment = literalFalse.code,
          ),
          Field(
            (f) => f
              ..name = r'_$isClosed'
              ..type = refer('bool', 'dart:core')
              ..assignment = literalFalse.code,
          ),
          Field(
            (f) => f
              ..name = r'_$closedError'
              ..type = refer('StateError', 'dart:core')
              ..modifier = FieldModifier.final$
              ..assignment = refer('StateError', 'dart:core').newInstance([
                literalString(
                  'Cannot access the HTTP client after the server has been '
                  'closed.',
                ),
              ]).code,
          ),
        ])
        ..constructors.add(
          Constructor(
            (c) => c.requiredParameters.add(
              Parameter(
                (p) => p
                  ..name = 'serverConfig'
                  ..toThis = true,
              ),
            ),
          ),
        )
        ..methods.addAll([
          Method(
            (m) => m
              ..name = clientGetterName
              ..type = MethodType.getter
              ..returns = clientType
              ..body = Block.of([
                const Code(r'if (_$isClosed) {'),
                const Code(r'  throw _$closedError;'),
                const Code('}'),
                const Code(''),
                const Code(r'final cachedClient = _$client;'),
                const Code('if (cachedClient != null) {'),
                const Code('  return cachedClient;'),
                const Code('}'),
                const Code(''),
                const Code('final configuredClient = serverConfig.client;'),
                const Code(
                  'final resolvedClient = configuredClient ?? '
                  'serverConfig.clientFactory?.call() ?? ',
                ),
                clientType.newInstance([]).code,
                const Code(';'),
                const Code(r'_$ownsClient = configuredClient == null;'),
                const Code(r'return _$client = resolvedClient;'),
              ]),
          ),
          Method(
            (m) => m
              ..name = 'close'
              ..returns = refer('void')
              ..body = Block.of([
                const Code(r'if (_$isClosed) {'),
                const Code('  return;'),
                const Code('}'),
                const Code(''),
                const Code(r'_$isClosed = true;'),
                const Code(r'if (_$ownsClient) {'),
                const Code(r'  _$client?.close();'),
                const Code('}'),
              ]),
          ),
        ]),
    );
  }

  @override
  Iterable<Spec> generateOperationSupport(Operation operation) {
    final hasMultipart =
        operation.requestBody?.resolvedContent.any(
          (content) => content.contentType == ContentType.multipart,
        ) ??
        false;
    if (!hasMultipart) return const [];

    final multipartContents = operation.requestBody!.resolvedContent.where(
      (content) => content.contentType == ContentType.multipart,
    );
    final includesPartHeaders = extractOperationMultipartHeaderParamInfo(
      operation,
    ).any((header) => header.rawHeaderName.toLowerCase() != 'content-type');
    return buildHttpMultipartSupport(
      includesPartHeaders: includesPartHeaders,
      includesPlainFields: multipartContents.any(
        httpMultipartContentHasPlainFields,
      ),
    );
  }

  @override
  Method generateBodyMethod({
    required Operation operation,
    required NameManager nameManager,
    required String package,
    required bool useImmutableCollections,
  }) => HttpBodyGenerator(
    nameManager: nameManager,
    package: package,
    useImmutableCollections: useImmutableCollections,
  ).generateBodyMethod(operation);

  @override
  Method generateOptionsMethod({
    required Operation operation,
    required NameManager nameManager,
    required String package,
    required bool useImmutableCollections,
    required List<({String normalizedName, RequestHeaderObject parameter})>
    headers,
    required List<({String normalizedName, CookieParameterObject parameter})>
    cookies,
  }) => HttpHeadersGenerator(
    nameManager: nameManager,
    package: package,
    useImmutableCollections: useImmutableCollections,
  ).generateHeadersMethod(operation, headers, cookies);

  @override
  Code generateDispatchStatements({
    required OperationRequestPlan plan,
    required String responseVariable,
    required Reference resultValueType,
  }) {
    final cancellation = plan.cancellation;
    const resolvedClient = r'_$client';
    const request = r'_$request';
    final bodyBytesType = TypeReference(
      (b) => b
        ..symbol = 'List'
        ..url = 'dart:core'
        ..types.add(refer('int', 'dart:core')),
    );
    final multipartFilesType = TypeReference(
      (b) => b
        ..symbol = 'List'
        ..url = 'dart:core'
        ..types.add(refer('MultipartFile', 'package:http/http.dart')),
    );
    final isRequiredMultipart = switch (plan.body) {
      MultipartBodyPlan(:final isRequired) => isRequired,
      _ => false,
    };
    final canBeMultipart = switch (plan.body) {
      MultipartBodyPlan() => true,
      BodySelectionPlan(:final variants) => variants.any(
        (variant) => variant is MultipartBodyPlan,
      ),
      _ => false,
    };
    final requestType = isRequiredMultipart
        ? refer('_TonikMultipartRequest')
        : canBeMultipart
        ? refer('BaseRequest', 'package:http/http.dart')
        : refer('AbortableRequest', 'package:http/http.dart');

    return Block.of([
      const Code('late final '),
      nativeResponseType.code,
      Code(' $responseVariable;'),
      Block.of([
        const Code('if ('),
        cancellation.code,
        const Code(' != null && '),
        cancellation.property('isCancelled').code,
        const Code(') {'),
        declareFinal('exception')
            .assign(
              refer(
                'RequestAbortedException',
                'package:http/http.dart',
              ).newInstance([plan.uri]),
            )
            .statement,
        _resultClass('TonikError', resultValueType)
            .call(
              [refer('exception')],
              {
                'stackTrace': refer(
                  'StackTrace',
                  'dart:core',
                ).property('current'),
                'type': refer(
                  'TonikErrorType.cancelled',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': literalNull,
              },
            )
            .returned
            .statement,
        const Code('}'),
      ]),
      const Code(''),
      const Code('final '),
      nativeClientType.code,
      const Code(' $resolvedClient;'),
      Block.of([
        const Code('try {'),
        refer(
          resolvedClient,
        ).assign(refer(clientAccessorFieldName).call([])).statement,
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        _resultClass('TonikError', resultValueType)
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
            .returned
            .statement,
        const Code('}\n'),
      ]),
      const Code('late final '),
      requestType.code,
      const Code(' $request;'),
      Block.of([
        const Code('try {'),
        if (isRequiredMultipart)
          ..._requiredMultipartRequestStatements(
            plan: plan,
            request: request,
            cancellation: cancellation,
          )
        else if (canBeMultipart)
          ..._selectedRequestStatements(
            plan: plan,
            request: request,
            cancellation: cancellation,
            bodyBytesType: bodyBytesType,
            multipartFilesType: multipartFilesType,
          )
        else
          ..._ordinaryRequestStatements(
            plan: plan,
            request: request,
            cancellation: cancellation,
          ),
        refer(request).property('headers').property('addAll').call([
          refer(r'_$options'),
        ]).statement,
        if (isRequiredMultipart)
          refer(request).property('files').property('addAll').call([
            refer(r'_$data').asA(multipartFilesType),
          ]).statement
        else if (!canBeMultipart)
          Block.of([
            const Code(r'if (_$data != null) {'),
            refer(request)
                .property('bodyBytes')
                .assign(refer(r'_$data').asA(bodyBytesType))
                .statement,
            const Code('}'),
          ]),
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        _resultClass('TonikError', resultValueType)
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
        const Code('}\n'),
      ]),
      const Code('final '),
      refer('StreamedResponse', 'package:http/http.dart').code,
      const Code(r' _$streamedResponse;'),
      Block.of([
        const Code('try {'),
        ..._headerValidationStatements(request),
        refer(r'_$streamedResponse')
            .assign(
              refer(
                resolvedClient,
              ).property('send').call([refer(request)]).awaited,
            )
            .statement,
        const Code('} on '),
        refer('RequestAbortedException', 'package:http/http.dart').code,
        const Code(' catch (exception, stackTrace) {'),
        _resultClass('TonikError', resultValueType)
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': _requestAbortErrorType(cancellation),
                'response': literalNull,
              },
            )
            .returned
            .statement,
        const Code('} on '),
        refer('ClientException', 'package:http/http.dart').code,
        const Code(' catch (exception, stackTrace) {'),
        _transportErrorReturn(
          resultValueType,
          type: refer(
            'TonikErrorType.network',
            'package:tonik_util/tonik_util.dart',
          ),
        ),
        const Code('} on '),
        refer('TimeoutException', 'dart:async').code,
        const Code(' catch (exception, stackTrace) {'),
        _transportErrorReturn(
          resultValueType,
          type: refer(
            'TonikErrorType.network',
            'package:tonik_util/tonik_util.dart',
          ),
        ),
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        _transportErrorReturn(
          resultValueType,
          type: refer(
            'TonikErrorType.other',
            'package:tonik_util/tonik_util.dart',
          ),
        ),
        const Code('}\n'),
      ]),
      Block.of([
        const Code('try {'),
        refer(responseVariable)
            .assign(
              refer('Response', 'package:http/http.dart')
                  .property('fromStream')
                  .call([refer(r'_$streamedResponse')])
                  .awaited,
            )
            .statement,
        const Code('} on '),
        refer('RequestAbortedException', 'package:http/http.dart').code,
        const Code(' catch (exception, stackTrace) {'),
        _resultClass('TonikError', resultValueType)
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': _requestAbortErrorType(cancellation),
                'response': literalNull,
              },
            )
            .returned
            .statement,
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        _transportErrorReturn(
          resultValueType,
          type: refer(
            'TonikErrorType.network',
            'package:tonik_util/tonik_util.dart',
          ),
        ),
        const Code('}\n'),
      ]),
    ]);
  }

  List<Code> _headerValidationStatements(String request) => [
    const Code('for (final value in '),
    refer(request).property('headers').property('values').code,
    const Code(') {'),
    const Code('final invalid = value.codeUnits.any('),
    const Code('(unit) => unit < 32 && unit != 9 || unit == 127,'),
    const Code(');'),
    const Code('if (invalid) {'),
    refer('ClientException', 'package:http/http.dart')
        .newInstance([
          literalString('Invalid HTTP header value.'),
          refer(request).property('url'),
        ])
        .thrown
        .statement,
    const Code('}'),
    const Code('}'),
  ];

  Code _transportErrorReturn(
    Reference resultValueType, {
    required Expression type,
  }) => _resultClass('TonikError', resultValueType)
      .call(
        [refer('exception')],
        {
          'stackTrace': refer('stackTrace'),
          'type': type,
          'response': literalNull,
        },
      )
      .returned
      .statement;

  Expression _requestAbortErrorType(Expression cancellation) => cancellation
      .nullSafeProperty('isCancelled')
      .ifNullThen(literalFalse)
      .conditional(
        refer(
          'TonikErrorType.cancelled',
          'package:tonik_util/tonik_util.dart',
        ),
        refer(
          'TonikErrorType.network',
          'package:tonik_util/tonik_util.dart',
        ),
      );

  List<Code> _requiredMultipartRequestStatements({
    required OperationRequestPlan plan,
    required String request,
    required Expression cancellation,
  }) => [
    refer(request)
        .assign(
          refer(
            '_TonikMultipartRequest',
          ).newInstance(
            [literalString(plan.methodName), plan.uri],
            {
              'abortTrigger': cancellation.nullSafeProperty('whenCancelled'),
            },
          ),
        )
        .statement,
  ];

  List<Code> _ordinaryRequestStatements({
    required OperationRequestPlan plan,
    required String request,
    required Expression cancellation,
  }) => [
    refer(request)
        .assign(
          refer(
            'AbortableRequest',
            'package:http/http.dart',
          ).newInstance(
            [literalString(plan.methodName), plan.uri],
            {
              'abortTrigger': cancellation.nullSafeProperty('whenCancelled'),
            },
          ),
        )
        .statement,
  ];

  List<Code> _selectedRequestStatements({
    required OperationRequestPlan plan,
    required String request,
    required Expression cancellation,
    required TypeReference bodyBytesType,
    required TypeReference multipartFilesType,
  }) {
    const multipartRequest = r'_$multipartRequest';
    const ordinaryRequest = r'_$ordinaryRequest';
    return [
      Block.of([
        const Code(r'if (_$data is '),
        multipartFilesType.code,
        const Code(') {'),
        declareFinal(multipartRequest)
            .assign(
              refer(
                '_TonikMultipartRequest',
              ).newInstance(
                [literalString(plan.methodName), plan.uri],
                {
                  'abortTrigger': cancellation.nullSafeProperty(
                    'whenCancelled',
                  ),
                },
              ),
            )
            .statement,
        refer(multipartRequest).property('files').property('addAll').call([
          refer(r'_$data'),
        ]).statement,
        refer(request).assign(refer(multipartRequest)).statement,
        const Code('} else {'),
        declareFinal(ordinaryRequest)
            .assign(
              refer(
                'AbortableRequest',
                'package:http/http.dart',
              ).newInstance(
                [literalString(plan.methodName), plan.uri],
                {
                  'abortTrigger': cancellation.nullSafeProperty(
                    'whenCancelled',
                  ),
                },
              ),
            )
            .statement,
        Block.of([
          const Code(r'if (_$data != null) {'),
          refer(ordinaryRequest)
              .property('bodyBytes')
              .assign(refer(r'_$data').asA(bodyBytesType))
              .statement,
          const Code('}'),
        ]),
        refer(request).assign(refer(ordinaryRequest)).statement,
        const Code('}'),
      ]),
    ];
  }

  Reference _resultClass(String symbol, Reference resultValueType) {
    return TypeReference(
      (b) => b
        ..symbol = symbol
        ..url = 'package:tonik_util/tonik_util.dart'
        ..types.addAll([resultValueType, nativeResponseType]),
    );
  }
}
