import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/operation/dio_operation_base_generator.dart';
import 'package:tonik_generate/src/operation/operation_base_generator.dart';
import 'package:tonik_generate/src/transport/dio/dio_data_generator.dart';
import 'package:tonik_generate/src/transport/dio/dio_options_generator.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

final class DioBackendGenerator implements TransportBackendGenerator {
  const DioBackendGenerator();

  @override
  TransportBackend get backend => TransportBackend.dio;

  @override
  OperationBaseGenerator get operationBaseGenerator =>
      const DioOperationBaseGenerator();

  @override
  List<DependencyDescriptor> get dependencies => const [
    DependencyDescriptor(name: 'dio', versionConstraint: '^5.8.0+1'),
  ];

  @override
  Reference get nativeClientType => refer('Dio', 'package:dio/dio.dart');

  @override
  TypeReference get nativeResponseType => TypeReference(
    (b) => b
      ..symbol = 'Response'
      ..url = 'package:dio/dio.dart'
      ..types.add(
        TypeReference(
          (b) => b
            ..symbol = 'Object'
            ..url = 'dart:core'
            ..isNullable = true,
        ),
      ),
  );

  @override
  TypeReference get operationResponseType => TypeReference(
    (b) => b
      ..symbol = 'Response'
      ..url = 'package:dio/dio.dart'
      ..types.add(
        TypeReference(
          (b) => b
            ..symbol = 'List'
            ..url = 'dart:core'
            ..types.add(refer('int', 'dart:core')),
        ),
      ),
  );

  @override
  Reference get requestOptionsType => refer('Options', 'package:dio/dio.dart');

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
  Expression responseStatusCode(Expression response) =>
      response.property('statusCode');

  @override
  Code responseStatusCodeRangeGuard(RangeResponseStatus status) => Code(
    'status != null '
    '&& status >= ${status.min} && status <= ${status.max}',
  );

  @override
  Expression responseContentType(Expression response) => response
      .property('headers')
      .property('value')
      .call([literalString('content-type')]);

  @override
  Expression responseBodyBytes(Expression response) =>
      response.property('data');

  @override
  Expression responseHeaderValues(Expression response, String name) =>
      response.property('headers').index(specLiteralString(name));

  @override
  Reference get serverConfigType => TypeReference(
    (b) => b
      ..symbol = 'ServerConfig'
      ..url = 'package:tonik_util/tonik_util.dart'
      ..types.add(nativeClientType),
  );

  @override
  String get clientGetterName => 'dio';

  @override
  String get clientAccessorFieldName => '_dio';

  @override
  Reference get nativeClientAccessorType =>
      FunctionType((b) => b..returnType = nativeClientType);

  @override
  String get clientAdapterName => '_DioClientAdapter';

  @override
  String get clientAdapterFieldName => r'_$dioAdapter';

  @override
  List<Expression> clientAdapterConstructorArguments({
    required Expression baseUrl,
    required Expression serverConfig,
  }) => [baseUrl, serverConfig];

  @override
  Method generateBodyMethod({
    required Operation operation,
    required OperationRequestPlan requestPlan,
    required NameManager nameManager,
    required String package,
    required bool useImmutableCollections,
  }) => DioDataGenerator(
    nameManager: nameManager,
    package: package,
    useImmutableCollections: useImmutableCollections,
  ).generateDataMethod(operation, bodyPlan: requestPlan.body);

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
  }) => DioOptionsGenerator(
    nameManager: nameManager,
    package: package,
    useImmutableCollections: useImmutableCollections,
  ).generateOptionsMethod(operation, headers, cookies);

  @override
  Class generateClientAdapter() {
    final dioType = nativeClientType;

    return Class(
      (b) => b
        ..name = clientAdapterName
        ..fields.addAll([
          Field(
            (f) => f
              ..name = 'baseUrl'
              ..type = refer('String', 'dart:core')
              ..modifier = FieldModifier.final$,
          ),
          Field(
            (f) => f
              ..name = 'serverConfig'
              ..type = serverConfigType
              ..modifier = FieldModifier.final$,
          ),
          Field(
            (f) => f
              ..name = r'_$dio'
              ..type = TypeReference(
                (b) => b
                  ..symbol = 'Dio'
                  ..url = 'package:dio/dio.dart'
                  ..isNullable = true,
              ),
          ),
          Field(
            (f) => f
              ..name = r'_$ownsDio'
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
                  'Cannot access Dio after the server has been closed.',
                ),
              ]).code,
          ),
        ])
        ..constructors.add(
          Constructor(
            (c) => c
              ..requiredParameters.addAll([
                Parameter(
                  (p) => p
                    ..name = 'baseUrl'
                    ..toThis = true,
                ),
                Parameter(
                  (p) => p
                    ..name = 'serverConfig'
                    ..toThis = true,
                ),
              ]),
          ),
        )
        ..methods.addAll([
          Method(
            (m) => m
              ..name = clientGetterName
              ..type = MethodType.getter
              ..returns = dioType
              ..body = Block.of([
                const Code(r'if (_$isClosed) {'),
                const Code(r'  throw _$closedError;'),
                const Code('}'),
                const Code(''),
                const Code(r'final cachedDio = _$dio;'),
                const Code('if (cachedDio != null) {'),
                const Code('  return cachedDio;'),
                const Code('}'),
                const Code(''),
                const Code('final client = serverConfig.client;'),
                const Code('final clientFactory = serverConfig.clientFactory;'),
                const Code(
                  'final resolvedDio = '
                  'client ?? clientFactory?.call() ?? ',
                ),
                dioType.newInstance([]).code,
                const Code(';'),
                const Code(r'_$ownsDio = client == null;'),
                const Code('resolvedDio.options.baseUrl = baseUrl;'),
                const Code(r'return _$dio = resolvedDio;'),
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
                const Code(r'if (_$ownsDio) {'),
                const Code(r'  _$dio?.close();'),
                const Code('}'),
              ]),
          ),
        ]),
    );
  }
}
