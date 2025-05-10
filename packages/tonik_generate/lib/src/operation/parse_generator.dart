import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/naming/property_name_normalizer.dart';
import 'package:tonik_generate/src/util/exception_code_generator.dart';
import 'package:tonik_generate/src/util/from_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/from_simple_value_expression_generator.dart';

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
      final contentTypes = <String?>{};

      if (response is ResponseObject) {
        for (final body in response.bodies) {
          contentTypes.add(body.rawContentType);
        }
      }
      if (contentTypes.isEmpty) {
        contentTypes.add(null);
      }
      for (final contentType in contentTypes) {
        final casePattern = _casePattern(status, contentType);
        final caseBody = _caseBody(operation, status, response, contentType);
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
                        (b) => b
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
    Response response,
    String? contentType,
  ) {
    final isMulti = operation.responses.length > 1;
    final wrapperName =
        isMulti ? nameManager.responseWrapperNames(operation).$2[status] : null;
    final hasHeaders = response.hasHeaders;
    final hasBody = response.bodyCount > 0;
    final responseClassName =
        hasHeaders || response.bodyCount > 1
            ? nameManager.responseName(response.resolved)
            : null;
    final bodyModel =
        hasBody && response is ResponseObject
            ? response.bodies.first.model
            : null;
    final bodyDecode =
        hasBody && bodyModel != null
            ? _decodeBody('response.data', bodyModel, nameManager)
            : null;
    final headerAssignments =
        hasHeaders && response is ResponseObject
            ? _decodeHeaders(response.headers)
            : const Code('');

    if (isMulti) {
      if (hasHeaders || response.bodyCount > 1) {
        // Wrapper subclass with response class
        return Block.of([
          Code('return $wrapperName('),
          Code('body: $responseClassName('),
          if (bodyDecode != null) ...[
            const Code('body: '),
            bodyDecode.code,
            const Code(','),
          ],
          headerAssignments,
          const Code('),'),
          const Code(');'),
        ]);
      } else if (hasBody && bodyDecode != null) {
        // Wrapper subclass with direct body
        return Block.of([
          Code('return $wrapperName('),
          const Code('body: '),
          bodyDecode.code,
          const Code(');'),
        ]);
      } else {
        // Wrapper subclass with no body
        return Code('return const $wrapperName();');
      }
    } else {
      if (hasHeaders || response.bodyCount > 1) {
        // Just response class
        return Block.of([
          Code('return $responseClassName('),
          if (bodyDecode != null) ...[
            const Code('body: '),
            bodyDecode.code,
            const Code(','),
          ],
          headerAssignments,
          const Code(');'),
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
        return const Code('return null;');
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

  Code _decodeHeaders(Map<String, ResponseHeader> headers) {
    final assignments = <Code>[];
    final properties =
        headers.entries
            .map(
              (entry) => Property(
                name: entry.key,
                model: (entry.value as ResponseHeaderObject).model,
                isRequired: (entry.value as ResponseHeaderObject).isRequired,
                isNullable: false,
                isDeprecated:
                    (entry.value as ResponseHeaderObject).isDeprecated,
              ),
            )
            .toList();
    final normalized = normalizeProperties(properties);
    for (final norm in normalized) {
      final name = norm.property.name;
      final normalizedName = norm.normalizedName;
      final header = headers[name] as ResponseHeaderObject;
      final headerValue = refer('response')
          .property('headers')
          .property('value')
          .call([literalString(name, raw: true)]);
      final decode = buildSimpleValueExpression(
        headerValue,
        model: header.model,
        isRequired: header.isRequired,
        nameManager: nameManager,
        package: package,
      );
      assignments.add(
        Block.of([Code('$normalizedName: '), decode.code, const Code(',')]),
      );
    }
    return Block.of(assignments);
  }
}
