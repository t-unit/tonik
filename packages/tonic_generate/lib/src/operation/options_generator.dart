import 'package:code_builder/code_builder.dart';
import 'package:tonic_core/tonic_core.dart';
import 'package:tonic_generate/src/util/name_manager.dart';
import 'package:tonic_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonic_generate/src/util/type_reference_generator.dart';

/// Generator for creating options method for operations.
class OptionsGenerator {
  const OptionsGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  /// Generates the options method for the operation.
  Method generateOptionsMethod(
    Operation operation,
    List<({String normalizedName, RequestHeaderObject parameter})> headers,
  ) {
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
    final parameters = <Parameter>[];

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

        final valueExpression = buildToJsonHeaderParameterExpression(
          paramName,
          resolvedParam,
        );
        final headerAssignment =
            refer('headers')
                .index(literalString(resolvedParam.rawName, raw: true))
                .assign(
                  refer('headerEncoder')
                      .property('encode')
                      .call(
                        [refer(valueExpression)],
                        {
                          'explode': literalBool(resolvedParam.explode),
                          'allowEmpty': literalBool(
                            resolvedParam.allowEmptyValue,
                          ),
                        },
                      ),
                )
                .statement;

        if (!resolvedParam.isRequired) {
          bodyStatements.add(
            Block.of([
              Code('if ($paramName != null) {'),
              headerAssignment,
              const Code('}'),
            ]),
          );
        } else {
          bodyStatements.add(headerAssignment);
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
            ..optionalParameters.addAll(parameters)
            ..lambda = false
            ..body = Block((b) => b..statements.addAll(bodyStatements)),
    );
  }
}
