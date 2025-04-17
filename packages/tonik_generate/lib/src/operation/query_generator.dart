import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/util/name_manager.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Generator for creating query parameters method for operations.
class QueryGenerator {
  const QueryGenerator({
    required this.nameManager,
    required this.package,
  });

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
                  'package:tonik_util/tonik_util.dart',
                ).property(factoryName).call([]),
              )
              .statement,
        );
      } else {
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

      final encoding = resolvedParam.encoding;
      final encoderName = encoders[encoding]!;
      final valueExpression = buildToJsonQueryParameterExpression(
        paramName,
        resolvedParam,
      );
      final value = refer(valueExpression);

      final encodeCall = refer(encoderName)
          .property('encode')
          .call(
            [
              if (encoding == QueryParameterEncoding.deepObject ||
                  encoding == QueryParameterEncoding.form)
                literalString(resolvedParam.rawName, raw: true),
              value,
            ],
            {
              'explode': literalBool(resolvedParam.explode),
              'allowEmpty': literalBool(resolvedParam.allowEmptyValue),
            },
          );

      if (!resolvedParam.isRequired) {
        body.add(
          Block.of([
            Code('if ($paramName != null) {'),
            if (encoding == QueryParameterEncoding.spaceDelimited ||
                encoding == QueryParameterEncoding.pipeDelimited)
              Block.of([
                Code('for (final value in $encoderName.encode('),
                value.code,
                Code(', explode: ${resolvedParam.explode}, '),
                Code('allowEmpty: ${resolvedParam.allowEmptyValue},'),
                const Code(')) {'),
                Code(
                  "result.add((name: '${resolvedParam.rawName}', "
                  'value: value));',
                ),
                const Code('}'),
              ])
            else
              refer('result').property('addAll').call([encodeCall]).statement,
            const Code('}'),
          ]),
        );
      } else {
        if (encoding == QueryParameterEncoding.spaceDelimited ||
            encoding == QueryParameterEncoding.pipeDelimited) {
          body.add(
            Block.of([
              Code('for (final value in $encoderName.encode('),
              value.code,
              Code(', explode: ${resolvedParam.explode}, '),
              Code('allowEmpty: ${resolvedParam.allowEmptyValue},'),
              const Code(')) {'),
              Code(
                "result.add((name: '${resolvedParam.rawName}', value: value));",
              ),
              const Code('}'),
            ]),
          );
        } else {
          body.add(
            refer('result').property('addAll').call([encodeCall]).statement,
          );
        }
      }
    }

    body.add(
      refer('result')
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
          .statement,
    );

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
}
