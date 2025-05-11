import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';
import 'package:tonik_generate/src/util/response_property_normalizer.dart';

class ParseGenerator {
  const ParseGenerator({required this.nameManager, required this.package});

  final NameManager nameManager;
  final String package;

  /// Generates the _parseResponse method for the operation.
  Method generateParseResponseMethod(
    Operation operation,
    Reference responseType,
  ) {
    final responses = operation.responses;
    final cases = <Code>[];

    for (final entry in responses.entries) {
      final status = entry.key;
      final response = entry.value;
      final contentTypes = _getContentTypes(response);

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

    // Always add a default case
    final defaultCase = Block.of([
      const Code('default:'),
      const Code(
        "final content = response.headers.value('content-type') "
        "?? 'not specified';",
      ),
      const Code('final status = response.statusCode;'),
      generateDecodingExceptionExpression(
        r'Unexpected content type: $content for status code: $status',
      ).statement,
    ]);

    final switchBody = Block.of([
      const Code(
        'switch ((response.statusCode, '
        "response.headers.value('content-type'))) {",
      ),
      ...cases,
      defaultCase,
      const Code('}'),
    ]);

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
          'when status >= ${status.min} && status <= ${status.max}:',
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
    final isMulti = operation.responses.length > 1;
    final hasBody = response.bodyCount > 0;
    final bodyModel = response.bodies.firstOrNull?.model;

    final bodyDecode =
        hasBody && bodyModel != null
            ? _decodeBody('response.data', bodyModel, nameManager)
            : null;

    if (isMulti) {
      final wrapperName =
          nameManager.responseWrapperNames(operation).$2[status]!;

      if (response.hasHeaders || response.bodyCount > 1) {
        // Wrapper subclass with response class
        final responseArgs = <String, Expression>{};
        if (bodyDecode != null) {
          responseArgs['body'] = bodyDecode;
        }
        responseArgs.addAll(_decodeHeaders(response));

        final wrapperArgs = <String, Expression>{
          'body': refer(
            nameManager.responseName(response.resolved),
            package,
          ).call([], responseArgs),
        };

        return Block.of([
          const Code('return '),
          refer(wrapperName, package).call([], wrapperArgs).code,
          const Code(';'),
        ]);
      } else if (hasBody && bodyDecode != null) {
        // Wrapper subclass with direct body
        return Block.of([
          const Code('return '),
          refer(wrapperName, package).call([], {'body': bodyDecode}).code,
          const Code(';'),
        ]);
      } else {
        // Wrapper subclass with no body
        return Block.of([
          const Code('return const '),
          refer(wrapperName, package).call([]).code,
          const Code(';'),
        ]);
      }
    } else {
      if (response.hasHeaders || response.bodyCount > 1) {
        // Just response class
        final args = <String, Expression>{};
        if (bodyDecode != null) {
          args['body'] = bodyDecode;
        }
        args.addAll(_decodeHeaders(response));

        return Block.of([
          const Code('return '),
          refer(
            nameManager.responseName(response.resolved),
            package,
          ).call([], args).code,
          const Code(';'),
        ]);
      } else if (hasBody && bodyDecode != null) {
        // Just body
        return Block.of([
          const Code('return '),
          bodyDecode.code,
          const Code(';'),
        ]);
      } else {
        // No body
        return const Code('return;');
      }
    }
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
