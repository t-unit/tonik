import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Generator for creating path method for operations.
class PathGenerator {
  const PathGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  /// Generates the path method for the operation.
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

    final parameters = <Parameter>[];
    final encoders = <PathParameterEncoding, String>{};
    final body = <Code>[];

    for (final pathParam in pathParameters) {
      final paramName = pathParam.normalizedName;
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
    }

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
        declareConst(encoderName)
            .assign(
              refer(
                encoderClass,
                'package:tonik_util/tonik_util.dart',
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
          final valueExpression = buildToJsonPathParameterExpression(
            param.normalizedName,
            param.parameter,
          );

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
