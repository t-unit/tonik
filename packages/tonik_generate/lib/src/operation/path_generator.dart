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
    if (pathParameters.isEmpty) {
      final pathSegments = operation.path
          .split('/')
          .where((s) => s.isNotEmpty)
          .map(specLiteralStringCode)
          .join(', ');

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

    // Split by '/' first to get proper URL segments, then handle parameters
    // within each segment. This ensures that suffixes like '.json' after a
    // parameter (e.g. '{Sid}.json') stay in the same segment rather than
    // becoming a separate path entry.
    final segments = operation.path.split('/').where((s) => s.isNotEmpty);

    for (final segment in segments) {
      final parts = segment.splitAndKeep(RegExp(r'\{[^}]+\}'));

      // Pure literal segment — no parameters at all.
      if (!parts.any((p) => p.startsWith('{') && p.endsWith('}'))) {
        pathPartExpressions.add(specLiteralString(segment));
        continue;
      }

      // Process parts within the segment. Simple-encoded parameters and
      // adjacent literals are concatenated into a single list entry. Label
      // and matrix parameters always become their own list entries because
      // they produce their own prefix (. or ;).
      final currentConcatParts = <Expression>[];

      for (final part in parts.where((p) => p.isNotEmpty)) {
        if (!part.startsWith('{') || !part.endsWith('}')) {
          // Literal text within the segment — accumulate for concatenation.
          currentConcatParts.add(specLiteralString(part));
          continue;
        }

        final paramName = part.substring(1, part.length - 1);
        final param = pathParameters.firstWhereOrNull(
          (p) => p.parameter.rawName == paramName,
        );

        if (param == null) {
          // Unknown parameter reference — treat as literal.
          currentConcatParts.add(specLiteralString(part));
          continue;
        }

        if (param.parameter.encoding == PathParameterEncoding.simple) {
          final model = param.parameter.model;
          if (model is ListModel &&
              model.content.encodingShape != EncodingShape.simple) {
            body.add(
              generateEncodingExceptionExpression(
                'Simple encoding does not support list with complex elements '
                'for path parameter ${param.parameter.rawName}',
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
          // Simple parameters concatenate with adjacent literals.
          currentConcatParts.add(valueExpression);
        } else if (param.parameter.encoding == PathParameterEncoding.label) {
          // Flush any accumulated concat parts before the label parameter.
          _flushConcatParts(currentConcatParts, pathPartExpressions);

          final valueExpression = buildToLabelPathParameterExpression(
            param.normalizedName,
            param.parameter,
          );
          pathPartExpressions.add(valueExpression);
        } else if (param.parameter.encoding == PathParameterEncoding.matrix) {
          // Flush any accumulated concat parts before the matrix parameter.
          _flushConcatParts(currentConcatParts, pathPartExpressions);

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

      // Flush any remaining concat parts after the last parameter in the
      // segment.
      _flushConcatParts(currentConcatParts, pathPartExpressions);
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

  /// Flushes accumulated concatenation parts into a single expression and
  /// adds it to [target]. If there is exactly one part, it is added directly.
  /// If there are multiple parts, they are joined with '+' to form a single
  /// concatenated expression. After flushing, [parts] is cleared.
  void _flushConcatParts(List<Expression> parts, List<Expression> target) {
    if (parts.isEmpty) return;

    if (parts.length == 1) {
      target.add(parts.first);
    } else {
      final codes = <Code>[];
      for (var i = 0; i < parts.length; i++) {
        if (i > 0) {
          codes.add(const Code(' + '));
        }
        codes.add(parts[i].code);
      }
      target.add(CodeExpression(Block.of(codes)));
    }

    parts.clear();
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
