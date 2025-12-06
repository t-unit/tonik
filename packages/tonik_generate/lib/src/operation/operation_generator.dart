import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/parameter_name_normalizer.dart';
import 'package:tonik_generate/src/operation/data_generator.dart';
import 'package:tonik_generate/src/operation/options_generator.dart';
import 'package:tonik_generate/src/operation/parse_generator.dart';
import 'package:tonik_generate/src/operation/path_generator.dart';
import 'package:tonik_generate/src/operation/query_generator.dart';
import 'package:tonik_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonik_generate/src/util/format_with_header.dart';
import 'package:tonik_generate/src/util/operation_parameter_generator.dart';
import 'package:tonik_generate/src/util/response_type_generator.dart';

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
      ),
      _parseGenerator = ParseGenerator(
        nameManager: nameManager,
        package: package,
      );

  final NameManager nameManager;
  final String package;

  final OptionsGenerator _optionsGenerator;
  final QueryGenerator _queryParametersGenerator;
  final PathGenerator _pathGenerator;
  final DataGenerator _dataGenerator;
  final ParseGenerator _parseGenerator;

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

    final code = formatter.formatWithHeader(library.accept(emitter).toString());

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
      (b) {
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
          );

        if (operation.isDeprecated) {
          b.annotations.add(
            refer('Deprecated', 'dart:core').call([
              literalString('This operation is deprecated.'),
            ]),
          );
        }

        b
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
            if (operation.responses.isNotEmpty)
              _parseGenerator.generateParseResponseMethod(operation),
          ]);
      },
    );
  }

  /// Generates the call() method for the operation
  @visibleForTesting
  Method generateCallMethod(
    Operation operation,
    NormalizedRequestParameters normalizedParams,
  ) {
    final hasRequestBody =
        operation.requestBody?.resolvedContent.isNotEmpty ?? false;
    final parameters = generateParameters(
      operation: operation,
      nameManager: nameManager,
      package: package,
    );

    final pathArgs = <String, Expression>{};
    final queryArgs = <String, Expression>{};
    final headerArgs = <String, Expression>{};
    final dataArgs = <String, Expression>{};

    if (hasRequestBody) {
      dataArgs['body'] = refer('body');
    }

    for (final pathParam in normalizedParams.pathParameters) {
      pathArgs[pathParam.normalizedName] = refer(pathParam.normalizedName);
    }

    for (final queryParam in normalizedParams.queryParameters) {
      queryArgs[queryParam.normalizedName] = refer(queryParam.normalizedName);
    }

    for (final headerParam in normalizedParams.headers) {
      headerArgs[headerParam.normalizedName] = refer(
        headerParam.normalizedName,
      );
    }

    final pathExpr =
        pathArgs.isEmpty ? refer('_path()') : refer('_path').call([], pathArgs);

    final queryExpr = refer('_queryParameters').call([], queryArgs);

    final resultType = resultTypeForOperation(operation, nameManager, package);
    final isVoidReturn =
        resultType.types.isNotEmpty && resultType.types.first.symbol == 'void';
    const responseVar = r'_$response';
    const parsedResponseVar = r'_$parsedResponse';
    final responseType =
        resultType.types.isNotEmpty ? resultType.types.first : refer('void');

    final bodyStatements = <Code>[
      _generateRequestStatements(
        operation,
        pathExpr,
        queryExpr,
        hasRequestBody,
        (operation.requestBody?.contentCount ?? 0) > 1,
        headerArgs,
        pathArgs,
        queryArgs,
      ),
      _generateResponseStatements(responseVar),
    ];

    // Always parse the response if responses are defined
    final hasResponses = operation.responses.isNotEmpty;

    if (hasResponses) {
      if (!isVoidReturn) {
        bodyStatements
          ..addAll(
            _generateParsedResponseStatements(
              responseVar,
              parsedResponseVar,
              responseType,
            ),
          )
          ..add(
            refer('TonikSuccess', 'package:tonik_util/tonik_util.dart')
                .call([refer(parsedResponseVar), refer(responseVar)])
                .returned
                .statement,
          );
      } else {
        // For void return type, just call the parse method without
        // assigning to a variable
        bodyStatements
          ..add(
            Block.of([
              const Code('try {'),
              refer('_parseResponse').call([refer(responseVar)]).statement,
              const Code('} on '),
              refer('Object', 'dart:core').code,
              const Code(' catch (exception, stackTrace) {'),
              refer('TonikError', 'package:tonik_util/tonik_util.dart')
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
          )
          ..add(
            refer(
              'TonikSuccess',
              'package:tonik_util/tonik_util.dart',
            ).call([literalNull, refer(responseVar)]).returned.statement,
          );
      }
    } else {
      bodyStatements.add(
        refer(
          'TonikSuccess',
          'package:tonik_util/tonik_util.dart',
        ).call([literalNull, refer(responseVar)]).returned.statement,
      );
    }

    return Method(
      (b) =>
          b
            ..name = 'call'
            ..returns = TypeReference(
              (b) =>
                  b
                    ..symbol = 'Future'
                    ..url = 'dart:core'
                    ..types.add(resultType),
            )
            ..optionalParameters.addAll(parameters)
            ..modifier = MethodModifier.async
            ..lambda = false
            ..body = Block((b) => b..statements.addAll(bodyStatements)),
    );
  }

  Code _generateRequestStatements(
    Operation operation,
    Expression pathExpr,
    Expression queryExpr,
    bool hasRequestBody,
    bool hasVariableContent,
    Map<String, Expression> headerArgs,
    Map<String, Expression> pathArgs,
    Map<String, Expression> queryArgs,
  ) {
    return Block.of([
      declareFinal(r'_$uri', type: refer('Uri', 'dart:core')).statement,
      declareFinal(r'_$data', type: refer('Object?', 'dart:core')).statement,
      declareFinal(
        r'_$options',
        type: refer('Options', 'package:dio/dio.dart'),
      ).statement,
      Block.of([
        const Code('try {'),
        declareFinal(r'_$baseUri')
            .assign(
              refer('Uri', 'dart:core').property('parse').call([
                refer('_dio').property('options').property('baseUrl'),
              ]),
            )
            .statement,
        declareFinal(
          r'_$pathResult',
        ).assign(refer('_path').call([], pathArgs)).statement,
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
        refer(r'_$data')
            .assign(
              refer(
                '_data',
              ).call([], {if (hasRequestBody) 'body': refer('body')}),
            )
            .statement,
        refer(r'_$options')
            .assign(
              refer('_options').call([], {
                ...headerArgs,
                if (hasVariableContent) 'body': refer('body'),
              }),
            )
            .statement,
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        refer('TonikError', 'package:tonik_util/tonik_util.dart')
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

  Code _generateResponseStatements(String responseVar) {
    return Block.of([
      const Code('final '),
      TypeReference(
        (b) =>
            b
              ..symbol = 'Response'
              ..url = 'package:dio/dio.dart'
              ..types.add(refer('dynamic', 'dart:core')),
      ).code,
      Code(' $responseVar;'),
      Block.of([
        const Code('try {'),
        refer(responseVar)
            .assign(
              refer('_dio').property('requestUri').call(
                [refer(r'_$uri')],
                {'data': refer(r'_$data'), 'options': refer(r'_$options')},
                [refer('dynamic', 'dart:core')],
              ).awaited,
            )
            .statement,
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        refer('TonikError', 'package:tonik_util/tonik_util.dart')
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

  List<Code> _generateParsedResponseStatements(
    String responseVar,
    String parsedResponseVar,
    Reference responseType,
  ) {
    return [
      declareFinal(parsedResponseVar, type: responseType).statement,
      Block.of([
        const Code('try {'),
        refer(
          parsedResponseVar,
        ).assign(refer('_parseResponse').call([refer(responseVar)])).statement,
        const Code('} on '),
        refer('Object', 'dart:core').code,
        const Code(' catch (exception, stackTrace) {'),
        refer('TonikError', 'package:tonik_util/tonik_util.dart')
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
}
