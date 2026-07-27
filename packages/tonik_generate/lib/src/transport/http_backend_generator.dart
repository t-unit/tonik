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
  Expression get baseUrlExpression => throw UnsupportedError(
    'The http transport backend is not supported yet.',
  );

  @override
  Parameter get cancellationParameter => throw UnsupportedError(
    'The http transport backend is not supported yet.',
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
  String get clientFieldName => '_client';

  @override
  String get clientAdapterName => '_HttpClientAdapter';

  @override
  String get clientAdapterFieldName => r'_$httpClientAdapter';

  @override
  Class generateClientAdapter() => throw UnsupportedError(
    'The http transport backend is not supported yet.',
  );

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
  }) => throw UnsupportedError(
    'The http transport backend is not supported yet.',
  );
}
