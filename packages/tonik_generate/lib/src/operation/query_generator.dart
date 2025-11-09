import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/to_delimited_query_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_form_query_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Generator for creating query parameters method for operations.
class QueryGenerator {
  const QueryGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  /// Generates the query parameters method for the operation.
  Method generateQueryParametersMethod(
    Operation operation,
    List<({String normalizedName, QueryParameterObject parameter})>
    queryParameters,
  ) {
    final parameters = <Parameter>[];
    final body = <Code>[
      declareFinal('result')
          .assign(
            literalList(
              [],
              refer('ParameterEntry', 'package:tonik_util/tonik_util.dart'),
            ),
          )
          .statement,
    ];

    final needsDeepObjectEncoder = queryParameters
        .any((q) => q.parameter.encoding == QueryParameterEncoding.deepObject);

    if (needsDeepObjectEncoder) {
      body.add(
        declareConst('deepObjectEncoder')
            .assign(
              refer(
                'DeepObjectEncoder',
                'package:tonik_util/tonik_util.dart',
              ).newInstance([]),
            )
            .statement,
      );
    }

    for (final queryParam in queryParameters) {
      final paramName = queryParam.normalizedName;
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

      final encodingCode = _generateEncodingCode(paramName, resolvedParam);
      _addCodeWithNullCheck(body, encodingCode, paramName, resolvedParam);
    }

    body.add(_generateReturnStatement());

    return Method(
      (b) =>
          b
            ..name = '_queryParameters'
            ..returns = refer('String', 'dart:core')
            ..optionalParameters.addAll(parameters)
            ..lambda = false
            ..body = Block.of(body),
    );
  }

  List<Code> _generateEncodingCode(
    String paramName,
    QueryParameterObject resolvedParam,
  ) {
    final encoding = resolvedParam.encoding;

    if (encoding == QueryParameterEncoding.form) {
      return buildToFormQueryParameterCode(
        paramName,
        resolvedParam,
        explode: resolvedParam.explode,
        allowEmpty: resolvedParam.allowEmptyValue,
      );
    }

    if (encoding == QueryParameterEncoding.spaceDelimited ||
        encoding == QueryParameterEncoding.pipeDelimited) {
      return buildToDelimitedQueryParameterCode(
        paramName,
        resolvedParam,
        encoding: encoding,
        explode: resolvedParam.explode,
        allowEmpty: resolvedParam.allowEmptyValue,
      );
    }

    return [
      _generateDeepObjectEncodingStatement(paramName, resolvedParam),
    ];
  }

  Code _generateDeepObjectEncodingStatement(
    String paramName,
    QueryParameterObject resolvedParam,
  ) {
    final valueExpression = buildToJsonQueryParameterExpression(
      paramName,
      resolvedParam,
    );
    final value = refer(valueExpression);

    final encodeCall = refer('deepObjectEncoder')
        .property('encode')
        .call(
          [
            literalString(resolvedParam.rawName, raw: true),
            value,
          ],
          {
            'explode': literalBool(resolvedParam.explode),
            'allowEmpty': literalBool(resolvedParam.allowEmptyValue),
          },
        );

    return refer('result').property('addAll').call([encodeCall]).statement;
  }

  void _addCodeWithNullCheck(
    List<Code> body,
    List<Code> code,
    String paramName,
    QueryParameterObject resolvedParam,
  ) {
    if (!resolvedParam.isRequired) {
      body.add(
        Block.of([
          Code('if ($paramName != null) {'),
          ...code,
          const Code('}'),
        ]),
      );
    } else {
      body.addAll(code);
    }
  }

  Code _generateReturnStatement() {
    return refer('result')
        .property('map')
        .call([
          Method(
            (b) =>
                b
                  ..lambda = true
                  ..requiredParameters.add(Parameter((b) => b..name = 'e'))
                  ..body = const Code(r"'${e.name}=${e.value}'"),
          ).closure,
        ])
        .property('join')
        .call([literalString('&')])
        .returned
        .statement;
  }
}
