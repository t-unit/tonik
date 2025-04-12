import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/core_prefixed_allocator.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/parameter_name_normalizer.dart';
import 'package:tonic_generate/src/util/type_reference_generator.dart';

/// Generator for creating callable operation classes
/// from Operation definitions.
class OperationGenerator {
  const OperationGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

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
      '// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_raw_strings\n\n'
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
              generatePathMethod(operation, normalizedParams.pathParameters),
              generateDataMethod(operation),
              generateQueryParametersMethod(
                operation,
                normalizedParams.queryParameters,
              ),
              generateOptionsMethod(operation, normalizedParams.headers),
            ]),
    );
  }

  /// Generates the call() method for the operation
  @visibleForTesting
  Method generateCallMethod(
    Operation operation,
    NormalizedRequestParameters normalizedParams,
  ) {
    final headerParameters = <Parameter>[];
    final headerArgs = <String, Expression>{};
    final pathParameters = <Parameter>[];
    final pathArgs = <String, Expression>{};
    final queryParameters = <Parameter>[];
    final queryArgs = <String, Expression>{};

    for (final pathParam in normalizedParams.pathParameters) {
      final paramName = pathParam.normalizedName;
      final resolvedParam = pathParam.parameter;

      final parameterType = typeReference(
        resolvedParam.model,
        nameManager,
        package,
        isNullableOverride: !resolvedParam.isRequired,
      );

      pathParameters.add(
        Parameter(
          (b) =>
              b
                ..name = paramName
                ..type = parameterType
                ..named = true
                ..required = resolvedParam.isRequired,
        ),
      );

      pathArgs[paramName] = refer(paramName);
    }

    for (final queryParam in normalizedParams.queryParameters) {
      final paramName = queryParam.normalizedName;
      final resolvedParam = queryParam.parameter;

      final parameterType = typeReference(
        resolvedParam.model,
        nameManager,
        package,
        isNullableOverride: !resolvedParam.isRequired,
      );

      queryParameters.add(
        Parameter(
          (b) =>
              b
                ..name = paramName
                ..type = parameterType
                ..named = true
                ..required = resolvedParam.isRequired,
        ),
      );

      queryArgs[paramName] = refer(paramName);
    }

    for (final headerParam in normalizedParams.headers) {
      final paramName = headerParam.normalizedName;
      final resolvedParam = headerParam.parameter;

      final parameterType = typeReference(
        resolvedParam.model,
        nameManager,
        package,
        isNullableOverride: !resolvedParam.isRequired,
      );

      headerParameters.add(
        Parameter(
          (b) =>
              b
                ..name = paramName
                ..type = parameterType
                ..named = true
                ..required = resolvedParam.isRequired,
        ),
      );

      headerArgs[paramName] = refer(paramName);
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
                    ..types.add(refer('void')),
            )
            ..optionalParameters.addAll([
              ...pathParameters,
              ...queryParameters,
              ...headerParameters,
            ])
            ..modifier = MethodModifier.async
            ..lambda = false
            ..body = Block(
              (b) =>
                  b
                    ..statements.add(
                      refer('_dio')
                          .property('request')
                          .call(
                            [pathExpr],
                            {
                              'data': refer('_data()'),
                              'queryParameters': queryExpr,
                              'options': optionsExpr,
                            },
                            [refer('dynamic', 'dart:core')],
                          )
                          .awaited
                          .statement,
                    ),
            ),
    );
  }

  /// Generates a path expression for the operation
  @visibleForTesting
  Method generatePathMethod(
    Operation operation,
    List<({String normalizedName, PathParameterObject parameter})>
    pathParameters,
  ) {
    if (pathParameters.isEmpty) {
      return Method(
        (b) =>
            b
              ..name = '_path'
              ..returns = refer('String', 'dart:core')
              ..lambda = false
              ..body = Code("return r'${operation.path}';"),
      );
    }

    final body = <Code>[];
    final encoders = <PathParameterEncoding, String>{};

    for (final encoding
        in pathParameters.map((p) => p.parameter.encoding).toSet()) {
      final encoderName = switch (encoding) {
        PathParameterEncoding.simple => 'simpleEncoder',
        PathParameterEncoding.label => 'labelEncoder',
        PathParameterEncoding.matrix => 'matrixEncoder',
      };

      final encoderClass = switch (encoding) {
        PathParameterEncoding.simple => 'SimpleEncoder',
        PathParameterEncoding.label => 'LabelEncoder',
        PathParameterEncoding.matrix => 'MatrixEncoder',
      };

      encoders[encoding] = encoderName;

      body.add(
        declareFinal(encoderName)
            .assign(
              refer(
                encoderClass,
                'package:tonic_util/tonic_util.dart',
              ).newInstance([]),
            )
            .statement,
      );
    }

    final pathParts = operation.path
        .splitAndKeep(RegExp(r'\{[^}]+\}'))
        .where((pathComponent) => pathComponent.isNotEmpty)
        .map((pathComponent) {
          if (!pathComponent.startsWith('{') || !pathComponent.endsWith('}')) {
            return Code("r'$pathComponent'");
          }

          final paramName = pathComponent.substring(
            1,
            pathComponent.length - 1,
          );
          final param = pathParameters.firstWhereOrNull(
            (p) => p.parameter.rawName == paramName,
          );

          if (param == null) {
            return Code("r'$pathComponent'");
          }

          final encoderName = encoders[param.parameter.encoding]!;
          final needsToJson =
              param.parameter.model is! PrimitiveModel &&
              param.parameter.model is! ListModel;

          final valueExpression =
              needsToJson
                  ? '${param.normalizedName}.toJson()'
                  : param.normalizedName;

          return Code(
            "'\${$encoderName.encode($valueExpression, "
            'explode: ${param.parameter.explode}, '
            "allowEmpty: ${param.parameter.allowEmptyValue})}'",
          );
        });

    body
      ..add(const Code('return '))
      ..addAll(pathParts)
      ..add(const Code(';'));

    return Method(
      (b) =>
          b
            ..name = '_path'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll([
              for (final pathParam in pathParameters)
                Parameter(
                  (b) =>
                      b
                        ..name = pathParam.normalizedName
                        ..type = typeReference(
                          pathParam.parameter.model,
                          nameManager,
                          package,
                          isNullableOverride: !pathParam.parameter.isRequired,
                        )
                        ..named = true
                        ..required = pathParam.parameter.isRequired,
                ),
            ])
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  /// Generates a data expression for the operation
  @visibleForTesting
  Method generateDataMethod(Operation operation) {
    return Method(
      (b) =>
          b
            ..name = '_data'
            ..returns = refer('Object?', 'dart:core')
            ..lambda = false
            ..body = const Code('return null;'),
    );
  }

  /// Generates a query parameters expression for the operation
  @visibleForTesting
  Method generateQueryParametersMethod(
    Operation operation,
    List<({String normalizedName, QueryParameterObject parameter})>
    queryParameters,
  ) {
    final body = <Code>[];
    final parameters = <Parameter>[];

    body.add(
      declareFinal('result')
          .assign(
            literalMap(
              {},
              refer('String', 'dart:core'),
              refer('dynamic', 'dart:core'),
            ),
          )
          .statement,
    );

    final encoders = <QueryParameterEncoding, String>{};

    for (final encoding
        in queryParameters.map((q) => q.parameter.encoding).toSet()) {
      final encoderName = switch (encoding) {
        QueryParameterEncoding.form => 'formEncoder',
        QueryParameterEncoding.spaceDelimited => 'spacedEncoder',
        QueryParameterEncoding.pipeDelimited => 'pipedEncoder',
        QueryParameterEncoding.deepObject => 'deepObjectEncoder',
      };

      final encoderClass = switch (encoding) {
        QueryParameterEncoding.form => 'FormEncoder',
        QueryParameterEncoding.spaceDelimited => 'DelimitedEncoder',
        QueryParameterEncoding.pipeDelimited => 'DelimitedEncoder',
        QueryParameterEncoding.deepObject => 'DeepObjectEncoder',
      };

      encoders[encoding] = encoderName;

      if (encoding == QueryParameterEncoding.spaceDelimited ||
          encoding == QueryParameterEncoding.pipeDelimited) {
        final factoryName = switch (encoding) {
          QueryParameterEncoding.spaceDelimited => 'spaced',
          QueryParameterEncoding.pipeDelimited => 'piped',
          _ => throw StateError('Unexpected encoding type'),
        };

        body.add(
          declareFinal(encoderName)
              .assign(
                refer(
                  encoderClass,
                  'package:tonic_util/tonic_util.dart',
                ).property(factoryName).call([]),
              )
              .statement,
        );
      } else {
        body.add(
          declareFinal(encoderName)
              .assign(
                refer(
                  encoderClass,
                  'package:tonic_util/tonic_util.dart',
                ).newInstance([]),
              )
              .statement,
        );
      }
    }

    for (final queryParam in queryParameters) {
      final paramName = queryParam.normalizedName;
      final rawName = queryParam.parameter.rawName;
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

      final encoding = resolvedParam.encoding;
      final encoderName = encoders[encoding]!;
      final needsToJson =
          resolvedParam.model is! PrimitiveModel &&
          resolvedParam.model is! ListModel;

      final value =
          needsToJson
              ? refer(paramName).property('toJson').call([])
              : refer(paramName);

      Expression encodedValue;
      if (encoding == QueryParameterEncoding.deepObject) {
        encodedValue = refer(encoderName)
            .property('encode')
            .call(
              [literalString(rawName, raw: true), value],
              {
                'explode': literalBool(resolvedParam.explode),
                'allowEmpty': literalBool(resolvedParam.allowEmptyValue),
              },
            );
      } else if (encoding == QueryParameterEncoding.form) {
        encodedValue = refer(encoderName)
            .property('encode')
            .call(
              [literalString(rawName, raw: true), value],
              {
                'explode': literalBool(resolvedParam.explode),
                'allowEmpty': literalBool(resolvedParam.allowEmptyValue),
              },
            );
      } else {
        encodedValue = refer(encoderName)
            .property('encode')
            .call(
              [value],
              {
                'explode': literalBool(resolvedParam.explode),
                'allowEmpty': literalBool(resolvedParam.allowEmptyValue),
              },
            );
      }

      if (!resolvedParam.isRequired) {
        body.add(
          Block.of([
            Code('if ($paramName != null) {'),
            if (encoding == QueryParameterEncoding.deepObject)
              refer('result').property('addAll').call([encodedValue]).statement
            else
              refer(
                'result',
              ).index(literalString(rawName, raw: true)).assign(encodedValue).statement,
            const Code('}'),
          ]),
        );
      } else {
        if (encoding == QueryParameterEncoding.deepObject) {
          body.add(
            refer('result').property('addAll').call([encodedValue]).statement,
          );
        } else {
          body.add(
            refer(
              'result',
            ).index(literalString(rawName, raw: true)).assign(encodedValue).statement,
          );
        }
      }
    }

    body.add(refer('result').returned.statement);

    return Method(
      (b) =>
          b
            ..name = '_queryParameters'
            ..returns = buildMapStringDynamicType()
            ..optionalParameters.addAll(parameters)
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  /// Generates an options expression for the operation
  @visibleForTesting
  Method generateOptionsMethod(
    Operation operation,
    List<({String normalizedName, RequestHeaderObject parameter})> headers,
  ) {
    // Convert HttpMethod enum to string using a switch statement
    final methodString = switch (operation.method) {
      HttpMethod.get => 'GET',
      HttpMethod.post => 'POST',
      HttpMethod.put => 'PUT',
      HttpMethod.delete => 'DELETE',
      HttpMethod.patch => 'PATCH',
      HttpMethod.head => 'HEAD',
      HttpMethod.options => 'OPTIONS',
      HttpMethod.trace => 'TRACE',
    };

    final hasHeaders = headers.isNotEmpty;
    final bodyStatements = <Code>[];
    final optionalParameters = <Parameter>[];

    if (hasHeaders) {
      bodyStatements
        ..add(
          declareFinal('headers')
              .assign(
                literalMap(
                  {},
                  refer('String', 'dart:core'),
                  refer('dynamic', 'dart:core'),
                ),
              )
              .statement,
        )
        ..add(
          declareConst('headerEncoder')
              .assign(
                refer(
                  'SimpleEncoder',
                  'package:tonic_util/tonic_util.dart',
                ).newInstance([]),
              )
              .statement,
        );

      for (final headerParam in headers) {
        final paramName = headerParam.normalizedName;
        final rawName = headerParam.parameter.rawName;
        final resolvedParam = headerParam.parameter;

        final parameterType = typeReference(
          resolvedParam.model,
          nameManager,
          package,
          isNullableOverride: !resolvedParam.isRequired,
        );

        optionalParameters.add(
          Parameter(
            (b) =>
                b
                  ..name = paramName
                  ..type = parameterType
                  ..named = true
                  ..required = resolvedParam.isRequired,
          ),
        );

        final needsToJson =
            resolvedParam.model is! PrimitiveModel &&
            resolvedParam.model is! ListModel;

        Expression headerValue;
        if (needsToJson) {
          headerValue = refer('headerEncoder')
              .property('encode')
              .call(
                [refer(paramName).property('toJson').call([])],
                {
                  'explode': literalBool(resolvedParam.explode),
                  'allowEmpty': literalBool(resolvedParam.allowEmptyValue),
                },
              );
        } else {
          headerValue = refer('headerEncoder')
              .property('encode')
              .call(
                [refer(paramName)],
                {
                  'explode': literalBool(resolvedParam.explode),
                  'allowEmpty': literalBool(resolvedParam.allowEmptyValue),
                },
              );
        }

        if (!resolvedParam.isRequired) {
          bodyStatements.add(
            Block.of([
              Code('if ($paramName != null) {'),
              refer(
                'headers',
              ).index(literalString(rawName, raw: true)).assign(headerValue).statement,
              const Code('}'),
            ]),
          );
        } else {
          bodyStatements.add(
            refer(
              'headers',
            ).index(literalString(rawName, raw: true)).assign(headerValue).statement,
          );
        }
      }
    }

    final optionsExpr = refer('Options', 'package:dio/dio.dart').call([], {
      'method': literalString(methodString),
      if (hasHeaders) 'headers': refer('headers'),
    });

    bodyStatements.add(optionsExpr.returned.statement);

    return Method(
      (b) =>
          b
            ..name = '_options'
            ..returns = refer('Options', 'package:dio/dio.dart')
            ..optionalParameters.addAll(optionalParameters)
            ..lambda = false
            ..body = Block((b) => b..statements.addAll(bodyStatements)),
    );
  }
}

extension on String {
  List<String> splitAndKeep(RegExp pattern) {
    final result = <String>[];
    var lastEnd = 0;

    for (final match in pattern.allMatches(this)) {
      if (match.start > lastEnd) {
        result.add(substring(lastEnd, match.start));
      }
      result.add(match.group(0)!);
      lastEnd = match.end;
    }

    if (lastEnd < length) {
      result.add(substring(lastEnd));
    }

    return result;
  }
}
