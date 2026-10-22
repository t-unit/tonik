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
class const PathGenerator({
  required final NameManager nameManager,
  required final String package,
  final bool useImmutableCollections = false,
}) {
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

    // Every expansion belongs to its original slash-delimited segment,
    // including label and matrix prefixes (. or ;) and adjacent literals.
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

      late final Expression encodedValue;
      late final String emptyValue;
      switch (param.parameter.encoding) {
        case PathParameterEncoding.simple:
          final throwReason = simpleEncodingThrowReason(param.parameter.model);
          if (throwReason != null) {
            final error = generateEncodingExceptionExpression(
              'Simple encoding does not support $throwReason '
              'for path parameter ${param.parameter.rawName}',
              raw: true,
            );
            if (!isNullableParameterType(param.parameter.model)) {
              // `throw X + literal` parses as `throw (X + literal)`.
              currentConcatParts.clear();
              body.add(error.statement);
              return;
            }
            encodedValue = error;
          } else {
            encodedValue = buildToSimplePathParameterExpression(
              param.normalizedName,
              param.parameter,
              explode: param.parameter.explode,
              allowEmpty: param.parameter.allowEmptyValue,
              isNullChecked: true,
            ).expression;
          }
          emptyValue = '';
        case PathParameterEncoding.label:
          final valueExpression = buildToLabelPathParameterExpression(
            param.normalizedName,
            param.parameter,
            isNullChecked: true,
          );
          encodedValue = valueExpression.expression;
          emptyValue = '.';
        case PathParameterEncoding.matrix:
          // `.resolved` is only needed for this pre-flight type test —
          // The nullability check and `buildMatrixParameterExpression`
          // handle aliases.
          final model = param.parameter.model.resolved;
          if (model is ListModel && model.content.resolved is ListModel) {
            final error = generateEncodingExceptionExpression(
              'Matrix encoding does not support arrays of objects or '
              'nested arrays for path parameter '
              '${param.parameter.rawName}',
              raw: true,
            );
            if (!isNullableParameterType(param.parameter.model)) {
              currentConcatParts.clear();
              body.add(error.statement);
              return;
            }
            encodedValue = error;
          } else {
            encodedValue = buildMatrixParameterExpression(
              refer(param.normalizedName),
              param.parameter.model,
              paramName: specLiteralString(param.parameter.rawName),
              explode: literalBool(param.parameter.explode),
              allowEmpty: literalBool(param.parameter.allowEmptyValue),
            ).expression;
          }
          emptyValue = ';${param.parameter.rawName}';
      }

      currentConcatParts.add(
        isNullableParameterType(param.parameter.model)
            ? refer(param.normalizedName)
                  .equalTo(literalNull)
                  .conditional(specLiteralString(emptyValue), encodedValue)
                  .parenthesized
            : encodedValue,
      );
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
        // Encoders can emit `throw` expressions. Parentheses keep an adjacent
        // literal from becoming part of the thrown expression.
        final part = parts[i];
        codes.add(
          part is BinaryExpression ? part.parenthesized.code : part.code,
        );
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
