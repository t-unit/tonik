import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/response_property_normalizer.dart';
import 'package:tonik_generate/src/util/response_type_generator.dart';

class ParseGenerator {
  const ParseGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  /// Generates the _parseResponse method for the operation.
  Method generateParseResponseMethod(Operation operation) {
    final responses = operation.responses;
    final responseType = resultTypeForOperation(
      operation,
      nameManager,
      package,
    ).types.first;
    final cases = <Code>[];

    // Check if we have a default response with null content type
    var hasDefaultWithNullContentType = false;

    for (final entry in responses.entries) {
      final status = entry.key;
      final response = entry.value;
      final contentTypes = _getContentTypes(response);

      if (status is DefaultResponseStatus && contentTypes.contains(null)) {
        hasDefaultWithNullContentType = true;
      }

      for (final contentType in contentTypes) {
        final casePattern = _casePattern(status, contentType);
        final caseBody = _caseBody(
          operation,
          status,
          response.resolved,
          contentType,
        );
        cases
          ..add(casePattern)
          ..add(caseBody);
      }
    }

    // Only add a default case if we don't have a default response with
    // null content type
    final switchCases = <Code>[
      const Code(
        'switch ((response.statusCode, '
        "response.headers.value('content-type'))) {",
      ),
      ...cases,
    ];

    if (!hasDefaultWithNullContentType) {
      switchCases.add(
        Block.of([
          const Code('default:'),
          const Code(
            "final content = response.headers.value('content-type') "
            "?? 'not specified';",
          ),
          const Code('final status = response.statusCode;'),
          generateResponseDecodingExceptionExpression(
            r'Unexpected content type: $content for status code: $status',
          ).statement,
        ]),
      );
    }

    switchCases.add(const Code('}'));

    final switchBody = Block.of(switchCases);

    return Method(
      (b) => b
        ..name = '_parseResponse'
        ..returns = responseType
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = 'response'
              ..type = TypeReference(
                (b) => b
                  ..symbol = 'Response'
                  ..url = 'package:dio/dio.dart'
                  ..types.add(
                    TypeReference(
                      (b) => b
                        ..symbol = 'List'
                        ..url = 'dart:core'
                        ..types.add(refer('int', 'dart:core')),
                    ),
                  ),
              ),
          ),
        )
        ..lambda = false
        ..body = switchBody,
    );
  }

  Code _casePattern(ResponseStatus status, String? contentType) {
    final contentTypePattern = contentType != null ? "'$contentType'" : '_';
    switch (status) {
      case ExplicitResponseStatus():
        return Code('case (${status.statusCode}, $contentTypePattern):');
      case RangeResponseStatus():
        return Code(
          'case (var status, $contentTypePattern) '
          'when status != null '
          '&& status >= ${status.min} && status <= ${status.max}:',
        );
      case DefaultResponseStatus():
        return Code('case (_, $contentTypePattern):');
    }
  }

  Code _caseBody(
    Operation operation,
    ResponseStatus status,
    ResponseObject response,
    String? contentType,
  ) {
    if (operation.responses.length > 1) {
      return _generateMultiResponseCase(
        operation,
        status,
        response,
        contentType,
      );
    } else {
      return _generateSingleResponseCase(response, contentType);
    }
  }

  ({List<Code> statements, String varName})? _createBodyDecode(
    ResponseObject response,
    String? contentType,
  ) {
    final hasBody = response.bodyCount > 0;
    if (!hasBody) return null;

    final responseBody = contentType != null
        ? response.bodies.firstWhere(
            (body) => body.rawContentType == contentType,
            orElse: () => response.bodies.first,
          )
        : response.bodies.firstOrNull;

    if (responseBody == null) return null;

    final contentTypeEnum = responseBody.contentType;

    return switch (contentTypeEnum) {
      ContentType.json => _createJsonBodyDecode(responseBody),
      ContentType.text => _createTextBodyDecode(),
      ContentType.bytes => _createBytesBodyDecode(),
    };
  }

  ({List<Code> statements, String varName}) _createJsonBodyDecode(
    ResponseBody responseBody,
  ) {
    final statements = <Code>[];
    const jsonVar = r'_$json';
    const bodyVar = r'_$body';

    statements.add(
      declareFinal(jsonVar)
          .assign(
            refer(
              'decodeResponseJson',
              'package:tonik_util/tonik_util.dart',
            ).call(
              [refer('response.data')],
              {},
              [refer('Object?', 'dart:core')],
            ),
          )
          .statement,
    );

    final bodyExpr = buildFromJsonValueExpression(
      jsonVar,
      model: responseBody.model,
      nameManager: nameManager,
      package: package,
    );
    statements.add(declareFinal(bodyVar).assign(bodyExpr).statement);

    return (statements: statements, varName: bodyVar);
  }

  ({List<Code> statements, String varName}) _createTextBodyDecode() {
    const bodyVar = r'_$body';
    return (
      statements: [
        declareFinal(bodyVar)
            .assign(
              refer(
                'decodeResponseText',
                'package:tonik_util/tonik_util.dart',
              ).call([refer('response.data')]),
            )
            .statement,
      ],
      varName: bodyVar,
    );
  }

  ({List<Code> statements, String varName}) _createBytesBodyDecode() {
    const bodyVar = r'_$body';
    return (
      statements: [
        declareFinal(bodyVar)
            .assign(
              refer(
                'decodeResponseBytes',
                'package:tonik_util/tonik_util.dart',
              ).call([refer('response.data')]),
            )
            .statement,
      ],
      varName: bodyVar,
    );
  }

  Code _generateMultiResponseCase(
    Operation operation,
    ResponseStatus status,
    ResponseObject response,
    String? contentType,
  ) {
    final wrapperName = nameManager.responseWrapperNames(operation).$2[status]!;
    final bodyDecode = _createBodyDecode(response, contentType);

    if (response.hasHeaders || response.bodyCount > 1) {
      return _generateMultiResponseWithHeaders(
        wrapperName,
        response,
        contentType,
        bodyDecode,
      );
    } else if (bodyDecode != null) {
      return _generateMultiResponseWithBody(wrapperName, bodyDecode);
    } else {
      return refer(wrapperName, package).call([]).returned.statement;
    }
  }

  Code _generateSingleResponseCase(
    ResponseObject response,
    String? contentType,
  ) {
    final bodyDecode = _createBodyDecode(response, contentType);

    if (response.hasHeaders || response.bodyCount > 1) {
      return _generateSingleResponseWithHeaders(
        response,
        contentType,
        bodyDecode,
      );
    } else if (bodyDecode != null) {
      return Block.of([
        ...bodyDecode.statements,
        refer(bodyDecode.varName).returned.statement,
      ]);
    } else {
      return const Code('return;');
    }
  }

  Code _generateMultiResponseWithHeaders(
    String wrapperName,
    ResponseObject response,
    String? contentType,
    ({List<Code> statements, String varName})? bodyDecode,
  ) {
    final headerResult = _decodeHeaders(response);

    if (headerResult.unsupported.isNotEmpty) {
      final unsupported = headerResult.unsupported.first;
      return generateSimpleDecodingExceptionExpression(
        '${unsupported.reason} at ${unsupported.headerName}',
      ).statement;
    }

    final responseArgs = <String, Expression>{};
    if (bodyDecode != null) {
      responseArgs['body'] = refer(bodyDecode.varName);
    }
    responseArgs.addAll(headerResult.supported);

    final wrapperArgs = <String, Expression>{
      'body': refer(
        contentType != null && response.bodyCount > 1
            ? nameManager
                  .responseNames(response)
                  .implementationNames[contentType]!
            : nameManager.responseNames(response).baseName,
        package,
      ).call([], responseArgs),
    };

    return Block.of([
      if (bodyDecode != null) ...bodyDecode.statements,
      refer(wrapperName, package).call([], wrapperArgs).returned.statement,
    ]);
  }

  Code _generateMultiResponseWithBody(
    String wrapperName,
    ({List<Code> statements, String varName}) bodyDecode,
  ) {
    return Block.of([
      ...bodyDecode.statements,
      refer(
        wrapperName,
        package,
      ).call([], {'body': refer(bodyDecode.varName)}).returned.statement,
    ]);
  }

  Code _generateSingleResponseWithHeaders(
    ResponseObject response,
    String? contentType,
    ({List<Code> statements, String varName})? bodyDecode,
  ) {
    final headerResult = _decodeHeaders(response);

    if (headerResult.unsupported.isNotEmpty) {
      final unsupported = headerResult.unsupported.first;
      return generateSimpleDecodingExceptionExpression(
        '${unsupported.reason} at ${unsupported.headerName}',
      ).statement;
    }

    final args = <String, Expression>{};
    if (bodyDecode != null) {
      args['body'] = refer(bodyDecode.varName);
    }
    args.addAll(headerResult.supported);

    return Block.of([
      if (bodyDecode != null) ...bodyDecode.statements,
      refer(
        contentType != null && response.bodyCount > 1
            ? nameManager
                  .responseNames(response)
                  .implementationNames[contentType]!
            : nameManager.responseNames(response).baseName,
        package,
      ).call([], args).returned.statement,
    ]);
  }

  ({
    Map<String, Expression> supported,
    List<({String headerName, String reason})> unsupported,
  })
  _decodeHeaders(ResponseObject response) {
    final supported = <String, Expression>{};
    final unsupported = <({String headerName, String reason})>[];
    final normalizedProperties = normalizeResponseProperties(response);
    final normalizedHeaders = normalizedProperties.where(
      (norm) => norm.property.name != 'body',
    );

    for (final norm in normalizedHeaders) {
      final rawHeaderName = response.headers.entries
          .firstWhere((entry) => entry.value == norm.header)
          .key;

      final normalizedName = norm.normalizedName;
      final unsupportedReason = getSimpleDecodingUnsupportedReason(
        norm.property.model,
      );

      if (unsupportedReason != null) {
        unsupported.add((headerName: rawHeaderName, reason: unsupportedReason));
        continue;
      }

      final headerValue = refer('response')
          .property('headers')
          .property('value')
          .call([literalString(rawHeaderName, raw: true)]);
      final resolvedHeader = norm.header!.resolve();
      final decode = buildSimpleValueExpression(
        headerValue,
        model: norm.property.model,
        isRequired: norm.property.isRequired,
        nameManager: nameManager,
        package: package,
        contextProperty: rawHeaderName,
        explode: literalBool(resolvedHeader.explode),
      );
      supported[normalizedName] = decode;
    }
    return (supported: supported, unsupported: unsupported);
  }

  Set<String?> _getContentTypes(Response response) {
    final contentTypes = <String?>{};
    final resolvedResponse = response.resolved;

    for (final body in resolvedResponse.bodies) {
      contentTypes.add(body.rawContentType);
    }

    if (contentTypes.isEmpty) {
      contentTypes.add(null);
    }

    return contentTypes;
  }
}
