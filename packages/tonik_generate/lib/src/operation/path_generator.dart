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

    // Split by '/' first to get proper URL segments, then handle parameters
    // within each segment. This ensures that suffixes like '.json' after a
    // parameter (e.g. '{Sid}.json') stay in the same segment rather than
    // becoming a separate path entry.
    final segments = operation.path.split('/').where((s) => s.isNotEmpty);

    for (final segment in segments) {
      _processSegment(segment, pathParameters, pathPartExpressions, body);
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

  void _processSegment(
    String segment,
    List<({String normalizedName, PathParameterObject parameter})>
    pathParameters,
    List<Expression> pathPartExpressions,
    List<Code> body,
  ) {
    final parts = segment.splitAndKeep(RegExp(r'\{[^}]+\}'));

    if (!parts.any((p) => p.startsWith('{') && p.endsWith('}'))) {
      pathPartExpressions.add(specLiteralString(segment));
      return;
    }

    // Simple-encoded parameters and adjacent literals are concatenated into a
    // single list entry. Label and matrix parameters always become their own
    // list entries because they produce their own prefix (. or ;).
    final currentConcatParts = <Expression>[];

    for (final part in parts.where((p) => p.isNotEmpty)) {
      if (!part.startsWith('{') || !part.endsWith('}')) {
        currentConcatParts.add(specLiteralString(part));
        continue;
      }

      final paramName = part.substring(1, part.length - 1);
      final param = pathParameters.firstWhereOrNull(
        (p) => p.parameter.rawName == paramName,
      );

      if (param == null) {
        currentConcatParts.add(specLiteralString(part));
        continue;
      }

      switch (param.parameter.encoding) {
        case PathParameterEncoding.simple:
          final throwReason = simpleEncodingThrowReason(param.parameter.model);
          if (throwReason != null) {
            // `throw X + literal` parses as `throw (X + literal)`; emit the
            // throw as a standalone statement instead.
            currentConcatParts.clear();
            body.add(
              generateEncodingExceptionExpression(
                'Simple encoding does not support $throwReason '
                'for path parameter ${param.parameter.rawName}',
              ).statement,
            );
            return;
          }

          final valueExpression = buildToSimplePathParameterExpression(
            param.normalizedName,
            param.parameter,
            explode: param.parameter.explode,
            allowEmpty: param.parameter.allowEmptyValue,
          );
          currentConcatParts.add(valueExpression);
        case PathParameterEncoding.label:
          _flushConcatParts(currentConcatParts, pathPartExpressions);

          final valueExpression = buildToLabelPathParameterExpression(
            param.normalizedName,
            param.parameter,
          );
          pathPartExpressions.add(valueExpression);
        case PathParameterEncoding.matrix:
          _flushConcatParts(currentConcatParts, pathPartExpressions);

          // `.resolved` is only needed for this pre-flight type test —
          // `isEffectivelyNullable` and `buildMatrixParameterExpression`
          // handle aliases.
          final model = param.parameter.model.resolved;
          if (model is ListModel && model.content.resolved is ListModel) {
            currentConcatParts.clear();
            body.add(
              generateEncodingExceptionExpression(
                'Matrix encoding does not support arrays of objects or '
                'nested arrays for path parameter '
                '${param.parameter.rawName}',
              ).statement,
            );
            return;
          }

          final isModelNullable = param.parameter.model.isEffectivelyNullable;
          // Path params are required; use ! assertion for nullable types.
          final matrixReceiver = isModelNullable
              ? refer(param.normalizedName).nullChecked
              : refer(param.normalizedName);
          final matrixExpression = buildMatrixParameterExpression(
            matrixReceiver,
            param.parameter.model,
            paramName: specLiteralString(param.parameter.rawName),
            explode: literalBool(param.parameter.explode),
            allowEmpty: literalBool(param.parameter.allowEmptyValue),
          );
          pathPartExpressions.add(matrixExpression);
      }
    }

    _flushConcatParts(currentConcatParts, pathPartExpressions);
  }

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
