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
  bool get responseStatusCodeIsNullable => true;

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
  String get clientAccessorFieldName => '_dio';

  @override
  Reference get nativeClientAccessorType => FunctionType(
    (b) => b..returnType = nativeClientType,
  );

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
    final cancelTokenType = TypeReference(
      (b) => b
        ..symbol = 'CancelToken'
        ..url = 'package:dio/dio.dart'
        ..isNullable = true,
    );
    final cancellation = plan.cancellation;
    const internalCancelToken = r'_$cancelToken';
    const resolvedDio = r'_$dio';

    return Block.of([
      const Code('final '),
      operationResponseType.code,
      Code(' $responseVariable;'),
      cancelTokenType.code,
      const Code(' $internalCancelToken;'),
      Block.of([
        const Code('if ('),
        cancellation.code,
        const Code(' != null) {'),
        refer(internalCancelToken)
            .assign(
              refer('CancelToken', 'package:dio/dio.dart').newInstance([]),
            )
            .statement,
        Block.of([
          const Code('if ('),
          cancellation.property('isCancelled').code,
          const Code(') {'),
          refer(internalCancelToken).property('cancel').call([
            cancellation.property('reason'),
          ]).statement,
          _resultClass('TonikError', resultValueType)
              .call(
                [
                  refer(
                    internalCancelToken,
                  ).property('cancelError').nullChecked,
                ],
                {
                  'stackTrace': refer(
                    internalCancelToken,
                  ).property('cancelError').nullChecked.property('stackTrace'),
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
        refer('unawaited', 'dart:async').call([
          cancellation.property('whenCancelled').property('then').call([
            Method(
              (m) => m
                ..requiredParameters.add(
                  Parameter((p) => p..name = '_'),
                )
                ..body = refer(internalCancelToken).nullChecked
                    .property('cancel')
                    .call([cancellation.property('reason')])
                    .statement,
            ).closure,
          ]),
        ]).statement,
        const Code('}'),
      ]),
      const Code(''),
      const Code('final '),
      nativeClientType.code,
      const Code(' $resolvedDio;'),
      Block.of([
        const Code('try {'),
        refer(
          resolvedDio,
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
      Block.of([
        const Code('try {'),
        refer(responseVariable)
            .assign(
              refer(resolvedDio).property('requestUri').call(
                [plan.uri],
                {
                  'data': refer(r'_$data'),
                  'options': refer(r'_$options'),
                  'cancelToken': refer(internalCancelToken),
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
                const Code(
                  'final clientFactory = serverConfig.clientFactory;',
                ),
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

  @override
  Iterable<Spec> generateOperationSupport(Operation operation) => const [];

  Reference _resultClass(String symbol, Reference resultValueType) {
    return TypeReference(
      (b) => b
        ..symbol = symbol
        ..url = 'package:tonik_util/tonik_util.dart'
        ..types.addAll([resultValueType, nativeResponseType]),
    );
  }
}
