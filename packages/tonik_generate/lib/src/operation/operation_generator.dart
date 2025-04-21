import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/operation/data_generator.dart';
import 'package:tonik_generate/src/operation/options_generator.dart';
import 'package:tonik_generate/src/operation/path_generator.dart';
import 'package:tonik_generate/src/operation/query_generator.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Generator for creating callable operation classes
/// from Operation definitions.
class OperationGenerator {
  OperationGenerator({required this.nameManager, required this.package})
    : _optionsGenerator = OptionsGenerator(
        nameManager: nameManager,
        package: package,
      ),
      _queryParametersGenerator = QueryGenerator(
        nameManager: nameManager,
        package: package,
      ),
      _pathGenerator = PathGenerator(
        nameManager: nameManager,
        package: package,
      ),
      _dataGenerator = DataGenerator(
        nameManager: nameManager,
        package: package,
      );

  final NameManager nameManager;
  final String package;

  final OptionsGenerator _optionsGenerator;
  final QueryGenerator _queryParametersGenerator;
  final PathGenerator _pathGenerator;
  final DataGenerator _dataGenerator;

  ({String code, String filename}) generateCallableOperation(
    Operation operation,
  ) {
    final className = nameManager.operationName(operation);
    final fileNameSnakeCase = className.toSnakeCase();
    final fileName = '$fileNameSnakeCase.dart';

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

    final code = formatter.format(
      '// Generated code - do not modify by hand\n'
      '// ignore_for_file: lines_longer_than_80_chars\n '
      '// ignore_for_file: unnecessary_brace_in_string_interps\n '
      '// ignore_for_file: cascade_invocations\n '
      '// ignore_for_file: unnecessary_raw_strings\n'
      '${library.accept(emitter)}',
    );

    return (code: code, filename: fileName);
  }

  /// Generates the callable operation class
  @visibleForTesting
  Class generateClass(Operation operation, String className) {
    final pathParams = operation.pathParameters.map((p) => p.resolve()).toSet();
    final queryParams =
        operation.queryParameters.map((p) => p.resolve()).toSet();
    final headerParams = operation.headers.map((p) => p.resolve()).toSet();

    final normalizedParams = normalizeRequestParameters(
      pathParameters: pathParams,
      queryParameters: queryParams,
      headers: headerParams,
    );

    return Class(
      (b) =>
          b
            ..name = className
            ..fields.add(
              Field(
                (b) =>
                    b
                      ..name = '_dio'
                      ..modifier = FieldModifier.final$
                      ..type = refer('Dio', 'package:dio/dio.dart'),
              ),
            )
            ..constructors.add(
              Constructor(
                (b) =>
                    b
                      ..requiredParameters.add(
                        Parameter(
                          (b) =>
                              b
                                ..name = '_dio'
                                ..toThis = true,
                        ),
                      ),
              ),
            )
            ..methods.addAll([
              generateCallMethod(operation, normalizedParams),
              _pathGenerator.generatePathMethod(
                operation,
                normalizedParams.pathParameters,
              ),
              _dataGenerator.generateDataMethod(operation),
              if (operation.queryParameters.isNotEmpty)
                _queryParametersGenerator.generateQueryParametersMethod(
                  operation,
                  normalizedParams.queryParameters,
                ),
              _optionsGenerator.generateOptionsMethod(
                operation,
                normalizedParams.headers,
              ),
            ]),
    );
  }

  /// Generates the call() method for the operation
  @visibleForTesting
  Method generateCallMethod(
    Operation operation,
    NormalizedRequestParameters normalizedParams,
  ) {
    final parameters = <Parameter>[];
    final pathArgs = <String, Expression>{};
    final queryArgs = <String, Expression>{};
    final headerArgs = <String, Expression>{};
    final dataArgs = <String, Expression>{};

    // Handle request body first to reserve the 'body' name if needed
    final hasRequestBody =
        operation.requestBody?.resolvedContent.isNotEmpty ?? false;

    if (hasRequestBody) {
      final requestBody = operation.requestBody!;

      final parameterType =
          requestBody.contentCount == 1
              ? typeReference(
                requestBody.resolvedContent.first.model,
                nameManager,
                package,
                isNullableOverride: !requestBody.isRequired,
              )
              : TypeReference(
                (b) =>
                    b
                      ..symbol = nameManager.requestBodyName(requestBody)
                      ..url = package
                      ..isNullable = !requestBody.isRequired,
              );

      parameters.add(
        Parameter(
          (b) =>
              b
                ..name = 'body'
                ..type = parameterType
                ..named = true
                ..required = requestBody.isRequired,
        ),
      );

      dataArgs['body'] = refer('body');
    }

    // Add suffix to any parameter named 'body' if request body exists
    String normalizeParamName(String name, String suffix) {
      return name == 'body' && hasRequestBody ? '$name$suffix' : name;
    }

    for (final pathParam in normalizedParams.pathParameters) {
      final paramName = normalizeParamName(pathParam.normalizedName, 'Path');
      final resolvedParam = pathParam.parameter;

      final parameterType = typeReference(
        resolvedParam.model,
        nameManager,
        package,
        isNullableOverride: !resolvedParam.isRequired,
      );

      parameters.add(
        Parameter(
          (b) =>
              b
                ..name = paramName
                ..type = parameterType
                ..named = true
                ..required = resolvedParam.isRequired,
        ),
      );

      pathArgs[pathParam.normalizedName] = refer(paramName);
    }

    for (final queryParam in normalizedParams.queryParameters) {
      final paramName = normalizeParamName(queryParam.normalizedName, 'Query');
      final resolvedParam = queryParam.parameter;

      final parameterType = typeReference(
        resolvedParam.model,
        nameManager,
        package,
        isNullableOverride: !resolvedParam.isRequired,
      );

      parameters.add(
        Parameter(
          (b) =>
              b
                ..name = paramName
                ..type = parameterType
                ..named = true
                ..required = resolvedParam.isRequired,
        ),
      );

      queryArgs[queryParam.normalizedName] = refer(paramName);
    }

    for (final headerParam in normalizedParams.headers) {
      final paramName = normalizeParamName(
        headerParam.normalizedName,
        'Header',
      );
      final resolvedParam = headerParam.parameter;

      final parameterType = typeReference(
        resolvedParam.model,
        nameManager,
        package,
        isNullableOverride: !resolvedParam.isRequired,
      );

      parameters.add(
        Parameter(
          (b) =>
              b
                ..name = paramName
                ..type = parameterType
                ..named = true
                ..required = resolvedParam.isRequired,
        ),
      );

      headerArgs[headerParam.normalizedName] = refer(paramName);
    }

    final pathExpr =
        pathArgs.isEmpty ? refer('_path()') : refer('_path').call([], pathArgs);

    final queryExpr = refer('_queryParameters').call([], queryArgs);

    final optionsExpr = refer('_options').call([], headerArgs);

    return Method(
      (b) =>
          b
            ..name = 'call'
            ..returns = TypeReference(
              (b) =>
                  b
                    ..symbol = 'Future'
                    ..url = 'dart:core'
                    ..types.add(
                      TypeReference(
                        (b) =>
                            b
                              ..symbol = 'TonikResult'
                              ..url = 'package:tonik_util/tonik_util.dart'
                              ..types.add(refer('void')),
                      ),
                    ),
            )
            ..optionalParameters.addAll(parameters)
            ..modifier = MethodModifier.async
            ..lambda = false
            ..body = Block(
              (b) =>
                  b
                    ..statements.addAll([
                      declareFinal(
                        r'_$uri',
                        type: refer('Uri', 'dart:core'),
                      ).statement,
                      declareFinal(
                        r'_$data',
                        type: refer('Object?', 'dart:core'),
                      ).statement,
                      declareFinal(
                        r'_$options',
                        type: refer('Options', 'package:dio/dio.dart'),
                      ).statement,
                      Block.of([
                        const Code('try {'),
                        refer(r'_$uri')
                            .assign(
                              refer('Uri', 'dart:core')
                                  .property('parse')
                                  .call([
                                    refer(
                                      '_dio',
                                    ).property('options').property('baseUrl'),
                                  ])
                                  .property('resolveUri')
                                  .call([
                                    refer('Uri', 'dart:core').call(
                                      [],
                                      operation.queryParameters.isEmpty
                                          ? {'path': pathExpr}
                                          : {
                                            'path': pathExpr,
                                            'query': queryExpr,
                                          },
                                    ),
                                  ]),
                            )
                            .statement,
                        refer(r'_$data').assign(refer('_data()')).statement,
                        refer(r'_$options').assign(optionsExpr).statement,
                        const Code('} on '),
                        refer('Exception', 'dart:core').code,
                        const Code(' catch (exception, stackTrace) {'),
                        refer(
                              'TonikError',
                              'package:tonik_util/tonik_util.dart',
                            )
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
                      TypeReference(
                        (b) =>
                            b
                              ..symbol = 'Response'
                              ..url = 'package:dio/dio.dart'
                              ..types.add(refer('dynamic', 'dart:core')),
                      ).code,
                      const Code(' response;'),
                      Block.of([
                        const Code('try {'),
                        refer('response')
                            .assign(
                              refer('_dio').property('requestUri').call(
                                [refer(r'_$uri')],
                                {
                                  'data': refer(r'_$data'),
                                  'options': refer(r'_$options'),
                                },
                                [refer('dynamic', 'dart:core')],
                              ).awaited,
                            )
                            .statement,
                        const Code('} on '),
                        refer('Exception', 'dart:core').code,
                        const Code(' catch (exception, stackTrace) {'),
                        refer(
                              'TonikError',
                              'package:tonik_util/tonik_util.dart',
                            )
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
                      refer(
                            'TonikSuccess',
                            'package:tonik_util/tonik_util.dart',
                          )
                          .call([literalNull, refer('response')])
                          .returned
                          .statement,
                    ]),
            ),
    );
  }
}
