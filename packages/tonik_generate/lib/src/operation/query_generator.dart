import 'package:code_builder/code_builder.dart';
import 'package:tonik_core/tonik_core.dart';
import 'package:tonik_generate/src/naming/name_manager.dart';
import 'package:tonik_generate/src/util/built_expression.dart';
import 'package:tonik_generate/src/util/form_entries_expression_builder.dart';
import 'package:tonik_generate/src/util/inline_helper_context.dart';
import 'package:tonik_generate/src/util/spec_literal_string.dart';
import 'package:tonik_generate/src/util/to_deep_object_query_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_delimited_query_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_form_query_parameter_expression_generator.dart';
import 'package:tonik_generate/src/util/to_json_value_expression_generator.dart';
import 'package:tonik_generate/src/util/type_reference_generator.dart';

/// Generator for creating query parameters method for operations.
class const QueryGenerator({
  required final NameManager nameManager,
  required final String package,
  final bool useImmutableCollections = false,
}) {
  /// Generates the query parameters method for the operation.
  Method generateQueryParametersMethod(
    Operation operation,
    List<({String normalizedName, QueryParameterObject parameter})>
    queryParameters,
  ) {
    final parameters = <Parameter>[];
    final helperContext = InlineHelperContext(nameManager: nameManager);
    final helpers = <InlineHelper>[];
    final body = <Code>[
      declareFinal(r'_$entries')
          .assign(
            literalList(
              [],
              refer('ParameterEntry', 'package:tonik_util/tonik_util.dart'),
            ),
          )
          .statement,
    ];

    for (final queryParam in queryParameters) {
      final paramName = queryParam.normalizedName;
      final resolvedParam = queryParam.parameter;

      final parameterType = typeReference(
        resolvedParam.model,
        nameManager,
        package,
        isNullableOverride: !resolvedParam.isRequired,
        useImmutableCollections: useImmutableCollections,
      );

      parameters.add(
        Parameter(
          (b) => b
            ..name = paramName
            ..type = parameterType
            ..named = true
            ..required = resolvedParam.isRequired,
        ),
      );

      final encodingCode = _generateEncodingCode(
        paramName,
        resolvedParam,
        helperContext: helperContext,
      );
      helpers.addAll(encodingCode.inlineFunctions);
      _addCodeWithNullCheck(
        body,
        encodingCode.unsafeRawStatements,
        paramName,
        resolvedParam,
      );
    }

    body
      ..insertAll(0, spliceInlineHelpers(helpers))
      ..add(_generateReturnStatement());

    return Method(
      (b) => b
        ..name = '_queryParameters'
        ..returns = refer('String?', 'dart:core')
        ..optionalParameters.addAll(parameters)
        ..lambda = false
        ..body = Block.of(body),
    );
  }

  BuiltStatements _generateEncodingCode(
    String paramName,
    QueryParameterObject resolvedParam, {
    required InlineHelperContext helperContext,
  }) {
    final encoding = resolvedParam.encoding;

    if (encoding == QueryParameterEncoding.json) {
      final value = buildToJsonQueryParameterExpression(
        paramName,
        resolvedParam,
        nameManager: nameManager,
        package: package,
        helperContext: helperContext,
        useImmutableCollections: useImmutableCollections,
        receiverIsPromotedNonNull: !resolvedParam.isRequired,
      );
      final entries = refer('jsonEncode', 'dart:convert')
          .call([value.unsafeRawBody])
          .property('toForm')
          .call(
            [specLiteralString(resolvedParam.rawName)],
            {
              'explode': literalBool(false),
              'allowEmpty': literalBool(false),
              'textEncoding': refer('utf8', 'dart:convert'),
            },
          );
      return BuiltStatements(
        statements: [
          refer(r'_$entries').property('addAll').call([entries]).statement,
        ],
        inlineFunctions: value.inlineFunctions,
      );
    }

    if (encoding == QueryParameterEncoding.form) {
      return buildToFormQueryParameterCode(
        paramName,
        resolvedParam,
        explode: resolvedParam.explode,
        allowEmpty: resolvedParam.allowEmptyValue,
        allowReserved: resolvedParam.allowReserved,
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
        allowReserved: resolvedParam.allowReserved,
      );
    }

    return BuiltStatements.simple([
      _generateDeepObjectEncodingStatement(paramName, resolvedParam),
    ]);
  }

  Code _generateDeepObjectEncodingStatement(
    String paramName,
    QueryParameterObject resolvedParam,
  ) {
    final deepObjectExpression = buildToDeepObjectQueryParameterCode(
      paramName,
      resolvedParam,
      allowReserved: resolvedParam.allowReserved,
    );

    return Block.of([
      const Code(r'_$entries.addAll('),
      deepObjectExpression.code,
      const Code(');'),
    ]);
  }

  void _addCodeWithNullCheck(
    List<Code> body,
    List<Code> code,
    String paramName,
    QueryParameterObject resolvedParam,
  ) {
    if (!resolvedParam.isRequired) {
      body.add(
        Block.of([Code('if ($paramName != null) {'), ...code, const Code('}')]),
      );
    } else {
      body.addAll(code);
    }
  }

  Code _generateReturnStatement() {
    return Block.of([
      const Code(r'if (_$entries.isEmpty) {'),
      const Code('  return null;'),
      const Code('}'),
      refer(r'_$entries')
          .property('map')
          .call([formEntryToWireString()])
          .property('join')
          .call([literalString('&')])
          .returned
          .statement,
    ]);
  }
}
