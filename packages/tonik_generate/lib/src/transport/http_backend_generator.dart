import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/http_operation_base_generator.dart';
import 'package:tonik_generate/src/operation/operation_base_generator.dart';
import 'package:tonik_generate/src/transport/http/http_body_generator.dart';
import 'package:tonik_generate/src/transport/http/http_headers_generator.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

final class HttpBackendGenerator implements TransportBackendGenerator {
  const HttpBackendGenerator();

  @override
  TransportBackend get backend => TransportBackend.http;

  @override
  OperationBaseGenerator get operationBaseGenerator =>
      const HttpOperationBaseGenerator();

  @override
  List<DependencyDescriptor> get dependencies => const [
    DependencyDescriptor(name: 'http', versionConstraint: '^1.6.0'),
  ];

  @override
  Reference get nativeClientType => refer('Client', 'package:http/http.dart');

  @override
  TypeReference get nativeResponseType => TypeReference(
    (builder) => builder
      ..symbol = 'Response'
      ..url = 'package:http/http.dart',
  );

  @override
  TypeReference get operationResponseType => TypeReference(
    (builder) => builder
      ..symbol = 'Response'
      ..url = 'package:http/http.dart',
  );

  @override
  Reference get requestOptionsType => TypeReference(
    (builder) => builder
      ..symbol = 'Map'
      ..url = 'dart:core'
      ..types.addAll([
        refer('String', 'dart:core'),
        refer('String', 'dart:core'),
      ]),
  );

  @override
  Parameter get cancellationParameter => Parameter(
    (builder) => builder
      ..name = 'cancellation'
      ..type = TypeReference(
        (type) => type
          ..symbol = 'TonikCancellation'
          ..url = 'package:tonik_util/tonik_util.dart'
          ..isNullable = true,
      )
      ..named = true
      ..required = false,
  );

  @override
  Expression responseStatusCode(Expression response) =>
      response.property('statusCode');

  @override
  Code responseStatusCodeRangeGuard(RangeResponseStatus status) =>
      Code('status >= ${status.min} && status <= ${status.max}');

  @override
  Expression responseContentType(Expression response) =>
      response.property('headers').index(literalString('content-type'));

  @override
  Expression responseBodyBytes(Expression response) =>
      response.property('bodyBytes');

  @override
  Expression responseHeaderValues(Expression response, String name) => response
      .property('headersSplitValues')
      .index(specLiteralString(name.toLowerCase()));

  @override
  Reference get serverConfigType => TypeReference(
    (builder) => builder
      ..symbol = 'ServerConfig'
      ..url = 'package:tonik_util/tonik_util.dart'
      ..types.add(nativeClientType),
  );

  @override
  String get clientGetterName => 'client';

  @override
  String get clientAccessorFieldName => '_client';

  @override
  Reference get nativeClientAccessorType =>
      FunctionType((builder) => builder..returnType = nativeClientType);

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
      (builder) => builder
        ..name = clientAdapterName
        ..fields.addAll([
          Field(
            (field) => field
              ..name = 'serverConfig'
              ..type = serverConfigType
              ..modifier = FieldModifier.final$,
          ),
          Field(
            (field) => field
              ..name = r'_$client'
              ..type = TypeReference(
                (type) => type
                  ..symbol = 'Client'
                  ..url = 'package:http/http.dart'
                  ..isNullable = true,
              ),
          ),
          Field(
            (field) => field
              ..name = r'_$ownsClient'
              ..type = refer('bool', 'dart:core')
              ..assignment = literalFalse.code,
          ),
          Field(
            (field) => field
              ..name = r'_$isClosed'
              ..type = refer('bool', 'dart:core')
              ..assignment = literalFalse.code,
          ),
          Field(
            (field) => field
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
            (constructor) => constructor.requiredParameters.add(
              Parameter(
                (parameter) => parameter
                  ..name = 'serverConfig'
                  ..toThis = true,
              ),
            ),
          ),
        )
        ..methods.addAll([
          Method(
            (method) => method
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
            (method) => method
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
    required OperationRequestPlan requestPlan,
    required NameManager nameManager,
    required String package,
    required bool useImmutableCollections,
  }) => HttpBodyGenerator(
    nameManager: nameManager,
    package: package,
    useImmutableCollections: useImmutableCollections,
  ).generateBodyMethod(operation, bodyPlan: requestPlan.body);

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
}
