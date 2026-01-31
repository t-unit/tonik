import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/to_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';
import 'package:tonik_util/tonik_util.dart';

/// Generator for creating options method for operations.
class OptionsGenerator {
  const OptionsGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  /// Generates the options method for the operation.
  Method generateOptionsMethod(
    Operation operation,
    List<({String normalizedName, RequestHeaderObject parameter})> headers,
    List<({String normalizedName, CookieParameterObject parameter})>
    cookieParameters,
  ) {
    final bodyStatements = <Code>[];
    final parameters = <Parameter>[];

    final methodString = _generateMethodString(operation.method);
    final contentType = _generateContentType(
      operation.requestBody,
      bodyStatements,
      parameters,
    );
    _generateHeaders(
      headers,
      bodyStatements,
      parameters,
      operation,
    );
    _generateCookieHeader(
      cookieParameters,
      bodyStatements,
      parameters,
    );

    final optionsExpr = refer('Options', 'package:dio/dio.dart').call([], {
      'method': literalString(methodString),
      'headers': refer('headers'),
      'contentType': ?contentType,
      'responseType': refer(
        'ResponseType',
        'package:dio/dio.dart',
      ).property('bytes'),
      'validateStatus': _generateValidateStatus(),
    });

    bodyStatements.add(optionsExpr.returned.statement);

    return Method(
      (b) => b
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
        (b) => b
          ..name = 'body'
          ..type = TypeReference(
            (b) => b
              ..symbol = baseName
              ..url = package
              ..isNullable = !requestBody.isRequired,
          )
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

    // Add null case if body is optional - return null (no Content-Type header)
    if (!requestBody.isRequired) {
      cases.add(const Code('null => null,\n'));
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

  void _generateHeaders(
    List<({String normalizedName, RequestHeaderObject parameter})> headers,
    List<Code> bodyStatements,
    List<Parameter> parameters,
    Operation operation,
  ) {
    // Accept header logic
    final hasAcceptHeader = headers.any(
      (h) => h.parameter.rawName.toLowerCase() == 'accept',
    );
    final acceptHeader = headers
        .cast<({String normalizedName, RequestHeaderObject parameter})?>()
        .firstWhere(
          (h) => h?.parameter.rawName.toLowerCase() == 'accept',
          orElse: () => null,
        );
    String? acceptParamName;
    var acceptIsRequired = false;
    if (acceptHeader != null) {
      acceptParamName = acceptHeader.normalizedName;
      acceptIsRequired = acceptHeader.parameter.isRequired;
    }

    // Collect all unique response content types
    final contentTypes = <String>{};

    for (final response in operation.responses.values) {
      if (response is ResponseObject) {
        for (final body in response.bodies) {
          contentTypes.add(body.rawContentType);
        }
      }
    }

    final acceptValue = contentTypes.isNotEmpty
        ? contentTypes.join(',')
        : '*/*';

    bodyStatements.add(
      declareFinal('headers')
          .assign(
            literalMap(
              {},
              refer('String', 'dart:core'),
              refer('dynamic', 'dart:core'),
            ),
          )
          .statement,
    );

    // For required Accept header, always assign using encoder
    if (hasAcceptHeader && acceptIsRequired) {
      bodyStatements.add(
        refer('headers')
            .index(literalString('Accept', raw: true))
            .assign(
              buildToSimpleHeaderParameterExpression(
                acceptParamName!,
                acceptHeader!.parameter,
                explode: acceptHeader.parameter.explode,
                allowEmpty: acceptHeader.parameter.allowEmptyValue,
              ),
            )
            .statement,
      );
    } else if (hasAcceptHeader && !acceptIsRequired) {
      bodyStatements
        ..add(Code('if ($acceptParamName != null) {'))
        ..add(
          refer('headers')
              .index(literalString('Accept', raw: true))
              .assign(
                buildToSimpleHeaderParameterExpression(
                  acceptParamName!,
                  acceptHeader!.parameter,
                  explode: acceptHeader.parameter.explode,
                  allowEmpty: acceptHeader.parameter.allowEmptyValue,
                ),
              )
              .statement,
        )
        ..add(const Code('} else {'))
        ..add(
          refer('headers')
              .index(literalString('Accept'))
              .assign(literalString(acceptValue))
              .statement,
        )
        ..add(const Code('}'));
    } else {
      // No Accept header param, just assign default
      bodyStatements.add(
        refer('headers')
            .index(literalString('Accept'))
            .assign(literalString(acceptValue))
            .statement,
      );
    }

    // Only add headerEncoder if there are user-defined headers
    // (excluding Accept) or Accept needs encoding

    for (final headerParam in headers) {
      // Skip Accept header, already handled
      if (headerParam.parameter.rawName.toLowerCase() == 'accept') {
        parameters.add(
          _generateHeaderParameter(
            headerParam.normalizedName,
            headerParam.parameter,
          ),
        );
        continue;
      }
      final paramName = headerParam.normalizedName;
      final resolvedParam = headerParam.parameter;

      // For simple encoding, reject headers that are lists with
      // complex elements
      if (resolvedParam.encoding == HeaderParameterEncoding.simple &&
          resolvedParam.model is ListModel &&
          (resolvedParam.model as ListModel).content.encodingShape !=
              EncodingShape.simple) {
        if (resolvedParam.isRequired) {
          // Required: immediately throw at runtime
          bodyStatements.add(
            generateEncodingExceptionExpression(
              'Simple encoding does not support list with complex elements for'
              ' header ${resolvedParam.rawName}',
            ).statement,
          );
        } else {
          // Optional: only throw if provided
          bodyStatements.add(
            Block.of([
              Code('if ($paramName != null) {'),
              generateEncodingExceptionExpression(
                'Simple encoding does not support list with complex elements'
                ' for header ${resolvedParam.rawName}',
              ).statement,
              const Code('}'),
            ]),
          );
        }
        parameters.add(_generateHeaderParameter(paramName, resolvedParam));
        continue;
      }

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
  }

  /// Generates the Cookie header for cookie parameters.
  ///
  /// Cookies are encoded using form style (the only style valid for cookies
  /// per OpenAPI 3.x) and concatenated as `name1=value1; name2=value2`.
  void _generateCookieHeader(
    List<({String normalizedName, CookieParameterObject parameter})>
    cookieParameters,
    List<Code> bodyStatements,
    List<Parameter> parameters,
  ) {
    if (cookieParameters.isEmpty) {
      return;
    }

    // Generate method parameters for each cookie.
    for (final cookie in cookieParameters) {
      final paramType = typeReference(
        cookie.parameter.model,
        nameManager,
        package,
        isNullableOverride: !cookie.parameter.isRequired,
      );

      parameters.add(
        Parameter(
          (b) => b
            ..name = cookie.normalizedName
            ..type = paramType
            ..named = true
            ..required = cookie.parameter.isRequired,
        ),
      );
    }

    final requiredCookies = cookieParameters
        .where((c) => c.parameter.isRequired)
        .toList();
    final optionalCookies = cookieParameters
        .where((c) => !c.parameter.isRequired)
        .toList();

    bodyStatements.add(
      declareFinal('cookieParts')
          .assign(
            literalList(
              [],
              refer('String', 'dart:core'),
            ),
          )
          .statement,
    );

    for (final cookie in requiredCookies) {
      _addCookieEncodingStatement(cookie, bodyStatements);
    }

    for (final cookie in optionalCookies) {
      bodyStatements.add(Code('if (${cookie.normalizedName} != null) {'));
      _addCookieEncodingStatement(cookie, bodyStatements);
      bodyStatements.add(const Code('}'));
    }

    bodyStatements
      ..add(const Code('if (cookieParts.isNotEmpty) {'))
      ..add(
        refer('headers')
            .index(literalString('Cookie', raw: true))
            .assign(
              refer('cookieParts').property('join').call([literalString('; ')]),
            )
            .statement,
      )
      ..add(const Code('}'));
  }

  void _addCookieEncodingStatement(
    ({String normalizedName, CookieParameterObject parameter}) cookie,
    List<Code> bodyStatements,
  ) {
    final model = cookie.parameter.model;
    final rawName = cookie.parameter.rawName;
    final paramName = cookie.normalizedName;
    final explode = cookie.parameter.explode;

    if (model is ListModel) {
      final contentModel = model.content is AliasModel
          ? (model.content as AliasModel).resolved
          : model.content;

      if (contentModel is StringModel) {
        final encodedValue = refer(paramName).property('toForm').call([], {
          'explode': literalBool(explode),
          'allowEmpty': literalBool(true),
        });
        bodyStatements.add(
          refer('cookieParts').property('add').call([
            literalString('$rawName=', raw: true).operatorAdd(encodedValue),
          ]).statement,
        );
        return;
      }

      bodyStatements.add(
        refer('cookieParts').property('add').call([
          literalString('$rawName=', raw: true).operatorAdd(
            refer(paramName)
                .property('map')
                .call([
                  Method(
                    (b) => b
                      ..lambda = true
                      ..requiredParameters.add(
                        Parameter((b) => b..name = 'e'),
                      )
                      ..body = refer('e').property('toForm').call([], {
                        'explode': literalBool(explode),
                        'allowEmpty': literalBool(true),
                      }).code,
                  ).closure,
                ])
                .property('toList')
                .call([])
                .property('toForm')
                .call([], {
                  'explode': literalBool(explode),
                  'allowEmpty': literalBool(true),
                  'alreadyEncoded': literalBool(true),
                }),
          ),
        ]).statement,
      );
      return;
    }

    // For non-list types, use toForm directly.
    final encodedValue = refer(paramName).property('toForm').call([], {
      'explode': literalBool(explode),
      'allowEmpty': literalBool(true),
    });
    bodyStatements.add(
      refer('cookieParts').property('add').call([
        literalString('$rawName=', raw: true).operatorAdd(encodedValue),
      ]).statement,
    );
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
      (b) => b
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
    final valueExpression = buildToSimpleHeaderParameterExpression(
      paramName,
      resolvedParam,
      explode: resolvedParam.explode,
      allowEmpty: resolvedParam.allowEmptyValue,
    );

    return refer('headers')
        .index(literalString(resolvedParam.rawName, raw: true))
        .assign(valueExpression)
        .statement;
  }

  Expression _generateValidateStatus() => Method(
    (b) => b
      ..lambda = true
      ..requiredParameters.add(Parameter((b) => b..name = '_'))
      ..body = literalBool(true).code,
  ).closure;
}
