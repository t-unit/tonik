import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

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
    final bodyStatements = <Code>[];
    final parameters = <Parameter>[];

    final methodString = _generateMethodString(operation.method);
    final contentType = _generateContentType(
      operation.requestBody,
      bodyStatements,
      parameters,
    );
    final headersData = _generateHeaders(headers, bodyStatements, parameters);

    final optionsExpr = refer('Options', 'package:dio/dio.dart').call([], {
      'method': literalString(methodString),
      if (headersData != null) 'headers': refer('headers'),
      if (contentType != null) 'contentType': contentType,
      'validateStatus': _generateValidateStatus(),
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

  String _generateMethodString(HttpMethod method) => switch (method) {
    HttpMethod.get => 'GET',
    HttpMethod.post => 'POST',
    HttpMethod.put => 'PUT',
    HttpMethod.delete => 'DELETE',
    HttpMethod.patch => 'PATCH',
    HttpMethod.head => 'HEAD',
    HttpMethod.options => 'OPTIONS',
    HttpMethod.trace => 'TRACE',
  };

  Expression? _generateContentType(
    RequestBody? requestBody,
    List<Code> bodyStatements,
    List<Parameter> parameters,
  ) {
    if (requestBody?.resolvedContent.isEmpty ?? true) {
      return null;
    }

    if (requestBody!.contentCount == 1) {
      return literalString(requestBody.resolvedContent.first.rawContentType);
    }

    final (baseName, subclassNames) = nameManager.requestBodyNames(requestBody);
    parameters.add(
      Parameter(
        (b) =>
            b
              ..name = 'body'
              ..type = refer(baseName, package)
              ..named = true
              ..required = requestBody.isRequired,
      ),
    );

    final cases = <Code>[];
    for (final content in requestBody.resolvedContent) {
      final className = subclassNames[content.rawContentType]!;
      final caseCode = [
        refer(className, package).code,
        const Code(' _ => '),
        literalString(content.rawContentType).code,
        const Code(',\n'),
      ];
      cases.addAll(caseCode);
    }

    bodyStatements.add(
      declareFinal('contentType')
          .assign(
            CodeExpression(
              Block.of([
                const Code('switch (body) {'),
                ...cases,
                const Code('}'),
              ]),
            ),
          )
          .statement,
    );
    return refer('contentType');
  }

  Expression? _generateHeaders(
    List<({String normalizedName, RequestHeaderObject parameter})> headers,
    List<Code> bodyStatements,
    List<Parameter> parameters,
  ) {
    if (headers.isEmpty) return null;

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
                'package:tonik_util/tonik_util.dart',
              ).newInstance([]),
            )
            .statement,
      );

    for (final headerParam in headers) {
      final paramName = headerParam.normalizedName;
      final resolvedParam = headerParam.parameter;

      parameters.add(_generateHeaderParameter(paramName, resolvedParam));
      final headerAssignment = _generateHeaderAssignment(
        paramName,
        resolvedParam,
      );

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

    return refer('headers');
  }

  Parameter _generateHeaderParameter(
    String paramName,
    RequestHeaderObject resolvedParam,
  ) {
    final parameterType = typeReference(
      resolvedParam.model,
      nameManager,
      package,
      isNullableOverride: !resolvedParam.isRequired,
    );

    return Parameter(
      (b) =>
          b
            ..name = paramName
            ..type = parameterType
            ..named = true
            ..required = resolvedParam.isRequired,
    );
  }

  Code _generateHeaderAssignment(
    String paramName,
    RequestHeaderObject resolvedParam,
  ) {
    final valueExpression = buildToJsonHeaderParameterExpression(
      paramName,
      resolvedParam,
    );

    return refer('headers')
        .index(literalString(resolvedParam.rawName, raw: true))
        .assign(
          refer('headerEncoder')
              .property('encode')
              .call(
                [refer(valueExpression)],
                {
                  'explode': literalBool(resolvedParam.explode),
                  'allowEmpty': literalBool(resolvedParam.allowEmptyValue),
                },
              ),
        )
        .statement;
  }

  Expression _generateValidateStatus() =>
      Method(
        (b) =>
            b
              ..lambda = true
              ..requiredParameters.add(Parameter((b) => b..name = '_'))
              ..body = literalBool(true).code,
      ).closure;
}
