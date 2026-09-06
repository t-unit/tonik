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
  required final String operationBaseFilename,
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
    ).plan(operation, normalizedParams);
    final resultValueType = resultTypeForOperation(
      operation,
      nameManager,
      package,
      backendGenerator,
      useImmutableCollections: useImmutableCollections,
    ).types.first;

    return Class((b) {
      b
        ..name = className
        ..modifier = ClassModifier.final$
        ..extend = backendGenerator.operationBaseGenerator.baseType(
          package: package,
          valueType: resultValueType,
          filename: operationBaseFilename,
        )
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
                    ..name = 'baseUrl'
                    ..toSuper = true,
                ),
                Parameter(
                  (b) => b
                    ..name = backendGenerator
                        .operationBaseGenerator
                        .clientConstructorParameterName
                    ..toSuper = true,
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
    requestPlan ??= OperationRequestPlanner(backend: backendGenerator.backend)
        .plan(operation, normalizedParams);

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

    final resultType = resultTypeForOperation(
      operation,
      nameManager,
      package,
      backendGenerator,
      useImmutableCollections: useImmutableCollections,
    );
    final resultValueType = resultType.types.first;
    final isVoidReturn = resultValueType.symbol == 'void';
    final hasResponses = operation.responses.isNotEmpty;
    final dataArgs = <String, Expression>{
      if (hasRequestBody) 'body': refer('body'),
      if (hasRequestBody)
        for (final info in extractOperationMultipartHeaderParamInfo(operation))
          info.name: refer(info.name),
    };
    final optionsArgs = <String, Expression>{
      ...headerArgs,
      ...cookieArgs,
      if (requestContentTypeNeedsBodyValue(operation.requestBody))
        'body': refer('body'),
    };
    final isDataAsync = _bodyRequiresAsyncLowering(requestPlan.body);
    final execution = backendGenerator.operationBaseGenerator
        .executionInvocation(
          package: package,
          filename: operationBaseFilename,
          plan: requestPlan,
          path: pathExpr,
          queryParameters: queryArgs.isEmpty
              ? literalNull
              : refer('_queryParameters').call([], queryArgs),
          data: refer('_data').call([], dataArgs),
          options: refer('_options').call([], optionsArgs),
          decode: hasResponses ? refer('_parseResponse') : null,
          isVoid: isVoidReturn,
          isDataAsync: isDataAsync,
        );

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
        ..lambda = false
        ..body = execution.returned.statement,
    );
  }

  bool _bodyRequiresAsyncLowering(RequestBodyPlan body) => switch (body) {
    MultipartBodyPlan() => true,
    BodySelectionPlan(:final variants) => variants.any(
      (variant) => variant is MultipartBodyPlan,
    ),
    _ => false,
  };
}
