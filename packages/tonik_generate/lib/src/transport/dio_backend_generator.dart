import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/transport/dio/dio_data_generator.dart';
import 'package:tonik_generate/src/transport/dio/dio_options_generator.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';

final class DioBackendGenerator implements TransportBackendGenerator {
  const DioBackendGenerator();

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
  Expression get baseUrlExpression =>
      refer(clientFieldName).property('options').property('baseUrl');

  @override
  Parameter get cancellationParameter => Parameter(
    (b) => b
      ..name = 'cancelToken'
      ..type = TypeReference(
        (b) => b
          ..symbol = 'CancelToken'
          ..url = 'package:dio/dio.dart'
          ..isNullable = true,
      )
      ..named = true
      ..required = false,
  );

  @override
  Expression responseStatusCode(Expression response) =>
      response.property('statusCode');

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
  String get clientFieldName => '_dio';

  @override
  String get clientAdapterName => '_DioClientAdapter';

  @override
  String get clientAdapterFieldName => r'_$dioAdapter';

  @override
  Method generateBodyMethod({
    required Operation operation,
    required NameManager nameManager,
    required String package,
    required bool useImmutableCollections,
  }) => DioDataGenerator(
    nameManager: nameManager,
    package: package,
    useImmutableCollections: useImmutableCollections,
  ).generateDataMethod(operation);

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
  Code generateDispatchStatements({
    required OperationRequestPlan plan,
    required String responseVariable,
    required Reference resultValueType,
  }) {
    return Block.of([
      const Code('final '),
      operationResponseType.code,
      Code(' $responseVariable;'),
      Block.of([
        const Code('try {'),
        refer(responseVariable)
            .assign(
              refer(clientFieldName).property('requestUri').call(
                [plan.uri],
                {
                  'data': refer(r'_$data'),
                  'options': refer(r'_$options'),
                  'cancelToken': plan.cancellation,
                },
                [
                  TypeReference(
                    (b) => b
                      ..symbol = 'List'
                      ..url = 'dart:core'
                      ..types.add(refer('int', 'dart:core')),
                  ),
                ],
              ).awaited,
            )
            .statement,
        const Code('} on '),
        refer('DioException', 'package:dio/dio.dart').code,
        const Code(' catch (exception, stackTrace) {'),
        Block.of([
          const Code('if (exception.type == '),
          refer(
            'DioExceptionType.cancel',
            'package:dio/dio.dart',
          ).code,
          const Code(') {'),
          _resultClass('TonikError', resultValueType)
              .call(
                [refer('exception')],
                {
                  'stackTrace': refer('stackTrace'),
                  'type': refer(
                    'TonikErrorType.cancelled',
                    'package:tonik_util/tonik_util.dart',
                  ),
                  'response': refer('exception').property('response'),
                },
              )
              .returned
              .statement,
          const Code('}'),
        ]),
        _resultClass('TonikError', resultValueType)
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer(
                  'TonikErrorType.network',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': refer('exception').property('response'),
              },
            )
            .returned
            .statement,
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        _resultClass('TonikError', resultValueType)
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
            .returned
            .statement,
        const Code('}\n'),
      ]),
    ]);
  }

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
        ..methods.add(
          Method(
            (m) => m
              ..name = clientGetterName
              ..type = MethodType.getter
              ..returns = dioType
              ..body = Block.of([
                const Code(r'final cachedDio = _$dio;'),
                const Code('if (cachedDio != null) {'),
                const Code('  return cachedDio;'),
                const Code('}'),
                const Code(''),
                const Code('final client = serverConfig.client;'),
                const Code(
                  'final clientFactory = serverConfig.clientFactory;',
                ),
                const Code(
                  'final resolvedDio = '
                  'client ?? clientFactory?.call() ?? ',
                ),
                dioType.newInstance([]).code,
                const Code(';'),
                const Code('resolvedDio.options.baseUrl = baseUrl;'),
                const Code(r'return _$dio = resolvedDio;'),
              ]),
          ),
        ),
    );
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
