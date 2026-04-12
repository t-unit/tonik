import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/to_label_path_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_matrix_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';
import 'package:tonik_util/tonik_util.dart';

/// Generator for creating path method for operations.
class PathGenerator {
  const PathGenerator({
    required this.nameManager,
    required this.package,
    this.useImmutableCollections = false,
  });

  final NameManager nameManager;
  final String package;
  final bool useImmutableCollections;

  /// Generates the path method for the operation.
  Method generatePathMethod(
    Operation operation,
    List<({String normalizedName, PathParameterObject parameter})>
    pathParameters,
  ) {
    final hasTrailingSlash =
        operation.path.endsWith('/') && operation.path.length > 1;

    if (pathParameters.isEmpty) {
      final segments = operation.path
          .split('/')
          .where((s) => s.isNotEmpty)
          .map(specLiteralStringCode)
          .toList();

      if (hasTrailingSlash) {
        segments.add(specLiteralStringCode(''));
      }

      final pathSegments = segments.join(', ');

      return Method(
        (b) => b
          ..name = '_path'
          ..returns = TypeReference(
            (b) => b
              ..symbol = 'List'
              ..url = 'dart:core'
              ..types.add(refer('String', 'dart:core')),
          )
          ..lambda = false
          ..body = Code('return [$pathSegments];'),
      );
    }

    final parameters = <Parameter>[];
    final body = <Code>[];

    for (final pathParam in pathParameters) {
      final paramName = pathParam.normalizedName;
      final resolvedParam = pathParam.parameter;

      final parameterType = typeReference(
        resolvedParam.model,
        nameManager,
        package,
        isNullableOverride: !resolvedParam.isRequired,
        useImmutableCollections: useImmutableCollections,
      );

      parameters.add(
        Parameter(
          (b) => b
            ..name = paramName
            ..type = parameterType
            ..named = true
            ..required = resolvedParam.isRequired,
        ),
      );
    }

    final pathPartExpressions = <Expression>[];

    for (final pathComponent
        in operation.path
            .splitAndKeep(RegExp(r'\{[^}]+\}'))
            .where((pathComponent) => pathComponent.isNotEmpty)) {
      if (!pathComponent.startsWith('{') || !pathComponent.endsWith('}')) {
        final segments = pathComponent
            .split('/')
            .where((s) => s.isNotEmpty)
            .map(specLiteralString);
        pathPartExpressions.addAll(segments);
        continue;
      }

      final paramName = pathComponent.substring(1, pathComponent.length - 1);
      final param = pathParameters.firstWhereOrNull(
        (p) => p.parameter.rawName == paramName,
      );

      if (param == null) {
        final segments = pathComponent
            .split('/')
            .where((s) => s.isNotEmpty)
            .map(specLiteralString);
        pathPartExpressions.addAll(segments);
        continue;
      }

      if (param.parameter.encoding == PathParameterEncoding.simple) {
        final model = param.parameter.model;
        if (model is ListModel &&
            model.content.encodingShape != EncodingShape.simple) {
          body.add(
            generateEncodingExceptionExpression(
              'Simple encoding does not support list with complex elements for '
              'path parameter ${param.parameter.rawName}',
            ).statement,
          );

          continue;
        }

        final valueExpression = buildToSimplePathParameterExpression(
          param.normalizedName,
          param.parameter,
          explode: param.parameter.explode,
          allowEmpty: param.parameter.allowEmptyValue,
        );
        pathPartExpressions.add(valueExpression);
      } else if (param.parameter.encoding == PathParameterEncoding.label) {
        final valueExpression = buildToLabelPathParameterExpression(
          param.normalizedName,
          param.parameter,
        );
        pathPartExpressions.add(valueExpression);
      } else if (param.parameter.encoding == PathParameterEncoding.matrix) {
        final model = param.parameter.model;
        if (model is ListModel && model.content is ListModel) {
          body.add(
            generateEncodingExceptionExpression(
              'Matrix encoding does not support arrays of objects or '
              'nested arrays',
            ).statement,
          );

          continue;
        }

        final matrixExpression = buildMatrixParameterExpression(
          refer(param.normalizedName),
          param.parameter.model,
          paramName: specLiteralString(param.parameter.rawName),
          explode: literalBool(param.parameter.explode),
          allowEmpty: literalBool(param.parameter.allowEmptyValue),
        );
        pathPartExpressions.add(matrixExpression);
      }
    }

    if (hasTrailingSlash) {
      pathPartExpressions.add(specLiteralString(''));
    }

    final listExpr = literalList(pathPartExpressions);
    body.add(listExpr.returned.statement);

    return Method(
      (b) => b
        ..name = '_path'
        ..returns = TypeReference(
          (b) => b
            ..symbol = 'List'
            ..url = 'dart:core'
            ..types.add(refer('String', 'dart:core')),
        )
        ..optionalParameters.addAll(parameters)
        ..lambda = false
        ..body = Block.of(body),
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
