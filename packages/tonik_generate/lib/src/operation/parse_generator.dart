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
    final responseType =
        resultTypeForOperation(
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
          generateJsonDecodingExceptionExpression(
            r'Unexpected content type: $content for status code: $status',
          ).statement,
        ]),
      );
    }

    switchCases.add(const Code('}'));

    final switchBody = Block.of(switchCases);

    return Method(
      (b) =>
          b
            ..name = '_parseResponse'
            ..returns = responseType
            ..requiredParameters.add(
              Parameter(
                (b) =>
                    b
                      ..name = 'response'
                      ..type = TypeReference(
                        (b) =>
                            b
                              ..symbol = 'Response'
                              ..url = 'package:dio/dio.dart'
                              ..types.add(refer('Object?', 'dart:core')),
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

  Expression? _createBodyDecode(ResponseObject response, String? contentType) {
    final hasBody = response.bodyCount > 0;
    if (!hasBody) return null;

    final bodyModel =
        contentType != null
            ? response.bodies
                .firstWhere(
                  (body) => body.rawContentType == contentType,
                  orElse: () => response.bodies.first,
                )
                .model
            : response.bodies.firstOrNull?.model;

    if (bodyModel == null) return null;

    return _decodeBody('response.data', bodyModel, nameManager);
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
      return bodyDecode.returned.statement;
    } else {
      return const Code('return;');
    }
  }

  Code _generateMultiResponseWithHeaders(
    String wrapperName,
    ResponseObject response,
    String? contentType,
    Expression? bodyDecode,
  ) {
    final responseArgs = <String, Expression>{};
    if (bodyDecode != null) {
      responseArgs['body'] = bodyDecode;
    }
    responseArgs.addAll(_decodeHeaders(response));

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

    return refer(wrapperName, package).call([], wrapperArgs).returned.statement;
  }

  Code _generateMultiResponseWithBody(
    String wrapperName,
    Expression bodyDecode,
  ) {
    return refer(
      wrapperName,
      package,
    ).call([], {'body': bodyDecode}).returned.statement;
  }

  Code _generateSingleResponseWithHeaders(
    ResponseObject response,
    String? contentType,
    Expression? bodyDecode,
  ) {
    final args = <String, Expression>{};
    if (bodyDecode != null) {
      args['body'] = bodyDecode;
    }
    args.addAll(_decodeHeaders(response));

    return Block.of([
      const Code('return '),
      refer(
        contentType != null && response.bodyCount > 1
            ? nameManager
                .responseNames(response)
                .implementationNames[contentType]!
            : nameManager.responseNames(response).baseName,
        package,
      ).call([], args).statement,
    ]);
  }

  Expression _decodeBody(String expr, Model model, NameManager nameManager) {
    return buildFromJsonValueExpression(
      expr,
      model: model,
      nameManager: nameManager,
      package: package,
    );
  }

  Map<String, Expression> _decodeHeaders(ResponseObject response) {
    final assignments = <String, Expression>{};
    final normalizedProperties = normalizeResponseProperties(response);
    final normalizedHeaders = normalizedProperties.where(
      (norm) => norm.property.name != 'body',
    );

    for (final norm in normalizedHeaders) {
      final rawHeaderName =
          response.headers.entries
              .firstWhere((entry) => entry.value == norm.header)
              .key;

      final normalizedName = norm.normalizedName;
      final headerValue = refer('response')
          .property('headers')
          .property('value')
          .call([literalString(rawHeaderName, raw: true)]);
      final decode = buildSimpleValueExpression(
        headerValue,
        model: norm.property.model,
        isRequired: norm.property.isRequired,
        nameManager: nameManager,
        package: package,
        contextProperty: rawHeaderName,
      );
      assignments[normalizedName] = decode;
    }
    return assignments;
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
