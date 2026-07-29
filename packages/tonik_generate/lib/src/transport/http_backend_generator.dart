import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator.dart';

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
  Reference get requestOptionsType => throw UnsupportedError(
    'The http transport backend is not supported yet.',
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
  Expression responseStatusCode(Expression response) => throw UnsupportedError(
    'The http transport backend is not supported yet.',
  );

  @override
  Expression responseContentType(Expression response) => throw UnsupportedError(
    'The http transport backend is not supported yet.',
  );

  @override
  Expression responseBodyBytes(Expression response) => throw UnsupportedError(
    'The http transport backend is not supported yet.',
  );

  @override
  Expression responseHeaderValues(Expression response, String name) =>
      throw UnsupportedError(
        'The http transport backend is not supported yet.',
      );

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
  Method generateBodyMethod({
    required Operation operation,
    required NameManager nameManager,
    required String package,
    required bool useImmutableCollections,
  }) => throw UnsupportedError(
    'The http transport backend is not supported yet.',
  );

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
  }) => throw UnsupportedError(
    'The http transport backend is not supported yet.',
  );

  @override
  Code generateDispatchStatements({
    required OperationRequestPlan plan,
    required String responseVariable,
    required Reference resultValueType,
  }) {
    const resolvedClient = r'_$client';

    return Block.of([
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
      refer('UnsupportedError', 'dart:core')
          .newInstance([
            literalString(
              'The http transport backend does not support request dispatch '
              'yet.',
            ),
          ])
          .thrown
          .statement,
    ]);
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
