import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/operation/parse_generator.dart';
import 'package:tonik_generate/src/operation/path_generator.dart';
import 'package:tonik_generate/src/operation/query_generator.dart';
import 'package:tonik_generate/src/transport/multipart_header_plan.dart';
import 'package:tonik_generate/src/transport/operation_request_plan.dart';
import 'package:tonik_generate/src/transport/operation_request_planner.dart';
import 'package:tonik_generate/src/transport/transport_backend_generator.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/operation_parameter_defaults.dart';
import 'package:tonik_generate/src/util/operation_parameter_generator.dart';
import 'package:tonik_generate/src/util/response_type_generator.dart';

/// Generator for creating callable operation classes
/// from Operation definitions.
class OperationGenerator({
  required final NameManager nameManager,
  required final String package,
  required final OperationDefaultsCache defaultsCache,
  required final TransportBackendGenerator backendGenerator,
  final bool useImmutableCollections = false,
}) {
  final QueryGenerator _queryParametersGenerator = QueryGenerator(
    nameManager: nameManager,
    package: package,
    useImmutableCollections: useImmutableCollections,
  );
  final PathGenerator _pathGenerator = PathGenerator(
    nameManager: nameManager,
    package: package,
    useImmutableCollections: useImmutableCollections,
  );
  final ParseGenerator _parseGenerator = ParseGenerator(
    nameManager: nameManager,
    package: package,
    backendGenerator: backendGenerator,
    useImmutableCollections: useImmutableCollections,
  );

  ({String code, String filename}) generateCallableOperation(
    Operation operation,
  ) {
    final className = nameManager.operationName(operation);
    final fileName = nameManager.fileNameForClass(className);

    final library = Library(
      (b) => b..body.add(generateClass(operation, className)),
    );

    final emitter = DartEmitter(
      allocator: CorePrefixedAllocator(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

    return (code: code, filename: fileName);
  }

  /// Generates the callable operation class
  @visibleForTesting
  Class generateClass(Operation operation, String className) {
    final pathParams = operation.pathParameters.map((p) => p.resolve()).toSet();
    final queryParams = operation.queryParameters
        .map((p) => p.resolve())
        .toSet();
    final headerParams = operation.headers.map((p) => p.resolve()).toSet();
    final cookieParams = operation.cookieParameters
        .map((p) => p.resolve())
        .toSet();

    final hasRequestBody =
        operation.requestBody?.resolvedContent.isNotEmpty ?? false;

    final normalizedParams = normalizeRequestParameters(
      pathParameters: pathParams,
      queryParameters: queryParams,
      headers: headerParams,
      cookieParameters: cookieParams,
      reservedNames: operationReservedParameterNames(
        hasRequestBody: hasRequestBody,
      ),
    );

    final defaults = defaultsCache.forOperation(
      operation,
      normalizedParams: normalizedParams,
      operationClassName: className,
      initialReservedNames: initialOperationDefaultReservedNames(
        normalizedParams: normalizedParams,
        hasRequestBody: hasRequestBody,
      ),
    );

    final requestPlan = OperationRequestPlanner(
      backend: backendGenerator.backend,
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
    ).plan(operation, normalizedParams);

    return Class((b) {
      b
        ..name = className
        ..fields.addAll([
          Field(
            (b) => b
              ..name = '_baseUrl'
              ..modifier = FieldModifier.final$
              ..type = refer('String', 'dart:core'),
          ),
          Field(
            (b) => b
              ..name = backendGenerator.clientAccessorFieldName
              ..modifier = FieldModifier.final$
              ..type = backendGenerator.nativeClientAccessorType,
          ),
        ])
        ..fields.addAll(defaults.fields);

      if (operation.isDeprecated) {
        b.annotations.add(
          refer(
            'Deprecated',
            'dart:core',
          ).call([literalString('This operation is deprecated.')]),
        );
      }

      b
        ..constructors.add(
          Constructor(
            (b) => b
              ..requiredParameters.addAll([
                Parameter(
                  (b) => b
                    ..name = '_baseUrl'
                    ..toThis = true,
                ),
                Parameter(
                  (b) => b
                    ..name = backendGenerator.clientAccessorFieldName
                    ..toThis = true,
                ),
              ]),
          ),
        )
        ..methods.addAll([
          ...defaults.getters,
          generateCallMethod(
            operation,
            normalizedParams,
            defaultsByName: defaults.byName,
            requestPlan: requestPlan,
          ),
          _pathGenerator.generatePathMethod(
            operation,
            normalizedParams.pathParameters,
          ),
          backendGenerator.generateBodyMethod(
            operation: operation,
            requestPlan: requestPlan,
            nameManager: nameManager,
            package: package,
            useImmutableCollections: useImmutableCollections,
          ),
          if (operation.queryParameters.isNotEmpty)
            _queryParametersGenerator.generateQueryParametersMethod(
              operation,
              normalizedParams.queryParameters,
            ),
          backendGenerator.generateOptionsMethod(
            operation: operation,
            nameManager: nameManager,
            package: package,
            useImmutableCollections: useImmutableCollections,
            headers: normalizedParams.headers,
            cookies: normalizedParams.cookieParameters,
          ),
          if (operation.responses.isNotEmpty)
            _parseGenerator.generateParseResponseMethod(operation),
        ]);
    });
  }

  /// Generates the call() method for the operation
  @visibleForTesting
  Method generateCallMethod(
    Operation operation,
    NormalizedRequestParameters normalizedParams, {
    Map<String, OperationParameterDefault> defaultsByName = const {},
    OperationRequestPlan? requestPlan,
  }) {
    final hasRequestBody =
        operation.requestBody?.resolvedContent.isNotEmpty ?? false;
    final parameters = generateParameters(
      operation: operation,
      nameManager: nameManager,
      package: package,
      defaultsByName: defaultsByName,
    );

    final pathArgs = <String, Expression>{};
    final queryArgs = <String, Expression>{};
    final headerArgs = <String, Expression>{};
    final cookieArgs = <String, Expression>{};
    requestPlan ??= OperationRequestPlanner(
      backend: backendGenerator.backend,
      nameManager: nameManager,
      package: package,
      useImmutableCollections: useImmutableCollections,
    ).plan(operation, normalizedParams);

    for (final pathParam in requestPlan.pathParameters) {
      pathArgs[pathParam.normalizedName] = pathParam.value;
    }

    for (final queryParam in requestPlan.queryParameters) {
      queryArgs[queryParam.normalizedName] = queryParam.value;
    }

    for (final headerParam in requestPlan.headers) {
      headerArgs[headerParam.normalizedName] = headerParam.value;
    }

    for (final cookieParam in requestPlan.cookies) {
      cookieArgs[cookieParam.normalizedName] = cookieParam.value;
    }

    final pathExpr = pathArgs.isEmpty
        ? refer('_path()')
        : refer('_path').call([], pathArgs);

    final queryExpr = refer('_queryParameters').call([], queryArgs);

    final resultType = resultTypeForOperation(
      operation,
      nameManager,
      package,
      backendGenerator,
      useImmutableCollections: useImmutableCollections,
    );
    final resultValueType = resultType.types.first;
    final nativeResponseType = resultType.types[1];
    final isVoidReturn = resultValueType.symbol == 'void';
    // The unassigned try/catch is only safe when `_parseResponse` is
    // statically guaranteed to throw. `Never?` widens to a type that can
    // legitimately complete normally with `null`, so the nullable case
    // must keep the final-var assignment. The url == 'dart:core' guard
    // excludes a user-defined type that happens to be named `Never`.
    final firstResultType = resultType.types.firstOrNull;
    final isNeverParseReturn =
        firstResultType != null &&
        firstResultType.symbol == 'Never' &&
        firstResultType.url == 'dart:core' &&
        (firstResultType is! TypeReference ||
            firstResultType.isNullable != true);
    const responseVar = r'_$response';
    const parsedResponseVar = r'_$parsedResponse';
    final responseType = resultType.types.isNotEmpty
        ? resultType.types.first
        : refer('void');

    final bodyStatements = <Code>[
      _generateRequestStatements(
        operation,
        requestPlan,
        pathExpr,
        queryExpr,
        hasRequestBody,
        requestContentTypeNeedsBodyValue(operation.requestBody),
        headerArgs,
        cookieArgs,
        pathArgs,
        queryArgs,
        resultValueType,
        nativeResponseType,
      ),
      backendGenerator.generateDispatchStatements(
        plan: requestPlan,
        responseVariable: responseVar,
        resultValueType: resultValueType,
      ),
    ];

    final hasResponses = operation.responses.isNotEmpty;

    if (hasResponses) {
      if (isNeverParseReturn) {
        bodyStatements.add(
          _unassignedParseResponseTryCatch(
            responseVar,
            resultValueType,
            nativeResponseType,
          ),
        );
      } else if (!isVoidReturn) {
        bodyStatements
          ..addAll(
            _generateParsedResponseStatements(
              responseVar,
              parsedResponseVar,
              responseType,
              resultValueType,
              nativeResponseType,
            ),
          )
          ..add(
            _resultClass('TonikSuccess', resultValueType, nativeResponseType)
                .call([refer(parsedResponseVar), refer(responseVar)])
                .returned
                .statement,
          );
      } else {
        bodyStatements
          ..add(
            _unassignedParseResponseTryCatch(
              responseVar,
              resultValueType,
              nativeResponseType,
            ),
          )
          ..add(
            _resultClass(
              'TonikSuccess',
              resultValueType,
              nativeResponseType,
            ).call([literalNull, refer(responseVar)]).returned.statement,
          );
      }
    } else {
      bodyStatements.add(
        _resultClass(
          'TonikSuccess',
          resultValueType,
          nativeResponseType,
        ).call([literalNull, refer(responseVar)]).returned.statement,
      );
    }

    return Method(
      (b) => b
        ..name = 'call'
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'Future'
            ..url = 'dart:core'
            ..types.add(resultType),
        )
        ..optionalParameters.addAll([
          ...parameters,
          backendGenerator.cancellationParameter,
        ])
        ..modifier = MethodModifier.async
        ..lambda = false
        ..body = Block((b) => b..statements.addAll(bodyStatements)),
    );
  }

  Code _generateRequestStatements(
    Operation operation,
    OperationRequestPlan requestPlan,
    Expression pathExpr,
    Expression queryExpr,
    bool hasRequestBody,
    bool optionsNeedsBody,
    Map<String, Expression> headerArgs,
    Map<String, Expression> cookieArgs,
    Map<String, Expression> pathArgs,
    Map<String, Expression> queryArgs,
    Reference resultValueType,
    Reference nativeResponseType,
  ) {
    return Block.of([
      declareFinal(
        r'_$uri',
        type: refer('Uri', 'dart:core'),
        late: true,
      ).statement,
      declareFinal(
        r'_$data',
        type: refer('Object?', 'dart:core'),
        late: true,
      ).statement,
      Block.of([
        const Code('late final '),
        backendGenerator.requestOptionsType.code,
        const Code(r' _$options;'),
      ]),
      Block.of([
        const Code('try {'),
        declareFinal(r'_$baseUri')
            .assign(
              refer(
                'Uri',
                'dart:core',
              ).property('parse').call([refer('_baseUrl')]),
            )
            .statement,
        declareFinal(r'_$pathResult')
            .assign(refer('_path').call([], pathArgs))
            .statement,
        const Code(
          r"final _$newPath = _$baseUri.path.endsWith('/') "
          r"? '${_$baseUri.path.substring(0, _$baseUri.path.length - 1)}/${_$pathResult.join('/')}' "
          r": '${_$baseUri.path}/${_$pathResult.join('/')}';",
        ),
        refer(r'_$uri')
            .assign(
              refer(r'_$baseUri').property('replace').call([], {
                'path': refer(r'_$newPath'),
                if (queryArgs.isNotEmpty)
                  'query': refer('_queryParameters').call([], queryArgs),
              }),
            )
            .statement,
        refer(r'_$data').assign(() {
          final isDataAsync = _bodyRequiresAsyncLowering(requestPlan.body);
          final dataCall = refer('_data').call([], {
            if (hasRequestBody) 'body': refer('body'),
            if (hasRequestBody)
              ...() {
                final args = <String, Expression>{};
                for (final info in extractOperationMultipartHeaderParamInfo(
                  operation,
                  nameManager: nameManager,
                  package: package,
                )) {
                  args[info.name] = refer(info.name);
                }
                return args;
              }(),
          });
          return isDataAsync ? dataCall.awaited : dataCall;
        }()).statement,
        refer(r'_$options')
            .assign(
              refer('_options').call([], {
                ...headerArgs,
                ...cookieArgs,
                if (optionsNeedsBody) 'body': refer('body'),
              }),
            )
            .statement,
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        _resultClass('TonikError', resultValueType, nativeResponseType)
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
    ]);
  }

  bool _bodyRequiresAsyncLowering(RequestBodyPlan body) => switch (body) {
    MultipartBodyPlan() => true,
    BodySelectionPlan(:final variants) => variants.any(
      (variant) => variant is MultipartBodyPlan,
    ),
    _ => false,
  };

  Code _unassignedParseResponseTryCatch(
    String responseVar,
    Reference resultValueType,
    Reference nativeResponseType,
  ) {
    return Block.of([
      const Code('try {'),
      refer('_parseResponse').call([refer(responseVar)]).statement,
      const Code('} on '),
      refer('Object', 'dart:core').code,
      const Code(' catch (exception, stackTrace) {'),
      _resultClass('TonikError', resultValueType, nativeResponseType)
          .call(
            [refer('exception')],
            {
              'stackTrace': refer('stackTrace'),
              'type': refer(
                'TonikErrorType.decoding',
                'package:tonik_util/tonik_util.dart',
              ),
              'response': refer(responseVar),
            },
          )
          .returned
          .statement,
      const Code('}\n'),
    ]);
  }

  List<Code> _generateParsedResponseStatements(
    String responseVar,
    String parsedResponseVar,
    Reference responseType,
    Reference resultValueType,
    Reference nativeResponseType,
  ) {
    return [
      Block.of([
        const Code('final '),
        responseType.code,
        Code(' $parsedResponseVar;'),
      ]),
      Block.of([
        const Code('try {'),
        refer(parsedResponseVar)
            .assign(refer('_parseResponse').call([refer(responseVar)]))
            .statement,
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        _resultClass('TonikError', resultValueType, nativeResponseType)
            .call(
              [refer('exception')],
              {
                'stackTrace': refer('stackTrace'),
                'type': refer(
                  'TonikErrorType.decoding',
                  'package:tonik_util/tonik_util.dart',
                ),
                'response': refer(responseVar),
              },
            )
            .returned
            .statement,
        const Code('}\n'),
      ]),
    ];
  }

  Reference _resultClass(
    String symbol,
    Reference resultValueType,
    Reference nativeResponseType,
  ) {
    return TypeReference(
      (b) => b
        ..symbol = symbol
        ..url = 'package:tonik_util/tonik_util.dart'
        ..types.addAll([resultValueType, nativeResponseType]),
    );
  }
}
